import 'package:entropy_debugging/src/distribution/tracker.dart';
import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/planner/planner.dart';
import 'package:entropy_debugging/src/simplifier/builder.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal.dart';
import 'package:entropy_debugging/src/simplifier/n_minimal_async.dart';
import 'package:entropy_debugging/src/simplifier/noop.dart';
import 'package:entropy_debugging/src/simplifier/lazily_built_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/two_pass_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/two_pass_async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/string.dart';
import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/presampling.dart';
import 'package:entropy_debugging/src/simplifier/presampling_async.dart';
import 'package:entropy_debugging/src/simplifier/adaptive.dart';
import 'package:entropy_debugging/src/simplifier/adaptive_async.dart';
import 'package:entropy_debugging/src/planner/caching.dart';
import 'package:entropy_debugging/src/planner/capped_size_tree.dart';
import 'package:entropy_debugging/src/planner/probability_threshold_planner.dart';
import 'package:entropy_debugging/src/decision_tree/huffmanlike_builder.dart';

/// Get the entropy debugging simplifier.
Simplifier simplifier() => SimplifierBuilder(minimize: false).buildSimplifier();

/// Get the entropy debugging simplifier.
Simplifier minimizer() => SimplifierBuilder().buildSimplifier();

/// Get the entropy debugging string simplifier.
StringSimplifier stringSimplifier() =>
    SimplifierBuilder(minimize: false).stringSimplifier();

/// Perform entropy debugging simplification on the string against the [test].
String stringSimplify(String input, bool Function(String) test) =>
    stringSimplifier().simplify(input, test);

/// Get the entropy debugging string minimizer.
StringSimplifier stringMinimizer() => SimplifierBuilder().stringSimplifier();

/// Perform entropy debugging minimization on the string against the [test].
String stringMinimize(String input, bool Function(String) test) =>
    stringMinimizer().simplify(input, test);

/// Get the entropy debugging async simplifier.
AsyncSimplifier asyncSimplifier() =>
    AsyncSimplifierBuilder(minimize: false).buildSimplifier();

/// Get the entropy debugging azync minimizing simplifier.
AsyncSimplifier asyncMinimizer() => AsyncSimplifierBuilder().buildSimplifier();

/// Get the entropy debugging async string simplifier.
AsyncStringSimplifier asyncStringSimplifier() =>
    AsyncSimplifierBuilder(minimize: false).stringSimplifier();

/// Perform entropy debugging simplification on the string against the [test].
Future<String> asyncStringSimplify(
        String input, Future<bool> Function(String) test) =>
    asyncStringSimplifier().simplify(input, test);

/// Get the entropy debugging async string minimizer.
AsyncStringSimplifier asyncStringMinimizer() =>
    AsyncSimplifierBuilder().stringSimplifier();

/// Perform entropy debugging async minimization on the string against the test.
Future<String> asyncStringMinimize(
        String input, Future<bool> Function(String) test) =>
    asyncStringMinimizer().simplify(input, test);
