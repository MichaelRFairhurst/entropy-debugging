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
  final int maxTreeSize;
  final DistributionTracker tracker;
  Simplifier _simplifier;

  AdaptiveSimplifier _adaptiveSimplifier;

  SimplifierBuilder({
    Simplifier startWith,
    this.cacheTrees = true,
    this.maxTreeSize = 80,
    DistributionTracker tracker,
  })  : this.tracker = tracker ?? DistributionTracker(),
        _simplifier = startWith;

  Simplifier finish() => _simplifier;

  StringSimplifier stringSimplifier() => StringSimplifier(_simplifier);

  void presample([int count = 5]) => andThen(_buildPresampling(count));

  void adaptiveConsume() => andThen(_buildAdaptive());

  void profile([String label]) => _simplifier = (label == null
      ? ProfilingSimplifier(_simplifier)
      : ProfilingSimplifier(_simplifier, printAfter: true, label: label));

  void minimize() => andThen(
      LazilyBuiltSimplifier((_) => _buildMinimizer(_adaptiveSimplifier)));

  void andThen(Simplifier next) {
    if (next is AdaptiveSimplifier) {
      _adaptiveSimplifier = next;
    }
    if (_simplifier == null) {
      _simplifier = next;
    }
    _simplifier = TwoPassSimplifier(_simplifier, next);
  }

  Simplifier _buildMinimizer(AdaptiveSimplifier adaptiveSimplifier) {
    if (adaptiveSimplifier == null) {
      return OneMinimalSimplifier();
    }
    if (adaptiveSimplifier.lastDeletedOffset == null) {
      return NoopSimplifier();
    }
    return OneMinimalSimplifier(
        lastDeletedOffset: adaptiveSimplifier.lastDeletedOffset);
  }

  PresamplingSimplifier _buildPresampling(int count) =>
      PresamplingSimplifier.forTracker(tracker, samples: count);

  AdaptiveSimplifier _buildAdaptive() =>
      AdaptiveSimplifier.forTracker(tracker, _buildPlanner);
}

class AsyncSimplifierBuilder extends _SimplifierBuilderBase {
  final bool cacheTrees;
  final int maxTreeSize;
  final DistributionTracker tracker;
  AsyncSimplifier _simplifier;

  AdaptiveAsyncSimplifier _adaptiveSimplifier;

  AsyncSimplifierBuilder({
    AsyncSimplifier startWith,
    this.cacheTrees = true,
    this.maxTreeSize = 80,
    DistributionTracker tracker,
  })  : this.tracker = tracker ?? DistributionTracker(),
        _simplifier = startWith;

  AsyncSimplifier finish() => _simplifier;

  AsyncStringSimplifier stringSimplifier() =>
      AsyncStringSimplifier(_simplifier);

  void presample([int count = 5]) => andThen(_buildPresampling(count));

  void adaptiveConsume() => andThen(_buildAdaptive());

  void profile([String label]) => _simplifier = (label == null
      ? ProfilingAsyncSimplifier(_simplifier)
      : ProfilingAsyncSimplifier(_simplifier, printAfter: true, label: label));

  void minimize() => andThen(
      LazilyBuiltAsyncSimplifier((_) => _buildMinimizer(_adaptiveSimplifier)));

  void andThen(AsyncSimplifier next) {
    if (next is AdaptiveAsyncSimplifier) {
      _adaptiveSimplifier = next;
    }
    if (_simplifier == null) {
      _simplifier = next;
    }
    _simplifier = TwoPassAsyncSimplifier(_simplifier, next);
  }

  AsyncSimplifier _buildMinimizer(AdaptiveAsyncSimplifier adaptiveSimplifier) {
    if (adaptiveSimplifier == null) {
      return OneMinimalAsyncSimplifier();
    }
    if (adaptiveSimplifier.lastDeletedOffset == null) {
      return NoopSimplifierAsync();
    }
    return OneMinimalAsyncSimplifier(
        lastDeletedOffset: adaptiveSimplifier.lastDeletedOffset);
  }

  PresamplingAsyncSimplifier _buildPresampling(int count) =>
      PresamplingAsyncSimplifier.forTracker(tracker, samples: count);

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
