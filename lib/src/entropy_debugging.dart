import 'package:entropy_debugging/src/simplifier/builder.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/string.dart';
import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';

/// Get the entropy debugging simplifier builder.
SimplifierBuilder get simplifierBuilder => SimplifierBuilder()
  ..presample(5)
  ..adaptiveConsume();

/// Get the entropy debugging minimizer builder.
SimplifierBuilder get minimizerBuilder => simplifierBuilder..minimize();

/// Get the entropy debugging simplifier.
Simplifier get simplifier => simplifierBuilder.finish();

/// Get the entropy debugging simplifier.
Simplifier get minimizer => minimizerBuilder.finish();

/// Get the entropy debugging string simplifier.
StringSimplifier get stringSimplifier => simplifierBuilder.stringSimplifier();

/// Perform entropy debugging simplification on the string against the [test].
String stringSimplify(String input, bool Function(String) test) =>
    stringSimplifier.simplify(input, test);

/// Get the entropy debugging string minimizer.
StringSimplifier get stringMinimizer => minimizerBuilder.stringSimplifier();

/// Perform entropy debugging minimization on the string against the [test].
String stringMinimize(String input, bool Function(String) test) =>
    stringMinimizer.simplify(input, test);

/// Get the async entropy debugging simplifier builder.
AsyncSimplifierBuilder get asyncSimplifierBuilder => AsyncSimplifierBuilder()
  ..presample(5)
  ..adaptiveConsume();

/// Get the async entropy debugging minimizer builder.
AsyncSimplifierBuilder get asyncMinimizerBuilder =>
    asyncSimplifierBuilder..minimize();

/// Get the entropy debugging async simplifier.
AsyncSimplifier get asyncSimplifier => asyncSimplifierBuilder.finish();

/// Get the entropy debugging azync minimizing simplifier.
AsyncSimplifier get asyncMinimizer => asyncMinimizerBuilder.finish();

/// Get the entropy debugging async string simplifier.
AsyncStringSimplifier get asyncStringSimplifier =>
    asyncSimplifierBuilder.stringSimplifier();

/// Perform entropy debugging simplification on the string against the [test].
Future<String> asyncStringSimplify(
        String input, Future<bool> Function(String) test) =>
    asyncStringSimplifier.simplify(input, test);

/// Get the entropy debugging async string minimizer.
AsyncStringSimplifier get asyncStringMinimizer =>
    asyncMinimizerBuilder.stringSimplifier();

/// Perform entropy debugging async minimization on the string against the test.
Future<String> asyncStringMinimize(
        String input, Future<bool> Function(String) test) =>
    asyncStringMinimizer.simplify(input, test);
