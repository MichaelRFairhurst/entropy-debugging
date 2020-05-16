import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/caching.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Caching tree planner', () {
    MockTreePlanner innerPlanner;
    CachingTreePlanner planner;

    group('caches for same length/previous', () {
      final tree = Branch<Sequence>(
          null,
          Decision<Sequence>(
              Sequence([EventKind.unimportant, EventKind.unimportant]), 0.5));

      setUp(() {
        innerPlanner = MockTreePlanner();
        planner = CachingTreePlanner(innerPlanner);
      });

      test('first time', () {
        when(innerPlanner.plan(2, EventKind.unknown)).thenReturn(tree);
        expect(planner.plan(2, EventKind.unknown), same(tree));
      });

      test('second time is cached', () {
        when(innerPlanner.plan(2, EventKind.unknown)).thenReturn(tree);
        expect(planner.plan(2, EventKind.unknown), same(tree));
        expect(planner.plan(2, EventKind.unknown), same(tree));
        verify(innerPlanner.plan(2, EventKind.unknown)).called(1);
      });
    });

    group('caches for shortened trees', () {
      final tree = Branch<Sequence>(
          null,
          Decision<Sequence>(
              Sequence([EventKind.unimportant, EventKind.unimportant]), 0.5));

      setUp(() {
        innerPlanner = MockTreePlanner();
        planner = CachingTreePlanner(innerPlanner);
      });

      test('first time', () {
        when(innerPlanner.plan(5, EventKind.unknown)).thenReturn(tree);
        expect(planner.plan(5, EventKind.unknown), same(tree));
      });

      test('twice for same length', () {
        when(innerPlanner.plan(5, EventKind.unknown)).thenReturn(tree);
        expect(planner.plan(5, EventKind.unknown), same(tree));
        expect(planner.plan(5, EventKind.unknown), same(tree));
        verify(innerPlanner.plan(5, EventKind.unknown)).called(1);
      });

      test('again with exact capped length', () {
        when(innerPlanner.plan(5, EventKind.unknown)).thenReturn(tree);
        expect(planner.plan(5, EventKind.unknown), same(tree));
        expect(planner.plan(2, EventKind.unknown), same(tree));
        verifyNever(innerPlanner.plan(2, EventKind.unknown));
      });

      test('again with shorter capped length', () {
        when(innerPlanner.plan(5, EventKind.unknown)).thenReturn(tree);
        expect(planner.plan(5, EventKind.unknown), same(tree));
        expect(planner.plan(4, EventKind.unknown), same(tree));
        verifyNever(innerPlanner.plan(4, EventKind.unknown));
      });

      test('again with longer capped length', () {
        when(innerPlanner.plan(5, EventKind.unknown)).thenReturn(tree);
        expect(planner.plan(5, EventKind.unknown), same(tree));
        expect(planner.plan(10, EventKind.unknown), same(tree));
        verifyNever(innerPlanner.plan(10, EventKind.unknown));
      });
    });

    group('does not cache for different length', () {
      final tree = Branch<Sequence>(
          null,
          Decision<Sequence>(
              Sequence([EventKind.unimportant, EventKind.unimportant]), 0.5));

      setUp(() {
        innerPlanner = MockTreePlanner();
        planner = CachingTreePlanner(innerPlanner);
      });

      test('after same length returned', () {
        when(innerPlanner.plan(2, EventKind.unknown)).thenReturn(tree);
        when(innerPlanner.plan(3, EventKind.unknown))
            .thenReturn(Branch<Sequence>(null, tree.right));
        expect(planner.plan(2, EventKind.unknown), same(tree));
        expect(planner.plan(3, EventKind.unknown), isNot(same(tree)));
      });

      test('below previous capped length', () {
        final smallerTree = Branch<Sequence>(
            null, Decision<Sequence>(Sequence([EventKind.important]), 0.5));
        when(innerPlanner.plan(5, EventKind.unknown)).thenReturn(tree);
        when(innerPlanner.plan(1, EventKind.unknown)).thenReturn(smallerTree);
        expect(planner.plan(5, EventKind.unknown), same(tree));
        expect(planner.plan(1, EventKind.unknown), same(smallerTree));
      });
    });

    test('does not cache for different previous', () {
      final tree = Branch<Sequence>(
          null,
          Decision<Sequence>(
              Sequence([EventKind.unimportant, EventKind.unimportant]), 0.5));

      innerPlanner = MockTreePlanner();
      planner = CachingTreePlanner(innerPlanner);

      when(innerPlanner.plan(2, EventKind.unknown)).thenReturn(tree);
      when(innerPlanner.plan(2, EventKind.important))
          .thenReturn(Branch<Sequence>(null, tree.right));
      expect(planner.plan(2, EventKind.unknown), same(tree));
      expect(planner.plan(2, EventKind.important), isNot(same(tree)));
    });
  });
}

class MockTreePlanner extends Mock implements TreePlanner {}
