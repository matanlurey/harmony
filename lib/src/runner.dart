// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:args/command_runner.dart';
import 'package:cable/cable.dart';
import 'package:din/din.dart' as din;
import 'package:http/http.dart';
import 'package:timeago/timeago.dart';

import 'cache.dart';

part 'commands/about.dart';
part 'commands/flip.dart';
part 'commands/joke.dart';
part 'commands/uptime.dart';
part 'commands/roll.dart';
part 'commands/seen.dart';

/// A limited interface into bot functionality to implement commands.
abstract class Interface {
  /// Name of the bot application and version.
  String get botNameAndVersion;

  /// Whether to attempt to reply with markdown formatting.
  bool get formatForMarkdown;

  /// Returns when the specified [userId] was last seen online.
  DateTime lastSeenOnline(String userId);

  /// What users were mentioned in this last message, if any.
  List<din.User> get mentions;

  /// Random, potentially seeded.
  Random get random;

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
    addCommand(new _FlipCommand(_interface));
    addCommand(new _JokeCommand(_interface, _cache));
    addCommand(new _UptimeCommand(_interface, _lastOnline));
    addCommand(new _RollCommand(_interface));
    addCommand(new _SeenCommand(_interface));
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
