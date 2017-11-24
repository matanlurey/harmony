// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../runner.dart';

class _AboutCommand extends Command<Null> with _CommandMixin {
  @override
  final Interface _interface;

  _AboutCommand(this._interface);

  @override
  final name = 'about';

  @override
  final description = 'Display the bot name and version';

  @override
  Future<Null> run() async {
    await _interface.reply(_interface.botNameAndVersion);
  }
}
