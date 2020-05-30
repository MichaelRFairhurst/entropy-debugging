import 'package:entropy_debugging/src/decision_tree/top_down_builder_step.dart';
import 'package:entropy_debugging/src/decision_tree/builder_combinator.dart';
import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';
import 'package:entropy_debugging/src/decision_tree/optimal_builder.dart';
import 'package:entropy_debugging/src/model/entropy.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// A [DecisionTreeBuilder] that emulates entropy based decision tree learning.
///
/// This does not do well in our benchmarks. It is preferable to either use
/// [HuffmanLikeDecisionTreeBuilder], or [entropyCombinatorBuilder] which is a
/// combination of the two algorithms (and can build better trees, but is also
/// slower to build them).
DecisionTreeBuilder<T> naiveEntropyDecisionTreeBuilder<T>() =>
    SimpleTopDownBuilder<T>(NaiveEntropyDecisionTreeBuilderStep<T>());

/// A decision tree builder that combines the naive entropy approach, with a
/// huffmanlike approach, and for non-huffmanlike paths builds optimal subtrees
/// below a certain size (currently 8).
///
/// Not optimal if input size is over 8, and slower to build than huffman or
/// naive entropy builders, but can produce better trees.
DecisionTreeBuilder<T> entropyCombinatorBuilder<T>() =>
    DecisionTreeBuilderCombinator<T>(
        OptimalSizeThresholdTreeBuilderStep<T>(
            NaiveEntropyDecisionTreeBuilderStep<T>(), 8),
        [HuffmanLikeDecisionTreeBuilder<T>()]);

/// A [TopDownDecisionTreeBuilderStep]s that emulate entropy based decision tree
/// learning.
///
/// See [naiveEntropyDecisionTreeBuilder] and [entropyCombinator
/// however, a combination of the two can result in better performance. This
/// also integrates better with [OptimalDecisionTreeBuilder] since it is a top
/// down algorithm. That is why [TopDownDecisionTreeBuilderStep] exists, to
/// compose those algorithms together.
class NaiveEntropyDecisionTreeBuilderStep<T>
    implements TopDownDecisionTreeBuilderStep<T> {
  @override
  DecisionTree<T> build(
      List<Decision<T>> decisions, DecisionTreeBuilder nextStep) {
    double entropyLeft =
        decisions.fold(0.0, (h, d) => h + entropy(d.probability));
    double entropyRight = 0;

    if (decisions.length == 1) {
      return decisions.single;
    } else if (decisions.length == 2) {
      return Branch<T>(decisions.first, decisions.last);
    }

    final left = List<Decision<T>>.from(decisions);
    final right = <Decision<T>>[];
    while (entropyLeft > entropyRight && left.length > 1) {
      final move = left.last;
      final moveEntropy = entropy(move.probability);
      // Take 0.1, 0.7, 0.2. We want to keep 0.7 left because 0.8 < 0.9.
      if (entropyLeft < entropyRight + moveEntropy) {
        break;
      }
      left.removeLast();
      right.add(move);
      entropyLeft -= moveEntropy;
      entropyRight += moveEntropy;
    }

    return Branch<T>(
        nextStep.build(left), nextStep.build(right.reversed.toList()));
  }
}
