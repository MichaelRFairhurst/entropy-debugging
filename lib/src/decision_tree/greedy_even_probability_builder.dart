import 'package:entropy_debugging/src/decision_tree/top_down_builder_step.dart';
import 'package:entropy_debugging/src/decision_tree/builder_combinator.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';

/// A [DecisionTreeBuilder] that greedily makes 50/50 probability branches.
///
/// Even so slightly slower than ordered huffman, but also closer to producing
/// optimal results (usually within .5% of optimal).
DecisionTreeBuilder<T> greedyEvenProbabilityDecisionTreeBuilder<T>() =>
    SimpleTopDownBuilder<T>(GreedyEvenProbabilityDecisionTreeBuilderStep<T>());

/// A decision tree builder that combines the greedy 50/50 approach, with the
/// slower optimal search for subtrees below a certain size (currently 8).
///
/// Not optimal if input size is over 8, and slower to build than ordered
/// huffman or plain greedy 50/50 builders, but it can produce trees that are
/// ridiculously close to optimal (like a tenth of a percent off).
DecisionTreeBuilder<T> greedyEvenProbabilityCombinatorBuilder<T>() =>
    DecisionTreeBuilderCombinator<T>(
        OptimalSizeThresholdTreeBuilderStep<T>(
            GreedyEvenProbabilityDecisionTreeBuilderStep<T>(), 15),
        [HuffmanLikeDecisionTreeBuilder<T>()]);

/// A [TopDownDecisionTreeBuilderStep]s to always take the closest path to 50%.
///
/// This does very well in benchmarks, is it is both fast and it produces nearly
/// optimal trees -- usually, within a half a percent of the optimum.
/// Additionally, the top down nature means it can easily blend with other
/// algorithms to solve the subtrees, such as the slower optimal solver.
/// Therefore this is implemented as a [TopDownDecisionTreeBuilderStep] to
/// enable that in a customizable way.
class GreedyEvenProbabilityDecisionTreeBuilderStep<T>
    implements TopDownDecisionTreeBuilderStep<T> {
  @override
  DecisionTree<T> build(
      List<Decision<T>> decisions, DecisionTreeBuilder nextStep) {

    if (decisions.length == 1) {
      return decisions.single;
    } else if (decisions.length == 2) {
      return Branch<T>(decisions.first, decisions.last);
    }

    final left = List<Decision<T>>.from(decisions.take(decisions.length - 1));
    final right = <Decision<T>>[decisions.last];

    double probabilityLeft =
        left.fold(0.0, (h, d) => h + d.probability);
    double probabilityRight = decisions.last.probability;
    while (probabilityLeft > probabilityRight && left.length > 1) {
      final move = left.last;
      final moveProbability = move.probability;
      // Take 0.1, 0.7, 0.2. We want to keep 0.7 left because 0.8 < 0.9.
      if (probabilityLeft < probabilityRight + moveProbability) {
        break;
      }
      left.removeLast();
      right.add(move);
      probabilityLeft -= moveProbability;
      probabilityRight += moveProbability;
    }

    return Branch<T>(
        nextStep.build(left), nextStep.build(right.reversed.toList()));
  }
}
