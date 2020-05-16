import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/planner.dart';

/// A tree planner that calls an input [decisionTreeBuilder] for the remainder
/// of the sample.
class BasicTreePlanner implements TreePlanner {
  /// The markov model used to calculated the probabilities in the tree.
  final MarkovModel markov;

  /// The decision tree builder, may be optimal or suboptimal.
  final DecisionTreeBuilder<Sequence> decisionTreeBuilder;

  BasicTreePlanner(this.markov, this.decisionTreeBuilder);

  DecisionTree<Sequence> plan(int length, EventKind previous) {
    final decisions = <Decision<Sequence>>[];
    for (int i = 0; i < length + 1; ++i) {
      final events =
          Iterable.generate(i, (_) => EventKind.unimportant).toList();
      if (i < length) {
        events.add(EventKind.important);
      }
      decisions.add(Decision(
          Sequence(events), markov.probabilityOfAll(events, previous)));
    }

    return decisionTreeBuilder.build(decisions);
  }
}
