import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/planner.dart';

/// A tree planner that builds an optimal tree for the next [maxSize] events, or
/// the remainder of the sample, whichever comes first.
class MaxSizeOptimalTreePlanner implements TreePlanner {
  /// The maximum size of tree built by this planner.
  final int maxTreeSize;

  /// The markov model used to calculated the probabilities in the tree.
  final MarkovModel markov;

  MaxSizeOptimalTreePlanner(this.markov, {this.maxTreeSize = 10});

  DecisionTree<Sequence> plan(int length, EventKind previous) {
    final decisions = <Decision<Sequence>>[];
    for (int i = 0; i < length + 1 && i < maxTreeSize; ++i) {
      final events =
          Iterable.generate(i, (_) => EventKind.unimportant).toList();
      if (i < length && i < maxTreeSize - 1) {
        events.add(EventKind.important);
      }
      decisions.add(Decision(
          Sequence(events), markov.probabilityOfAll(events, previous)));
    }

    return DecisionTreeBuilder<Sequence>().buildOptimal(decisions);
  }
}
