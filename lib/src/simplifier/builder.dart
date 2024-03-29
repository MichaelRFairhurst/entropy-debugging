import 'dart:async';

import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/distribution/tracker.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/planner/builder.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal_async.dart';
import 'package:entropy_debugging/src/simplifier/noop.dart';
import 'package:entropy_debugging/src/simplifier/profiling.dart';
import 'package:entropy_debugging/src/simplifier/string.dart';
import 'package:entropy_debugging/src/simplifier/lazily_built_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/two_pass_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/presampling.dart';
import 'package:entropy_debugging/src/simplifier/presampling_async.dart';
import 'package:entropy_debugging/src/simplifier/adaptive.dart';
import 'package:entropy_debugging/src/simplifier/nonadaptive.dart';
import 'package:entropy_debugging/src/simplifier/adaptive_async.dart';
import 'package:entropy_debugging/src/planner/caching.dart';
import 'package:entropy_debugging/src/planner/capped_size_tree.dart';
import 'package:entropy_debugging/src/planner/probability_threshold_planner.dart';
import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';
import 'package:entropy_debugging/src/decision_tree/naive_entropy_builder.dart';

class SimplifierBuilder<T> extends _SimplifierBuilderBase<T, List<T>, bool> {
  AdaptiveSimplifier _adaptiveSimplifier;

  SimplifierBuilder({
    Simplifier<T, List<T>, bool> startWith,
    bool cacheTrees = true,
    int maxTreeSize = 1000,
    DistributionTracker tracker,
    TreePlanner Function(MarkovModel) buildPlanner,
  }) : super(
            startWith: startWith,
            cacheTrees: cacheTrees,
            maxTreeSize: maxTreeSize,
            tracker: tracker,
            buildPlanner: buildPlanner);

  PresamplingSimplifier<T> _buildPresampling(int count) =>
      PresamplingSimplifier<T>.forTracker(tracker, samples: count);

  AdaptiveSimplifier<T> _buildAdaptive() => _adaptiveSimplifier =
      AdaptiveSimplifier<T>.forTracker(tracker, _buildPlanner);

  NonadaptiveSimplifier<T> _buildNonadaptive(MarkovModel model) =>
      NonadaptiveSimplifier<T>(model, _buildPlanner(model));

  OneMinimalSimplifier<T> _buildOneMinimal({int lastDeletedOffset}) =>
      OneMinimalSimplifier<T>(lastDeletedOffset: lastDeletedOffset);

  int Function() get _getLastDeletedOffset => _adaptiveSimplifier == null
      ? null
      : () => _adaptiveSimplifier.lastDeletedOffset;
}

class AsyncSimplifierBuilder<T>
    extends _SimplifierBuilderBase<T, Future<List<T>>, Future<bool>> {
  AdaptiveAsyncSimplifier _adaptiveSimplifier;

  AsyncSimplifierBuilder({
    Simplifier<T, Future<List<T>>, Future<bool>> startWith,
    bool cacheTrees = true,
    int maxTreeSize = 80,
    DistributionTracker tracker,
    TreePlanner Function(MarkovModel) buildPlanner,
  }) : super(
            startWith: startWith,
            cacheTrees: cacheTrees,
            maxTreeSize: maxTreeSize,
            tracker: tracker,
            buildPlanner: buildPlanner);

  PresamplingAsyncSimplifier<T> _buildPresampling(int count) =>
      PresamplingAsyncSimplifier<T>.forTracker(tracker, samples: count);

  AdaptiveAsyncSimplifier<T> _buildAdaptive() => _adaptiveSimplifier =
      AdaptiveAsyncSimplifier<T>.forTracker(tracker, _buildPlanner);

  AdaptiveAsyncSimplifier<T> _buildNonadaptive(MarkovModel model) => throw "Not supported.";

  OneMinimalAsyncSimplifier<T> _buildOneMinimal({int lastDeletedOffset}) =>
      OneMinimalAsyncSimplifier<T>(lastDeletedOffset: lastDeletedOffset);

  int Function() get _getLastDeletedOffset => _adaptiveSimplifier == null
      ? null
      : () => _adaptiveSimplifier.lastDeletedOffset;
}

abstract class _SimplifierBuilderBase<T, R extends FutureOr<List<T>>,
    S extends FutureOr<bool>> {
  final bool cacheTrees;
  final int maxTreeSize;
  final DistributionTracker tracker;
  final TreePlanner Function(MarkovModel) _buildPlanner;
  Simplifier<T, R, S> _simplifier;

  _SimplifierBuilderBase({
    Simplifier<T, R, S> startWith,
    this.cacheTrees,
    this.maxTreeSize,
    DistributionTracker tracker,
    TreePlanner Function(MarkovModel) buildPlanner,
  })  : this.tracker = tracker ?? DistributionTracker(),
        _simplifier = startWith,
        _buildPlanner = buildPlanner ?? TreePlannerBuilder.defaultPlanner;

  Simplifier<T, R, S> finish() => _simplifier;

  void presample([int count = 5]) => andThen(_buildPresampling(count));

  void adaptiveConsume() => andThen(_buildAdaptive());

  void nonadaptiveConsume(MarkovModel model) => andThen(_buildNonadaptive(model));

  void profile([String label]) => _simplifier = (label == null
      ? ProfilingSimplifier<T, R, S>(_simplifier)
      : ProfilingSimplifier<T, R, S>(_simplifier,
          printAfter: true, label: label));

  void minimize() =>
      andThen(LazilyBuiltSimplifier<T, R, S>((_) => _buildMinimizer()));

  void andThen(Simplifier<T, R, S> next) {
    if (_simplifier == null) {
      _simplifier = next;
    } else {
      _simplifier = TwoPassSimplifier(_simplifier, next);
    }
  }

  Simplifier<T, R, S> _buildMinimizer() {
    if (_getLastDeletedOffset == null) {
      return _buildOneMinimal();
    }
    int lastDeletedOffset = _getLastDeletedOffset();
    if (lastDeletedOffset == null) {
      return NoopSimplifier();
    }
    return _buildOneMinimal(lastDeletedOffset: lastDeletedOffset);
  }

  Simplifier<T, R, S> _buildAdaptive();
  Simplifier<T, R, S> _buildNonadaptive(MarkovModel model);
  Simplifier<T, R, S> _buildPresampling(int count);
  Simplifier<T, R, S> _buildOneMinimal({int lastDeletedOffset});
  int Function() get _getLastDeletedOffset;
}
