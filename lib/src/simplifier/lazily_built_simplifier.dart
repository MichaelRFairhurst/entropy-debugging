import 'dart:async';

import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class LazilyBuiltSimplifier<T, R extends FutureOr<List<T>>,
    S extends FutureOr<bool>> implements Simplifier<T, R, S> {
  final Simplifier<T, R, S> Function(List<Object>) build;

  LazilyBuiltSimplifier(this.build);
  R simplify(List<T> input, S Function(List<T>) test) =>
      build(input).simplify(input, test);
}
