import 'dart:math';

import 'package:entropy_debugging/src/simplifier/simplifier.dart';

/// A simplifier that finds a `1-minimal` case, as defined by the original delta
/// debugging paper, via a simple brute search.
class OneMinimalSimplifier<T> implements Simplifier<T> {
  final bool Function(List<T>) test;

  OneMinimalSimplifier(this.test);

  @override
  List<T> simplify(List<T> input) {
    var result = List<T>.from(input);
    int searchUntil;
    do {
      searchUntil = result.length;
      for (int i = 0; i < result.length; ++i) {
        final candidate = List<T>.from(result)..removeAt(i);
        if (test(candidate)) {
          result = candidate;
          searchUntil = min(searchUntil, i);
          --i;
        }
      }
    } while (searchUntil != result.length);
    return result;
  }
}
