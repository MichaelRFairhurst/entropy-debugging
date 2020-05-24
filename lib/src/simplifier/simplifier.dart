/// A simplifier of the input list, returning the smallest output list it can
/// find matching some test function.
abstract class Simplifier {
  List<T> simplify<T>(List<T> input, bool Function(List<T>) test);
}
