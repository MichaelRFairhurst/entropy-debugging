import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/adaptive.dart';
import 'package:entropy_debugging/src/simplifier/adaptive_async.dart';
import 'package:entropy_debugging/src/planner/caching.dart';
import 'package:entropy_debugging/src/planner/capped_size_tree.dart';
import 'package:entropy_debugging/src/planner/probability_threshold_planner.dart';
import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';

/// Get the entropy debugging simplifier for [test] function, with defaults.
Simplifier<T> defaultSimplifier<T>(bool Function(List<T>) test) =>
    AdaptiveSimplifier<T>(
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
    );

/// Perform entropy debugging simplification on the string against the test.
String defaultStringSimplify(String input, bool Function(String) test) =>
    defaultSimplifier<String>((input) => test(input.join('')))
        .simplify(input.split(''))
        .join('');

/// Get the entropy debugging simplifier for async [test] function, with defaults.
AsyncSimplifier<T> defaultAsyncSimplifier<T>(
        Future<bool> Function(List<T>) test) =>
    AdaptiveAsyncSimplifier<T>(
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
    );

/// Perform entropy debugging simplification on the string against the async test.
Future<String> defaultStringSimplifyAsync(
        String input, Future<bool> Function(String) test) async =>
    (await defaultAsyncSimplifier<String>((input) => test(input.join('')))
            .simplify(input.split('')))
        .join('');
