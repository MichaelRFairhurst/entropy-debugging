import 'dart:math';

import 'package:entropy_debugging/src/decision_tree/executor.dart';
import 'package:entropy_debugging/src/decision_tree/rightmost.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/distribution/tracker.dart';

/// A simplifier which generates a [MarkovModel] as it simplifies to build
/// optimal decision trees based on the observed statistics of the data.
class AdaptiveSimplifier<T> implements Simplifier<T> {
  final DistributionTracker distributionTracker;
  final bool Function(List<T>) function;
  TreePlanner Function(MarkovModel) plannerBuilder;

  AdaptiveSimplifier(this.function, this.plannerBuilder)
      : distributionTracker = DistributionTracker();

  AdaptiveSimplifier.forTracker(
      this.distributionTracker, this.function, this.plannerBuilder);

  List<T> simplify(List<T> input) {
    var result = List<T>.from(input);
    EventKind previous = EventKind.unknown;

    int offset = 0;
    while (offset < result.length) {
      final markov = distributionTracker.markov;
      final decisionTree =
          plannerBuilder(markov).plan(result.length - offset, previous);

      final executor = DecisionTreeExecutor<Sequence>((left, right) {
        final pivot = DecisionTreeRightMost<Sequence>().walk(left, null);
        final list = pivot.outcome.list;
        return !function(List<T>.from(result)
          ..replaceRange(offset, offset + list.length, []));
      });

      final decision = executor.execute(decisionTree);
      final realSequence = decision.outcome.list;
      if (realSequence.last == EventKind.important) {
        result.replaceRange(offset, offset + realSequence.length - 1, []);
        offset += 1;
      } else {
        result.replaceRange(offset, offset + realSequence.length, []);
      }
      distributionTracker.sequenceHit(realSequence, previous);
      previous = realSequence.last;
    }

    return result;
  }
}
