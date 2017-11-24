// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

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
    ];
  }

  Future<Null> _onMessage(din.Message message) async {
    if (message.mentions.length == 1 &&
        message.mentions.first.id == _loggedInAs.id &&
        message.content.startsWith('<@')) {
      log(
        'Received message from "${message.user.name}".\n${message.content}',
        severity: Severity.info,
      );
      Iterable<String> args = shellSplit(message.content);
      final runner = new Runner(
        new _Interface(_client, message.channelId),
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

  Future<Null> close() async {
    await _cache.clear();
    await Future.wait<dynamic>(_streamSubs.map((s) => s.cancel()));
    await _gateway.close();
  }
}

class _Interface implements Interface {
  final din.ApiClient _api;
  final String _channelId;

  _Interface(this._api, this._channelId);

  @override
  String get botNameAndVersion => 'Harmony v0.1.0-dev+1';

  @override
  bool get formatForMarkdown => true;

  @override
  Future<Null> reply(String message) async {
    await _api.channels.createMessage(channelId: _channelId, content: message);
  }
}
