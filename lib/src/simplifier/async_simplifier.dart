/// A simplifier of the input list, returning the smallest output list it can
/// find matching some criteria, allowing for asynchrony.
abstract class AsyncSimplifier<T> {
  Future<List<T>> simplify(List<T> input);
}
