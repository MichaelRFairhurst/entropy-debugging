import 'package:entropy_debugging/src/model/markov.dart';

/// A class that tracks the distribution of important/unimportant in a sample,
/// and can create [MarkovModel]s from that distribution.
class DistributionTracker {
  int trialsUnimportant = 0;
  int hitsUnimportant = 0;
  int trialsUnimportantRepeat = 0;
  int hitsUnimportantRepeat = 0;

  void unimportantHit() {
    trialsUnimportant++;
    hitsUnimportant++;
  }

  void importantHit() {
    trialsUnimportant++;
  }

  void unimportantRepeatHit() {
    unimportantHit();
    trialsUnimportantRepeat++;
    hitsUnimportantRepeat++;
  }

  void unimportantRepeatMiss() {
    importantHit();
    trialsUnimportantRepeat++;
  }

  void sequenceHit(List<EventKind> sequence, EventKind previousEvent) {
    if (sequence.last == EventKind.important) {
      hitsUnimportant += sequence.length - 1;
      trialsUnimportant += sequence.length;
      if (previousEvent == EventKind.unimportant) {
        hitsUnimportantRepeat += sequence.length - 1;
        trialsUnimportantRepeat += sequence.length;
      } else if (sequence.length > 1) {
        hitsUnimportantRepeat += sequence.length - 2;
        trialsUnimportantRepeat += sequence.length - 1;
      }
    } else {
      hitsUnimportant += sequence.length;
      trialsUnimportant += sequence.length;
      if (previousEvent == EventKind.unimportant) {
        hitsUnimportantRepeat += sequence.length;
        trialsUnimportantRepeat += sequence.length;
      } else if (sequence.length > 1) {
        hitsUnimportantRepeat += sequence.length - 1;
        trialsUnimportantRepeat += sequence.length - 1;
      }
    }
  }

  /// Note that we use n+1/s+2 for correct bayesian probability matrix. This
  /// means that if 100% of events are observed important, we don't guess a 100%
  /// probability of all events being important.
  MarkovModel get markov => MarkovModel(
      1 - (hitsUnimportantRepeat + 1) / (trialsUnimportantRepeat + 2),
      1 - (hitsUnimportant + 1) / (trialsUnimportant + 2));

  /// Functions like [markov], except it does not use the rule of succession to
  /// fudge probabilities away from 100%.
  MarkovModel finalizeMarkov() => MarkovModel(
      1 - hitsUnimportantRepeat / trialsUnimportantRepeat,
      1 - hitsUnimportant / trialsUnimportant);
}
