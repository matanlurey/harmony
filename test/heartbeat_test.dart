// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:harmony/src/heartbeat.dart';
import 'package:test/test.dart';

void main() {
  group('Heartbeat', () {
    Heartbeat heartbeat;
    DateTime time;
    FakeTimer timer;

    setUp(() {
      heartbeat = new Heartbeat(
        clock: () => time,
        timeout: const Duration(seconds: 10),
        schedule: (time, fn) => timer = new FakeTimer(time, fn),
      );
    });

    test('should trigger onPing', () {
      expect(heartbeat.onPing.first, completion(const Duration(seconds: 5)));
      time = new DateTime.utc(2017);
      heartbeat.sentBeat();
      expect(timer._time, const Duration(seconds: 10));
      time = time.add(const Duration(seconds: 5));
      heartbeat.receivedAck();
    });

    test('should trigger onTimeout', () {
      time = new DateTime.utc(2017);
      expect(heartbeat.onTimeout.first, completion(time));
      heartbeat.sentBeat();
      timer.trigger();
    });
  });
}

class FakeTimer implements Timer {
  final Duration _time;
  final void Function() _callback;

  const FakeTimer(this._time, this._callback);

  void trigger() => _callback();

  @override
  void cancel() {}

  @override
  bool get isActive => true;
}
