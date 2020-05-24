import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class LazilyBuiltSimplifier implements Simplifier {
  final Simplifier Function(List<Object>) build;

  LazilyBuiltSimplifier(this.build);
  List<T> simplify<T>(List<T> input, bool Function(List<T>) test) =>
      build(input).simplify(input, test);
}

class LazilyBuiltAsyncSimplifier implements AsyncSimplifier {
  final AsyncSimplifier Function(List<Object>) build;

  LazilyBuiltAsyncSimplifier(this.build);
  Future<List<T>> simplify<T>(
          List<T> input, Future<bool> Function(List<T>) test) =>
      build(input).simplify(input, test);
}
