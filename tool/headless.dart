// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cable/cable.dart';
import 'package:harmony/src/cache.dart';
import 'package:harmony/src/logger.dart';
import 'package:harmony/src/runner.dart';
import 'package:harmony/src/safety.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:io/io.dart';

Future<Null> main(List<String> args) async {
  var json = const <String, Object>{};
  if (args.length > 1) {
    // ignore: invalid_assignment
    json = JSON.decode(new File(args.last).readAsStringSync());
  }
  // ignore: argument_type_not_assignable
  return initLogging(() {
    return runSafely(() async {
      ProcessSignal.SIGINT.watch().first.then((_) {
        log('Received SIGINT...', severity: Severity.notice);
        log('Exiting...', severity: Severity.info);
        exit(0);
      });
      log('Starting in HEADLESS mode...', severity: Severity.notice);
      final runner = new Runner(
        const _Headless(),
        const NullCache(),
        new DateTime.now(),
      );
      log('Listening for commands...', severity: Severity.notice);
      await for (final line in sharedStdIn.lines()) {
        try {
          await runner.run(shellSplit(line));
        } on UsageException catch (_) {
          // TODO(https://github.com/dart-lang/args/issues/81).
        }
      }
    }, (e, s) {
      log('UNHANDLED EXCEPTION: $e\n$s', severity: Severity.error);
    });
  }, googleCloudKey: json, severity: Severity.debug);
}

class _Headless implements Interface {
  const _Headless();

  @override
  String get botNameAndVersion => 'Harmony [HEADLESS] v0.1.0-dev';

  @override
  bool get formatForMarkdown => false;

  @override
  Future<DateTime> lastSeen(String userId) async => null;

  @override
  Future<Null> reply(String message) async {
    print(ansi.wrapWith(_indent4(message), [
      ansi.darkGray,
    ]));
  }

  static String _indent4(String input) =>
      input.split('\n').map((line) => "${(' ' * 4)}$line").join('\n');
}
