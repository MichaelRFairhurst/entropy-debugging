import 'package:entropy_debugging/src/model/markov.dart';

/// A lightweight class for sequences, currently used to make decision trees
/// prettier when printed.
class Sequence {
  /// The list of events in this sequence.
  final List<EventKind> list;

  Sequence(this.list);

  @override
  String toString() =>
      list.map((event) => event == EventKind.important ? '!' : '.').join('');
}
