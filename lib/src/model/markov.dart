import 'dart:math';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/model/entropy.dart';

enum EventKind { important, unimportant, unknown }

/// A markov model used to predict which events (characters in a string, for
/// instance) are important.
///
/// We assume that there is a chance of correlation between segments of useful
/// and segments of unuseful code. We do this by defining two states (important,
/// unimportant), and tracking the transition probabilities between them.
///
/// If there is no correlation, the transition probability will reflect that. If
/// there is a correlation, the transition probability will estimate that.
///
/// If there is more complex correlation than a simple transition function, this
/// model will not allow us to optimize against that. However, this model lends
/// itself to a fairly performant algorithm and the ability to integrate better
/// models in the future is an avenue to be explored.
///
/// It's worth noting that important events do not always stay important. It may
/// possible to model this as a hidden markov model in the future. As we learn
/// the emission probabilities we can then guess when there is a certain
/// likelihood of a sample being, say, 99% important.
class MarkovModel {
  /// The probability that an unimportant event (characters in a string, for
  /// instance) is followed by an important event.
  final double pTransitionToImportant;

  /// The probability that an unimportant event (characters in a string, for
  /// instance) are followed by an unimportant event.
  double get pRepeatUnimportant => 1 - pTransitionToImportant;

  /// The probability that an important events (characters in a string, for
  /// instance) is followed by an unimportant event.
  double get pTransitionToUnimportant => 1 - pRepeatImportant;

  /// The probability that an important event (characters in a string, for
  /// instance) is followed by an important event.
  double get pRepeatImportant =>
      (pUnderlyingImportant - pUnderlyingUnimportant * pTransitionToImportant) /
      pUnderlyingImportant;

  /// The underlying probability that any random event (characters in a string,
  /// for instance) is important.
  final double pUnderlyingImportant;

  /// The underlying probability that any random event (characters in a string,
  /// for instance) is unimportant.
  double get pUnderlyingUnimportant => 1 - pUnderlyingImportant;

  Map<EventKind, Map<EventKind, double>> _probabilityMatrix;

  MarkovModel(this.pTransitionToImportant, this.pUnderlyingImportant) {
    _probabilityMatrix = {
      EventKind.unknown: {
        EventKind.important: pUnderlyingImportant,
        EventKind.unimportant: pUnderlyingUnimportant,
        EventKind.unknown: 1,
      },
      EventKind.unimportant: {
        EventKind.unimportant: pRepeatUnimportant,
        EventKind.important: pTransitionToImportant,
      },
      EventKind.important: {
        EventKind.important: pRepeatImportant,
        EventKind.unimportant: pTransitionToUnimportant,
      }
    };
  }

  double probabilityOf(EventKind first, EventKind second) =>
      _probabilityMatrix[first][second] ??
      (throw UnimplementedError('Unimplemented: $first -> $second'));

  double probabilityOfAll(List<EventKind> sequence, EventKind beforeSequence) {
    var probability = 1.0;
    var current = beforeSequence;
    for (final next in sequence) {
      probability *= probabilityOf(current, next);
      current = next;
    }
    return probability;
  }

  /// Get the entropy of each state transition in this markov model.
  double get entropyRate => pUnderlyingImportant *
          (entropy(pTransitionToUnimportant) + entropy(pRepeatImportant)) +
      pUnderlyingUnimportant *
          (entropy(pTransitionToImportant) + entropy(pRepeatUnimportant));

  /// Get the entropy of a sequence of state transitions with the specified
  /// [length], which is the entropy of the starting state plus the [entropyRate]
  /// for each subsequent event.
  double entropyFor(int length) {
    return entropy(pUnderlyingImportant) +
        entropy(pUnderlyingUnimportant) +
        entropyRate * (length - 1);
  }

  /// Get the lower bound of tests for simplifying an input of [length]. This
  /// differs from entropy in that low entropy near-minimal samples have their
  /// lower bound which is greater than entropy.
  double lowerBound(int length) =>
    max(entropyFor(length), pUnderlyingImportant * length);

  @override
  String toString() => "Markov matrix with probabilities $_probabilityMatrix";

  //double probabilityOf(Sequence sequence, SequenceKind beforeSequence,
  //    SequenceKind afterSequence) {
  //  double result;
  //  if (sequence.sequenceKind == SequenceKind.knownImportant) {
  //    if (beforeSequence == SequenceKind.unknownImportance) {
  //      result = pUnderlyingImportart;
  //    }
  //    if (sequence.length > 1) {
  //      throw UnimplementedError("transition probability for important");
  //    }
  //    return result;
  //  }
  //}
}
