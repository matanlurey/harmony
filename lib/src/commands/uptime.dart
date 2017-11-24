// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../runner.dart';

class _UptimeCommand extends Command<Null> with _CommandMixin {
  @override
  final Interface _interface;
  final DateTime _lastOnline;

  _UptimeCommand(this._interface, this._lastOnline);

  @override
  final name = 'uptime';

  @override
  final description = 'Display when the bot connected';

  @override
  Future<Null> run() async {
    return _interface.reply('Online since ${timeAgo(_lastOnline)}');
  }
}
