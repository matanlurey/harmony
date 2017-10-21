// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cable/cable.dart';
import 'package:cable_stackdriver/cable_stackdriver.dart';

/// Executes [run], setting up a logging service.
///
/// If [googleCloudKey] is provided, creates a GCP logging client as well.
Future<T> initLogging<T>(
  T Function<T>() run, {
  Map<String, Object> googleCloudKey: const {},
  Severity severity: Severity.info,
}) async {
  String name = googleCloudKey['project_id'];
  if (name == null) {
    name = 'harmony';
  } else {
    name = 'projects/$name/logs/bot';
  }
  return new Logger<Object>(
    destinations: [
      LogSink.printSink,
      googleCloudKey.isNotEmpty
          ? await Stackdriver.serviceAccount<String>(googleCloudKey)
          : LogSink.nullSink,
    ],
    name: name,
  ).scope<T>(() {
    log(
      'Logging initialized ${googleCloudKey.isNotEmpty ? '(GCP)' : '(Local)'}',
      severity: severity,
    );
    return run();
  });
}
