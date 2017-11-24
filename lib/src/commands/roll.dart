// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../runner.dart';

class _RollCommand extends Command<Null> with _CommandMixin {
  static final _rng = new Random();

  static int _roll(int sides) => _rng.nextInt(sides) + 1;

  @override
  final Interface _interface;

  _RollCommand(this._interface);

  @override
  final name = 'roll';

  @override
  final description = 'Roll a dice in the format of NdN.';

  @override
  Future<Null> run() async {
    int amount;
    int sides;
    if (argResults.rest.isEmpty) {
      amount = 1;
      sides = 6;
    } else {
      final parse = argResults.rest.first.split('d');
      amount = int.parse(parse.first, onError: (_) => null);
      sides = int.parse(parse.last, onError: (_) => null);
      if (amount == null || sides == null) {
        log('Ignoring "$parse" (cannot parse).');
        return;
      }
    }
    if (amount > 10 || sides > 100) {
      log('Ignoring ${amount}d$sides (abusive request).');
      return;
    }
    final results = new List<String>.generate(
      amount,
      (i) => '* ${_roll(sides)}',
    );
    _interface.reply(
      '🎲  Rolled 🎲  ${amount}d$sides\n\n${results.join('\n')}',
    );
  }
}
