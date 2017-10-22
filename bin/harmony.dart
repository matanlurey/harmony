// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cable/cable.dart';
import 'package:harmony/harmony.dart';
import 'package:harmony/src/cache.dart';
import 'package:harmony/src/logger.dart';
import 'package:harmony/src/safety.dart';
import 'package:stack_trace_codec/stack_trace_codec.dart';

Future<Null> main(List<String> args) async {
  final results = _parser.parse(args);
  var json = const <String, Object>{};
  Cache<Object, Object> cache = const NullCache();
  if (results.wasParsed('gcloud-json-path')) {
    final path = results['gcloud-json-path'] as String;
    // ignore: invalid_assignment
    json = JSON.decode(new File(path).readAsStringSync());
  }
  if (results['cache'] == true) {
    cache = new MemoryCache();
  }
  // ignore: argument_type_not_assignable
  await initLogging<Null>(() {
    return runSafely(() async {
      final key = results['discord-api-key'] as String;
      final bot = await HarmonyBot.connect(key, cache: cache);
      await ProcessSignal.SIGINT.watch().first;
      log('Received SIGINT...', severity: Severity.notice);
      await bot.close();
      log('Exiting...', severity: Severity.info);
    }, (e, s) {
      log('UNHANDLED EXCEPTION: $e', severity: Severity.error);
      log({
        'error': '$e',
        'stack': const JsonTraceCodec().encode(s.toTrace()),
      }, severity: Severity.error);
    });
  }, googleCloudKey: json, severity: Severity.debug);
}

final _parser = new ArgParser()
  ..addOption('discord-api-key', abbr: 'd', help: 'Discord API Key')
  ..addOption('gcloud-json-path', abbr: 'g', help: 'Google Cloud JSON Path')
  ..addFlag('cache', abbr: 'c', defaultsTo: false);
