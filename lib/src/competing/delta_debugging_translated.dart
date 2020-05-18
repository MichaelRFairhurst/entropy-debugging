/// $Id: DD.py,v 1.2 2001/11/05 19:53:33 zeller Exp $
/// Enhanced Delta Debugging class
/// Copyright (c) 1999, 2000, 2001 Andreas Zeller.
///
/// This module (written in Python) implements the base delta debugging
/// algorithms and is at the core of all our experiments.  This should
/// easily run on any platform and any Python version since 1.6.
///
/// To plug this into your system, all you have to do is to create a
/// subclass with a dedicated `test()' method.  Basically, you would
/// invoke the DD test case minimization algorithm (= the `ddmin()'
/// method) with a list of characters; the `test()' method would combine
/// them to a document and run the test.  This should be easy to realize
/// and give you some good starting results; the file includes a simple
/// sample application.
///
/// This file is in the public domain; feel free to copy, modify, use
/// and distribute this software as you wish - with one exception.
/// Passau University has filed a patent for the use of delta debugging
/// on program states (A. Zeller: `Isolating cause-effect chains',
/// Saarland University, 2001).  The fact that this file is publicly
/// available does not imply that I or anyone else grants you any rights
/// related to this patent.
///
/// The use of Delta Debugging to isolate failure-inducing code changes
/// (A. Zeller: `Yesterday, my program worked', ESEC/FSE 1999) or to
/// simplify failure-inducing input (R. Hildebrandt, A. Zeller:
/// `Simplifying failure-inducing input', ISSTA 2000) is, as far as I
/// know, not covered by any patent, nor will it ever be.  If you use
/// this software in any way, I'd appreciate if you include a citation
/// such as `This software uses the delta debugging algorithm as
/// described in (insert one of the papers above)'.
///
/// All about Delta Debugging is found at the delta debugging web site,
///
///               http://www.st.cs.uni-sb.de/dd/
///
/// Happy debugging,
///
/// Andreas Zeller

/// Translated to Dart by Mike Fairhurst.
import 'dart:math';

enum Result { pass, fail, unresolved }

// Start with some helpers.

/// This class holds test outcomes for configurations.  This avoids
/// running the same test twice.
///
/// The outcome cache is implemented as a tree.  Each node points
/// to the outcome of the remaining list.
///
/// Example: ([1, 2, 3], PASS), ([1, 2], FAIL), ([1, 4, 5], FAIL):
///
///      (2, FAIL)--(3, PASS)
///     /
/// (1, None)
///     \
///      (4, None)--(5, FAIL)
class OutcomeCache<T extends Comparable<T>> {
  // Points to outcome of tail
  final tail = <T, OutcomeCache<T>>{};
  // Result so far
  var result = null;

  /// Add (C, RESULT) to the cache.  C must be a list of scalars.
  void add(List<T> c, result) {
    var cs = List<T>.from(c)..sort();

    var p = this;
    for (var start = 0; start < c.length; ++start) {
      if (!p.tail.containsKey(c[start])) {
        p.tail[c[start]] = OutcomeCache<T>();
      }
      p = p.tail[c[start]];
    }
    p.result = result;
  }

  /// Return RESULT if (C, RESULT) is in the cache; null, otherwise.
  Result lookup(List<T> c) {
    var p = this;
    for (var start = 0; start < c.length; start++) {
      if (!p.tail.containsKey(c[start])) {
        return null;
      }
      p = p.tail[c[start]];
    }

    return p.result;
  }

  /// Return RESULT if there is some (C', RESULT) in the cache with C' being a
  /// superset of C or equal to C.  Otherwise, return null
  Result lookup_superset(List<T> c, [start = 0]) {
    // (from original source) FIXME: Make this non-recursive!
    if (start >= c.length) {
      if (result != null) {
        return result;
      } else if (tail.isNotEmpty) {
        // Select some superset
        final superset = tail[tail.keys.first];
        return superset.lookup_superset(c, start + 1);
      } else {
        return null;
      }
    }

    if (tail.containsKey(c[start])) {
      return tail[c[start]].lookup_superset(c, start + 1);
    }

    // Let K0 be the largest element in TAIL such that K0 <= C[START]
    T k0 = null;
    for (var k in tail.keys) {
      if ((k0 == null || k.compareTo(k0) > 0) && k.compareTo(c[start]) < 0) {
        k0 = k;
      }
    }

    if (k0 != null) {
      return tail[k0].lookup_superset(c, start);
    }

    return null;
  }

  /// Return RESULT if there is some (C', RESULT) in the cache with C' being a
  /// subset of C or equal to C.  Otherwise, return null.
  Result lookup_subset(List<T> c) {
    var p = this;
    for (var start = 0; start < c.length; start++) {
      if (p.tail.containsKey(c[start])) {
        p = p.tail[c[start]];
      }
    }

    return p.result;
  }
}

//// Test the outcome cache
//void oc_test() {
//  var oc = OutcomeCache();
//
//  assert(oc.lookup([1, 2, 3]) == null);
//  oc.add([1, 2, 3], 4);
//  assert(oc.lookup([1, 2, 3]) == 4);
//  assert(oc.lookup([1, 2, 3, 4]) == null);
//
//  assert(oc.lookup([5, 6, 7]) == null);
//  oc.add([5, 6, 7], 8);
//  assert(oc.lookup([5, 6, 7]) == 8);
//
//  assert(oc.lookup([]) == null);
//  oc.add([], 0);
//  assert(oc.lookup([]) == 0);
//
//  assert(oc.lookup([1, 2]) == null);
//  oc.add([1, 2], 3);
//  assert(oc.lookup([1, 2]) == 3);
//  assert(oc.lookup([1, 2, 3]) == 4);
//
//  assert(oc.lookup_superset([1]) == 3 || oc.lookup_superset([1]) == 4);
//  assert(oc.lookup_superset([1, 2]) == 3 || oc.lookup_superset([1, 2]) == 4);
//  assert(oc.lookup_superset([5]) == 8);
//  assert(oc.lookup_superset([5, 6]) == 8);
//  assert(oc.lookup_superset([6, 7]) == 8);
//  assert(oc.lookup_superset([7]) == 8);
//  assert(oc.lookup_superset([]) != null);
//
//  assert(oc.lookup_superset([9]) == null);
//  assert(oc.lookup_superset([7, 9]) == null);
//  assert(oc.lookup_superset([-5, 1]) == null);
//  assert(oc.lookup_superset([1, 2, 3, 9]) == null);
//  assert(oc.lookup_superset([4, 5, 6, 7]) == null);
//
//  assert(oc.lookup_subset([]) == 0);
//  assert(oc.lookup_subset([1, 2, 3]) == 4);
//  assert(oc.lookup_subset([1, 2, 3, 4]) == 4);
//  assert(oc.lookup_subset([1, 3]) == null);
//  assert(oc.lookup_subset([1, 2]) == 3);
//
//  assert(oc.lookup_subset([-5, 1]) == null);
//  assert(oc.lookup_subset([-5, 1, 2]) == 3);
//  assert(oc.lookup_subset([-5]) == 0);
//}

enum Direction { add, remove }

/// Main Delta Debugging algorithm.
/// Delta debugging base class.  To use this class for a particular
/// setting, create a subclass with an overloaded `test()' method.
///
/// Main entry points are:
/// - `ddmin()' which computes a minimal failure-inducing configuration, and
/// - `dd()' which computes a minimal failure-inducing difference.
///
/// See also the usage sample at the end of this file.
///
/// For further fine-tuning, you can implement an own `resolve()'
/// method (tries to add or remove configuration elements in case of
/// inconsistencies), or implement an own `split()' method, which
/// allows you to split configurations according to your own
/// criteria.
///
/// The class includes other previous delta debugging alorithms,
/// which are obsolete now; they are only included for comparison
/// purposes.
abstract class DD {
  //# Debugging output (set to 1 to enable)
  //debug_test      = 0
  //debug_dd        = 0
  //debug_split     = 0
  //debug_resolve   = 0

  var __resolving = false;
  var __last_reported_length = 0;
  var monotony = false;
  var outcome_cache = OutcomeCache<Delta>();
  var cache_outcomes = true;
  var minimize = true;
  var maximize = true;
  var assume_axioms_hold = true;
  List<Delta> CC;

  // Helpers

  /// Return a list of all elements of C1 that are not in C2.
  List<T> __listminus<T>(List<T> c1, List<T> c2) {
    final s2 = <T, bool>{};
    for (var delta in c2) {
      s2[delta] = true;
    }

    final c = <T>[];
    for (var delta in c1) {
      if (!s2.containsKey(delta)) {
        c.add(delta);
      }
    }

    return c;
  }

  /// Return the common elements of C1 and C2.
  List<T> __listintersect<T>(List<T> c1, List<T> c2) {
    final s2 = <T, bool>{};
    for (var delta in c2) {
      s2[delta] = true;
    }

    final c = <T>[];
    for (var delta in c1) {
      if (s2.containsKey(delta)) {
        c.add(delta);
      }
    }

    return c;
  }

  /// Return the union of C1 and C2.
  List<T> __listunion<T>(List<T> c1, List<T> c2) {
    final s1 = <T, bool>{};
    for (final delta in c1) {
      s1[delta] = true;
    }

    final c = List<T>.from(c1);
    for (final delta in c2) {
      if (!s1.containsKey(delta)) {
        c.add(delta);
      }
    }

    return c;
  }

  /// Return 1 if C1 is a subset or equal to C2.
  bool __listsubseteq<T>(List<T> c1, List<T> c2) {
    final s2 = <T, bool>{};
    for (final delta in c2) {
      s2[delta] = true;
    }

    for (final delta in c1) {
      if (!s2.containsKey(delta)) {
        return false;
      }
    }

    return true;
  }

//    # Output
//    def coerce(self, c):
//	"""Return the configuration C as a compact string"""
//	# Default: use printable representation
//	return `c`
//
//    def pretty(self, c):
//        """Like coerce(), but sort beforehand"""
//        sorted_c = c[:]
//        sorted_c.sort()
//        return self.coerce(sorted_c)

  // Testing

  /// Test the configuration C.  Return PASS, FAIL, or UNRESOLVED
  Result test(List<Delta> c) {
    c.sort((a, b) => a.offset.compareTo(b.offset));

    // If we had this test before, return its result
    if (cache_outcomes != null) {
      final cached_result = outcome_cache.lookup(c);
      if (cached_result != null) {
        return cached_result;
      }
    }

    if (monotony) {
      // Check whether we had a passing superset of this test before
      var cached_result = outcome_cache.lookup_superset(c);
      if (cached_result == Result.pass) {
        return Result.pass;
      }

      cached_result = outcome_cache.lookup_subset(c);
      if (cached_result == Result.fail) {
        return Result.fail;
      }
    }

// if self.debug_test:
//          print
//    print "test(" + self.coerce(c) + ")..."

    final outcome = doTest(c);

    // if self.debug_test:
    //     print "test(" + self.coerce(c) + ") = " + `outcome`

    if (cache_outcomes) {
      outcome_cache.add(c, outcome);
    }

    return outcome;
  }

  /// Stub to overload in subclasses
  Result doTest(List<Delta> c);

  // Splitting

  /// Split C into [C_1, C_2, ..., C_n].
  List<List<Delta>> split(List<Delta> c, int n) {
    // if self.debug_split:
    //     print "split(" + self.coerce(c) + ", " + `n` + ")..."

    final outcome = _split(c, n);

    // if self.debug_split:
    //     print "split(" + self.coerce(c) + ", " + `n` + ") = " + `outcome`

    return outcome;
  }

  /// Stub to overload in subclasses
  List<List<Delta>> _split(List<Delta> c, int n) {
    final subsets = <List<Delta>>[];
    var start = 0;
    for (var i = 0; i < n; ++i) {
      final subset =
          c.sublist(start, (start + (c.length - start) / (n - i)).ceil());
      subsets.add(subset);
      start = start + subset.length;
    }
    return subsets;
  }

  // Resolving

  /// If direction == ADD, resolve inconsistency by adding deltas to CSUB.
  /// Otherwise, resolve by removing deltas from CSUB.
  resolve(csub, c, direction) {
//	if self.debug_resolve:
//	    print "resolve(" + `csub` + ", " + self.coerce(c) + ", " + \
//		  `direction` + ")..."

    final outcome = _resolve(csub, c, direction);

//	if self.debug_resolve:
//	    print "resolve(" + `csub` + ", " + self.coerce(c) + ", " + \
//		  `direction` + ") = " + `outcome`

    return outcome;
  }

  /// Stub to overload in subclasses.
  Result _resolve(csub, c, Direction direction) {
    // By default, no way to resolve
    return null;
  }

  // Test with fixes
  /// Repeat testing CSUB + R while unresolved.
  Pair<Result, List<Delta>> test_and_resolve(
      List<Delta> csub, List<Delta> r, List<Delta> c, Direction direction) {
    final initial_csub = List<Delta>.from(csub);
    final c2 = __listunion(r, c);

    var csubr = __listunion(csub, r);
    var t = test(csubr);

    // necessary to use more resolving mechanisms which can reverse each
    // other, can (but needn't) be used in subclasses
    var _resolve_type = 0;

    while (t == Result.unresolved) {
      __resolving = true;
      csubr = resolve(csubr, c, direction);

      if (csubr == null) {
        // Nothing left to resolve
        break;
      }

      if (csubr.length >= c2.length) {
        // Added everything: csub == c2. ("Upper" Baseline)
        // This has already been tested.
        csubr = null;
        break;
      }
      if (csubr.length <= r.length) {
        // Removed everything: csub == r. (Baseline)
        // This has already been tested.
        csubr = null;
        break;
      }
    }

    t = test(csubr);

    __resolving = false;
    if (csubr == null) {
      return Pair<Result, List<Delta>>(Result.unresolved, initial_csub);
    }

    //# assert t == self.PASS or t == self.FAIL
    csub = __listminus(csubr, r);
    return Pair<Result, List<Delta>>(t, csub);
  }

  // Inquiries
  /// Return true while resolving."""
  bool resolving() {
    return __resolving;
  }

//    # Logging
//    def report_progress(self, c, title):
//	if len(c) != self.__last_reported_length:
//	    print
//	    print title + ": " + `len(c)` + " deltas left:", self.coerce(c)
//	    self.__last_reported_length = len(c)

//    # Delta Debugging (old ESEC/FSE version)
//    def old_dd(self, c, r = [], n = 2):
//	"""Return the failure-inducing subset of C"""
//
//        assert self.test([]) == dd.PASS
//        assert self.test(c)  == dd.FAIL
//
//	if self.debug_dd:
//	    print ("dd(" + self.pretty(c) + ", " + `r` + ", " + `n` + ")...")
//
//	outcome = self._old_dd(c, r, n)
//
//	if self.debug_dd:
//	    print ("dd(" + self.pretty(c) + ", " + `r` + ", " + `n` +
//		   ") = " + `outcome`)
//
//	return outcome
//
//    def _old_dd(self, c, r, n):
//	"""Stub to overload in subclasses"""
//
//        if r == []:
//            assert self.test([]) == self.PASS
//            assert self.test(c)  == self.FAIL
//        else:
//            assert self.test(r)     != self.FAIL
//            assert self.test(c + r) != self.PASS
//
//        assert self.__listintersect(c, r) == []
//
//	if len(c) == 1:
//	    # Nothing to split
//	    return c
//
//	run = 1
//	next_c = c[:]
// 	next_r = r[:]
//
//	# We replace the tail recursion from the paper by a loop
//	while 1:
//	    self.report_progress(c, "dd")
//
//	    cs = self.split(c, n)
//
//	    print
//	    print "dd (run #" + `run` + "): trying",
//	    for i in range(n):
//		if i > 0:
//		    print "+",
//		print len(cs[i]),
//	    print
//
//	    # Check subsets
//	    ts = []
//	    for i in range(n):
//                if self.debug_dd:
//                    print "dd: trying cs[" + `i` + "] =", self.pretty(cs[i])
//
//		t, cs[i] = self.test_and_resolve(cs[i], r, c, self.REMOVE)
//		ts.append(t)
//		if t == self.FAIL:
//		    # Found
//                    if self.debug_dd:
//                        print "dd: found", len(cs[i]), "deltas:",
//                        print self.pretty(cs[i])
//                    return self.dd(cs[i], r)
//
//	    # Check complements
//	    cbars = []
//	    tbars = []
//
//	    for i in range(n):
//		cbar = self.__listminus(c, cs[i] + r)
//		tbar, cbar = self.test_and_resolve(cbar, r, c, self.ADD)
//
//
//                doubled =  self.__listintersect(cbar, cs[i])
//                if doubled != []:
//	            cs[i] = self.__listminus(cs[i], doubled)
//
//
//		cbars.append(cbar)
//		tbars.append(tbar)
//
//		if ts[i] == self.PASS and tbars[i] == self.PASS:
//		    # Interference
//                    if self.debug_dd:
//                        print "dd: interference of", self.pretty(cs[i]),
//                        print "and", self.pretty(cbars[i])
//
//		    d    = self.dd(cs[i][:], cbars[i] + r)
//		    dbar = self.dd(cbars[i][:], cs[i] + r)
//		    return d + dbar
//
//		if ts[i] == self.UNRESOLVED and tbars[i] == self.PASS:
//		    # Preference
//                    if self.debug_dd:
//                        print "dd: preferring", len(cs[i]), "deltas:",
//                        print self.pretty(cs[i])
//
//		    return self.dd(cs[i][:], cbars[i] + r)
//
//		if ts[i] == self.PASS or tbars[i] == self.FAIL:
//                    if self.debug_dd:
//                        excluded = self.__listminus(next_c, cbars[i])
//                        print "dd: excluding", len(excluded), "deltas:",
//                        print self.pretty(excluded)
//
//                    if ts[i] == self.PASS:
//                        next_r = self.__listunion(next_r, cs[i])
//		    next_c = self.__listintersect(next_c, cbars[i])
//		    self.report_progress(next_c, "dd")
//
//            next_n = min(len(next_c), n * 2)
//
//	    if next_n == n and next_c[:] == c[:] and next_r[:] == r[:]:
//		# Nothing left
//                if self.debug_dd:
//                    print "dd: nothing left"
//		return next_c
//
//            # Try again
//            if self.debug_dd:
//                print "dd: try again"
//
//	    c = next_c
//	    r = next_r
//	    n = next_n
//	    run = run + 1

  Pair<Result, List<Delta>> test_mix(
      List<Delta> csub, List<Delta> c, Direction direction) {
    if (minimize) {
      var pair = test_and_resolve(csub, <Delta>[], c, direction);
      var t = pair.a;
      csub = pair.b;
      if (t == Result.fail) {
        return pair;
      }

      if (maximize) {
        var csubbar = __listminus(CC, csub);
        final cbar = __listminus(CC, c);
        Direction directionbar;
        if (direction == Direction.add) {
          directionbar = Direction.remove;
        } else {
          directionbar = Direction.add;
        }

        final pair = test_and_resolve(csubbar, <Delta>[], cbar, directionbar);
        final tbar = pair.a;
        csubbar = pair.b;

        csub = __listminus(CC, csubbar);

        if (tbar == Result.pass) {
          t = Result.fail;
        } else if (tbar == Result.fail) {
          t = Result.pass;
        } else {
          t = Result.unresolved;
        }
      }

      return Pair<Result, List<Delta>>(t, csub);
    }
  }

  // Delta Debugging (new ISSTA version)

  /// Return a 1-minimal failing subset of C
  ddgen(List<Delta> c, bool minimize, bool maximize) {
    this.minimize = minimize;
    this.maximize = maximize;

    var n = 2;
    CC = c;

//	if self.debug_dd:
//	    print ("dd(" + self.pretty(c) + ", " + `n` + ")...")

    var outcome = _dd(c, n);

//	if self.debug_dd:
//	    print ("dd(" + self.pretty(c) + ", " + `n` + ") = " + `outcome`)

    return outcome;
  }

  /// Stub to overload in subclasses
  _dd(List<Delta> c, int n) {
    assert(test(<Delta>[]) == Result.pass);

    var run = 1;
    var cbar_offset = 0;

    // We replace the tail recursion from the paper by a loop
    while (true) {
      var tc = test(c);
      assert(tc == Result.fail || tc == Result.unresolved);

      if (n > c.length) {
        // No further minimizing
        //print("dd: done");
        return c;
      }

      // self.report_progress(c, "dd")

      final cs = split(c, n);

      //print
      //print "dd (run #" + `run` + "): trying",
//	    for i in range(n):
//		if i > 0:
//		    print "+",
//		print len(cs[i]),
//	    print

      var c_failed = false;
      var cbar_failed = false;

      var next_c = List<Delta>.from(c);
      var next_n = n;

      // Check subsets
      for (int i = 0; i < n; ++i) {
        //if self.debug_dd:
        //    print "dd: trying", self.pretty(cs[i])

        var pair = test_mix(cs[i], c, Direction.remove);
        final t = pair.a;
        cs[i] = pair.b;

        if (t == Result.fail) {
          // Found
          // if self.debug_dd:
          //     print "dd: found", len(cs[i]), "deltas:",
          //     print self.pretty(cs[i])

          c_failed = true;
          next_c = cs[i];
          next_n = 2;
          cbar_offset = 0;
          //self.report_progress(next_c, "dd")
          break;
        }
      }

      if (!c_failed) {
        // Check complements

        // TODO: is this correct?
        // cbars = n * [self.UNRESOLVED]
        var cbars = List<List<Delta>>.filled(n, null); //, [Result.unresolved]);

        // print "cbar_offset =", cbar_offset

        for (var j = 0; j < n; ++j) {
          var i = (j + cbar_offset) % n;
          cbars[i] = __listminus(c, cs[i]);
          var pair = test_mix(cbars[i], c, Direction.add);
          final t = pair.a;
          cbars[i] = pair.b;

          final doubled = __listintersect(cbars[i], cs[i]);
          if (doubled.isNotEmpty) {
            cs[i] = __listminus(cs[i], doubled);
          }

          if (t == Result.fail) {
            //if self.debug_dd:
            //    print "dd: reduced to", len(cbars[i]),
            //    print "deltas:",
            //    print self.pretty(cbars[i])

            cbar_failed = true;
            next_c = __listintersect(next_c, cbars[i]);
            next_n = next_n - 1;
            //self.report_progress(next_c, "dd")

            // In next run, start removing the following subset
            cbar_offset = i;
            break;
          }
        }
      }

      if (!c_failed && !cbar_failed) {
        if (n >= c.length) {
          // No further minimizing
          //print "dd: done"
          return c;
        }

        next_n = min<int>(c.length, n * 2);
        //print "dd: increase granularity to", next_n
        cbar_offset = ((cbar_offset * next_n) / n).round();
      }

      c = next_c;
      n = next_n;
      run = run + 1;
    }
  }

  ddmin(List<Delta> c) => ddgen(c, true, false);

  ddmax(List<Delta> c) => ddgen(c, false, true);

  ddmix(List<Delta> c) => ddgen(c, true, true);

  /// General delta debugging (new TSE version)
//    dddiff(self, c) {
//        var n = 2
//
////	if self.debug_dd:
////	    print ("dddiff(" + self.pretty(c) + ", " + `n` + ")...")
////
//	var outcome = _dddiff([], c, n);
//
//	//if self.debug_dd:
//	//    print ("dddiff(" + self.pretty(c) + ", " + `n` + ") = " +
//  //                 `outcome`)
//
//	return outcome;
//    }
//
//     _dddiff(c1, c2, n) {
//	var run = 1;
//        var cbar_offset = 0;
//
//	// We replace the tail recursion from the paper by a loop
//	while (true) {
//            if self.debug_dd:
//                print "dd: c1 =", self.pretty(c1)
//                print "dd: c2 =", self.pretty(c2)
//
//            if self.assume_axioms_hold:
//                t1 = self.PASS
//                t2 = self.FAIL
//            else:
//                t1 = self.test(c1)
//                t2 = self.test(c2)
//
//            assert t1 == self.PASS
//            assert t2 == self.FAIL
//            assert self.__listsubseteq(c1, c2)
//
//            c = self.__listminus(c2, c1)
//
//            if self.debug_dd:
//                print "dd: c2 - c1 =", self.pretty(c)
//
//            if n > len(c):
//                # No further minimizing
//                print "dd: done"
//                return (c, c1, c2)
//
//	    self.report_progress(c, "dd")
//
//	    cs = self.split(c, n)
//
//	    print
//	    print "dd (run #" + `run` + "): trying",
//	    for i in range(n):
//		if i > 0:
//		    print "+",
//		print len(cs[i]),
//	    print
//
//            progress = 0
//
//            next_c1 = c1[:]
//            next_c2 = c2[:]
//            next_n = n
//
//	    # Check subsets
//            for j in range(n):
//                i = (j + cbar_offset) % n
//
//                if self.debug_dd:
//                    print "dd: trying", self.pretty(cs[i])
//
//                (t, csub) = self.test_and_resolve(cs[i], c1, c, self.REMOVE)
//                csub = self.__listunion(c1, csub)
//
//                if t == self.FAIL and t1 == self.PASS:
//                    # Found
//                    progress    = 1
//                    next_c2     = csub
//                    next_n      = 2
//                    cbar_offset = 0
//
//                    if self.debug_dd:
//                        print "dd: reduce c2 to", len(next_c2), "deltas:",
//                        print self.pretty(next_c2)
//                    break
//
//                if t == self.PASS and t2 == self.FAIL:
//                    # Reduce to complement
//                    progress    = 1
//                    next_c1     = csub
//                    next_n      = max(next_n - 1, 2)
//                    cbar_offset = i
//
//                    if self.debug_dd:
//                        print "dd: increase c1 to", len(next_c1), "deltas:",
//                        print self.pretty(next_c1)
//                    break
//
//
//                csub = self.__listminus(c, cs[i])
//                (t, csub) = self.test_and_resolve(csub, c1, c, self.ADD)
//                csub = self.__listunion(c1, csub)
//
//                if t == self.PASS and t2 == self.FAIL:
//                    # Found
//                    progress    = 1
//                    next_c1     = csub
//                    next_n      = 2
//                    cbar_offset = 0
//
//                    if self.debug_dd:
//                        print "dd: increase c1 to", len(next_c1), "deltas:",
//                        print self.pretty(next_c1)
//                    break
//
//                if t == self.FAIL and t1 == self.PASS:
//                    # Increase
//                    progress    = 1
//                    next_c2     = csub
//                    next_n      = max(next_n - 1, 2)
//                    cbar_offset = i
//
//                    if self.debug_dd:
//                        print "dd: reduce c2 to", len(next_c2), "deltas:",
//                        print self.pretty(next_c2)
//                    break
//
//            if progress:
//                self.report_progress(self.__listminus(next_c2, next_c1), "dd")
//            else:
//                if n >= len(c):
//                    # No further minimizing
//                    print "dd: done"
//                    return (c, c1, c2)
//
//                next_n = min(len(c), n * 2)
//                print "dd: increase granularity to", next_n
//                cbar_offset = (cbar_offset * next_n) / n
//
//            c1  = next_c1
//            c2  = next_c2
//            n   = next_n
//	    run = run + 1
//
//    def dd(self, c):
//        return self.dddiff(c)           # Backwards compatibility
}

// if __name__ == '__main__':
//     # Test the outcome cache
//     oc_test()
//
//     # Define our own DD class, with its own test method
//     class MyDD(DD):
// 	def _test_a(self, c):
// 	    "Test the configuration C.  Return PASS, FAIL, or UNRESOLVED."
//
// 	    # Just a sample
// 	    # if 2 in c and not 3 in c:
// 	    #	return self.UNRESOLVED
// 	    # if 3 in c and not 7 in c:
//             #   return self.UNRESOLVED
// 	    if 7 in c and not 2 in c:
// 		return self.UNRESOLVED
// 	    if 5 in c and 8 in c:
// 		return self.FAIL
// 	    return self.PASS
//
// 	def _test_b(self, c):
// 	    if c == []:
// 		return self.PASS
// 	    if 1 in c and 2 in c and 3 in c and 4 in c and \
// 	       5 in c and 6 in c and 7 in c and 8 in c:
// 		return self.FAIL
// 	    return self.UNRESOLVED
//
// 	def _test_c(self, c):
// 	    if 1 in c and 2 in c and 3 in c and 4 in c and \
// 	       6 in c and 8 in c:
//                 if 5 in c and 7 in c:
//                     return self.UNRESOLVED
//                 else:
//                     return self.FAIL
// 	    if 1 in c or 2 in c or 3 in c or 4 in c or \
// 	       6 in c or 8 in c:
//                 return self.UNRESOLVED
//             return self.PASS
//
// 	def __init__(self):
// 	    self._test = self._test_c
//             DD.__init__(self)
//
//
//     print "WYNOT - a tool for delta debugging."
//     mydd = MyDD()
//     # mydd.debug_test     = 1			# Enable debugging output
//     # mydd.debug_dd       = 1			# Enable debugging output
//     # mydd.debug_split    = 1			# Enable debugging output
//     # mydd.debug_resolve  = 1			# Enable debugging output
//
//     # mydd.cache_outcomes = 0
//     # mydd.monotony = 0
//
//     print "Minimizing failure-inducing input..."
//     c = mydd.ddmin([1, 2, 3, 4, 5, 6, 7, 8])  # Invoke DDMIN
//     print "The 1-minimal failure-inducing input is", c
//     print "Removing any element will make the failure go away."
//     print
//
//     print "Computing the failure-inducing difference..."
//     (c, c1, c2) = mydd.dd([1, 2, 3, 4, 5, 6, 7, 8])	# Invoke DD
//     print "The 1-minimal failure-inducing difference is", c
//     print c1, "passes,", c2, "fails"
//
//

class Delta implements Comparable<Delta> {
  final int offset;
  final dynamic value;

  Delta(this.offset, this.value);

  @override
  int compareTo(Delta other) {
    if (offset < other.offset) {
      return -1;
    } else if (offset == other.offset) {
      return 0;
    } else {
      return 1;
    }
  }
}

class Pair<A, B> {
  final A a;
  final B b;

  Pair(this.a, this.b);
}

//
// # Local Variables:
// # mode: python
// # End:
