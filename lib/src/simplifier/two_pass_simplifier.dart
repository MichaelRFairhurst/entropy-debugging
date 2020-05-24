import 'package:entropy_debugging/src/simplifier/simplifier.dart';

/// A simplifier that simply passes the result of the [first] simplifier into
/// the [second] simplifier.
class TwoPassSimplifier implements Simplifier {
  final Simplifier first;
  final Simplifier second;

  TwoPassSimplifier(this.first, this.second);

  @override
  List<T> simplify<T>(List<T> input, bool Function(List<T>) test) =>
      second.simplify(first.simplify(input, test), test);
}
