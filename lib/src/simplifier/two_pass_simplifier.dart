import 'package:entropy_debugging/src/simplifier/simplifier.dart';

/// A simplifier that simply passes the result of the [first] simplifier into
/// the [second] simplifier.
class TwoPassSimplifier<T> implements Simplifier<T> {
  final Simplifier<T> first;
  final Simplifier<T> second;

  TwoPassSimplifier(this.first, this.second);

  @override
  List<T> simplify(List<T> input) => second.simplify(first.simplify(input));
}
