/// A class to represent a decision tree, where the leaves are [Decision]s with
/// some [probability], and the [Branch]es can be turned into questions.
///
/// This is used by the entropy debugging algorithm to scan for unneeded
/// elements in the input set with some attempt at optimal searching, given the
/// probability of the items in the input set being unneeded.
abstract class DecisionTree<Outcome> {
  /// The probability that this tree will be explored.
  double get probability;

  /// The average number of questions asked in walking this tree.
  double get cost;

  double _costAtDepth(int depth);
}

class Decision<Outcome> implements DecisionTree<Outcome> {
  final Outcome outcome;

  @override
  final double probability;

  @override
  double get cost => probability;

  @override
  double _costAtDepth(int depth) => depth * cost;

  @override
  Decision(this.outcome, this.probability);

  operator ==(Object other) =>
      other is Decision<Outcome> &&
      other.outcome == outcome &&
      other.probability == probability;
}

class Branch<O> implements DecisionTree<O> {
  /// The left side of the branch, which is executed if the test returns true.
  final DecisionTree left;

  /// The right side of the branch, which is executed if the test returns false.
  final DecisionTree right;

  @override
  double get probability => left.probability + right.probability;

  @override
  double get cost => _costAtDepth(0);

  @override
  double _costAtDepth(int depth) =>
      left._costAtDepth(depth + 1) + right._costAtDepth(depth + 1);

  Branch(this.left, this.right);

  operator ==(Object other) =>
      other is Branch<O> && other.left == left && other.right == right;
}
