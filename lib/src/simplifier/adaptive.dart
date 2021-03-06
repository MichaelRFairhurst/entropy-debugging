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
class AdaptiveSimplifier<T> implements Simplifier<T, List<T>, bool> {
  final DistributionTracker distributionTracker;
  TreePlanner Function(MarkovModel) plannerBuilder;
  int lastDeletedOffset;

  AdaptiveSimplifier(this.plannerBuilder)
      : distributionTracker = DistributionTracker();

  AdaptiveSimplifier.forTracker(this.distributionTracker, this.plannerBuilder);

  List<T> simplify(List<T> input, bool Function(List<T>) function) {
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
        if (realSequence.length > 1) {
          lastDeletedOffset = offset;
        }
        offset += 1;
      } else {
        result.replaceRange(offset, offset + realSequence.length, []);
        lastDeletedOffset = offset;
      }
      distributionTracker.sequenceHit(realSequence, previous);
      previous = realSequence.last;
    }

    return result;
  }
}
