// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  return new Logger<Object>(
    destinations: [
      const _JsonFormattedSink(),
      googleCloudKey.isNotEmpty
          ? await Stackdriver.serviceAccount<String>(
              googleCloudKey,
              toJson: (j) => j as Map<String, Object>,
              logName: 'projects/${googleCloudKey['project_id']}/logs/bot',
            )
          : LogSink.nullSink,
    ],
    name: 'harmony',
    severity: severity,
  ).scope<T>(() {
    log(
      'Logging initialized ${googleCloudKey.isNotEmpty ? '(GCP)' : '(Local)'}',
      severity: Severity.notice,
    );
    return run();
  });
}

class _JsonFormattedSink implements Sink<Record> {
  const _JsonFormattedSink();

  @override
  void add(Record data) {
    stdout.writeln(_formatter(data));
  }

  @override
  void close() {}
}

const _json = const JsonEncoder.withIndent('  ');

String _formatter(Record<Object> record) {
  final timestamp = record.timestamp;
  final timeFormat = new StringBuffer()
    ..write(timestamp.hour)
    ..write(':')
    ..write(timestamp.minute)
    ..write(':')
    ..write(timestamp.second);
  final name = record.origin != null ? ' ${record.origin}:' : '';
  final payload = record.payload is Map
      ? _json.convert(record.payload)
      : record.payload.toString();
  return '[${record.severity} @ $timeFormat]$name $payload';
}
