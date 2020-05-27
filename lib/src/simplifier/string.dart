import 'dart:async';

import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class StringSimplifier<T extends FutureOr<String>,
    R extends FutureOr<List<String>>, S extends FutureOr<bool>> {
  final Simplifier<String, R, S> innerSimplifier;

  StringSimplifier(this.innerSimplifier);

  T simplify(String input, S Function(String) test) {
    final result = innerSimplifier.simplify(
        input.split(''), (input) => test(input.join('')));
    if (result is Future<List<String>>) {
      return result.then((result) => result.join('')) as T;
    }
    return (result as List<String>).join('') as T;
  }

  static StringSimplifier<String, List<String>, bool> sync(
          Simplifier<String, List<String>, bool> simplifier) =>
      StringSimplifier<String, List<String>, bool>(simplifier);

  static StringSimplifier<Future<String>, Future<List<String>>,
      Future<bool>> async(
          Simplifier<String, Future<List<String>>, Future<bool>> simplifier) =>
      StringSimplifier<Future<String>, Future<List<String>>, Future<bool>>(
          simplifier);
}
