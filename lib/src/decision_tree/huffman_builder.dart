import 'package:collection/priority_queue.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// A [DecisionTreeBuilder]s based on the huffman coding algorithm.
///
/// Unfortunately, the huffman coding algorithm does not produce runnable
/// trees. Thus, this exists purely for the purpose of benchmarking and
/// evaluating other decision tree builders.
class HuffmanDecisionTreeBuilder<T> implements DecisionTreeBuilder<T> {
  @override
  DecisionTree<T> build(List<Decision<T>> decisions) {
    if (decisions.length == 1) {
      return decisions.single;
    }
    if (decisions.length == 2) {
      return Branch<T>(decisions[0], decisions[1]);
    }

    final queue = PriorityQueue<DecisionTree<T>>(
      (a, b) => a.probability.compareTo(b.probability));
    queue.addAll(decisions);

    do {
      final head = queue.removeFirst();
      if (queue.isEmpty) {
        return head;
      }
      final neck = queue.removeFirst();
      final newBranch = Branch<T>(head, neck);
      queue.add(newBranch);
    } while (true);
  }
}
