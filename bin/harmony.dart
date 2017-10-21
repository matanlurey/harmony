// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cable/cable.dart';
import 'package:harmony/harmony.dart';
import 'package:harmony/src/logger.dart';
import 'package:harmony/src/safety.dart';

Future<Null> main(List<String> args) async {
  var json = const <String, Object>{};
  if (args.length > 1) {
    // ignore: invalid_assignment
    json = JSON.decode(new File(args.last).readAsStringSync());
  }
  // ignore: argument_type_not_assignable
  return initLogging(() {
    return runSafely(() async {
      final bot = await HarmonyBot.connect(args.first);
      await ProcessSignal.SIGINT.watch().first;
      log('Received SIGINT...', severity: Severity.notice);
      await bot.close();
      log('Exiting...', severity: Severity.info);
    }, (e, s) {
      log('UNHANDLED EXCEPTION: $e\n$s', severity: Severity.error);
    });
  }, googleCloudKey: json);
}
