import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/planner/basic.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('basic tree planner', () {
    DecisionTreeBuilderMock mockTreeBuilder;

    setUp(() {
      mockTreeBuilder = DecisionTreeBuilderMock();
    });

    group('single length', () {
      test('after unknown', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.5, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(2));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pUnderlyingImportant);
          expect(items[1].outcome.toString(), '.');
          expect(items[1].probability, planner.markov.pUnderlyingUnimportant);
          return tree = Branch<Sequence>(items[0], items[1]);
        });
        final result = planner.plan(1, EventKind.unknown);
        expect(result, same(tree));
      });

      test('after important', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.3, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(2));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pRepeatImportant);
          expect(items[1].outcome.toString(), '.');
          expect(items[1].probability, planner.markov.pTransitionToUnimportant);
          return tree = Branch<Sequence>(items[0], items[1]);
        });
        final result = planner.plan(1, EventKind.important);
        expect(result, same(tree));
      });

      test('after unimportant', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.3, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(2));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pTransitionToImportant);
          expect(items[1].outcome.toString(), '.');
          expect(items[1].probability, planner.markov.pRepeatUnimportant);
          return tree = Branch<Sequence>(items[0], items[1]);
        });
        final result = planner.plan(1, EventKind.unimportant);
        expect(result, same(tree));
      });
    });

    group('double length', () {
      test('after unknown', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.3, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(3));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pUnderlyingImportant);
          expect(items[1].outcome.toString(), '.!');
          expect(
              items[1].probability,
              planner.markov.pUnderlyingUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[2].outcome.toString(), '..');
          expect(
              items[2].probability,
              planner.markov.pUnderlyingUnimportant *
                  planner.markov.pRepeatUnimportant);
          return tree =
              Branch<Sequence>(items[0], Branch<Sequence>(items[1], items[2]));
        });
        final result = planner.plan(2, EventKind.unknown);
        expect(result, same(tree));
      });

      test('after important', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.3, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(3));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pRepeatImportant);
          expect(items[1].outcome.toString(), '.!');
          expect(
              items[1].probability,
              planner.markov.pTransitionToUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[2].outcome.toString(), '..');
          expect(
              items[2].probability,
              planner.markov.pTransitionToUnimportant *
                  planner.markov.pRepeatUnimportant);
          return tree =
              Branch<Sequence>(items[0], Branch<Sequence>(items[1], items[2]));
        });
        final result = planner.plan(2, EventKind.important);
        expect(result, same(tree));
      });

      test('after unimportant', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.3, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(3));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pTransitionToImportant);
          expect(items[1].outcome.toString(), '.!');
          expect(
              items[1].probability,
              planner.markov.pRepeatUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[2].outcome.toString(), '..');
          expect(
              items[2].probability,
              planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant);
          return tree =
              Branch<Sequence>(items[0], Branch<Sequence>(items[1], items[2]));
        });
        final result = planner.plan(2, EventKind.unimportant);
        expect(result, same(tree));
      });
    });

    group('length of four', () {
      test('after important', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.3, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(5));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pRepeatImportant);
          expect(items[1].outcome.toString(), '.!');
          expect(
              items[1].probability,
              planner.markov.pTransitionToUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[2].outcome.toString(), '..!');
          expect(
              items[2].probability,
              planner.markov.pTransitionToUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[3].outcome.toString(), '...!');
          expect(
              items[3].probability,
              planner.markov.pTransitionToUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[4].outcome.toString(), '....');
          expect(
              items[4].probability,
              planner.markov.pTransitionToUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant);
          return tree = Branch<Sequence>(Branch(items[0], items[1]),
              Branch<Sequence>(items[2], Branch<Sequence>(items[3], items[4])));
        });
        final result = planner.plan(4, EventKind.important);
        expect(result, same(tree));
      });

      test('after unimportant', () {
        final planner =
            BasicTreePlanner(MarkovModel(0.3, 0.6), mockTreeBuilder);
        var tree;
        when(mockTreeBuilder.build(argThat(anything))).thenAnswer((invocation) {
          final items =
              invocation.positionalArguments[0] as List<Decision<Sequence>>;
          expect(items, hasLength(5));
          expect(items[0].outcome.toString(), '!');
          expect(items[0].probability, planner.markov.pTransitionToImportant);
          expect(items[1].outcome.toString(), '.!');
          expect(
              items[1].probability,
              planner.markov.pRepeatUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[2].outcome.toString(), '..!');
          expect(
              items[2].probability,
              planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[3].outcome.toString(), '...!');
          expect(
              items[3].probability,
              planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pTransitionToImportant);
          expect(items[4].outcome.toString(), '....');
          expect(
              items[4].probability,
              planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant *
                  planner.markov.pRepeatUnimportant);
          return tree = Branch<Sequence>(Branch(items[0], items[1]),
              Branch<Sequence>(items[2], Branch<Sequence>(items[3], items[4])));
        });
        final result = planner.plan(4, EventKind.unimportant);
        expect(result, same(tree));
      });
    });
  });
}

class DecisionTreeBuilderMock extends Mock
    implements DecisionTreeBuilder<Sequence> {}
