import 'package:entropy_debugging/src/competing/delta_debugging_translated.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class DeltaDebuggingWrapper implements Simplifier {
  @override
  List<T> simplify<T>(List<T> input, bool Function(List<T>) test) =>
      _DeltaDebuggingWrapper<T>(test).simplify(input);
}

class _DeltaDebuggingWrapper<T> extends DD {
  final bool Function(List<T>) testFunction;

  _DeltaDebuggingWrapper(this.testFunction);

  @override
  Result doTest(List<Delta> c) {
    return testFunction(coerce(c)) ? Result.fail : Result.pass;
  }

  List<T> simplify(List<T> input) {
    var byOffset = <Delta>[];
    for (var i = 0; i < input.length; ++i) {
      byOffset.add(Delta(i, input[i]));
    }
    var result = ddmin(byOffset);
    return coerce(result);
  }

  List<T> coerce(List<Delta> c) => c.map((delta) => delta.value as T).toList();
}
