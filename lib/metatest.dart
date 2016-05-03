// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A test library for testing test libraries? We must go deeper.
///
/// Since unit testing code tends to use a lot of global state, it can be tough
/// to test. This library manages it by running each test case in a child
/// isolate, then reporting the results back to the parent isolate.
library metatest;

import 'dart:async';

// TODO(nweiz): Stop importing from src when dart-lang/test#48 is fixed.
import 'package:test/src/backend/declarer.dart';
import 'package:test/src/backend/live_test.dart';
import 'package:test/src/backend/state.dart';
import 'package:test/src/runner/engine.dart';
import 'package:test/src/runner/runner_suite.dart';
import 'package:test/src/runner/plugin/environment.dart';
import 'package:test/test.dart';

/// Declares a test with the given [description] and [body].
///
/// [body] corresponds to the `main` method of a test file. By default, this
/// expects that all tests defined in [body] pass, but if [passing] is passed,
/// only tests listed there are expected to pass.
void expectTestsPass(String description, void body(), {List<String> passing,
    String testOn, Timeout timeout, skip, Map<String, dynamic> onPlatform}) {
  _setUpTest(description, body, (liveTests) {
    if (passing == null) {
      if (liveTests.any(
          (liveTest) => liveTest.state.result != Result.success)) {
        fail('Expected all tests to pass, but some failed:\n'
            '${_summarizeTests(liveTests)}');
      }
      return;
    }

    var shouldPass = new Set.from(passing);
    var didPass = new Set.from(liveTests
        .where((liveTest) => liveTest.state.result == Result.success)
        .map((liveTest) => liveTest.test.name));

    if (!shouldPass.containsAll(didPass) ||
        !didPass.containsAll(shouldPass)) {
      stringify(tests) => '{${tests.map((t) => '"$t"').join(', ')}}';

      fail('Expected exactly ${stringify(shouldPass)} to pass, but '
          '${stringify(didPass)} passed.\n'
          '${_summarizeTests(liveTests)}');
    }
  }, testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

/// Asserts that all tests defined by [body] fail.
///
/// [body] corresponds to the `main` method of a test file.
void expectTestsFail(String description, body(), {String testOn,
    Timeout timeout, skip, Map<String, dynamic> onPlatform}) {
  expectTestsPass(description, body, passing: [], testOn: testOn,
      timeout: timeout, skip: skip, onPlatform: onPlatform);
}

/// Sets up a test with the given [description] and [body]. After the test runs,
/// calls [validate] with the result map.
void _setUpTest(String description, void body(),
    void validate(List<LiveTest> liveTests), {String testOn, Timeout timeout,
    skip, Map<String, dynamic> onPlatform}) {
  test(description, () async {
    var declarer = new Declarer();
    runZoned(body, zoneValues: {#test.declarer: declarer});

    var engine = new Engine.withSuites([
      new RunnerSuite(new PluginEnvironment(), declarer.build())
    ]);
    for (var test in engine.liveTests) {
      test.onPrint.listen(print);
    }
    await engine.run();

    validate(engine.liveTests);
  }, testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

/// Returns a string description of the test run descibed by [liveTests].
String _summarizeTests(List<LiveTest> liveTests) {
  var buffer = new StringBuffer();
  for (var liveTest in liveTests) {
    buffer.writeln("${liveTest.state.result}: ${liveTest.test.name}");
    for (var error in liveTest.errors) {
      buffer.writeln(error.error);
      if (error.stackTrace != null) buffer.writeln(error.stackTrace);
    }
  }
  return buffer.toString();
}
