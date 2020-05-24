import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/distribution/tracker.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal_async.dart';
import 'package:entropy_debugging/src/simplifier/noop.dart';
import 'package:entropy_debugging/src/simplifier/profiling.dart';
import 'package:entropy_debugging/src/simplifier/string.dart';
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

class SimplifierBuilder extends _SimplifierBuilderBase {
  final bool cacheTrees;
  final bool minimize;
  final bool profileSimplify;
  final int maxTreeSize;
  final int presamples;
  final DistributionTracker tracker;

  AdaptiveSimplifier _adaptiveSimplifier;

  SimplifierBuilder({
    this.minimize = true,
    this.cacheTrees = true,
    this.maxTreeSize = 80,
    this.presamples = 5,
    this.profileSimplify = false,
    DistributionTracker tracker,
  }) : this.tracker = tracker ?? DistributionTracker();

  StringSimplifier stringSimplifier() => StringSimplifier(buildSimplifier());

  Simplifier buildSimplifier() {
    Simplifier simplifier = null;

    if (presamples != 0) {
      simplifier = _buildPresampling();
    }

    simplifier = _andThen(simplifier, _buildAdaptive());

    if (profileSimplify) {
      simplifier = ProfilingSimplifier(simplifier);
    }

    if (minimize) {
      simplifier = _andThen(
        simplifier,
        LazilyBuiltSimplifier((_) => _buildMinimizer()),
      );
    }

    return simplifier;
  }

  Simplifier _andThen(Simplifier first, Simplifier second) {
    if (first == null) {
      return second;
    }
    return TwoPassSimplifier(first, second);
  }

  Simplifier _buildMinimizer() {
    if (_adaptiveSimplifier == null) {
      return OneMinimalSimplifier();
    }
    if (_adaptiveSimplifier.lastDeletedOffset == null) {
      return NoopSimplifier();
    }
    return OneMinimalSimplifier(
        lastDeletedOffset: _adaptiveSimplifier.lastDeletedOffset);
  }

  PresamplingSimplifier _buildPresampling() =>
      PresamplingSimplifier.forTracker(tracker, samples: presamples);

  AdaptiveSimplifier _buildAdaptive() =>
      AdaptiveSimplifier.forTracker(tracker, _buildPlanner);
}

class AsyncSimplifierBuilder extends _SimplifierBuilderBase {
  final bool cacheTrees;
  final bool minimize;
  final bool profileSimplify;
  final int maxTreeSize;
  final int presamples;
  final DistributionTracker tracker;

  AdaptiveAsyncSimplifier _adaptiveSimplifier;

  AsyncSimplifierBuilder({
    this.minimize = true,
    this.cacheTrees = true,
    this.maxTreeSize = 80,
    this.presamples = 5,
    this.profileSimplify = false,
    DistributionTracker tracker,
  }) : this.tracker = tracker ?? DistributionTracker();

  AsyncStringSimplifier stringSimplifier() =>
      AsyncStringSimplifier(buildSimplifier());

  AsyncSimplifier buildSimplifier() {
    AsyncSimplifier simplifier = null;

    if (presamples != 0) {
      simplifier = _buildPresampling();
    }

    simplifier = _andThen(simplifier, _buildAdaptive());

    if (profileSimplify) {
      simplifier = ProfilingAsyncSimplifier(simplifier);
    }

    if (minimize) {
      simplifier = _andThen(
        simplifier,
        LazilyBuiltAsyncSimplifier((_) => _buildMinimizer()),
      );
    }

    return simplifier;
  }

  AsyncSimplifier _andThen(AsyncSimplifier first, AsyncSimplifier second) {
    if (first == null) {
      return second;
    }
    return TwoPassAsyncSimplifier(first, second);
  }

  AsyncSimplifier _buildMinimizer() {
    if (_adaptiveSimplifier == null) {
      return OneMinimalAsyncSimplifier();
    }
    if (_adaptiveSimplifier.lastDeletedOffset == null) {
      return NoopSimplifierAsync();
    }
    return OneMinimalAsyncSimplifier(
        lastDeletedOffset: _adaptiveSimplifier.lastDeletedOffset);
  }

  PresamplingAsyncSimplifier _buildPresampling() =>
      PresamplingAsyncSimplifier.forTracker(tracker, samples: presamples);

  AdaptiveAsyncSimplifier _buildAdaptive() =>
      AdaptiveAsyncSimplifier.forTracker(tracker, _buildPlanner);
}

abstract class _SimplifierBuilderBase {
  bool get cacheTrees;
  int get maxTreeSize;

  DistributionTracker get tracker;

  TreePlanner _buildPlanner(MarkovModel model) {
    TreePlanner planner = ProbabilityThresholdTreePlanner(
      model,
      _buildTreeBuilder(),
    );

    if (cacheTrees) {
      planner = CachingTreePlanner(planner);
    }

    if (maxTreeSize != null) {
      planner = CappedSizeTreePlanner(planner, maxTreeSize: 80);
    }

    return planner;
  }

  DecisionTreeBuilder<Sequence> _buildTreeBuilder() =>
      HuffmanLikeDecisionTreeBuilder();
}
