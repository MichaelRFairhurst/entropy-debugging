// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

void main() {
  group('decision builder .buildOptimal()', () {
    test('single decision', () {
      final onlyOption = Decision(null, 1);
      final tree = DecisionTreeBuilder().buildOptimal([onlyOption]);
      expect(tree, onlyOption);
    });

    group('two decisions', () {
      test('larger left', () {
        final smaller = Decision(null, 0.3);
        final larger = Decision(null, 0.7);
        final tree = DecisionTreeBuilder().buildOptimal([larger, smaller]);
        expect(tree, Branch(larger, smaller));
      });

      test('larger right', () {
        final smaller = Decision(null, 0.3);
        final larger = Decision(null, 0.7);
        final tree = DecisionTreeBuilder().buildOptimal([smaller, larger]);
        expect(tree, Branch(smaller, larger));
      });
    });

    group('three decisions', () {
      final mostLikely = Decision(null, 0.4);
      final other1 = Decision(null, 0.3);
      final other2 = Decision(null, 0.3);
      test('left is most likely', () {
        final tree =
            DecisionTreeBuilder().buildOptimal([mostLikely, other1, other2]);
        expect(tree, Branch(mostLikely, Branch(other1, other2)));
      });
      test('middle is most likely', () {
        final tree =
            DecisionTreeBuilder().buildOptimal([other1, mostLikely, other2]);
        expect(tree, Branch(other1, Branch(mostLikely, other2)));
      });
      test('right is most likely', () {
        final tree =
            DecisionTreeBuilder().buildOptimal([other1, other2, mostLikely]);
        expect(tree, Branch(Branch(other1, other2), mostLikely));
      });
    });

    group('four decisions', () {
      final mostLikely = Decision(null, 0.51);
      final nextMost = Decision(null, 0.31);
      final nextLeast = Decision(null, 0.135);
      final leastLikely = Decision(null, 0.095);

      test('completely lopsided left', () {
        final tree = DecisionTreeBuilder()
            .buildOptimal([mostLikely, nextMost, nextLeast, leastLikely]);
        expect(
            tree,
            Branch(
                mostLikely, Branch(nextMost, Branch(nextLeast, leastLikely))));
      });

      test('completely lopsided right', () {
        final tree = DecisionTreeBuilder()
            .buildOptimal([leastLikely, nextLeast, nextMost, mostLikely]);
        expect(
            tree,
            Branch(
                Branch(Branch(leastLikely, nextLeast), nextMost), mostLikely));
      });

      test('balanced', () {
        final oneQuarter = Decision(null, 0.25);
        final tree = DecisionTreeBuilder()
            .buildOptimal([oneQuarter, oneQuarter, oneQuarter, oneQuarter]);
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
            DecisionTreeBuilder().buildOptimal([edge1, low1, low2, edge2]);
        expect(tree, Branch(Branch(edge1, Branch(low1, low2)), edge2));
      });
    });
  });

  group('decision builder .buildAll()', () {
    test('single decision', () {
      final onlyOption = Decision(null, 1);
      final trees = DecisionTreeBuilder().buildAll([onlyOption]);
      expect(trees.length, 1);
      final tree = trees.single;
      expect(tree, onlyOption);
    });

    test('two decisions', () {
      final first = Decision(null, 0.7);
      final second = Decision(null, 0.3);
      final trees = DecisionTreeBuilder().buildAll([first, second]);
      expect(trees.length, 1);
      final tree = trees.single;
      expect(tree, Branch(first, second));
    });

    group('three decisions', () {
      final first = Decision(null, 0.3);
      final second = Decision(null, 0.3);
      final third = Decision(null, 0.4);
      final trees = DecisionTreeBuilder().buildAll([first, second, third]);

      test('has two results', () {
        expect(trees.length, 2);
      });

      test('contains group on right', () {
        final tree = trees[0];
        expect(tree, Branch(first, Branch(second, third)));
      });

      test('contains group on left', () {
        final tree = trees[1];
        expect(tree, Branch(Branch(first, second), third));
      });
    });

    group('four decisions', () {
      final first = Decision(null, 0.25);
      final second = Decision(null, 0.25);
      final third = Decision(null, 0.25);
      final fourth = Decision(null, 0.25);
      final trees =
          DecisionTreeBuilder().buildAll([first, second, third, fourth]);

      test('has 5 results', () {
        expect(trees.length, 5);
      });

      test('contains deeply nested on right', () {
        final tree = trees[0];
        expect(tree, Branch(first, Branch(second, Branch(third, fourth))));
      });

      test('contains deeply nested on left', () {
        final tree = trees[4];
        expect(tree, Branch(Branch(Branch(first, second), third), fourth));
      });

      test('contains balanced', () {
        final tree = trees[2];
        expect(tree, Branch(Branch(first, second), Branch(third, fourth)));
      });

      test('contains 2nd/3rd deepest left', () {
        final tree = trees[1];
        expect(tree, Branch(first, Branch(Branch(second, third), fourth)));
      });

      test('contains 2nd/3rd deepest right', () {
        final tree = trees[3];
        expect(tree, Branch(Branch(first, Branch(second, third)), fourth));
      });
    });
  });
}
