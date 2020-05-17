import 'dart:math';

import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/executor.dart';
import 'package:entropy_debugging/src/decision_tree/printer.dart';
import 'package:entropy_debugging/src/decision_tree/rightmost.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/nonadaptive.dart';

/// A simplifier which samples the input to build an approximate [MarkovModel]
/// and then uses that sample result to run a [NonadaptiveSimplifier] on it.
///
/// With the presampling we build a probability distribution rather than to
/// account for sampling error. This means if we observe n/s, we assume a
/// probability of n+1/s+2 instead of n/s exactly. Otherwise, 10/10 would result
/// in an assumption of 100% probability, which is incorrect.
class PresamplingSimplifier<T> implements Simplifier<T> {
  final int samples;
  final bool Function(List<T>) function;
  TreePlanner Function(MarkovModel) plannerBuilder;

  PresamplingSimplifier(this.function, this.plannerBuilder,
      {this.samples = 25});

  List<T> simplify(List<T> input) {
    final random = Random();
    var hitsUnimportant = 0;
    var hitsUnimportantRepeats = 0;
    for (int i = 0; i < samples; ++i) {
      // TODO: handle sampling the same item twice
      final randomIndex = random.nextInt(input.length - 1);
      final candidate = List<T>.from(input)..remove(randomIndex);
      if (function(candidate)) {
        hitsUnimportant++;
        input = candidate;
        final pairCandidate = List<T>.from(candidate)..remove(randomIndex);
        if (function(pairCandidate)) {
          hitsUnimportantRepeats++;
          input = pairCandidate;
        }
      }
    }

    final markov = MarkovModel(
        1 - (hitsUnimportantRepeats + 1) / (hitsUnimportant + 2),
        1 - (hitsUnimportant + 1) / (samples + 2));
    return NonadaptiveSimplifier<T>(function, markov, plannerBuilder(markov))
        .simplify(input);
  }
}
