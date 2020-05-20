import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class NoopSimplifier<T> implements Simplifier<T> {
  List<T> simplify(List<T> input) => input;
}

class NoopSimplifierAsync<T> implements AsyncSimplifier<T> {
  Future<List<T>> simplify(List<T> input) => Future.value(input);
}
