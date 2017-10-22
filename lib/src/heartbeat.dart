// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Manages pending/sent heart beats in order to detect timeouts.
abstract class Heartbeat {
  static DateTime _defaultClock() => new DateTime.now();
  static Timer _defaultSchedule(Duration time, void Function() fn) {
    return new Timer(time, fn);
  }

  factory Heartbeat({
    DateTime Function() clock: _defaultClock,
    Duration timeout: const Duration(seconds: 10),
    Timer Function(Duration, void Function()) schedule: _defaultSchedule,
  }) =>
      new _Heartbeat(timeout, clock, schedule);

  /// Close and terminate the mechanism.
  void close();

  /// Invoke when a heart beat was sent.
  void sentBeat();

  /// Invoke when an "ack" was received.
  void receivedAck();

  /// Emits the time difference between [sentBeat] and [receivedAck].
  Stream<Duration> get onPing;

  /// Emits the time that a timeout was suspected.
  Stream<DateTime> get onTimeout;
}

class _Heartbeat implements Heartbeat {
  final Duration _timeout;
  final DateTime Function() _clock;
  final Timer Function(Duration, void Function()) _schedule;

  final _onPing = new StreamController<Duration>.broadcast();
  final _onTimeout = new StreamController<DateTime>.broadcast();

  DateTime _startTime;
  Timer _timeoutWait;

  _Heartbeat(this._timeout, this._clock, this._schedule);

  @override
  void close() {
    _timeoutWait?.cancel();
    _onPing.close();
    _onTimeout.close();
  }

  @override
  Stream<Duration> get onPing => _onPing.stream;

  @override
  Stream<DateTime> get onTimeout => _onTimeout.stream;

  @override
  void receivedAck() {
    _timeoutWait?.cancel();
    final endTime = _clock();
    _onPing.add(endTime.difference(_startTime));
  }

  @override
  void sentBeat() {
    _startTime = _clock();
    _timeoutWait?.cancel();
    _timeoutWait = _schedule(_timeout, () {
      _onTimeout.add(_startTime);
    });
  }
}
