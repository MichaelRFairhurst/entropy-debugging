import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/model/entropy.dart';

class SlidingWindowSimplifier<T> implements Simplifier<T, List<T>, bool> {
  final MarkovModel markov;

  SlidingWindowSimplifier(this.markov);

  @override
  List<T> simplify(List<T> input, bool Function(List<T>) test) {
    var state = EventKind.unknown;
    var prefix = Sequence([]);

    var iErr = 0.0;
    var uErr = 0.0;
    var iRuns = 0;
    var runs = 0;
    var sublength = input.length < 8 ? input.length : 8;
    final all = allScenarios(sublength);

    var allTests = getTests(Sequence(List.generate(sublength, (_) => EventKind.unknown)));
    var reduced = all;
    while (reduced.length > 1 || prefix.list.length + sublength != input.length) {
      final adjustp = probabilityOfAll(reduced);

      BitSequence clearTest = null;
      // test any 'i's to remove.
      for (int i = 1 << (sublength - 1); i > 0; i >>= 1) {
        final test = BitSequence(~i, -1.0);
        final reducedAgain = passedTestComplex(reduced, test);
        final p = probabilityOfAll(reducedAgain) / adjustp;
        if (p < 0.5 && p != 0.0) {
          iErr += 1 - entropy(p) - entropy(1 -p);
          iRuns++;
          clearTest = BitSequence(test.data, p);
          //print('---');
          //print(provenState(reduced, sublength));
          //print(clearTest);
          //print('p=$p');
          //print("loss = ${1 - entropy(p) - entropy(1 -p)}");
          //print(1 - entropy(p) - entropy(1 -p));
          break;
        }
      }

      //print('down to p=$adjustp');
      final tests = <BitSequence>[];
      if (clearTest == null) {
        for (final test in allTests) {
          final reducedAgain = passedTestComplex(reduced, test);
          //print('---');
          //print(test);
          //print(reducedAgain);
          final p = probabilityOfAll(reducedAgain) / adjustp;
          tests.add(BitSequence(test.data, p));
        }
      }

      final bestTest = clearTest == null ? pickBestTest(tests) : clearTest;
      if (clearTest == null) uErr += 1 - entropy(bestTest.probability) - entropy(1 - bestTest.probability);
      final result = doTest(input, test, bestTest, sublength, prefix);
      runs++;
      int prevLength = reduced.length;
      if (result) {
        reduced = passedTestComplex(reduced, bestTest);
        //print('$prevLength --($bestTest = TRUE, p=${bestTest.probability})-> ${reduced.length}');
      } else {
        reduced = failedTestComplex(reduced, bestTest);
        //print('$prevLength --($bestTest = FALSE, p=${bestTest.probability})-> ${reduced.length}');
      }

      //print(reduced);
      final pstate = provenState(reduced, sublength);
      //print(pstate);
      final addPrefix = addToPrefix(pstate);
      //print(sublength);
      //print(addPrefix);
      final mask = addPrefix.list.length == sublength ? 0 : (2 << (sublength - addPrefix.list.length - 1)) - 1;

      if (addPrefix.list.isNotEmpty) {
        //print('discovered prefix $addPrefix (proven=$pstate)');
        prefix.list.addAll(addPrefix.list);
        state = prefix.list.isEmpty ? EventKind.unknown : prefix.list.last;

        reduced = reduced.map((s) => BitSequence(s.data & mask, s.probability)).toList();
        reduced.sort((a, b) => a.data.compareTo(b.data));
        final newReduced = <BitSequence>[reduced.first];
        for (int i = 1; i < reduced.length; ++i) {
          if (reduced[i].data != reduced[i - 1].data) {
            newReduced.add(reduced[i]);
          }
        }
        reduced = newReduced;
        //print('here $pstate ${BitSequence(mask, 0.0)} $addPrefix $reduced');

        pstate.list.removeRange(0, addPrefix.list.length);
        sublength -= addPrefix.list.length;
      }

      allTests = getTests(pstate);
      //print('waffle $pstate $allTests');

      while (sublength + prefix.list.length < input.length && reduced.length * allTests.length < 4096) {
        if (sublength == 63) {
          break;
        }

        sublength++;
        //print('increasing to sublength $sublength');

        if (sublength == 1) {
          reduced = [
            BitSequence(0, markov.probabilityOf(prefix.list.last, EventKind.unimportant)),
            BitSequence(1, markov.probabilityOf(prefix.list.last, EventKind.important)),
          ];
        } else {
          reduced = [
            for (final scenario in reduced) scenario.thenUnimportant(markov),
            for (final scenario in reduced) scenario.thenImportant(markov),
          ];
        }

        if (allTests.isEmpty) {
          allTests = [
            BitSequence(0, markov.pUnderlyingUnimportant),
            BitSequence(1, markov.pUnderlyingImportant),
          ];
        } else {
          allTests = [
            for (final scenario in allTests) scenario.thenUnimportant(markov),
            for (final scenario in allTests) scenario.thenImportant(markov),
          ];
        }

        //print("expand to $sublength (${reduced.length} / ${allTests.length})");
      }
    }

    //print('FINISHED: ${reduced.single}');
    //print('runs $runs iErr $iErr, iRuns $iRuns, uErr $uErr, entropy ${markov.entropyFor(input.length)} lb ${markov.lowerBound(input.length)}');
    return constructValue(input, reduced.single, sublength, prefix);
  }

  Sequence addToPrefix(Sequence provenState) {
    final result = Sequence([]);
    for (int i = 0; i < provenState.list.length; ++i) {
      if (provenState.list[i] != EventKind.unknown) {
        result.list.add(provenState.list[i]);
      } else {
        break;
      }
    }

    return result;
  }

  Sequence provenState(List<BitSequence> scenarios, int sublength) {
    //print(scenarios.join('\n'));
    final allImportant = scenarios.map((s) => s.data).reduce((a, b) => a & b);
    final allUnimportant = scenarios.map((s) => ~s.data).reduce((a, b) => a & b);
    //print(BitSequence(allImportant, 0.0));
    //print(BitSequence(allUnimportant, 0.0));

    final result = Sequence(List.generate(sublength, (i) {
      final mask = 1 << (sublength - i - 1);
      if (allImportant & mask != 0) {
        return EventKind.important;
      } else if (allUnimportant & mask != 0) {
        return EventKind.unimportant;
      } else {
        return EventKind.unknown;
      }
    }));
    //print(result);
    return result;
  }

  List<BitSequence> getTests(Sequence provenState) {
    var tests = <BitSequence>[];
    for (final event in provenState.list) {
      if (tests.isEmpty) {
        tests = [
          if (event != EventKind.important)
            BitSequence(0, markov.pUnderlyingUnimportant),
          if (event != EventKind.unimportant)
            BitSequence(1, markov.pUnderlyingImportant),
        ];
      } else {
        tests = [
          if (event != EventKind.important)
            for (final scenario in tests) scenario.thenUnimportant(markov),
          if (event != EventKind.unimportant)
            for (final scenario in tests) scenario.thenImportant(markov),
        ];
      }
    }

    return tests;
  }

  BitSequence pickBestTest(List<BitSequence> tests) {
    tests..sort((a, b) => a.probability.compareTo(b.probability));
    //print(tests.map((t) => t.probability).toList());

    var lastp = tests[0].probability;

    if (lastp.isNaN) throw 'balls';

    for(int i = 1; i < tests.length; ++i) {
      if (tests[i].probability < 0.5) {
        lastp = tests[i].probability;
      } else {
        final deltaCurrent = (tests[i].probability - 0.5).abs();
        final deltaPrev = (lastp - 0.5).abs();
        if (deltaPrev < deltaCurrent) {
          //print('err $deltaPrev, p=$lastp');
          return tests[i - 1];
        } else {
          //print('err $deltaCurrent, p=${tests[i].probability}');
          return tests[i];
        }
      }
    }

    //print('max testp=${tests.last.probability}');
    return tests.last;
  }

  double probabilityOfAll(List<BitSequence> scenarios) =>
    scenarios.fold(0.0, (p, sequence) => p + sequence.probability);

  List<BitSequence> passedTestComplex(
      List<BitSequence> scenarios, BitSequence test) =>
    scenarios.where((sequence) => sequence.data & test.data == sequence.data).toList();

  List<BitSequence> failedTestComplex(
      List<BitSequence> scenarios, BitSequence test) =>
    scenarios.where((sequence) => sequence.data & test.data != sequence.data).toList();

  List<T> constructValue(List<T> original, BitSequence sequence, int length, Sequence prefix) {
    final newList = <T>[];
    for (int i = 0; i < prefix.list.length; ++i) {
      if (prefix.list[i] == EventKind.important) {
        newList.add(original[i]);
      }
    }

    if (length > 0) {
    for (int i = prefix.list.length, j = 0, mask = 1 << (length - 1);
        j < length;
	    ++i, ++j, mask >>= 1) {
	  if (sequence.data & mask != 0) {
        newList.add(original[i]);
      }
    }
    }

    for (int i = prefix.list.length + length;
        i < original.length;
        ++i) {
      newList.add(original[i]);
    }

    //print('$sequence $length ${prefix.list.length} $prefix');
    //print('$original');
    //print('$newList');
    return newList;
  }

  bool doTest(List<T> original, bool Function(List<T>) test, BitSequence config, int length, Sequence prefix) {
    return test(constructValue(original, config, length, prefix));
  }

  List<BitSequence> allScenarios(int length) {
    if (length == 1) {
      return [
        BitSequence(0, markov.pUnderlyingUnimportant),
        BitSequence(1, markov.pUnderlyingImportant),
      ];
    }

    final sub = allScenarios(length - 1);
    return [
      for (final scenario in sub)
        scenario.thenUnimportant(markov),
      for (final scenario in sub)
        scenario.thenImportant(markov),
    ];
  }
}

class BitSequence {
  final int data;
  final double probability;

  BitSequence(this.data, this.probability);

  BitSequence thenUnimportant(MarkovModel markov) {
    final px = data & 1 == 1
        ? markov.pTransitionToUnimportant
        : markov.pRepeatUnimportant;

    return BitSequence(
        data * 2,
        probability * px);
  }

  BitSequence thenImportant(MarkovModel markov) {
    final px = data & 1 == 1
        ? markov.pRepeatImportant
        : markov.pTransitionToImportant;

    return BitSequence(
        data * 2 + 1,
        probability * px);
  }

  String toString() {
    String result = '';
    for(int i = 63; i >= 0; --i) {
      if (data & (1 << i) == 0) {
        result += '0';
      } else {
        result += '1';
      }
      if (i % 4 == 0) {
        result += '.';
      }
    }

    return result;
  }
}

