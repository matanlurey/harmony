// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:args/command_runner.dart';
import 'package:cable/cable.dart';
import 'package:http/http.dart';
import 'package:timeago/timeago.dart';

import 'cache.dart';

/// A limited interface into bot functionality to implement commands.
abstract class Interface {
  /// Name of the bot application and version.
  String get botNameAndVersion;

  /// Whether to attempt to reply with markdown formatting.
  bool get formatForMarkdown;

  /// Returns a future that completes when [userId] was last seen online.
  ///
  /// If the user _is_ online, the result might be slightly off.
  ///
  /// If the user _is_ online, but AFK, returns when last not AFK.
  ///
  /// If data does not exist, returns `null`.
  Future<DateTime> lastSeen(String userId);

  /// Reply on the channel ID the commands was received with [message].
  Future<Null> reply(String message);
}

class Runner extends CommandRunner<Null> {
  final Interface _interface;
  final Cache<Object, Object> _cache;
  final DateTime _lastOnline;

  Runner(
    this._interface,
    this._cache,
    this._lastOnline,
  )
      : super('@Harmony', '') {
    addCommand(new _AboutCommand(_interface));
    addCommand(new _JokeCommand(_interface, _cache));
    addCommand(new _UptimeCommand(_interface, _lastOnline));
  }

  @override
  printUsage() {
    if (_interface.formatForMarkdown) {
      _interface.reply('```\n$usage\n```');
    } else {
      _interface.reply(usage);
    }
  }

  @override
  usageException(String message) {
    if (_interface.formatForMarkdown) {
      _interface.reply('$message\n```\n$usage\n```');
    }
    // TODO(https://github.com/dart-lang/args/issues/81).
    // Remove after it's safe not to always throw an exception.
    return super.usageException(message);
  }
}

abstract class _CommandMixin implements Command<Null> {
  Interface get _interface;

  @override
  printUsage() {
    if (_interface.formatForMarkdown) {
      _interface.reply('```\n$usage\n```');
    } else {
      _interface.reply(usage);
    }
  }

  @override
  usageException(String message) {
    if (_interface.formatForMarkdown) {
      _interface.reply('$message\n```\n$usage\n```');
    }
    // TODO(https://github.com/dart-lang/args/issues/81).
    // Remove after it's safe not to always throw an exception.
    return super.usageException(message);
  }
}

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

class _JokeCommand extends Command<Null> with _CommandMixin {
  @override
  final Interface _interface;
  final Cache<Object, Object> _cache;

  _JokeCommand(this._interface, this._cache);

  @override
  final name = 'joke';

  @override
  final description = 'Tells a random joke';

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
      final joke = jokes[random.nextInt(jokes.length)];
      final setup = joke['setup'] as String;
      final punch = joke['punchline'];
      await _interface.reply('_${setup}_');
      await new Future<Null>.delayed(const Duration(seconds: 4));
      await _interface.reply('_${punch}_');
    }
  }
}

// TODO: Add once supported.
// ignore: unused_element
class _SeenCommand extends Command<Null> with _CommandMixin {
  @override
  final Interface _interface;

  _SeenCommand(this._interface);

  @override
  final name = 'seen';

  @override
  final description = 'Displays when a user was last seen online';

  @override
  final usage = 'A @user name';

  @override
  Future<Null> run() async {
    final args = argResults.rest;
    if (args.length != 1) {
      return _interface.reply(usage);
    }
    final seen = await _interface.lastSeen(args.first);
    if (seen == null) {
      return _interface.reply('Unknown');
    }
    return _interface.reply('Last seen ${timeAgo(seen)}');
  }
}

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
