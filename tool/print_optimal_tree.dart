import 'package:entropy_debugging/src/decision_tree/optimal_builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/printer.dart';
import 'dart:math';

void main() {
  final random = Random();
  final length = 12;
  final randomValues =
      Iterable<int>.generate(length, (_) => random.nextInt(1000)).toList();
  final sum = randomValues.reduce((a, b) => a + b);
  final odds = randomValues.map((value) => value / sum);
  final decisions = odds.map((item) => Decision('', item)).toList();
  final tree = OptimalDecisionTreeBuilder().build(decisions);
  print(DecisionTreePrinter().print(tree));
}
