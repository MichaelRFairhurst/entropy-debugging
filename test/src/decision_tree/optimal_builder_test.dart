// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/optimal_builder.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

void main() {
  group('optimal decision tree builder .build()', () {
    test('single decision', () {
      final onlyOption = Decision(null, 1);
      final tree = OptimalDecisionTreeBuilder().build([onlyOption]);
      expect(tree, onlyOption);
    });

    group('two decisions', () {
      test('larger left', () {
        final smaller = Decision(null, 0.3);
        final larger = Decision(null, 0.7);
        final tree = OptimalDecisionTreeBuilder().build([larger, smaller]);
        expect(tree, Branch(larger, smaller));
      });

      test('larger right', () {
        final smaller = Decision(null, 0.3);
        final larger = Decision(null, 0.7);
        final tree = OptimalDecisionTreeBuilder().build([smaller, larger]);
        expect(tree, Branch(smaller, larger));
      });
    });

    group('three decisions', () {
      final mostLikely = Decision(null, 0.4);
      final other1 = Decision(null, 0.3);
      final other2 = Decision(null, 0.3);
      test('left is most likely', () {
        final tree =
            OptimalDecisionTreeBuilder().build([mostLikely, other1, other2]);
        expect(tree, Branch(mostLikely, Branch(other1, other2)));
      });
      test('middle is most likely', () {
        final tree =
            OptimalDecisionTreeBuilder().build([other1, mostLikely, other2]);
        expect(tree, Branch(other1, Branch(mostLikely, other2)));
      });
      test('right is most likely', () {
        final tree =
            OptimalDecisionTreeBuilder().build([other1, other2, mostLikely]);
        expect(tree, Branch(Branch(other1, other2), mostLikely));
      });
    });

    group('four decisions', () {
      final mostLikely = Decision(null, 0.51);
      final nextMost = Decision(null, 0.31);
      final nextLeast = Decision(null, 0.135);
      final leastLikely = Decision(null, 0.095);

      test('completely lopsided left', () {
        final tree = OptimalDecisionTreeBuilder()
            .build([mostLikely, nextMost, nextLeast, leastLikely]);
        expect(
            tree,
            Branch(
                mostLikely, Branch(nextMost, Branch(nextLeast, leastLikely))));
      });

      test('completely lopsided right', () {
        final tree = OptimalDecisionTreeBuilder()
            .build([leastLikely, nextLeast, nextMost, mostLikely]);
        expect(
            tree,
            Branch(
                Branch(Branch(leastLikely, nextLeast), nextMost), mostLikely));
      });

      test('balanced', () {
        final oneQuarter = Decision(null, 0.25);
        final tree = OptimalDecisionTreeBuilder()
            .build([oneQuarter, oneQuarter, oneQuarter, oneQuarter]);
        expect(
            tree,
            Branch(Branch(oneQuarter, oneQuarter),
                Branch(oneQuarter, oneQuarter)));
      });

      test('lopsided middle', () {
        final edge1 = Decision(null, 0.049);
        final low1 = Decision(null, 0.01);
        final low2 = Decision(null, 0.01);
        final edge2 = Decision(null, 0.49);
        final tree =
            OptimalDecisionTreeBuilder().build([edge1, low1, low2, edge2]);
        expect(tree, Branch(Branch(edge1, Branch(low1, low2)), edge2));
      });
    });
  });
}
