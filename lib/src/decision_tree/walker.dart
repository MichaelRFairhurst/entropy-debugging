import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';

abstract class DecisionTreeWalker<T, R, C> {
  R walk(DecisionTree<T> tree, C context) {
    if (tree is Decision<T>) {
      return visitDecision(tree, context);
    }
    return visitBranch(tree as Branch<T>, context);
  }

  R visitBranch(Branch<T> branch, C context);

  R visitDecision(Decision<T> decision, C context);
}
