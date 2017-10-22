// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A persistent agnostic and asynchronous cache interface.
abstract class Cache<K, V> {
  /// Clears the entire cache.
  Future<Null> clear();

  /// Clears entries in the cache older than [now].
  Future<Null> expire({DateTime now, Duration age});

  /// Retrieves a value stored as [key] from the cache.
  ///
  /// * If [age] is provided and the cache is old, it is considered a miss.
  /// * If [absent] is provided, and there is a miss, it is invoked.
  Future<T> get<T extends V>(
    K key, {
    DateTime now,
    Duration age,
    FutureOr<T> Function(K) absent,
  });

  /// Adds [data] to the cache under [key].
  ///
  /// Returns whether the data was added or not.
  Future<bool> put<T extends V>(K key, T data, {DateTime now});

  /// Remove [key], returning whether it existed in the cache.
  Future<bool> remove(K key);

  /// Size (number of items in the) of cache.
  Future<int> get size;
}

/// A simple in-memory LRU cache that is not persistent.
///
/// Stores a maximum number of key-value pairs before expunging the cache.
class MemoryCache<K, V> implements Cache<K, V> {
  final _pairs = <K, _Entry<V>>{};
  final _stack = <K>[];
  final int maxSize;

  MemoryCache([this.maxSize = 10]);

  @override
  Future<Null> clear() {
    _pairs.clear();
    _stack.clear();
    return new Future.value();
  }

  @override
  Future<Null> expire({DateTime now, Duration age: Duration.ZERO}) {
    now ??= new DateTime.now();
    final remove = <K>[];
    _pairs.forEach((k, v) {
      final diff = v.when.difference(now);
      if (diff >= age) {
        remove.add(k);
      }
    });
    for (final key in remove) {
      _stack.remove(key);
      _pairs.remove(key);
    }
    return new Future.value();
  }

  @override
  Future<T> get<T extends V>(
    K key, {
    DateTime now,
    Duration age,
    FutureOr<T> Function(K) absent,
  }) async {
    now ??= new DateTime.now();
    var result = _pairs[key];
    if (result != null && age != null && result.when.difference(now) >= age) {
      result = null;
    }
    if (result == null && absent != null) {
      await put(key, await absent(key));
      result = _pairs[key];
    }
    if (result == null) {
      return new Future.value();
    }
    return new Future.value(result.value as T);
  }

  @override
  Future<bool> put<T extends V>(K key, T data, {DateTime now}) {
    now ??= new DateTime.now();
    _stack.insert(0, key);
    _pairs[key] = new _Entry(data, now);
    if (_stack.length > maxSize) {
      _pairs.remove(_stack.removeLast());
    }
    return new Future.value(true);
  }

  @override
  Future<bool> remove(K key) {
    _pairs.remove(key);
    return new Future.value(_stack.remove(key));
  }

  @override
  Future<int> get size => new Future.value(_stack.length);
}

/// A no-op implementation of [Cache].
class NullCache<K, V> implements Cache<K, V> {
  const NullCache();

  @override
  Future<Null> clear() => new Future.value();

  @override
  Future<Null> expire({DateTime now, Duration age}) => new Future.value();

  @override
  Future<T> get<T extends V>(
    K key, {
    DateTime now,
    Duration age,
    FutureOr<T> Function(K) absent,
  }) =>
      absent == null ? new Future.value(null) : new Future.value(absent(key));

  @override
  Future<bool> put<T extends V>(K key, T data, {DateTime now}) {
    return new Future.value(true);
  }

  @override
  Future<bool> remove(K key) => new Future.value(false);

  @override
  Future<int> get size => new Future.value(0);
}

class _Entry<V> implements Comparable<_Entry<V>> {
  final V value;
  final DateTime when;

  const _Entry(this.value, this.when);

  @override
  int compareTo(_Entry<V> other) => when.compareTo(other.when);
}
