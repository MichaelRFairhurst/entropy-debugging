import 'dart:async';

import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class ProfilingSimplifier extends ProfilingSimplifierBase
    implements Simplifier {
  Simplifier innerSimplifier;

  ProfilingSimplifier(this.innerSimplifier, {bool printAfter, String label})
      : super._(printAfter, label);

  List<T> simplify<T>(List<T> input, bool Function(List<T>) test) {
    runs = 0;
    testTime = Duration.zero;
    final start = DateTime.now();
    final result = innerSimplifier.simplify(input, (input) {
      runs++;
      final start = DateTime.now();
      final result = test(input);
      testTime += DateTime.now().difference(start);
      return result;
    });
    fullTime = DateTime.now().difference(start);
    if (printAfter) {
      print(recap(input.length, result.length));
    }
    return result;
  }
}

class ProfilingAsyncSimplifier extends ProfilingSimplifierBase
    implements AsyncSimplifier {
  AsyncSimplifier innerSimplifier;
  ProfilingAsyncSimplifier(this.innerSimplifier,
      {bool printAfter, String label})
      : super._(printAfter, label);

  Future<List<T>> simplify<T>(
      List<T> input, Future<bool> Function(List<T>) test) async {
    runs = 0;
    testTime = Duration.zero;
    final start = DateTime.now();
    final result = await innerSimplifier.simplify(input, (input) async {
      runs++;
      final start = DateTime.now();
      final result = await test(input);
      testTime += DateTime.now().difference(start);
      return result;
    });
    fullTime = DateTime.now().difference(start);
    if (printAfter) {
      print(recap(input.length, result.length));
    }
    return result;
  }
}

abstract class ProfilingSimplifierBase {
  final bool printAfter;
  final String label;
  int runs = 0;
  Duration testTime;
  Duration fullTime;

  ProfilingSimplifierBase._(this.printAfter, this.label);

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
