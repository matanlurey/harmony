// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:harmony/harmony.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group('harmony', () {
    Interface interface;
    setUp(() => interface = new MockInterface());

    test('help should emit usage instructions', () async {
      when(interface.formatForMarkdown).thenReturn(true);
      await new Runner(interface).run(['help']);
      verify(
        // TODO(https://github.com/dart-lang/mockito/issues/80).
        // ignore: argument_type_not_assignable
        interface.reply(typed(argThat(
          allOf(
            startsWith('```'),
            contains('<command> [arguments]'),
            endsWith('```'),
          ),
        ))),
      );
    });

    test('about should emit the bot name and version', () async {
      when(interface.botNameAndVersion).thenReturn('Bot v1.0.0');
      await new Runner(interface).run(['about']);
      verify(interface.reply('Bot v1.0.0'));
    });

    group('seen', () {
      test('should emit unknown if not seen', () async {
        when(interface.lastSeen('123')).thenAnswer((_) async => null);
        await new Runner(interface).run(['seen', '123']);
        verify(interface.reply('Unknown'));
      });

      test('should return a fuzzy timestamp if seen', () async {
        when(interface.lastSeen('123')).thenAnswer((_) async {
          return new DateTime.utc(2017);
        });

        // TODO(https://github.com/andresaraujo/timeago.dart/issues/9).
        // Can't give a precise timestamp because there is no testability.
        await new Runner(interface).run(['seen', '123']);

        // TODO(https://github.com/dart-lang/mockito/issues/80).
        // ignore: argument_type_not_assignable
        verify(interface.reply(typed(argThat(startsWith('Last seen')))));
      });
    }, skip: 'Not current enabled.');
  });
}

class MockInterface extends Mock implements Interface {}
