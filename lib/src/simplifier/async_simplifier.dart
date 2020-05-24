/// A simplifier of the input list, returning the smallest output list it can
/// find matching some test function, allowing for asynchrony.
abstract class AsyncSimplifier {
  Future<List<T>> simplify<T>(
      List<T> input, Future<bool> Function(List<T>) test);
}
