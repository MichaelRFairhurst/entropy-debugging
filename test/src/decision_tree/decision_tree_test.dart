// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:test/test.dart';

void main() {
  group('a leaf', () {
    test('has its own outcome.1', () {
      final leaf = Decision(1, 0.1);
      expect(leaf.outcome, 1);
    });
    group('has its own probability', () {
      test('of 0.1', () {
        final leaf = Decision(null, 0.1);
        expect(leaf.probability, 0.1);
      });
      group('as its cost', () {
        test('given probability of 0.1', () {
          final leaf = Decision(null, 0.1);
          expect(leaf.cost, 0.1);
        });
      });
    });
    group('equals', () {
      test('itself', () {
        final leaf = Decision(null, 0.1);
        expect(leaf == leaf, isTrue);
      });

      test('other leaves with the same outcome & probability', () {
        final leaf = Decision(1, 0.1);
        final equivalent = Decision(1, 0.1);
        expect(leaf == equivalent, isTrue);
      });

      group('but not', () {
        test('other leaves with different probability', () {
          final leaf = Decision(1, 0.1);
          final notEqual = Decision(1, 0.2);
          expect(leaf == notEqual, isFalse);
        });
        test('other leaves with different outcome', () {
          final leaf = Decision(1, 0.1);
          final notEqual = Decision(2, 0.1);
          expect(leaf == notEqual, isFalse);
        });
      });
    });
  });

  group('a branch', () {
    group('has a sum of left and right probabilities', () {
      test('two leaves with 0.1', () {
        final left = Decision(null, 0.1);
        final right = Decision(null, 0.1);
        final branch = Branch(left, right);
        expect(branch.probability, 0.2);
      });

      test('a leaf with 0.1 and a leaf with 0.2', () {
        final left = Decision(null, 0.1);
        final right = Decision(null, 0.2);
        final branch = Branch(left, right);
        expect(branch.probability, closeTo(0.3, 0.0001));
      });

      test('a branch on the left side', () {
        final left = Branch(Decision(null, 0.1), Decision(null, 0.2));
        final right = Decision(null, 0.3);
        final branch = Branch(left, right);
        expect(branch.probability, closeTo(0.6, 0.0001));
      });

      test('a branch on the right side', () {
        final left = Decision(null, 0.1);
        final right = Branch(Decision(null, 0.2), Decision(null, 0.3));
        final branch = Branch(left, right);
        expect(branch.probability, 0.6);
      });

      test('a branch on each side', () {
        final left = Branch(Decision(null, 0.1), Decision(null, 0.2));
        final right = Branch(Decision(null, 0.3), Decision(null, 0.4));
        final branch = Branch(left, right);
        expect(branch.probability, 1);
      });
    });

    group('has a cost', () {
      group('of 1', () {
        test('for 50/50', () {
          final left = Decision(null, 0.5);
          final right = Decision(null, 0.5);
          final branch = Branch(left, right);
          expect(branch.cost, 1);
        });

        test('for 20/80', () {
          final left = Decision(null, 0.5);
          final right = Decision(null, 0.5);
          final branch = Branch(left, right);
          expect(branch.cost, 1);
        });
      });

      group('of 2', () {
        test('for 25/25/25/25', () {
          final left = Branch(Decision(null, 0.25), Decision(null, 0.25));
          final right = Branch(Decision(null, 0.25), Decision(null, 0.25));
          final branch = Branch(left, right);
          expect(branch.cost, 2);
        });

        test('for 1/49 & 1/49', () {
          final left = Branch(Decision(null, 0.01), Decision(null, 0.49));
          final right = Branch(Decision(null, 0.01), Decision(null, 0.49));
          final branch = Branch(left, right);
          expect(branch.cost, 2);
        });

        test('for 49/1 & 49/1', () {
          final left = Branch(Decision(null, 0.49), Decision(null, 0.01));
          final right = Branch(Decision(null, 0.49), Decision(null, 0.01));
          final branch = Branch(left, right);
          expect(branch.cost, 2);
        });
      });

      group('for lower entropy scenarios', () {
        test('such as 50/25/25', () {
          final left = Decision(null, 0.50);
          final right = Branch(Decision(null, 0.25), Decision(null, 0.25));
          final branch = Branch(left, right);
          expect(branch.cost, 1.5);
        });

        test('such as 25/25/50', () {
          final left = Branch(Decision(null, 0.25), Decision(null, 0.25));
          final right = Decision(null, 0.50);
          final branch = Branch(left, right);
          expect(branch.cost, 1.5);
        });
      });
      group('equals', () {
        test('itself', () {
          final branch = Branch(Decision(null, 0.1), Decision(null, 0.1));
          expect(branch == branch, isTrue);
        });

        test('branch with same left & right', () {
          final left = Decision(null, 0.1);
          final right = Decision(null, 0.2);
          final branch = Branch(left, right);
          final equivalent = Branch(left, right);
          expect(branch == equivalent, isTrue);
        });

        test('branch with same left & right decisions', () {
          final branch = Branch(Decision(1, 0.1), Decision(2, 0.2));
          final equivalent = Branch(Decision(1, 0.1), Decision(2, 0.2));
          expect(branch == equivalent, isTrue);
        });

        test('branch with equivalent left & right branches', () {
          final left = Branch(Decision(null, 0.25), Decision(null, 0.25));
          final right = Branch(Decision(null, 0.25), Decision(null, 0.25));
          final branch = Branch(left, right);
          final equivalent = Branch(
              Branch(left.left, left.right), Branch(right.left, right.right));
          expect(branch == equivalent, isTrue);
        });
      });
    });
  });
}
