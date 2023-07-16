import 'dart:collection';
import 'package:entropy_debugging/src/decision_tree/huffman_builder.dart';
import 'package:entropy_debugging/src/model/entropy.dart';
import 'package:entropy_debugging/src/decision_tree/decision_tree.dart';
import 'package:entropy_debugging/src/decision_tree/builder.dart';

/// A [DecisionTreeBuilder]s that uses the A* algorithm to search for the best
/// decision tree.
///
/// This is currently slower than the simpler [OptimalBuilder], even when given
/// a weight to produce approximate trees.
///
/// However, in theory this approach should be able to outperform that builder
/// if this can cache completed subproblems.
///
/// There are also a few different approaches coded up and commented out here.
/// Not all are necessarily currently working or compatible with each other.
/// Hopefully if this is further optimized to be more performant optimal
/// builder, some of these options can be ruled out and the best overall
/// approach can be kept.
class AStarDecisionTreeBuilder<T> implements DecisionTreeBuilder<T> {
  final double weight;

  // A* with configurable weight. A weight of 1.0 is standard A*, a weight
  // of 0.0 is Djikstra, and values between blend the two. Values above 1.0
  // will produce suboptimal trees but increase performance.
  //
  // Note that unfortunately, even suboptimal weighted A* approaches are
  // currently not faster than the optimal search, without generating extremely
  // poor results which other faster algorithms can beat in less time.
  AStarDecisionTreeBuilder([this.weight = 1.0]);

  @override
  DecisionTree<T> build(List<Decision<T>> decisions) {
    final open = HeapPriorityQueue<AStarNodeWithScore>(
        (a, b) => a.score.compareTo(b.score));

    final scoreMap = <AStarNode, AStarNodeWithScore>{};
    final cameFrom = <AStarNode, AStarNode>{};
    final edgeTo = <AStarNode, Edge>{};
    final estDist = <AStarNode, double>{};
    final scores = <AStarNode, double>{};
    final costs = <AStarNode, double>{};

    final root = AStarNode(1);
    final startingScore =
        decisions.fold(0.0, (h, d) => h + entropy(d.probability));
    final rootScore = AStarNodeWithScore(root, startingScore);
    open.add(rootScore);
    scoreMap[root] = rootScore;
    scores[root] = startingScore;
    costs[root] = 0.0;
    estDist[root] = startingScore;

    while (open.isNotEmpty) {
      final current = open.first;
      //print('current score ${current.score}, dist ${estDist[current.node]} id ${current.node.id}');

      open.removeFirst();
      scoreMap.remove(current.node);
      if (estDist[current.node] == 0) {
        return reconstruct(decisions, current.node, cameFrom, edgeTo);
      }

      final path = pathTo(current.node, cameFrom, edgeTo);
      //print('${path.length} / ${decisions.length} ... ${current.node.id}');

      // Option 1: calculate cost as depth. This is a good standard approach,
      // unless you're doing weighted A*, as the search is driven almost
      // entirely by variations in estimated distance. Requires
      // dist = distanceBasedOnEntropy or dist = distanceBasedOnHuffman below
      //for (final split in splits(path, decisions)) {

      // Option 2: calculate cost as loss of information gain. This is a bit
      // weirder of an approach but valid, and it works better with weighted A*,
      // I think? Requires nDist = distanceBasedOnGapsByLoss
      for (final split in splitsByLoss(path, decisions)) {
        final edge = split.edge;
        final newPath = [...path, edge];
        final pathSorted = newPath
          ..sort((a, b) => a.splitIndex.compareTo(b.splitIndex));
        final neighbor = nodeFromPath(pathSorted, decisions.length);

        final oldScore = scores[neighbor];
        // NOTE: This is just an extra optimization to avoid calculating costs
        // for this neighbor. We check this again with the new scores.
        if (oldScore != null && oldScore <= current.score) {
          continue;
        }

        final nCost = costs[current.node] + split.cost;

        // Option 1: calculate the distance by entropy of unsolved segments.
        // Requires calculating cost as depth above.
        //final nDist = distanceBasedOnEntropy(pathSorted, decisions);

        // Option 2: calculate the cost as the cost of the huffman codes of the
        // unsolved segments. This is a tigher estimate than entropy. Requires
        // calculating cost as depth above.
        //final nDist = distanceBasedOnHuffman(gaps(pathSorted, decisions));

        // Option 3: calculate the cost as the loss of information gain in the
        // huffman codes of unsolved segments. This is required when calculating
        // cost as loss of information gain above.
        final nDist = distanceBasedOnGapsByLoss(gaps(pathSorted, decisions, 2));
        final nScore = nCost + nDist * weight;

        if (oldScore != null && oldScore <= nScore) {
          continue;
        }

        edgeTo[neighbor] = edge;
        cameFrom[neighbor] = current.node;

        //print('adding $nCost $nDist via ${edge.splitIndex} id ${neighbor.id}');
        costs[neighbor] = nCost;
        estDist[neighbor] = nDist;
        scores[neighbor] = nScore;
        if (scoreMap.containsKey(neighbor)) {
          open.remove(scoreMap[neighbor]);
        }
        final neighborScore = AStarNodeWithScore(neighbor, nScore);
        open.add(neighborScore);
        scoreMap[neighbor] = neighborScore;
      }
    }

    throw 'Error, could not complete A* on $decisions';
  }

  List<Edge> edges(List<Edge> path, int size) {
    final sorted = path.toList()
      ..sort((a, b) => a.splitIndex.compareTo(b.splitIndex));
    final result = <Edge>[];
    for (int i = 0, j = 0; i < size - 1; ++i) {
      if (j >= sorted.length) {
        result.add(Edge(i));
        continue;
      }

      if (sorted[j].splitIndex > i) {
        result.add(Edge(i));
      } else {
        ++j;
      }
    }

    return result;
  }

  AStarNode nodeFromPath(List<Edge> path, int size) {
    // Theory: all splits, regardless of order, produce the same unexplored
    // subsections.

    int id = 1;
    if (path.isEmpty) {
      return AStarNode(id);
    }

    // Additional property. Splits of size 2 are effectively solved. Note that
    // this property plays poorly with weighted A*. Uncomment to use
    // alternatives such as distanceBasedOnEntropy and distanceBasedOnGaps
    // var lastidx = -1;
    for (final edge in path) {
      final index = edge.splitIndex;
      // Uncomment to leverage extra property
      //if (lastidx == index - 2) {
      //  // TODO: this can overflow
      //  id = id * size + index - 1;
      //}

      // TODO: this can overflow
      id = id * size + index;

      // Uncomment to leverage extra property
      //lastidx = index;

      // Uncomment to leverage extra property
      //if (index == size - 2) {
      //  // TODO: this can overflow
      //  id = id * size + index + 1;
      //  break;
      //}
    }

    return AStarNode(id);
  }

  List<Edge> pathTo(final AStarNode node, Map<AStarNode, AStarNode> cameFrom,
      Map<AStarNode, Edge> edgeTo) {
    var current = node;
    final edges = <Edge>[];

    while (edgeTo.containsKey(current)) {
      edges.add(edgeTo[current]);
      current = cameFrom[current];
    }

    return edges.reversed.toList();
  }

  List<EdgeInfo> splitsByLoss(
      List<Edge> edgesUnsorted, List<Decision<T>> decisions) {
    final edges = edgesUnsorted.toList()
      ..sort((a, b) => a.splitIndex.compareTo(b.splitIndex));

    List<EdgeInfo> infoFromGap(int start, int end) {
      if (start == end) {
        return const [];
      }
      final result = <EdgeInfo>[];
      var pLeft = decisions[start].probability;
      var pRight = decisions
          .skip(start + 1)
          .take(end - start - 1)
          .fold(0.0, (p, d) => p + d.probability);
      final pAll = pLeft + pRight;

      for (int i = start; i < end - 1; ++i) {
        final ig = entropy(pLeft / pAll) + entropy(pRight / pAll);
        var err = (1 - ig) * pAll;

        // Additional property. Splits of size 2 are effectively solved. Note
        // that this property plays poorly with weighted A*. Uncomment to use
        // alternatives such as distanceBasedOnEntropy and distanceBasedOnGaps

        //if (i == start + 1) {
        //  final pFirst = decisions[start].probability;
        //  final pSecond = decisions[start + 1].probability;
        //  final pBoth = pFirst + pSecond;
        //  final igBoth = entropy(pFirst / pBoth) + entropy(pSecond / pBoth);
        //  err += (1 - igBoth) * pBoth;
        //}

        //if (i == end - 3) {
        //  final pLast = decisions[end - 1].probability;
        //  final pBefore = decisions[end - 2].probability;
        //  final pBoth = pLast + pBefore;
        //  final igBoth = entropy(pLast / pBoth) + entropy(pBefore / pBoth);
        //  err += (1 - igBoth) * pBoth;
        //}

        pLeft += decisions[i + 1].probability;
        pRight -= decisions[i + 1].probability;
        result.add(EdgeInfo(Edge(i), err));
      }

      return result;
    }

    for (int ei = 0, di = 0; di < decisions.length; ++ei) {
      final distart = di;
      if (ei >= edges.length) {
        while (di < decisions.length) {
          ++di;
        }
        return infoFromGap(distart, di);
      }
      if (edges[ei].splitIndex >= di) {
        while (edges[ei].splitIndex >= di) {
          ++di;
        }

        if (di > distart + 1) {
          return infoFromGap(distart, di);
        }
      } else {
        ++di;
      }
    }

    return const [];
  }

  List<EdgeInfo> splits(List<Edge> edgesUnsorted, List<Decision<T>> decisions) {
    final result = <EdgeInfo>[];
    final edges = edgesUnsorted.toList()
      ..sort((a, b) => a.splitIndex.compareTo(b.splitIndex));

    List<EdgeInfo> infoFromGap(int start, int end) {
      if (start + 1 == end) {
        return const [];
      }
      final result = <EdgeInfo>[];
      final pAll = decisions
          .skip(start)
          .take(end - start)
          .fold(0.0, (p, d) => p + d.probability);

      for (int i = start; i < end - 1; ++i) {
        var cost = pAll;

        if (i == start + 1) {
          final pFirst = decisions[start].probability;
          final pSecond = decisions[start + 1].probability;
          final pBoth = pFirst + pSecond;
          cost += pBoth;
        }

        if (i == end - 3) {
          final pLast = decisions[end - 1].probability;
          final pBefore = decisions[end - 2].probability;
          final pBoth = pLast + pBefore;
          cost += pBoth;
        }

        result.add(EdgeInfo(Edge(i), cost));
      }

      return result;
    }

    for (int ei = 0, di = 0; di < decisions.length; ++ei) {
      final distart = di;
      if (ei >= edges.length) {
        while (di < decisions.length) {
          ++di;
        }
        result.addAll(infoFromGap(distart, di));
        break;
      }
      if (edges[ei].splitIndex >= di) {
        while (edges[ei].splitIndex >= di) {
          ++di;
        }
        result.addAll(infoFromGap(distart, di));
      } else {
        ++di;
      }
    }

    return result;
  }

  // The optimal tree preserving order can be no better than the optimal tree
  // order with any order. The latter, is easily found with huffman code. This
  // gives us a great estimate of distance to the end.
  double distanceBasedOnHuffman(List<List<Decision<T>>> gaps) {
    final huffman = HuffmanDecisionTreeBuilder<T>();
    double result = 0.0;
    for (final gap in gaps) {
      final unbeatable = huffman.build(gap);

      result += unbeatable.cost;
    }

    return result;
  }

  // For weighted A*, we use loss of information gain as our distance. However,
  // the remaining distance therefore needs to be an estimate of the remaining
  // loss. Luckily, huffman provides an estimate of exactly this.
  double distanceBasedOnGapsByLoss(List<List<Decision<T>>> gaps) {
    final huffman = HuffmanDecisionTreeBuilder<T>();
    double result = 0.0;
    for (final gap in gaps) {
      final unbeatable = huffman.build(gap);

      result += decisionTreeLoss(unbeatable);
    }

    return result;
  }

  double decisionTreeLoss(DecisionTree<T> tree) {
    if (tree is Decision<T>) {
      return 0;
    } else if (tree is Branch<T>) {
      final pLeft = tree.left.probability;
      final pRight = tree.right.probability;
      final pAll = pLeft + pRight;
      final h = entropy(pLeft / pAll) + entropy(pRight / pAll);
      final loss = 1 - h;
      return loss * pAll +
          decisionTreeLoss(tree.left) +
          decisionTreeLoss(tree.right);
    }

    throw 'unhandled type ${tree.runtimeType}';
  }

  // This calculates the distance based on the entropy, which doesn't requires
  // allocating lists which hold the gaps, it only requires having the edges.
  double distanceBasedOnEntropy(List<Edge> edges, List<Decision<T>> decisions) {
    var result = 0.0;
    for (int ei = 0, di = 0; di < decisions.length; ++ei) {
      if (ei >= edges.length) {
        final distart = di;
        while (di < decisions.length) {
          ++di;
        }
        if (di - distart > 2) {
          var pAll = 0.0;
          for (int i = distart; i < di; ++i) {
            pAll += decisions[i].probability;
          }
          for (int i = distart; i < di; ++i) {
            result += entropy(decisions[i].probability / pAll) * pAll;
          }
        }
        break;
      }
      if (edges[ei].splitIndex >= di) {
        final distart = di;
        while (edges[ei].splitIndex >= di) {
          ++di;
        }
        if (di - distart > 2) {
          var pAll = 0.0;
          for (int i = distart; i < di; ++i) {
            pAll += decisions[i].probability;
          }
          for (int i = distart; i < di; ++i) {
            result += entropy(decisions[i].probability / pAll) * pAll;
          }
        }
      } else {
        ++di;
      }
    }

    return result;
  }

  // Get the gaps based on the edges. Note that for using loss as the cost
  // function, we do not want to exploit the property of gaps being sized 2
  // being effectively solved, as it messes with the weights. However,
  // for standard A*, when using depth as cost and entropy or huffman cost as
  // distance, this property can be exploited, by using a minsize of 3.
  List<List<Decision<T>>> gaps(List<Edge> edges, List<Decision<T>> decisions,
      [int minsize = 3]) {
    if (edges.isEmpty) {
      return [decisions];
    }

    final result = <List<Decision<T>>>[];

    for (int ei = 0, di = 0; di < decisions.length; ++ei) {
      if (ei >= edges.length) {
        final newset = <Decision<T>>[];
        while (di < decisions.length) {
          newset.add(decisions[di]);
          ++di;
        }
        if (newset.length >= minsize) {
          result.add(newset);
        }
        break;
      }
      if (edges[ei].splitIndex >= di) {
        final newset = <Decision<T>>[];
        while (edges[ei].splitIndex >= di) {
          newset.add(decisions[di]);
          ++di;
        }
        if (newset.length >= minsize) {
          result.add(newset);
        }
      } else {
        ++di;
      }
    }

    return result;
  }

  DecisionTree<T> reconstruct(List<Decision<T>> decisions, final AStarNode node,
      Map<AStarNode, AStarNode> cameFrom, Map<AStarNode, Edge> edgeTo) {
    return reconstructFromPath(
        decisions, pathTo(node, cameFrom, edgeTo), 0, decisions.length, 0);
  }

  DecisionTree<T> reconstructFromPath(List<Decision<T>> decisions,
      List<Edge> path, int start, int end, int pathi) {
    if (start == end - 1) {
      return decisions[start];
    } else if (start == end - 2) {
      return Branch<T>(decisions[start], decisions[start + 1]);
    }

    while (pathi < path.length &&
        (path[pathi].splitIndex < start || path[pathi].splitIndex >= end)) {
      pathi++;
    }

    return Branch<T>(
      reconstructFromPath(
          decisions, path, start, path[pathi].splitIndex + 1, pathi + 1),
      reconstructFromPath(
          decisions, path, path[pathi].splitIndex + 1, end, pathi + 1),
    );
  }
}

class AStarNodeWithScore {
  final AStarNode node;
  final double score;

  AStarNodeWithScore(this.node, this.score);
}

class AStarNode {
  final int id;

  AStarNode(this.id);

  bool operator ==(Object other) => other is AStarNode && other.id == id;
  int get hashCode => id;
}

class Edge {
  final int splitIndex;
  Edge(this.splitIndex);
}

class EdgeInfo {
  final Edge edge;
  final double cost;

  EdgeInfo(this.edge, this.cost);
}

// Fork of priority queue with O(log n) deletion.
class HeapPriorityQueue<E> {
  /// Initial capacity of a queue when created, or when added to after a
  /// [clear].
  ///
  /// Number can be any positive value. Picking a size that gives a whole
  /// number of "tree levels" in the heap is only done for aesthetic reasons.
  static const int _initialCapacity = 7;

  /// The comparison being used to compare the priority of elements.
  final Comparator<E> comparison;

  /// List implementation of a heap.
  List<E> _queue = List<E>.filled(_initialCapacity, null);

  final _locations = <E, int>{};

  /// Number of elements in queue.
  ///
  /// The heap is implemented in the first [_length] entries of [_queue].
  int _length = 0;

  /// Modification count.
  ///
  /// Used to detect concurrent modifications during iteration.
  int _modificationCount = 0;

  /// Create a new priority queue.
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  ///
  /// If [comparison] is omitted, it defaults to [Comparable.compare]. If this
  /// is the case, `E` must implement [Comparable], and this is checked at
  /// runtime for every comparison.
  HeapPriorityQueue(this.comparison);

  E _elementAt(int index) => _queue[index] ?? (null as E);

  @override
  void add(E element) {
    _modificationCount++;
    _add(element);
  }

  @override
  void addAll(Iterable<E> elements) {
    var modified = 0;
    for (var element in elements) {
      modified = 1;
      _add(element);
    }
    _modificationCount += modified;
  }

  @override
  void clear() {
    _modificationCount++;
    _queue = const [];
    _length = 0;
  }

  @override
  bool contains(E object) => _locate(object) >= 0;

  /// Provides efficient access to all the elements currently in the queue.
  ///
  /// The operation is performed in the order they occur
  /// in the underlying heap structure.
  ///
  /// The order is stable as long as the queue is not modified.
  /// The queue must not be modified during an iteration.
  //@override
  //Iterable<E> get unorderedElements => _UnorderedElementsIterable<E>(this);

  @override
  E get first {
    if (_length == 0) throw StateError('No element');
    return _elementAt(0);
  }

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length != 0;

  @override
  int get length => _length;

  @override
  bool remove(E element) {
    //var index = _locate(element);
    var index = _locations[element];
    if (index == null) return false;
    _modificationCount++;
    var last = _removeLast();
    if (index < _length) {
      var comp = comparison(last, element);
      if (comp <= 0) {
        _bubbleUp(last, index);
      } else {
        _bubbleDown(last, index);
      }
    }
    _locations.remove(element);
    return true;
  }

  /// Removes all the elements from this queue and returns them.
  ///
  /// The returned iterable has no specified order.
  /// The operation does not copy the elements,
  /// but instead keeps them in the existing heap structure,
  /// and iterates over that directly.
  @override
  Iterable<E> removeAll() {
    _modificationCount++;
    var result = _queue;
    var length = _length;
    _queue = const [];
    _length = 0;
    return result.take(length).cast();
  }

  @override
  E removeFirst() {
    if (_length == 0) throw StateError('No element');
    _modificationCount++;
    var result = _elementAt(0);
    var last = _removeLast();
    if (_length > 0) {
      _bubbleDown(last, 0);
    }
    return result;
  }

  @override
  List<E> toList() => _toUnorderedList()..sort(comparison);

  @override
  Set<E> toSet() {
    var set = SplayTreeSet<E>(comparison);
    for (var i = 0; i < _length; i++) {
      set.add(_elementAt(i));
    }
    return set;
  }

  @override
  List<E> toUnorderedList() => _toUnorderedList();

  List<E> _toUnorderedList() =>
      [for (var i = 0; i < _length; i++) _elementAt(i)];

  /// Returns some representation of the queue.
  ///
  /// The format isn't significant, and may change in the future.
  @override
  String toString() {
    return _queue.take(_length).toString();
  }

  /// Add element to the queue.
  ///
  /// Grows the capacity if the backing list is full.
  void _add(E element) {
    if (_length == _queue.length) _grow();
    _bubbleUp(element, _length++);
  }

  /// Find the index of an object in the heap.
  ///
  /// Returns -1 if the object is not found.
  ///
  /// A matching object, `o`, must satisfy that
  /// `comparison(o, object) == 0 && o == object`.
  int _locate(E object) {
    if (_length == 0) return -1;
    // Count positions from one instead of zero. This gives the numbers
    // some nice properties. For example, all right children are odd,
    // their left sibling is even, and the parent is found by shifting
    // right by one.
    // Valid range for position is [1.._length], inclusive.
    var position = 1;
    // Pre-order depth first search, omit child nodes if the current
    // node has lower priority than [object], because all nodes lower
    // in the heap will also have lower priority.
    do {
      var index = position - 1;
      var element = _elementAt(index);
      var comp = comparison(element, object);
      if (comp <= 0) {
        if (comp == 0 && element == object) return index;
        // Element may be in subtree.
        // Continue with the left child, if it is there.
        var leftChildPosition = position * 2;
        if (leftChildPosition <= _length) {
          position = leftChildPosition;
          continue;
        }
      }
      // Find the next right sibling or right ancestor sibling.
      do {
        while (position.isOdd) {
          // While position is a right child, go to the parent.
          position >>= 1;
        }
        // Then go to the right sibling of the left-child.
        position += 1;
      } while (position > _length); // Happens if last element is a left child.
    } while (position != 1); // At root again. Happens for right-most element.
    return -1;
  }

  E _removeLast() {
    var newLength = _length - 1;
    var last = _elementAt(newLength);
    _locations.remove(last);
    _queue[newLength] = null;
    _length = newLength;
    return last;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has higher priority than the
  /// parent, swap it with the parent.
  void _bubbleUp(E element, int index) {
    while (index > 0) {
      var parentIndex = (index - 1) ~/ 2;
      var parent = _elementAt(parentIndex);
      if (comparison(element, parent) > 0) break;
      _queue[index] = parent;
      _locations[parent] = index;
      index = parentIndex;
    }
    _locations[element] = index;
    _queue[index] = element;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has lower priority than either child,
  /// swap it with the highest priority child.
  void _bubbleDown(E element, int index) {
    var rightChildIndex = index * 2 + 2;
    while (rightChildIndex < _length) {
      var leftChildIndex = rightChildIndex - 1;
      var leftChild = _elementAt(leftChildIndex);
      var rightChild = _elementAt(rightChildIndex);
      var comp = comparison(leftChild, rightChild);
      int minChildIndex;
      E minChild;
      if (comp < 0) {
        minChild = leftChild;
        minChildIndex = leftChildIndex;
      } else {
        minChild = rightChild;
        minChildIndex = rightChildIndex;
      }
      comp = comparison(element, minChild);
      if (comp <= 0) {
        _queue[index] = element;
        _locations[element] = index;
        return;
      }
      _queue[index] = minChild;
      _locations[minChild] = index;
      index = minChildIndex;
      rightChildIndex = index * 2 + 2;
    }
    var leftChildIndex = rightChildIndex - 1;
    if (leftChildIndex < _length) {
      var child = _elementAt(leftChildIndex);
      var comp = comparison(element, child);
      if (comp > 0) {
        _queue[index] = child;
        _locations[child] = index;
        index = leftChildIndex;
      }
    }
    _queue[index] = element;
    _locations[element] = index;
  }

  /// Grows the capacity of the list holding the heap.
  ///
  /// Called when the list is full.
  void _grow() {
    var newCapacity = _queue.length * 2 + 1;
    if (newCapacity < _initialCapacity) newCapacity = _initialCapacity;
    var newQueue = List<E>.filled(newCapacity, null);
    newQueue.setRange(0, _length, _queue);
    _queue = newQueue;
  }
}
