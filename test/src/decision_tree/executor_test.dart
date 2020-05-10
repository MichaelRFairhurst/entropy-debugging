// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/executor.dart';
import 'package:test/test.dart';

void main() {
  test('execute a tree with no branches', () {
    bool wasCalled = false;
    final executor = DecisionTreeExecutor((_, __) => wasCalled = true);
    final tree = Decision(null, 1);
    final result = executor.execute(tree);
    expect(result, same(tree));
    expect(wasCalled, isFalse);
  });

  group('execute a tree with two branches', () {
    final left = Decision(1, 0.5);
    final right = Decision(2, 0.5);
    final tree = Branch(left, right);

    test('and go left', () {
      bool wasCalled = false;
      final executor = DecisionTreeExecutor((shouldBeLeft, shouldBeRight) {
        expect(shouldBeLeft, same(left));
        expect(shouldBeRight, same(right));
        wasCalled = true;
        return true;
      });
      final result = executor.execute(tree);
      expect(result, same(left));
      expect(wasCalled, isTrue);
    });

    test('and go right', () {
      bool wasCalled = false;
      final executor = DecisionTreeExecutor((shouldBeLeft, shouldBeRight) {
        expect(shouldBeLeft, same(left));
        expect(shouldBeRight, same(right));
        wasCalled = true;
        return false;
      });
      final result = executor.execute(tree);
      expect(result, same(right));
      expect(wasCalled, isTrue);
    });
  });

  group('execute a tree with two branches', () {
    final tree = Branch(Branch(Decision(0, 0.25), Decision(1, 0.25)),
        Branch(Decision(2, 0.25), Decision(3, 0.25)));
    Set<DecisionTree> choosePath;
    final executor =
        DecisionTreeExecutor((left, right) => choosePath.contains(left));

    test('track left', () {
      choosePath = <DecisionTree>{tree.left, (tree.left as Branch).left};
      final result = executor.execute(tree);
      expect(result, same((tree.left as Branch).left));
    });

    test('track right', () {
      choosePath = <DecisionTree>{tree.right, (tree.right as Branch).right};
      final result = executor.execute(tree);
      expect(result, same((tree.right as Branch).right));
    });

    test('track middle left', () {
      choosePath = <DecisionTree>{tree.left, (tree.left as Branch).right};
      final result = executor.execute(tree);
      expect(result, same((tree.left as Branch).right));
    });

    test('track middle right', () {
      choosePath = <DecisionTree>{tree.right, (tree.right as Branch).left};
      final result = executor.execute(tree);
      expect(result, same((tree.right as Branch).left));
    });
  });
}
