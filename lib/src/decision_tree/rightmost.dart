import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/walker.dart';

class DecisionTreeRightMost<T>
    extends DecisionTreeWalker<T, Decision<T>, void> {
  @override
  Decision<T> visitBranch(Branch<T> branch, _) {
    return walk(branch.right, _);
  }

  @override
  Decision<T> visitDecision(Decision<T> decision, _) => decision;
}
