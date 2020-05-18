import 'dart:math';

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
  final int samples;
  final Future<bool> Function(List<T>) function;
  TreePlanner Function(MarkovModel) plannerBuilder;

  AdaptiveAsyncSimplifier(this.function, this.plannerBuilder,
      {this.samples = 5});

  Future<List<T>> simplify(List<T> input) async {
    // TODO: share code better with AdaptiveSimplifier (sync version)
    final random = Random();
    int trialsUnimportant = 0;
    int trialsUnimportantRepeats = 0;
    var hitsUnimportant = 0;
    var hitsUnimportantRepeats = 0;
    for (int i = 0; i < samples; ++i) {
      // TODO: handle sampling the same item twice
      final randomIndex = random.nextInt(input.length - 1);
      final candidate = List<T>.from(input)..remove(randomIndex);
      if (await function(candidate)) {
        hitsUnimportant++;
        input = candidate;
        trialsUnimportant++;
        final pairCandidate = List<T>.from(candidate)..remove(randomIndex);
        if (await function(pairCandidate)) {
          hitsUnimportantRepeats++;
          trialsUnimportantRepeats++;
          input = pairCandidate;
        }
      }
    }

    var result = List<T>.from(input);
    EventKind previous = EventKind.unknown;

    int offset = 0;
    while (offset < result.length) {
      final markov = MarkovModel(
          1 - (hitsUnimportantRepeats + 1) / (trialsUnimportantRepeats + 2),
          1 - (hitsUnimportant + 1) / (trialsUnimportant + 2));
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
        offset += 1;
        hitsUnimportant += realSequence.length - 1;
        trialsUnimportant += realSequence.length;
        if (previous == EventKind.unimportant) {
          hitsUnimportantRepeats += realSequence.length - 1;
          trialsUnimportantRepeats += realSequence.length;
        } else if (realSequence.length > 1) {
          hitsUnimportantRepeats += realSequence.length - 2;
          trialsUnimportantRepeats += realSequence.length - 1;
        }
      } else {
        result.replaceRange(offset, offset + realSequence.length, []);
        hitsUnimportant += realSequence.length;
        trialsUnimportant += realSequence.length;
        if (previous == EventKind.unimportant) {
          hitsUnimportantRepeats += realSequence.length;
          trialsUnimportantRepeats += realSequence.length;
        } else if (realSequence.length > 1) {
          hitsUnimportantRepeats += realSequence.length - 1;
          trialsUnimportantRepeats += realSequence.length - 1;
        }
      }
      previous = realSequence.last;
    }

    return result;
  }
}
