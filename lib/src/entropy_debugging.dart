import 'package:entropy_debugging/src/simplifier/builder.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';
import 'package:entropy_debugging/src/simplifier/string.dart';

/// Get the entropy debugging simplifier builder.
SimplifierBuilder<T> simplifierBuilder<T>() => SimplifierBuilder()
  ..presample(5)
  ..adaptiveConsume();

/// Get the entropy debugging minimizer builder.
SimplifierBuilder<T> minimizerBuilder<T>() =>
    simplifierBuilder<T>()..minimize();

/// Get the entropy debugging simplifier.
Simplifier<T, List<T>, bool> simplifier<T>() => simplifierBuilder<T>().finish();

/// Get the entropy debugging simplifier.
Simplifier<T, List<T>, bool> minimizer<T>() => minimizerBuilder<T>().finish();

/// Get the entropy debugging string simplifier.
StringSimplifier<String, List<String>, bool> stringSimplifier() =>
    StringSimplifier.sync(simplifier<String>());

/// Perform entropy debugging simplification on the string against the [test].
String stringSimplify(String input, bool Function(String) test) =>
    stringSimplifier().simplify(input, test);

/// Get the entropy debugging string minimizer.
StringSimplifier<String, List<String>, bool> stringMinimizer() =>
    StringSimplifier.sync(minimizerBuilder().finish());

/// Perform entropy debugging minimization on the string against the [test].
String stringMinimize(String input, bool Function(String) test) =>
    stringMinimizer().simplify(input, test);

/// Get the async entropy debugging simplifier builder.
AsyncSimplifierBuilder<T> asyncSimplifierBuilder<T>() =>
    AsyncSimplifierBuilder()
      ..presample(5)
      ..adaptiveConsume();

/// Get the async entropy debugging minimizer builder.
AsyncSimplifierBuilder<T> asyncMinimizerBuilder<T>() =>
    asyncSimplifierBuilder()..minimize();

/// Get the entropy debugging async simplifier.
Simplifier<T, Future<List<T>>, Future<bool>> asyncSimplifier<T>() =>
    asyncSimplifierBuilder().finish();

/// Get the entropy debugging azync minimizing simplifier.
Simplifier<T, Future<List<T>>, Future<bool>> asyncMinimizer<T>() =>
    asyncMinimizerBuilder().finish();

/// Get the entropy debugging async string simplifier.
StringSimplifier<Future<String>, Future<List<String>>, Future<bool>>
    asyncStringSimplifier() =>
        StringSimplifier.async(asyncSimplifierBuilder().finish());

/// Perform entropy debugging simplification on the string against the [test].
Future<String> asyncStringSimplify(
        String input, Future<bool> Function(String) test) =>
    asyncStringSimplifier().simplify(input, test);

/// Get the entropy debugging async string minimizer.
StringSimplifier<Future<String>, Future<List<String>>, Future<bool>>
    asyncStringMinimizer() =>
        StringSimplifier.async(asyncMinimizerBuilder().finish());

/// Perform entropy debugging async minimization on the string against the test.
Future<String> asyncStringMinimize(
        String input, Future<bool> Function(String) test) =>
    asyncStringMinimizer().simplify(input, test);
