import 'package:entropy_debugging/src/decision_tree/top_down_builder_step.dart';
import 'package:entropy_debugging/src/decision_tree/optimal_builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// A class to make a [TopDownDecisionTreeBuilderStep] into a combinator of
/// multiple [DecisionTreeBuilder] algorithms.
///
/// At each stage, each builder will be considered, and the best result will be
/// returned. The builder [step] will also be considered, where each substep
/// will consider each builder for the best known subtree.
///
/// For instance, to make a naive entropy builder that also tries huffman like
/// trees for each build step:
///
/// ```dart
///  DecisionTreeBuilderCominator<T>(
///    NaiveEntropyDecisionTreeBuilderStep<T>(),
///    [HuffmanLikeDecisionTreeBuilder<T>()],
/// ```
class DecisionTreeBuilderCombinator<T> implements DecisionTreeBuilder<T> {
  final TopDownDecisionTreeBuilderStep<T> step;
  final List<DecisionTreeBuilder<T>> builderOptions;

  DecisionTreeBuilderCombinator(this.step, this.builderOptions);

  DecisionTree<T> build(List<Decision<T>> decisions) => buildBest(decisions);

  DecisionTree<T> buildBest(List<Decision<T>> decisions) {
    DecisionTree<T> best = step.build(decisions, this);
    for (final builder in builderOptions) {
      final option = builder.build(decisions);
      if (option.cost < best.cost) {
        best = option;
      }
    }
    return best;
  }
}

/// A layer on top of a [TopDownDecisionTreeBuilderStep] to build the optimal
/// tree below a certain size threshold instead of continuing the step
/// potentially suboptimally.
///
/// For instance, to make a naive entropy builder step that reverts to optimal
/// for subtrees of fewer than 8 nodes:
///
/// ```dart
///  OptimalSizeThresholdTreeBuilderStep<T>(
///    NaiveEntropyDecisionTreeBuilderStep<T>(), 8);
/// ```
class OptimalSizeThresholdTreeBuilderStep<T>
    implements TopDownDecisionTreeBuilderStep<T> {
  final int sizeThreshold;
  final TopDownDecisionTreeBuilderStep<T> innerStep;

  OptimalSizeThresholdTreeBuilderStep(this.innerStep, this.sizeThreshold);

  DecisionTree<T> build(List<Decision<T>> decisions,
          DecisionTreeBuilder<T> nextStepBuilder) =>
      decisions.length < sizeThreshold
          ? OptimalDecisionTreeBuilder().build(decisions)
          : innerStep.build(decisions, nextStepBuilder);
}
