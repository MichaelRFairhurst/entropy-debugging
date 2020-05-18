import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';

/// A simplifier that simply passes the result of the [first] simplifier into
/// the [second] simplifier.
class TwoPassAsyncSimplifier<T> implements AsyncSimplifier<T> {
  final AsyncSimplifier<T> first;
  final AsyncSimplifier<T> second;

  TwoPassAsyncSimplifier(this.first, this.second);

  @override
  Future<List<T>> simplify(List<T> input) async =>
      second.simplify(await first.simplify(input));
}
