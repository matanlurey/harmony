// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../runner.dart';

class _JokeCommand extends Command<Null> with _CommandMixin {
  @override
  final Interface _interface;
  final Cache<Object, Object> _cache;

  _JokeCommand(this._interface, this._cache);

  @override
  final name = 'joke';

  @override
  final description = 'Tell a random joke.';

  static const _apiEndpoint =
      'https://08ad1pao69.execute-api.us-east-1.amazonaws.com/dev/random_ten';

  @override
  Future<Null> run() async {
    log('Checking cache for jokes...', severity: Severity.debug);
    final jokes = await _cache.get(
      'random-joke',
      age: const Duration(minutes: 1),
      absent: (_) {
        log('Cache miss. Calling API for jokes...', severity: Severity.debug);
        return get(_apiEndpoint)
            .then((response) {
          log(
            'Got a response from the jokes API!',
            severity: Severity.debug,
          );
          final json = JSON.decode(
            response.body,
          ) as List<Map<String, Object>>;
          return json;
        })
            .timeout(const Duration(seconds: 5))
            .catchError((Object e) async {
          log('Error calling jokes API: $e', severity: Severity.warning);
          await _interface.reply('I forgot my joke. Ask me later');
        });
      },
    );
    if (jokes != null) {
      final random = new Random();
      final joke = jokes.removeAt(random.nextInt(jokes.length));
      final setup = joke['setup'] as String;
      final punch = joke['punchline'];
      if (jokes.isEmpty) {
        await _cache.remove('random-joke');
      }
      await _interface.reply('_${setup}_');
      await new Future<Null>.delayed(const Duration(seconds: 4));
      await _interface.reply('_${punch}_');
    }
  }
}