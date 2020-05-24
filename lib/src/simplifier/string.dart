import 'dart:async';

import 'package:entropy_debugging/src/simplifier/async_simplifier.dart';
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class StringSimplifier {
  final Simplifier innerSimplifier;

  StringSimplifier(this.innerSimplifier);

  String simplify(String input, bool Function(String) test) => innerSimplifier
      .simplify(input.split(''), (input) => test(input.join('')))
      .join('');
}

class AsyncStringSimplifier {
  final AsyncSimplifier innerSimplifier;

  AsyncStringSimplifier(this.innerSimplifier);

  Future<String> simplify(
          String input, Future<bool> Function(String) test) async =>
      (await innerSimplifier.simplify(
              input.split(''), (input) => test(input.join(''))))
          .join('');
}
