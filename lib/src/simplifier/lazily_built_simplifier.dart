import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class LazilyBuiltSimplifier<T> implements Simplifier<T> {
  final Simplifier<T> Function(List<T>) build;

  LazilyBuiltSimplifier(this.build);
  List<T> simplify(List<T> input) => build(input).simplify(input);
}

class LazilyBuiltAsyncSimplifier<T> implements AsyncSimplifier<T> {
  final AsyncSimplifier<T> Function(List<T>) build;

  LazilyBuiltAsyncSimplifier(this.build);
  Future<List<T>> simplify(List<T> input) => build(input).simplify(input);
}
