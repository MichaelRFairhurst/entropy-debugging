import 'dart:math';

import 'package:entropy_debugging/src/distribution/tracker.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/executor.dart';
import 'package:entropy_debugging/src/decision_tree/executor_async.dart';
import 'package:entropy_debugging/src/decision_tree/printer.dart';
import 'package:entropy_debugging/src/decision_tree/rightmost.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';

/// A asynchronous simplifier which generates a [MarkovModel] as it simplifies
/// to build optimal decision trees based on the observed statistics of the
/// data.
class AdaptiveAsyncSimplifier<T> implements AsyncSimplifier<T> {
  final DistributionTracker distributionTracker;
  final Future<bool> Function(List<T>) function;
  TreePlanner Function(MarkovModel) plannerBuilder;
  int lastDeletedOffset;

  AdaptiveAsyncSimplifier(this.function, this.plannerBuilder)
      : distributionTracker = DistributionTracker();

  AdaptiveAsyncSimplifier.forTracker(
      this.distributionTracker, this.function, this.plannerBuilder);

  Future<List<T>> simplify(List<T> input) async {
    var result = List<T>.from(input);
    EventKind previous = EventKind.unknown;

    int offset = 0;
    while (offset < result.length) {
      final markov = distributionTracker.markov;
      final decisionTree =
          plannerBuilder(markov).plan(result.length - offset, previous);

      final executor = AsyncDecisionTreeExecutor<Sequence>((left, right) async {
        final pivot = DecisionTreeRightMost<Sequence>().walk(left, null);
        final list = pivot.outcome.list;
        return !await function(List<T>.from(result)
          ..replaceRange(offset, offset + list.length, []));
      });

      final decision = await executor.execute(decisionTree);
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
