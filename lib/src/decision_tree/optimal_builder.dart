import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// An optimal, in terms of result, [DecisionTreeBuilder]s, which is slow
/// to build.
class OptimalDecisionTreeBuilder<T> implements DecisionTreeBuilder<T> {
  @override
  DecisionTree<T> build(List<Decision<T>> decisions) {
    return buildSubproblem(decisions, 0, decisions.length, {});
  }

  /// Create an optimal subtree and cache it.
  DecisionTree<T> buildSubproblem(List<Decision<T>> decisions, int start,
      int end, Map<Range, DecisionTree<T>> cache) {
    if (start == end - 1) {
      return decisions[start];
    }
    if (start == end - 2) {
      return Branch<T>(decisions[start], decisions[start + 1]);
    }

    final range = Range(start, end);
    final cached = cache[range];
    if (cached != null) {
      return cached;
    }

    DecisionTree result;
    double resultCost;
    for (int i = start + 1; i < end; ++i) {
      final left = buildSubproblem(decisions, start, i, cache);
      final right = buildSubproblem(decisions, i, end, cache);
      final contender = Branch<T>(left, right);
      if (result == null || resultCost > contender.cost) {
        result = contender;
        resultCost = result.cost;
      }
    }

    cache[range] = result;
    return result;
  }
}

/// Class to store ranges for the sake of caching subproblem solutions.
class Range {
  final int start;
  final int end;
  Range(this.start, this.end);

  int get hashCode => Object.hash(start, end);

  bool operator ==(Object other) =>
      other is Range && other.start == start && other.end == end;
}
