import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';

/// A simplifier that simply passes the result of the [first] simplifier into
/// the [second] simplifier.
class TwoPassAsyncSimplifier implements AsyncSimplifier {
  final AsyncSimplifier first;
  final AsyncSimplifier second;

  TwoPassAsyncSimplifier(this.first, this.second);

  @override
  Future<List<T>> simplify<T>(
          List<T> input, Future<bool> Function(List<T>) test) async =>
      second.simplify(await first.simplify(input, test), test);
}
