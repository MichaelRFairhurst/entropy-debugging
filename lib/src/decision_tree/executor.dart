import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';

class DecisionTreeExecutor<O> {
  final bool Function(DecisionTree<O> leftSplit, DecisionTree<O> rightSplit)
      question;

  DecisionTreeExecutor(this.question);

  Decision<O> execute(DecisionTree<O> tree) {
    while (tree is Branch<O>) {
      final branch = tree as Branch<O>;
      tree = question(branch.left, branch.right) ? branch.left : branch.right;
    }
    return tree;
  }
}
