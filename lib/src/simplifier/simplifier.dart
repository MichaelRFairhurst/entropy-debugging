import 'dart:async';

/// A simplifier of the input list, returning the smallest output list it can
/// find matching some test function.
abstract class Simplifier<T, R extends FutureOr<List<T>>,
    S extends FutureOr<bool>> {
  R simplify(List<T> input, S Function(List<T>) test);
}
