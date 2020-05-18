import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';

class AsyncDecisionTreeExecutor<O> {
  final Future<bool> Function(
      DecisionTree<O> leftSplit, DecisionTree<O> rightSplit) question;

  AsyncDecisionTreeExecutor(this.question);

  Future<Decision<O>> execute(DecisionTree<O> tree) async {
    while (tree is Branch<O>) {
      final branch = tree as Branch<O>;
      tree = (await question(branch.left, branch.right))
          ? branch.left
          : branch.right;
    }
    return tree;
  }
}
