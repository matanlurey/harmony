// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../runner.dart';

class _FlipCommand extends Command<Null> with _CommandMixin {
  @override
  final Interface _interface;

  _FlipCommand(this._interface);

  @override
  final name = 'flip';

  @override
  final description = 'Flip a coin.';

  bool _flip() => _interface.random.nextInt(2) == 1;

  @override
  Future<Null> run() async {
    _interface.reply('Flipped a coin: got ${_flip() ? 'heads' : 'tails'}');
  }
}
