import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// A [DecisionTreeBuilder]s that produces close to optimal results based on
/// the huffman coding algorithm.
///
/// Unfortunately, the huffman coding algorithm is not optimal when order must
/// be preserved. Proof: [26, 24, 24, 26]. Huffman coding builds a balanced
/// tree, and the optimal ordered tree is also balanced. However, this algorithm
/// will produce an imbalanced tree because it preserves the order.
class HuffmanLikeDecisionTreeBuilder<T> implements DecisionTreeBuilder<T> {
  @override
  DecisionTree<T> build(List<Decision<T>> decisions) {
    final items = List<DecisionTree<T>>.from(decisions);
    while (true) {
      if (items.length == 1) {
        return items.single;
      }
      if (items.length == 2) {
        return Branch<T>(items[0], items[1]);
      }
      double smallestPairProbability;
      int smallestPairIndex;
      for (int i = 0; i < items.length - 1; ++i) {
        double pairProbability =
            items[i].probability + items[i + 1].probability;
        if (smallestPairProbability == null ||
            pairProbability < smallestPairProbability) {
          smallestPairProbability = pairProbability;
          smallestPairIndex = i;
        }
      }
      final newBranch =
          Branch<T>(items[smallestPairIndex], items[smallestPairIndex + 1]);
      items.replaceRange(smallestPairIndex, smallestPairIndex + 2, [newBranch]);
    }
  }
}
