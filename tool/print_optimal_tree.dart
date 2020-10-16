import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';
import 'package:entropy_debugging/src/decision_tree/optimal_builder.dart';
import 'package:entropy_debugging/src/decision_tree/naive_entropy_builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/printer.dart';
import 'dart:math';

void main() {
  final random = Random();
  final length = random.nextInt(8) + 8;
  final randomValues =
      Iterable<int>.generate(length, (_) => random.nextInt(1000)).toList();
  final sum = randomValues.reduce((a, b) => a + b);
  final odds = randomValues.map((value) => value / sum);
  final decisions = odds.map((item) => Decision('', item)).toList();
  final builders = {
    'huffman': HuffmanLikeDecisionTreeBuilder(),
    'information gain': informationGainDecisionTreeBuilder(),
    'combinator': informationGainCombinatorBuilder(),
  };
  final optimal = OptimalDecisionTreeBuilder().build(decisions);
  print('Optimal cost: (${optimal.cost})');
  print(DecisionTreePrinter().print(optimal));
  for (final builder in builders.entries) {
    final tree = builder.value.build(decisions);
    if (tree.cost == optimal.cost) {
      print('${builder.key} is optimal.');
    } else {
      print(
          '${builder.key}: (${tree.cost}, diff of ${tree.cost - optimal.cost})');
      print(DecisionTreePrinter().print(tree));
    }
  }
}
