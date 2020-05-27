import 'dart:async';

import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class NoopSimplifier<T, R extends FutureOr<List<T>>, S extends FutureOr<bool>>
    implements Simplifier<T, R, S> {
  R simplify(List<T> input, _) => input is R ? input : Future.value(input) as R;
}
