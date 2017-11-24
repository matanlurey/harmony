// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:harmony/src/runner.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group('harmony', () {
    Interface interface;
    setUp(() => interface = new MockInterface());

    test('help should emit usage instructions', () async {
      when(interface.formatForMarkdown).thenReturn(true);
      await new Runner(interface, null, null).run(['help']);
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
      await new Runner(interface, null, null).run(['about']);
      verify(interface.reply('Bot v1.0.0'));
    });
  });
}

class MockInterface extends Mock implements Interface {}
