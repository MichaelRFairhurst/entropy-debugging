import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/decision_tree/optimal_builder.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/naive_entropy_builder.dart';
import 'package:entropy_debugging/src/decision_tree/printer.dart';
import 'package:entropy_debugging/src/planner/builder.dart';
import 'dart:math';
import 'dart:io';

void main() {
  final random = Random();
  final sampleSize = 1000;
  var cost = 0.0;
  var entropy = 0.0;
  var perfect = 0.0;

  for (int i = 0; i < sampleSize; ++i) {
    final markov = MarkovModel(random.nextDouble(), random.nextDouble());
    if (markov.pRepeatImportant < 0) {
      i--;
      continue;
    }

    final stateRand = random.nextDouble();
    var event;
    if (stateRand < 1/3) {
      event = EventKind.unknown;
    } else if(stateRand < 2/3) {
      event = EventKind.important;
    } else {
      event = EventKind.unimportant;
    }

    final planner = TreePlannerBuilder.huffmanLike();
    final builder = (planner..probabilityThreshold(markov)..capSize(100)).finish();

    //final optPlanner = TreePlannerBuilder.slowOptimal();
    //final optBuilder = (optPlanner..probabilityThreshold(markov)..capSize(12)).finish();

    //final planner = TreePlannerBuilder.entropyCombinator();
    //final builder = (planner..basic(markov)..capSize(100)).finish();

    final length = random.nextInt(500);
    final tree = builder.plan(length, event);
    //final optTree = optBuilder.plan(length, event);
    cost += tree.cost;
    entropy += tree.entropy;
    //perfect += optTree.cost;
    stdout.write('.');
  }

  print('');
  print("Cost is ${cost / sampleSize}");
  print("Entropy is ${entropy / sampleSize}");
  print("Relative cost is ${cost/ entropy}");
  //print("Optimum is ${perfect / sampleSize}");
  //print("Relative cost is ${cost/ perfect}");
}

