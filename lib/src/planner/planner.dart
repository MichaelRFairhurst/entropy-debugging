import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';

/// A means of getting a decision tree from a remaining set of events in a
/// sample.
abstract class TreePlanner {
  DecisionTree<Sequence> plan(int length, EventKind previous);
}
