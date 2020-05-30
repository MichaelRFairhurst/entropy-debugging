import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// A step that can recursively build a decision tree by making greedy top down
/// decisions.
///
/// This class exists to abstract the idea of taking multiple possible steps
/// as the tree is built; for instance: a [NaiveEntropyDecisionTreeBuilder] may
/// prefer to builde optimal trees below decision list size `n`, but also share
/// code with an entropy builder that has different rules etc.
abstract class TopDownDecisionTreeBuilderStep<T> {
  DecisionTree<T> build(
      List<Decision<T>> decisions, DecisionTreeBuilder<T> nextStepBuilder);
}

/// A class to make a [TopDownDecisionTreeBuilderStep] into a simple recursive
/// algorithm such that it implemenst [DecisionTreeBuilder].
///
/// For instance, to create a naive entropy decision tree builder, do:
///
/// ```dart
///  SimpleTopDownBuilder<T>(NaiveEntropyDecisionTreeBuilderStep<T>());
/// ```
class SimpleTopDownBuilder<T> implements DecisionTreeBuilder<T> {
  final TopDownDecisionTreeBuilderStep<T> step;

  SimpleTopDownBuilder(this.step);
  DecisionTree<T> build(List<Decision<T>> decisions) =>
      step.build(decisions, this);
}
