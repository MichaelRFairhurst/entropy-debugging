import 'package:entropy_debugging/src/competing/delta_debugging_translated.dart'
    as sync;
import 'package:entropy_debugging/src/competing/delta_debugging_translated_async.dart'
    as async;
import 'package:entropy_debugging/src/simplifier/simplifier.dart';

class DeltaDebuggingWrapper<T> implements Simplifier<T, List<T>, bool> {
  @override
  List<T> simplify(List<T> input, bool Function(List<T>) test) =>
      _DeltaDebuggingWrapper<T>(test).doMinimize(input);
}

class DeltaDebuggingSimplifyWrapper<T> implements Simplifier<T, List<T>, bool> {
  @override
  List<T> simplify(List<T> input, bool Function(List<T>) test) =>
      _DeltaDebuggingWrapper<T>(test).simplify(input);
}

class DeltaDebuggingWrapperAsync<T>
    implements Simplifier<T, Future<List<T>>, Future<bool>> {
  @override
  Future<List<T>> simplify(
          List<T> input, Future<bool> Function(List<T>) test) =>
      _DeltaDebuggingWrapperAsync<T>(test).simplify(input);
}

class _DeltaDebuggingWrapper<T> extends sync.DD {
  final bool Function(List<T>) testFunction;

  _DeltaDebuggingWrapper(this.testFunction);

  @override
  sync.Result doTest(List<sync.Delta> c) {
    return testFunction(coerce(c)) ? sync.Result.fail : sync.Result.pass;
  }

  List<T> simplify(List<T> input) {
    var byOffset = <sync.Delta>[];
    for (var i = 0; i < input.length; ++i) {
      byOffset.add(sync.Delta(i, input[i]));
    }
    var result = ddsimplify(byOffset);
    return coerce(result);
  }

  List<T> doMinimize(List<T> input) {
    var byOffset = <sync.Delta>[];
    for (var i = 0; i < input.length; ++i) {
      byOffset.add(sync.Delta(i, input[i]));
    }
    var result = ddmin(byOffset);
    return coerce(result);
  }

  List<T> coerce(List<sync.Delta> c) =>
      c.map((delta) => delta.value as T).toList();
}

class _DeltaDebuggingWrapperAsync<T> extends async.DD {
  final Future<bool> Function(List<T>) testFunction;

  _DeltaDebuggingWrapperAsync(this.testFunction);

  @override
  Future<async.Result> doTest(List<async.Delta> c) async {
    return (await testFunction(coerce(c)))
        ? async.Result.fail
        : async.Result.pass;
  }

  Future<List<T>> simplify(List<T> input) async {
    var byOffset = <async.Delta>[];
    for (var i = 0; i < input.length; ++i) {
      byOffset.add(async.Delta(i, input[i]));
    }
    var result = await ddmin(byOffset);
    return coerce(result);
  }

  List<T> coerce(List<async.Delta> c) =>
      c.map((delta) => delta.value as T).toList();
}
