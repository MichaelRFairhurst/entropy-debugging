import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class NoopSimplifier implements Simplifier {
  List<T> simplify<T>(List<T> input, _) => input;
}

class NoopSimplifierAsync implements AsyncSimplifier {
  Future<List<T>> simplify<T>(List<T> input, _) => Future.value(input);
}
