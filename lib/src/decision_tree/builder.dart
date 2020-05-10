import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';

/// A builder of [DecisionTree]s, which can be used to build an optimal tree or
/// all possible trees for a set of [Decision]s.
///
/// Assumes the tree must be ordered. Examples of unordered trees would be
/// huffman coding, where we can always ask the most likely question first (such
/// as, in the case of english, "is the next letter an e?").
///
/// An ordered tree is one where the leaves maintain left to right ordering.
///
/// This is used because the question "are the first n characters waste" leads
/// us to differentiate between all possibilities where n+x characters are waste
/// for some negative integer x, vs all other cases. Therefore all valid
/// decision trees for simplification are equivalent to an ordered tree, where
/// each decision removes all posssibilities for some i such that all
/// possible i < x is removed and all x >= i are preserved.
class DecisionTreeBuilder {
  /// Build the optimal ordered tree for a list of decisions.
  DecisionTree buildOptimal(List<Decision> decisions) {
    if (decisions.length == 1) {
      return decisions.single;
    }
    if (decisions.length == 2) {
      return Branch(decisions[0], decisions[1]);
    }
    DecisionTree result;
    double resultCost;
    final leftDecisions = [decisions.first];
    var rightDecisions = decisions.skip(1).toList();
    while (rightDecisions.isNotEmpty) {
      final left = buildOptimal(leftDecisions);
      final right = buildOptimal(rightDecisions);
      final contender = Branch(left, right);
      if (result == null || resultCost > contender.cost) {
        result = contender;
        resultCost = result.cost;
      }
      leftDecisions.add(rightDecisions.first);
      rightDecisions = rightDecisions.skip(1).toList();
    }
    return result;
  }

  // SLOW Build the optimal tree for an ordered list of decisions.
  DecisionTree slowOldBuild(List<Decision> decisions) {
    final trees = buildAll(decisions);
    var result = trees.first;
    var worstCost = result.cost;
    for (final tree in trees.skip(1)) {
      if (tree.cost < worstCost) {
        result = tree;
        worstCost = result.cost;
      }
    }
    return result;
  }

  /// Build every possible ordered tree for a list of decisions.
  List<DecisionTree> buildAll(List<Decision> decisions) {
    if (decisions.length == 1) {
      return [decisions.single];
    }
    if (decisions.length == 2) {
      return [Branch(decisions[0], decisions[1])];
    }
    final result = <DecisionTree>[];
    final leftDecisions = [decisions.first];
    var rightDecisions = decisions.skip(1).toList();
    while (rightDecisions.isNotEmpty) {
      final allLeftTrees = buildAll(leftDecisions);
      final allRightTrees = buildAll(rightDecisions);
      result.addAll([
        for (final possibleTreeLeft in allLeftTrees)
          for (final possibleTreeRight in allRightTrees)
            Branch(possibleTreeLeft, possibleTreeRight)
      ]);
      leftDecisions.add(rightDecisions.first);
      rightDecisions = rightDecisions.skip(1).toList();
    }
    return result;
  }
}
