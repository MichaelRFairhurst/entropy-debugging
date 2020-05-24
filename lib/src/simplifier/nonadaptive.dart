import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/executor.dart';
import 'package:entropy_debugging/src/decision_tree/printer.dart';
import 'package:entropy_debugging/src/decision_tree/rightmost.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

/// A simplifier which expects an input [MarkovModel] and assumes it is accurate
/// for the inputs it receives, and simplifies them based on that model plus the
/// given [planner].
class NonadaptiveSimplifier implements Simplifier {
  final MarkovModel markov;
  final TreePlanner planner;

  NonadaptiveSimplifier(this.markov, this.planner);

  List<T> simplify<T>(List<T> input, bool Function(List<T>) function) {
    var result = List<T>.from(input);
    EventKind previous = EventKind.unknown;

    int offset = 0;
    while (offset < result.length) {
      final decisionTree = planner.plan(result.length - offset, previous);

      final executor = DecisionTreeExecutor<Sequence>((left, right) {
        final pivot = DecisionTreeRightMost<Sequence>().walk(left, null);
        final list = pivot.outcome.list;
        return !function(List<T>.from(result)
          ..replaceRange(offset, offset + list.length, []));
      });

      final decision = executor.execute(decisionTree);
      final realSequence = decision.outcome.list;
      previous = realSequence.last;
      if (realSequence.last == EventKind.important) {
        result.replaceRange(offset, offset + realSequence.length - 1, []);
        offset += 1;
      } else {
        result.replaceRange(offset, offset + realSequence.length, []);
      }
    }

    return result;
  }
}
