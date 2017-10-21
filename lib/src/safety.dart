// Copyright 2017, Matan Lurey.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stack_trace/stack_trace.dart';

/// Execute [run], invoking [onError] if an unhandled exception is thrown.
T runSafely<T>(T Function() run, void Function(Object, Chain) onError) {
  return Chain.capture(run, onError: (Object error, chain) {
    onError(error, chain.terse);
  });
}
