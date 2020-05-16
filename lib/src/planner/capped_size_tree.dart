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
      _innerPlanner.plan(length > maxTreeSize ? maxTreeSize : length, previous);
}
