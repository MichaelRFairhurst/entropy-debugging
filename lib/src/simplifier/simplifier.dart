/// A simplifier of the input list, returning the smallest output list it can
/// find matching some criteria.
abstract class Simplifier<T> {
  List<T> simplify(List<T> input);
}
