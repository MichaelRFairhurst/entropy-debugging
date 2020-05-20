import 'package:entropy_debugging/src/distribution/tracker.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal_async.dart';
import 'package:entropy_debugging/src/simplifier/noop.dart';
import 'package:entropy_debugging/src/simplifier/lazily_built_simplifier.dart';
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

TreePlanner _planner(MarkovModel model) => CappedSizeTreePlanner(
      CachingTreePlanner(
        ProbabilityThresholdTreePlanner(
          model,
          HuffmanLikeDecisionTreeBuilder(),
        ),
      ),
      maxTreeSize: 80,
    );

PresamplingSimplifier<T> _presampling<T>(
        DistributionTracker tracker, bool Function(List<T>) test) =>
    PresamplingSimplifier<T>.forTracker(tracker, test, samples: 5);

AdaptiveSimplifier<T> _adaptive<T>(
        DistributionTracker tracker, bool Function(List<T>) test) =>
    AdaptiveSimplifier<T>.forTracker(tracker, test, _planner);

/// Get the entropy debugging minimizer for [test] function.
Simplifier<T> simplifier<T>(bool Function(List<T>) test) {
  final tracker = DistributionTracker();
  return TwoPassSimplifier(
    _presampling(tracker, test),
    _adaptive(tracker, test),
  );
}

/// Get the entropy debugging simplifier for [test] function.
Simplifier<T> minimizer<T>(bool Function(List<T>) test) {
  final tracker = DistributionTracker();
  final adaptive = _adaptive(tracker, test);
  return LazilyBuiltSimplifier(
    (input) => TwoPassSimplifier(
      TwoPassSimplifier(_presampling(tracker, test), adaptive),
      LazilyBuiltSimplifier(
        (simplifiedInput) => adaptive.lastDeletedOffset == null
            ? NoopSimplifier()
            : OneMinimalSimplifier(
                test,
                lastDeletedOffset: adaptive.lastDeletedOffset,
              ),
      ),
    ),
  );
}

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

PresamplingAsyncSimplifier<T> _presamplingAsync<T>(
        DistributionTracker tracker, Future<bool> Function(List<T>) test) =>
    PresamplingAsyncSimplifier<T>.forTracker(tracker, test, samples: 5);

AdaptiveAsyncSimplifier<T> _adaptiveAsync<T>(
        DistributionTracker tracker, Future<bool> Function(List<T>) test) =>
    AdaptiveAsyncSimplifier<T>.forTracker(tracker, test, _planner);

/// Get the entropy debugging simplifier for async [test] function.
AsyncSimplifier<T> asyncSimplifier<T>(Future<bool> Function(List<T>) test) {
  final tracker = DistributionTracker();
  return TwoPassAsyncSimplifier(
    _presamplingAsync(tracker, test),
    _adaptiveAsync(tracker, test),
  );
}

/// Get the entropy debugging minimization for async [test] function.
AsyncSimplifier<T> asyncMinimizer<T>(Future<bool> Function(List<T>) test) {
  final tracker = DistributionTracker();
  final adaptive = _adaptiveAsync(tracker, test);
  return LazilyBuiltAsyncSimplifier(
    (input) => TwoPassAsyncSimplifier(
      TwoPassAsyncSimplifier(_presamplingAsync(tracker, test), adaptive),
      LazilyBuiltAsyncSimplifier(
        (simplifiedInput) => adaptive.lastDeletedOffset == null
            ? NoopSimplifierAsync()
            : OneMinimalAsyncSimplifier(
                test,
                lastDeletedOffset: adaptive.lastDeletedOffset,
              ),
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

/// Perform entropy debugging minimization on the string against the async test.
Future<String> stringMinimizeAsync(
        String input, Future<bool> Function(String) test) async =>
    (await asyncMinimizer<String>((input) => test(input.join('')))
            .simplify(input.split('')))
        .join('');
