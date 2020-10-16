import 'dart:math';

import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';

double maxCompression(
    MarkovModel markov, int maxSequenceLength, int eventsToFind) {
  // first event
  var firstEventEntropy = 0.0;
  for (int i = 0; i < maxSequenceLength + 1; ++i) {
    final events = Iterable.generate(i, (_) => EventKind.unimportant).toList();

    int minQuestions = 1;
    if (i < maxSequenceLength) {
      events.add(EventKind.important);
      minQuestions = 2;
    }

    final probability =
        markov.probabilityOfAll(events, EventKind.unknown) * minQuestions;
    firstEventEntropy += probability * -_log2(probability);
  }

  // subsequent events
  var remainingEventsEntropy = 0.0;
  for (int i = 1; i < maxSequenceLength + 1; ++i) {
    final events = Iterable.generate(i, (_) => EventKind.unimportant).toList();

    int minQuestions = 1;
    if (i < maxSequenceLength) {
      events.add(EventKind.important);
      minQuestions = 2;
    }

    final probability =
        markov.probabilityOfAll(events, EventKind.important) * minQuestions;
    remainingEventsEntropy += probability * -_log2(probability);
  }

  return firstEventEntropy + remainingEventsEntropy * eventsToFind;
}

double _log2(double x) => log(x) / log(2);
