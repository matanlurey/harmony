// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:args/command_runner.dart';
import 'package:cable/cable.dart';
import 'package:din/din.dart' as din;
import 'package:io/io.dart';

import 'cache.dart';
import 'runner.dart';

class HarmonyBot {
  static Future<HarmonyBot> connect(
    String apiKey, {
    Cache<Object, Object> cache: const NullCache(),
  }) async {
    final client = new din.ApiClient(
      rest: new din.RestClient(
        auth: new din.AuthScheme.asBot(apiKey),
      ),
    );
    log('Connecting...', severity: Severity.info);
    final connection = await client.gateway.getGatewayBot();
    final gateway = await client.connect(connection.url);
    log('Connected to ${connection.url}!', severity: Severity.notice);
    return new HarmonyBot._(
      cache,
      await gateway.events.ready.first.then((r) => r.user),
      client,
      gateway,
    );
  }

  final Cache<Object, Object> _cache;
  final din.User _loggedInAs;
  final din.ApiClient _client;
  final din.GatewayClient _gateway;

  List<StreamSubscription> _streamSubs;
  DateTime _lastOnline;

  HarmonyBot._(this._cache, this._loggedInAs, this._client, this._gateway) {
    _lastOnline = new DateTime.now();
    _gateway.onClose.then((reason) {
      if (reason != null) {
        log('Gateway closed: $reason', severity: Severity.critical);
      }
    });
    _streamSubs = [
      _gateway.events.messageCreate.listen(_onMessage),
      _gateway.events.guildCreate.listen(_onGuildCreate),
      _gateway.events.presenceUpdate.listen(_onPresence),
      _gateway.events.unknownEvent.listen(_onUnknown),
    ];
  }

  Future<Null> _onGuildCreate(din.Guild guild) async {
    guild.presences.forEach(_onPresence);
  }

  Future<Null> _onMessage(din.Message message) async {
    final mentions = message.mentions.reversed.toList();
    if (mentions.isNotEmpty &&
        mentions.first.id == _loggedInAs.id &&
        message.content.startsWith('<@${_loggedInAs.id}')) {
      log(
        'Received message from "${message.user.name}".\n${message.content}',
        severity: Severity.info,
      );
      Iterable<String> args = shellSplit(message.content);
      final runner = new Runner(
        _createInterface(message.channelId, mentions.skip(1).toList()),
        _cache,
        _lastOnline,
      );
      args = args.skip(1);
      try {
        await runner.run(args.toList());
      } on UsageException catch (_) {
        // TODO(https://github.com/dart-lang/args/issues/81).
      }
    }
  }

  Interface _createInterface(String channelId, List<din.User> mentions) {
    return new _Interface(
      _client,
      mentions,
      channelId,
      lastSeenOnline: (id) => _isCurrentlyOnline.contains(id)
          ? new DateTime.now()
          : _lastSeenOnline[id],
    );
  }

  // User ID --> DateTime.
  final _isCurrentlyOnline = new Set<String>();
  final _lastSeenOnline = <String, DateTime>{};

  Future<Null> _onPresence(din.PresenceUpdate update) async {
    if (update.status == 'online') {
      _isCurrentlyOnline.add(update.user.id);
      _lastSeenOnline.remove(update.user.id);
    } else {
      _isCurrentlyOnline.remove(update.user.id);
      _lastSeenOnline[update.user.id] = new DateTime.now();
    }
  }

  Future<Null> _onUnknown(din.GatewayDispatch dispatch) async {
    log(
      {
        'name': dispatch.name,
        'opcode': dispatch.op,
        'data': const JsonEncoder.withIndent('  ').convert(dispatch.data),
      },
      severity: Severity.debug,
    );
  }

  Future<Null> close() async {
    await _cache.clear();
    await Future.wait<dynamic>(_streamSubs.map((s) => s.cancel()));
    await _gateway.close();
  }
}

class _Interface implements Interface {
  final din.ApiClient _api;
  final String _channelId;

  @override
  final List<din.User> mentions;

  final DateTime Function(String) _lastSeen;

  _Interface(
    this._api,
    this.mentions,
    this._channelId, {
    DateTime Function(String) lastSeenOnline,
  })
      : this._lastSeen = lastSeenOnline;

  @override
  String get botNameAndVersion => 'Harmony v0.1.0-dev+1';

  @override
  bool get formatForMarkdown => true;

  @override
  DateTime lastSeenOnline(String id) => _lastSeen(id);

  @override
  final Random random = new Random.secure();

  @override
  Future<Null> reply(String message) async {
    await _api.channels.createMessage(channelId: _channelId, content: message);
  }
}
