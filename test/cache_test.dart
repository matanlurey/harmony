// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:harmony/src/cache.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryCache', () {
    // Create a cache of a maximum of 3 items.
    Cache<String, String> cache;
    setUp(() => cache = new MemoryCache(3));

    test('should automatically expunge cache on LRU', () async {
      await cache.put('1', 'one');
      await cache.put('2', 'two');
      await cache.put('3', 'three');
      expect(await cache.size, 3, reason: 'Should have 3 items');

      expect(await cache.get('1'), isNotNull, reason: 'Should not miss');
      await cache.put('4', 'four');

      expect(await cache.size, 3);
      expect(await cache.get('1'), isNull, reason: 'Should miss (LRU evict)');
    });

    test('should invoke absent() on a cache miss', () async {
      expect(await cache.get('foo', absent: (_) => 'bar'), 'bar');
    });

    // TODO: Add additional test coverage.
  });
}
