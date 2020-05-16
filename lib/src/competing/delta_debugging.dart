import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class DeltaDebugging<T> implements Simplifier<T> {
  final bool Function(List<T>) test;

  DeltaDebugging(this.test);

  List<T> simplify(List<T> input) {
    var chunkFactor = 2;
    var chunkSize = (input.length / chunkFactor).ceil();
    var result = List<T>.from(input);
    while (true) {
      for (int i = 0; i < result.length; i += chunkSize) {
        int end = i + chunkSize;
        if (end > result.length) {
          end = result.length;
        }
        var candidate = List<T>.from(result)..replaceRange(i, end, []);
        if (test(candidate)) {
          result = candidate;
          i = i - chunkSize;
        } else {
          candidate = result.sublist(i, end);
          if (test(candidate)) {
            result = candidate;
            break;
          }
        }
      }
      if (chunkSize == 1) {
        break;
      }
      chunkFactor *= 2;
      chunkSize = (input.length / chunkFactor).ceil();
    }
    return result;
  }
}
