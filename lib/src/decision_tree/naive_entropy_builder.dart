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
DecisionTreeBuilder<T> informationGainDecisionTreeBuilder<T>() =>
    SimpleTopDownBuilder<T>(InformationGainDecisionTreeBuilderStep<T>());

/// A decision tree builder that combines the naive entropy approach, with a
/// huffmanlike approach, and for non-huffmanlike paths builds optimal subtrees
/// below a certain size (currently 8).
///
/// Not optimal if input size is over 8, and slower to build than huffman or
/// naive entropy builders, but can produce better trees.
DecisionTreeBuilder<T> informationGainCombinatorBuilder<T>() =>
    DecisionTreeBuilderCombinator<T>(
        OptimalSizeThresholdTreeBuilderStep<T>(
            InformationGainDecisionTreeBuilderStep<T>(), 8),
        [HuffmanLikeDecisionTreeBuilder<T>()]);

/// A [TopDownDecisionTreeBuilderStep]s that emulate entropy based decision tree
/// learning.
///
/// See [informationGainDecisionTreeBuilder] and [entropyCombinator
/// however, a combination of the two can result in better performance. This
/// also integrates better with [OptimalDecisionTreeBuilder] since it is a top
/// down algorithm. That is why [TopDownDecisionTreeBuilderStep] exists, to
/// compose those algorithms together.
class InformationGainDecisionTreeBuilderStep<T>
    implements TopDownDecisionTreeBuilderStep<T> {
  double conditionalEntropy(List<Decision> decisions) {
    final pTotal = decisions.fold(0.0, (p, d) => p + d.probability);
    double entropy = 0.0;
    for (final decision in decisions) {
      entropy += decision.probability * -log2(decision.probability / pTotal);
    }
    return entropy;
  }

  @override
  DecisionTree<T> build(
      List<Decision<T>> decisions, DecisionTreeBuilder nextStep) {
    if (decisions.length == 1) {
      return decisions.single;
    } else if (decisions.length == 2) {
      return Branch<T>(decisions.first, decisions.last);
    }

    double entropyAll = conditionalEntropy(decisions);
    final left = <Decision<T>>[];
    final right = decisions.reversed.toList();
    var maxInformationGain = 0.0;
    var maxInformationIndex = null;
    for (var i = 0; i < decisions.length - 1; ++i) {
      left.add(right.removeLast());
      //print('$i ${conditionalEntropy(left)} ${conditionalEntropy(right)}');
      final informationGain =
          entropyAll - conditionalEntropy(left) - conditionalEntropy(right);
      if (informationGain > maxInformationGain) {
        maxInformationGain = informationGain;
        maxInformationIndex = i;
      }
    }

    return Branch<T>(
        nextStep.build(decisions.sublist(0, maxInformationIndex + 1)),
        nextStep.build(
            decisions.sublist(maxInformationIndex + 1, decisions.length)));
  }
}
