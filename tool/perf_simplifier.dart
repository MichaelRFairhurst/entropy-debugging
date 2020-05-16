import 'dart:math';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/simplifier/nonadaptive.dart';
import 'package:entropy_debugging/src/planner/max_size_optimal_tree.dart';
import 'package:entropy_debugging/src/competing/delta_debugging.dart';

void main() {
  final increment = 0.05;
  final factor = 1;
  final sampleSize = 500;
  final length = 500;
  final random = Random();
  var pImportant = increment;
  var pUnimportantRepeats = increment;

  while (pImportant < 1) {
    for (pUnimportantRepeats = increment;
        pUnimportantRepeats < 1;
        pUnimportantRepeats += increment) {
      final markov =
          MarkovModel(pImportant * factor, pUnimportantRepeats * factor);
      if (markov.pRepeatImportant < 0) {
        continue;
      }
      tabulate(markov, random, sampleSize, length);
    }
    pImportant += increment;
  }
}

class _Result {
  final int runs;
  final Duration duration;
  _Result(this.runs, this.duration);
}

void tabulate(MarkovModel markov, Random random, int sampleSize, int length) {
  double averageRuns = 0;
  double averageMs = 0;
  for (int i = 0; i < sampleSize; ++i) {
    final result = singleTrial(markov, random, length);
    averageRuns += result.runs / sampleSize;
    averageMs += result.duration.inMilliseconds / sampleSize;
  }
  print([
    markov.pUnderlyingImportant,
    markov.pRepeatUnimportant,
    averageRuns,
    averageMs
  ].join(','));
}

_Result singleTrial(MarkovModel markov, Random random, int length) {
  final input = <int>[];
  final expected = <int>[];
  var state = EventKind.unknown;
  for (int i = 1; i <= length; ++i) {
    EventKind next;
    switch (state) {
      case EventKind.unknown:
        if (random.nextDouble() < markov.pUnderlyingImportant) {
          next = EventKind.important;
        } else {
          next = EventKind.unimportant;
        }
        break;
      case EventKind.important:
        if (random.nextDouble() < markov.pRepeatImportant) {
          next = EventKind.important;
        } else {
          next = EventKind.unimportant;
        }
        break;
      case EventKind.unimportant:
        if (random.nextDouble() < markov.pRepeatUnimportant) {
          next = EventKind.unimportant;
        } else {
          next = EventKind.important;
        }
        break;
    }

    if (next == EventKind.unimportant) {
      input.add(-i);
    } else {
      input.add(i);
      expected.add(i);
    }
    state = next;
  }

  int runs = 0;
  bool test(List<int> candidate) {
    runs++;
    return candidate.where((i) => i > 0).length == expected.length;
  }

  final simplifier = NonadaptiveSimplifier<int>(
      test, markov, MaxSizeOptimalTreePlanner(markov));
  //final simplifier = DeltaDebugging<int>(test);
  final start = DateTime.now();
  final result = simplifier.simplify(input);
  final end = DateTime.now();
  if (result.length != expected.length) {
    throw 'bad result! $input produced $result';
  } else {
    for (int i = 0; i < expected.length; ++i) {
      if (result[i] != expected[i]) {
        throw 'bad result! $input produced $result';
      }
    }
  }
  return _Result(runs, end.difference(start));
}
