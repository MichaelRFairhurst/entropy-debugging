import 'dart:math';
import 'package:entropy_debugging/entropy_debugging.dart' as entropy_debugging;
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/lower_bound.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal.dart';
import 'package:entropy_debugging/src/competing/delta_debugging_translated_wrapper.dart';
import 'package:entropy_debugging/src/simplifier/profiling.dart';

void main() {
  final increment = 0.05;
  final factor = 1;
  final sampleSize = 500;
  final maxRepeatedUnimportant = 200;
  final eventCount = 100;
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
      tabulate(markov, random, sampleSize, maxRepeatedUnimportant, eventCount);
    }
    pImportant += increment;
  }
}

double maxCompression(
    MarkovModel markov, int maxRepeatedUnimportant, int eventCount) {
  var firstEventEntropy = 0.0;
  var probabilityTracker = 0.0;
  for (int i = 0; i <= maxRepeatedUnimportant; ++i) {
    final events = Iterable.generate(i, (_) => EventKind.unimportant).toList()
      ..add(EventKind.important);
    final probability = i == maxRepeatedUnimportant
        ? 1 - probabilityTracker
        : min(markov.probabilityOfAll(events, EventKind.unknown),
            1 - probabilityTracker);
    if (probability <= 0 || probabilityTracker >= 1.0) {
      break;
    }
    probabilityTracker += probability;
    // Standard entropy. Overly optimistic.
    firstEventEntropy += probability * -_log2(probability);
    // Updated entropy. Bugs?
    //firstEventEntropy += probability * max(-_log2(probability), i == 0 ? 1 : 2);
    // Less updated entropy.
    firstEventEntropy += probability * max(-_log2(probability), 1);
    if (-_log2(probability) < 1) {
      print('here $i $probability');
    }
    // Dimensional entropy; a few levels of derivation and needs proof.
    //firstEventEntropy += probability * (i == 0 ? 1 : 2);
  }

  var remainingEventsEntropy = 0.0;
  probabilityTracker = 0;
  for (int i = 0; i <= maxRepeatedUnimportant; ++i) {
    final events = Iterable.generate(i, (_) => EventKind.unimportant).toList()
      ..add(EventKind.important);
    final probability = i == maxRepeatedUnimportant
        ? 1 - probabilityTracker
        : min(markov.probabilityOfAll(events, EventKind.important),
            1 - probabilityTracker);
    if (probability <= 0 || probabilityTracker >= 1.0) {
      continue;
    }
    //print('here $i $probability $probabilityTracker ${-_log2(probability)}');
    probabilityTracker += probability;
    // Standard entropy. Overly optimistic.
    //remainingEventsEntropy += probability * -_log2(probability);
    // Updated entropy. Bugs?
    //remainingEventsEntropy +=
    //    probability * max(-_log2(probability), i == 0 ? 1 : 2);
    // Less updated entropy.
    remainingEventsEntropy += probability * max(-_log2(probability), 1);
    if (-_log2(probability) < 1) {
      print('here remaining $i $probability $events');
    }
    // Dimensional entropy; a few levels of derivation and needs proof.
    //remainingEventsEntropy += probability * (i == 0 ? 1 : 2);
  }
  //print('here $probabilityTracker $firstEventEntropy $remainingEventsEntropy');
  return max(firstEventEntropy, 1.0) +
      max(remainingEventsEntropy, 1.0) * (eventCount - 1);
}

double _log2(double x) => log(x) / ln2;

void tabulate(MarkovModel markov, Random random, int sampleSize,
    int maxRepeatedUnimportant, int eventCount) {
  double averageRuns = 0;
  for (int i = 0; i < sampleSize; ++i) {
    final result =
        singleTrial(markov, random, maxRepeatedUnimportant, eventCount);
    averageRuns += result / sampleSize;
  }
  if (averageRuns <
      maxCompression(markov, maxRepeatedUnimportant, eventCount)) {
    print('----OOOPS');
  }
  print([
    markov.pUnderlyingImportant,
    markov.pRepeatUnimportant,
    averageRuns,
    maxCompression(markov, maxRepeatedUnimportant, eventCount),
  ].join(','));
}

int singleTrial(MarkovModel markov, Random random, int maxRepeatedUnimportant,
    int eventCount) {
  var input = <int>[];
  var expected = <int>[];
  int eventsGenerated = 0;
  int repeatedUnimportant = 0;
  var state = EventKind.unknown;
  for (int i = 0; eventsGenerated < eventCount; ++i) {
    EventKind next;
    if (repeatedUnimportant == maxRepeatedUnimportant) {
      next = EventKind.important;
    } else {
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
    }

    if (next == EventKind.unimportant) {
      input.add(-(i + 1));
      repeatedUnimportant++;
    } else {
      input.add(i + 1);
      expected.add(i + 1);
      eventsGenerated++;
      repeatedUnimportant = 0;
    }
    state = next;
  }

  bool test(List<int> candidate) =>
      candidate.where((i) => i > 0).length == expected.length;

  final simplifier = ProfilingSimplifier<int, List<int>, bool>(
      entropy_debugging.simplifier()
      //DeltaDebuggingWrapper()
      //OneMinimalSimplifier<int>()
      ,
      printAfter: false);

  final result = simplifier.simplify(input, test);
  if (result.length != expected.length) {
    throw 'bad result! $input produced $result, not $expected';
  } else {
    for (int i = 0; i < expected.length; ++i) {
      if (result[i] != expected[i]) {
        throw 'bad result! $input produced $result';
      }
    }
  }
  return simplifier.runs;
}
