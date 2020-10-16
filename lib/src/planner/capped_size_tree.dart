import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/planner.dart';

/// A [TreePlanner] that takes an inner [TreePlanner] and caps it to a certain
/// [length] for better performance (smaller trees are quicker to build and
/// often have close to or even exactly identical efficiency).
class CappedSizeTreePlanner implements TreePlanner {
  /// The maximum size of tree built by this planner.
  final int maxTreeSize;

  /// The underlying planner which is being capped.
  final TreePlanner _innerPlanner;

  CappedSizeTreePlanner(this._innerPlanner, {this.maxTreeSize = 10});

  DecisionTree<Sequence> plan(int length, EventKind previous) =>
      _innerPlanner.plan(_cap(length), previous);

  int _cap(int length) {
    if (length < maxTreeSize) {
      return length;
    }
    // Split the sequence in even chunks rather than simply truncating. The hope
    // is that we get two trees of some low cost n, rather than one large tree
    // of cost much over n followed by a tree of cost very close to n.
    return (length / (length / maxTreeSize).ceil()).ceil();
  }
}
