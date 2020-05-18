import 'package:entropy_debugging/src/distribution/tracker.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal.dart';
import 'package:entropy_debugging/src/simplifier/two_pass_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/two_pass_async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/presampling.dart';
import 'package:entropy_debugging/src/simplifier/presampling_async.dart';
import 'package:entropy_debugging/src/simplifier/adaptive.dart';
import 'package:entropy_debugging/src/simplifier/adaptive_async.dart';
import 'package:entropy_debugging/src/planner/caching.dart';
import 'package:entropy_debugging/src/planner/capped_size_tree.dart';
import 'package:entropy_debugging/src/planner/probability_threshold_planner.dart';
import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';

/// Get the entropy debugging minimizer for [test] function.
Simplifier<T> simplifier<T>(bool Function(List<T>) test) {
  final tracker = DistributionTracker();
  return TwoPassSimplifier(
    PresamplingSimplifier<T>.forTracker(tracker, test, samples: 5),
    AdaptiveSimplifier<T>.forTracker(
      tracker,
      test,
      (markov) => CappedSizeTreePlanner(
        CachingTreePlanner(
          ProbabilityThresholdTreePlanner(
            markov,
            HuffmanLikeDecisionTreeBuilder(),
          ),
        ),
        maxTreeSize: 80,
      ),
    ),
  );
}

/// Get the entropy debugging simplifier for [test] function.
Simplifier<T> minimizer<T>(bool Function(List<T>) test) => TwoPassSimplifier(
      simplifier(test),
      OneMinimalSimplifier(test),
    );

/// Perform entropy debugging simplification on the string against the test.
String stringSimplify(String input, bool Function(String) test) =>
    simplifier<String>((input) => test(input.join('')))
        .simplify(input.split(''))
        .join('');

/// Perform entropy debugging minimization on the string against the test.
String stringMinimize(String input, bool Function(String) test) =>
    minimizer<String>((input) => test(input.join('')))
        .simplify(input.split(''))
        .join('');

/// Get the entropy debugging simplifier for async [test] function.
AsyncSimplifier<T> asyncSimplifier<T>(Future<bool> Function(List<T>) test) {
  final tracker = DistributionTracker();
  return TwoPassAsyncSimplifier(
    PresamplingAsyncSimplifier<T>.forTracker(tracker, test, samples: 5),
    AdaptiveAsyncSimplifier<T>.forTracker(
      tracker,
      test,
      (markov) => CappedSizeTreePlanner(
        CachingTreePlanner(
          ProbabilityThresholdTreePlanner(
            markov,
            HuffmanLikeDecisionTreeBuilder(),
          ),
        ),
        maxTreeSize: 80,
      ),
    ),
  );
}

/// Perform entropy debugging simplification on the string against the async test.
Future<String> stringSimplifyAsync(
        String input, Future<bool> Function(String) test) async =>
    (await asyncSimplifier<String>((input) => test(input.join('')))
            .simplify(input.split('')))
        .join('');
