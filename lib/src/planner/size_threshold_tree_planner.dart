import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/planner.dart';

/// A [TreePlanner] that contains a size threshold, and a plan for sequences
/// less than or equal to that threshold in size, and another plan for sequences
/// beyond that size.
///
/// The primary motivating use case for this planner is to enable the optimal
/// tree planner for small enough trees. Below the threshold, the optimal tree
/// should be built, and no other options should be considered. However, there
/// may be other cases where it is useful.
class SizeThresholdTreePlanner implements TreePlanner {
  final TreePlanner smaller;
  final int threshold;
  final TreePlanner larger;

  SizeThresholdTreePlanner(this.smaller, this.threshold, this.larger);

  DecisionTree<Sequence> plan(int length, EventKind previous) {
    if (length <= threshold) {
      return smaller.plan(length, previous);
    }
    return larger.plan(length, previous);
  }
}
