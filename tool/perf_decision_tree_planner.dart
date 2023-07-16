import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/decision_tree/huffman_builder.dart';
import 'package:entropy_debugging/src/planner/builder.dart';
import 'dart:math';
import 'dart:io';

void main() {
  final random = Random();
  final sampleSize = 500;

  final slowSet = {
    "A*": TreePlannerBuilder.astar(),
    "Weighted A*": TreePlannerBuilder.astar(1.3),
  };

  final benchPlanners = {
    'optimal': TreePlannerBuilder.slowOptimal(),
    "huffman": TreePlannerBuilder(HuffmanDecisionTreeBuilder()),
    "huffmanlike": TreePlannerBuilder.huffmanLike(),
    "evenProbability": TreePlannerBuilder.evenProbability(),
    "evenProbabilityCombinator": TreePlannerBuilder.evenProbabilityCombinator(),
  };

  final result20 = benchSet({...slowSet, ...benchPlanners}, 20, sampleSize, random);
  printResult(result20, sampleSize);
  final result100 = benchSet(benchPlanners, 100, sampleSize, random);
  printResult(result100, sampleSize);
}

void printResult(Result result, int sampleSize) {
  final costPerSample = result.getRelativeCosts(1.0*sampleSize);
  final costPerEntropy = result.getRelativeCosts(result.entropy);
  final resultMs = result.getRelativeMs(1.0*sampleSize);
  Map<String, double> costVsOptimal = null;
  if (result.costs.containsKey('optimal')) {
    costVsOptimal = result.getRelativeCosts(result.costs['optimal']);
  }

  print("Entropy is ${result.entropy / sampleSize}");
  for (final name in result.costs.keys) {
    final printName = (name + ' '*20).substring(0, 20);
    final parts = [
      '[$printName]:',
      'cost=${costPerSample[name].toStringAsFixed(6)}',
      '${costPerEntropy[name].toStringAsFixed(6)}/H',
    ];

    if (costVsOptimal != null) {
      parts.add('${costVsOptimal[name].toStringAsFixed(6)}/optimal');
    }

    parts.add('${resultMs[name].toStringAsFixed(8)}us');

    print(parts.join('\t'));
  }
}

class Result {
  double entropy = 0.0;
  final costs = <String, double>{};
  final ms = <String, double>{};

  Result(Set<String> planners) {
    for(final name in planners) {
      costs[name] = 0.0;
      ms[name] = 0.0;
    }
  }

  Map<String, double> getRelativeCosts(double standard) {
    final adjusted = <String, double>{};
    for (final name in costs.keys) {
      adjusted[name] = costs[name] / standard;
    }

    return adjusted;
  }

  Map<String, double> getRelativeMs(double adjustment) {
    final adjusted = <String, double>{};
    for (final name in ms.keys) {
      adjusted[name] = ms[name] / adjustment;
    }

    return adjusted;
  }
}

Result benchSet(
    Map<String, TreePlannerBuilder> benchPlanners,
    int capSize,
    int sampleSize,
    Random random
) {
  final result = Result(benchPlanners.keys.toSet());

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

    final length = random.nextInt(500);

    double entropy = 0.0;
    for (final plannerName in benchPlanners.keys) {
      final planner = benchPlanners[plannerName];
      final builder = (planner..basic(markov)..capSize(capSize)).finish();

      final startTime = DateTime.now();
      final tree = builder.plan(length, event);
      final ms = (DateTime.now().difference(startTime)).inMicroseconds;
      assert(entropy == 0 || entropy == tree.entropy, '$entropy != ${tree.entropy}');
      entropy = tree.entropy;
      result.costs[plannerName] += tree.cost;
      result.ms[plannerName] += ms;
      stdout.write('.');
    }

    result.entropy += entropy;
  }

  print('');
  return result;
}

