import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// An optimal, in terms of result, [DecisionTreeBuilder]s, which takes O(n!)
/// time to build.
class OptimalDecisionTreeBuilder<T> implements DecisionTreeBuilder<T> {
  @override
  DecisionTree<T> build(List<Decision<T>> decisions) {
    if (decisions.length == 1) {
      return decisions.single;
    }
    if (decisions.length == 2) {
      return Branch<T>(decisions[0], decisions[1]);
    }
    DecisionTree result;
    double resultCost;
    final leftDecisions = [decisions.first];
    var rightDecisions = decisions.skip(1).toList();
    while (rightDecisions.isNotEmpty) {
      final left = build(leftDecisions);
      final right = build(rightDecisions);
      final contender = Branch<T>(left, right);
      if (result == null || resultCost > contender.cost) {
        result = contender;
        resultCost = result.cost;
      }
      leftDecisions.add(rightDecisions.first);
      rightDecisions = rightDecisions.skip(1).toList();
    }
    return result;
  }
}
