import 'package:entropy_debugging/src/decision_tree/astar_builder.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';
import 'package:entropy_debugging/src/decision_tree/greedy_even_probability_builder.dart';
import 'package:entropy_debugging/src/decision_tree/optimal_builder.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/basic.dart';
import 'package:entropy_debugging/src/planner/caching.dart';
import 'package:entropy_debugging/src/planner/capped_size_tree.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/planner/size_threshold_tree_planner.dart';

import 'probability_threshold_planner.dart';

class TreePlannerBuilder {
  TreePlanner _planner;
  final DecisionTreeBuilder<Sequence> _treeBuilder;

  TreePlannerBuilder(this._treeBuilder);

  TreePlannerBuilder.evenProbability() : this(greedyEvenProbabilityDecisionTreeBuilder());
  TreePlannerBuilder.evenProbabilityCombinator() : this(greedyEvenProbabilityCombinatorBuilder());
  TreePlannerBuilder.huffmanLike() : this(HuffmanLikeDecisionTreeBuilder());
  TreePlannerBuilder.astar([double weight = 1.0]) : this(AStarDecisionTreeBuilder(weight));
  TreePlannerBuilder.slowOptimal() : this(OptimalDecisionTreeBuilder());

  static TreePlanner defaultPlanner(MarkovModel model,
          {int maxOptimalTreeSize = 10,
          int maxCombinatorSize = 100,
          int maxTreeSize = 1000}) =>
      (TreePlannerBuilder.slowOptimal()
            ..probabilityThreshold(model)
            ..sizeThreshold(maxOptimalTreeSize,
                aboveThreshold: (TreePlannerBuilder.huffmanLike()
                      ..probabilityThreshold(model)
                      ..sizeThreshold(maxCombinatorSize,
                          aboveThreshold: (TreePlannerBuilder.huffmanLike()
                                ..probabilityThreshold(model)
                                ..capSize(maxTreeSize))
                              .finish()))
                    .finish()))
          .finish();

  TreePlanner finish() => _planner;

  void probabilityThreshold(MarkovModel model) {
    assert(_planner == null);
    // TODO: make probabilyt threshold a composable planner
    _planner = ProbabilityThresholdTreePlanner(
      model,
      _treeBuilder,
    );
  }

  void basic(MarkovModel model) {
    assert(_planner == null);
    _planner = BasicTreePlanner(
      model,
      _treeBuilder,
    );
  }

  void cache() {
    _planner = CachingTreePlanner(_planner);
  }

  void capSize(int maxTreeSize) {
    _planner = CappedSizeTreePlanner(_planner, maxTreeSize: maxTreeSize);
  }

  void sizeThreshold(int threshold, {TreePlanner aboveThreshold}) =>
      _planner = SizeThresholdTreePlanner(_planner, threshold, aboveThreshold);
}
