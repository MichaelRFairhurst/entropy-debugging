import 'dart:math';

import 'package:entropy_debugging/src/simplifier/simplifier.dart';

/// A simplifier that finds a `1-minimal` case, as defined by the original delta
/// debugging paper, via a simple brute search.
///
/// The *only* optimization this makes is that it will not scan the input for
/// deletions past the last deleted point if it did not make any progress.
/// Imagine that a pass removed characters 5 & 7 in a 10 character input. On the
/// next pass, if characters 1-4 and 6 were not found to be wasteful, then we
/// already know that the input is one-minimal, because we already tried
/// removing characters 8 and 9. On the other hand, if character 6 were removed
/// in this pass, then we would have to see if this removal has made 8 or 9
/// waste, because we can make no guarantees about our blackbox function other
/// than idempotence.
class OneMinimalAsyncSimplifier<T>
    implements Simplifier<T, Future<List<T>>, Future<bool>> {
  final int _searchUntil;

  OneMinimalAsyncSimplifier({int lastDeletedOffset})
      : _searchUntil = lastDeletedOffset;

  @override
  Future<List<T>> simplify(
      List<T> input, Future<bool> Function(List<T>) test) async {
    var result = List<T>.from(input);
    bool madeProgress;

    var searchUntil = _searchUntil ?? result.length;

    do {
      madeProgress = false;

      for (int i = 0; i < result.length && i != searchUntil; ++i) {
        final candidate = List<T>.from(result)..removeAt(i);
        if (await test(candidate)) {
          result = candidate;
          madeProgress = true;
          searchUntil = i - 1;
          --i;
        }
      }
    } while (madeProgress);

    return result;
  }
}
