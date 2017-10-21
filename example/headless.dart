// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cable/cable.dart';
import 'package:cable_stackdriver/cable_stackdriver.dart';
import 'package:din/din.dart' as din;
import 'package:harmony/harmony.dart';
import 'package:io/io.dart';

Future<Null> main(List<String> args) async {
  var sink = LogSink.nullSink;
  var json = const <String, Object>{'project_id': 'debug'};
  if (args.length > 1) {
    // ignore: invalid_assignment
    json = JSON.decode(new File(args.last).readAsStringSync());
    sink = await Stackdriver.serviceAccount<Object>(json);
  }
  await new Logger(
    destinations: [
      // TODO: Replace with a prettier sink.
      LogSink.printSink,
      sink,
    ],
    severity: Severity.debug,
    name: 'projects/${json['project_id']}/logs/example',
  ).scope(() async {
    final client = new din.ApiClient(
      rest: new din.RestClient(
        auth: new din.AuthScheme.asBot(args.first),
      ),
    );
    log('Connecting...', severity: Severity.notice);
    final connection = await client.gateway.getGatewayBot();
    final gateway = await client.connect(connection.url);
    log('Connected!', severity: Severity.notice);
    final ready = await gateway.events.ready.first;
    log('Listening for messages...', severity: Severity.notice);
    await for (final message in gateway.events.messageCreate) {
      if (message.mentions.isNotEmpty &&
          message.mentions.first.id == ready.user.id) {
        log(
          'Received message from "${message.user.name}"',
          severity: Severity.info,
        );
        Iterable<String> args = shellSplit(message.content);
        log('Arguments: $args', severity: Severity.debug);
        try {
          final runner = new Runner(new _Interface(client, message.channelId));
          args = args.skip(1);
          await runner.run(args);
        } on UsageException catch (e) {
          log('Usage not allowed: $e', severity: Severity.warning);
        } catch (e) {
          log('Unhandled exception: $e', severity: Severity.error);
        }
      }
    }
  });
}

class _Interface implements Interface {
  final din.ApiClient _api;
  final String _channelId;

  _Interface(this._api, this._channelId);

  @override
  String get botNameAndVersion => 'Harmony v0.1.0-alpha';

  @override
  bool get formatForMarkdown => true;

  @override
  Future<DateTime> lastSeen(String userId) async => null;

  @override
  Future<Null> reply(String message) async {
    await _api.channels.createMessage(channelId: _channelId, content: message);
  }
}
