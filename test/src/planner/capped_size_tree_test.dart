import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/capped_size_tree.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Capped size tree', () {
    MockTreePlanner innerPlanner;
    CappedSizeTreePlanner planner;
    final tree = Branch<Sequence>(null, null);

    setUp(() {
      innerPlanner = MockTreePlanner();
      planner = CappedSizeTreePlanner(innerPlanner, maxTreeSize: 10);
    });

    test('below cap', () {
      when(innerPlanner.plan(5, EventKind.unimportant)).thenReturn(tree);
      expect(planner.plan(5, EventKind.unimportant), same(tree));
      verify(innerPlanner.plan(5, EventKind.unimportant));
    });

    test('at cap', () {
      when(innerPlanner.plan(10, EventKind.unimportant)).thenReturn(tree);
      expect(planner.plan(10, EventKind.unimportant), same(tree));
      verify(innerPlanner.plan(10, EventKind.unimportant));
    });

    test('above cap', () {
      when(innerPlanner.plan(10, EventKind.unimportant)).thenReturn(tree);
      expect(planner.plan(11, EventKind.unimportant), same(tree));
      verify(innerPlanner.plan(10, EventKind.unimportant));
    });

    test('far above cap', () {
      when(innerPlanner.plan(10, EventKind.unimportant)).thenReturn(tree);
      expect(planner.plan(15, EventKind.unimportant), same(tree));
      verify(innerPlanner.plan(10, EventKind.unimportant));
    });
  });
}

class MockTreePlanner extends Mock implements TreePlanner {}
