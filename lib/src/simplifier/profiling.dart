import 'dart:async';

import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class ProfilingSimplifier<T, R extends FutureOr<List<T>>,
    S extends FutureOr<bool>> implements Simplifier<T, R, S> {
  final Simplifier<T, R, S> innerSimplifier;
  final bool printAfter;
  final String label;
  int runs = 0;
  Duration testTime;
  Duration fullTime;

  ProfilingSimplifier(this.innerSimplifier, {this.printAfter, this.label});

  R simplify(List<T> input, S Function(List<T>) test) {
    runs = 0;
    testTime = Duration.zero;
    final start = DateTime.now();
    final result = innerSimplifier.simplify(input, _transformTest(test));
    if (result is Future<List<T>>) {
      return result.then((result) {
        _afterSimplify(start, input, result);
        return result;
      }) as R;
    }
    _afterSimplify(start, input, result as List<T>);
    return result;
  }

  S Function(List<T>) _transformTest(S Function(List<T>) test) {
    return (input) {
      runs++;
      final start = DateTime.now();
      final result = test(input);
      if (result is Future<bool>) {
        return result.then((result) {
          testTime += DateTime.now().difference(start);
          return result;
        }) as S;
      }
      testTime += DateTime.now().difference(start);
      return result;
    };
  }

  void _afterSimplify(DateTime start, List<T> input, List<T> result) {
    fullTime = DateTime.now().difference(start);
    if (printAfter) {
      print(recap(input.length, result.length));
    }
  }

  String recap(int inputLength, int resultLength) =>
      (label == null ? '' : '[$label] ') +
      'from $inputLength items to $resultLength items'
          ' in ${timingString()}';

  String timingString() => ''
      '$runs tests'
      ' (${fullTime.inMilliseconds}ms,'
      ' ${testTime.inMilliseconds}ms testing'
      ' ${(fullTime - testTime).inMilliseconds}ms overhead)';
}
