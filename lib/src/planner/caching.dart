import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/rightmost.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/model/sequence.dart';
import 'package:entropy_debugging/src/planner/planner.dart';

/// A tree planner to cache sequence trees based on previous builds.
///
/// In addition to caching simply based on the [length] and [previous]
/// parameters, this watches for when a tree is built that is smaller than the
/// given [length], and assumes that the extra length is ignored. It therefore
/// later on will cap the input length for the sake of better cache hits.
class CachingTreePlanner implements TreePlanner {
  final TreePlanner _innerPlanner;

  final _cache = <EventKind, Map<int, DecisionTree<Sequence>>>{
    EventKind.important: {},
    EventKind.unimportant: {},
    EventKind.unknown: {},
  };

  final _longest = <EventKind, int>{};

  CachingTreePlanner(this._innerPlanner);

  @override
  DecisionTree<Sequence> plan(int length, EventKind previous) {
    final cap = _longest[previous];
    if (cap != null && length > cap) {
      length = cap;
    }
    final lookup = _cache[previous][length];
    if (lookup != null) {
      return lookup;
    }
    final fresh = _innerPlanner.plan(length, previous);
    final longest =
        DecisionTreeRightMost<Sequence>().walk(fresh, null).outcome.list.length;
    if (longest < length) {
      _longest[previous] = longest;
      length = longest;
    }
    _cache[previous][length] = fresh;
    return fresh;
  }
}
