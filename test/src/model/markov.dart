import 'package:entropy_debugging/src/model/markov.dart';
import 'package:test/test.dart';

void main() {
  group('markov model', () {
    final markov = MarkovModel(0.3, 0.6);

    test('probability of transitioning to important', () {
      expect(markov.pTransitionToImportant, 0.3);
    });
    test('probability of staying unimportant', () {
      expect(markov.pRepeatUnimportant, 0.7);
    });
    test('underlying probability of being important', () {
      expect(markov.pUnderlyingImportant, 0.6);
    });
    test('underlying probability of being unmportant', () {
      expect(markov.pUnderlyingUnimportant, 0.4);
    });
    group('probability of transitioning to important', () {
      test('50 50 50 50', () {
        final markov = MarkovModel(0.5, 0.5);
        expect(markov.pTransitionToUnimportant, 0.5);
        expect(markov.pRepeatImportant, 0.5);
      });
      test('0 0 50 50', () {
        final markov = MarkovModel(1, 0.5);
        expect(markov.pTransitionToUnimportant, 1);
        expect(markov.pRepeatImportant, 0);
      });
      test('25 50 25 75', () {
        final markov = MarkovModel(0.25, 0.5);
        expect(markov.pTransitionToUnimportant, 0.25);
        expect(markov.pRepeatImportant, 0.75);
      });
    });

    group('transition probability', () {
      test('unknown -> important', () {
        expect(
            markov.probabilityOf(EventKind.unknown, EventKind.important), 0.6);
      });
      test('unknown -> unimportant', () {
        expect(markov.probabilityOf(EventKind.unknown, EventKind.unimportant),
            0.4);
      });
      test('unimportant -> important', () {
        expect(markov.probabilityOf(EventKind.unimportant, EventKind.important),
            0.3);
      });
      test('unimportant -> unimportant', () {
        expect(
            markov.probabilityOf(EventKind.unimportant, EventKind.unimportant),
            0.7);
      });
    });

    group('series probability', () {
      test('[important] after unknown', () {
        expect(
            markov.probabilityOfAll([EventKind.important], EventKind.unknown),
            0.6);
      });
      test('[unimportant] after unknown', () {
        expect(
            markov.probabilityOfAll([EventKind.unimportant], EventKind.unknown),
            0.4);
      });
      test('[unimportant, important] after unknown', () {
        expect(
            markov.probabilityOfAll(
                [EventKind.unimportant, EventKind.important],
                EventKind.unknown),
            0.4 * 0.3);
      });
      test('[unimportant, unimportant] after unknown', () {
        expect(
            markov.probabilityOfAll(
                [EventKind.unimportant, EventKind.unimportant],
                EventKind.unknown),
            0.4 * 0.7);
      });
      test('[unimportant, unimportant, important] after unknown', () {
        expect(
            markov.probabilityOfAll([
              EventKind.unimportant,
              EventKind.unimportant,
              EventKind.important
            ], EventKind.unknown),
            0.4 * 0.7 * 0.3);
      });
      test('[important] after unimportant', () {
        expect(
            markov
                .probabilityOfAll([EventKind.important], EventKind.unimportant),
            0.3);
      });
      test('[unimportant] after unimportant', () {
        expect(
            markov.probabilityOfAll(
                [EventKind.unimportant], EventKind.unimportant),
            0.7);
      });
      test('[unimportant, important] after unimportant', () {
        expect(
            markov.probabilityOfAll(
                [EventKind.unimportant, EventKind.important],
                EventKind.unimportant),
            0.7 * 0.3);
      });
      test('[unimportant, unimportant] after unimportant', () {
        expect(
            markov.probabilityOfAll(
                [EventKind.unimportant, EventKind.unimportant],
                EventKind.unimportant),
            0.7 * 0.7);
      });
      test('[unimportant, unimportant, important] after unimportant', () {
        expect(
            markov.probabilityOfAll([
              EventKind.unimportant,
              EventKind.unimportant,
              EventKind.important
            ], EventKind.unimportant),
            0.7 * 0.7 * 0.3);
      });
    });
  });
}
