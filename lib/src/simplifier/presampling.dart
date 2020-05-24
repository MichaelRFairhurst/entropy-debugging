import 'dart:math';

import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/executor.dart';
import 'package:entropy_debugging/src/decision_tree/printer.dart';
import 'package:entropy_debugging/src/decision_tree/rightmost.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/distribution/tracker.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/nonadaptive.dart';

/// A simplifier which is intended to be the first step in a
/// [FirstPassSimplifier], to sample the input before invoking a second
/// simplification.
///
/// Can be used in front of a nonadaptive simplifier as a means of doing pure
/// random sampling driven simplification, or can be used in front of an
/// adaptive simplifier to add in some pure random sampling behavior into its
/// approach.
class PresamplingSimplifier implements Simplifier {
  final DistributionTracker distributionTracker;
  final int samples;

  PresamplingSimplifier({this.samples = 25})
      : distributionTracker = DistributionTracker();

  PresamplingSimplifier.forTracker(this.distributionTracker,
      {this.samples = 25});

  List<T> simplify<T>(List<T> input, bool Function(List<T>) function) {
    final random = Random();
    for (int i = 0; i < samples; ++i) {
      if (input.length < 2) {
        // Not enough to sample. Stop.
        break;
      }

      // TODO: handle sampling the same item twice
      final randomIndex = random.nextInt(input.length - 1);
      final candidate = List<T>.from(input)..remove(randomIndex);
      if (function(candidate)) {
        distributionTracker.unimportantHit();
        input = candidate;
        final pairCandidate = List<T>.from(candidate)..remove(randomIndex);
        if (function(pairCandidate)) {
          distributionTracker.unimportantRepeatHit();
          input = pairCandidate;
        } else {
          distributionTracker.unimportantRepeatMiss();
        }
      } else {
        distributionTracker.importantHit();
      }
    }

    // TODO: have some way of reporting back which items were previously found
    // to be important.
    return input;
  }
}
