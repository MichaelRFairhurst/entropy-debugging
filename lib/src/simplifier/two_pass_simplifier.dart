import 'dart:async';

import 'package:entropy_debugging/src/simplifier/simplifier.dart';

/// A simplifier that simply passes the result of the [first] simplifier into
/// the [second] simplifier.
class TwoPassSimplifier<T, R extends FutureOr<List<T>>,
    S extends FutureOr<bool>> implements Simplifier<T, R, S> {
  final Simplifier<T, R, S> first;
  final Simplifier<T, R, S> second;

  TwoPassSimplifier(this.first, this.second);

  @override
  R simplify(List<T> input, S Function(List<T>) test) {
    final intermediate = first.simplify(input, test);
    if (intermediate is Future<List<T>>) {
      return intermediate
          .then((intermediate) => second.simplify(intermediate, test)) as R;
    }
    return second.simplify(intermediate as List<T>, test);
  }
}
