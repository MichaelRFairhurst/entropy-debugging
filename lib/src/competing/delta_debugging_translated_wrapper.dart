import 'package:entropy_debugging/src/competing/delta_debugging_translated.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class DeltaDebuggingWrapper<T> extends DD implements Simplifier<T> {
  final bool Function(List<T>) testFunction;

  DeltaDebuggingWrapper(this.testFunction);

  @override
  Result doTest(List<Delta> c) {
    return testFunction(coerce(c)) ? Result.fail : Result.pass;
  }

  @override
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
