import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';

/// A builder of [DecisionTree]s, which has implementations that offer various
/// benefits (for instance, an optimal output or a fast build time).
///
/// Assumes the tree must be ordered. Examples of unordered trees would be
/// huffman coding, where we can always ask the most likely question first (such
/// as, in the case of english, "is the next letter an e?").
///
/// An ordered tree is one where the leaves maintain left to right ordering.
///
/// This is used because the question "are the first n characters waste" leads
/// us to differentiate between all possibilities where n+x characters are waste
/// for some negative integer x, vs all other cases. Therefore all valid
/// decision trees for simplification are equivalent to an ordered tree, where
/// each decision removes all posssibilities for some i such that all
/// possible i < x is removed and all x >= i are preserved.
abstract class DecisionTreeBuilder<T> {
  /// Build the ordered tree for a list of decisions.
  DecisionTree<T> build(List<Decision<T>> decisions);
}
