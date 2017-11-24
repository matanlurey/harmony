// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../runner.dart';

class _SeenCommand extends Command<Null> with _CommandMixin {
  @override
  final Interface _interface;

  _SeenCommand(this._interface);

  @override
  final name = 'seen';

  @override
  final description = 'Displays when a user was last seen online.';

  @override
  Future<Null> run() async {
    if (_interface.mentions.length != 1) {
      _interface.reply(usage);
      return;
    }
    final user = _interface.mentions.first;
    final seen = _interface.lastSeenOnline(user.id);
    if (seen == null) {
      _interface.reply("I don't have that data, sorry.");
    } else {
      _interface.reply("I saw ${user.name} online ${timeAgo(seen)}.");
    }
  }
}
