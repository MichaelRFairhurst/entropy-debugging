import 'dart:io';

import 'package:entropy_debugging/src/model/markov.dart';
import 'package:entropy_debugging/src/planner/builder.dart';
import 'package:entropy_debugging/src/simplifier/nonadaptive.dart';
import 'package:entropy_debugging/src/simplifier/string.dart';
import 'package:entropy_debugging/src/simplifier/profiling.dart';
import 'package:entropy_debugging/src/competing/delta_debugging_translated_wrapper.dart';
import 'package:entropy_debugging/entropy_debugging.dart' as entropy_debugging;

const gccCompileExample = '''
#define SIZE 20

double mult(double z[], int n)
{
   int i, j;

   i = 0;
   for(j = 0; j < n; j++)
   {
      i = i + j + 1;
      z[i] = z[i] * (z[0] + 1.0);
   }

   return z[n];
}

double copy(double to[], double from[], int count)
{
    int n = (count + 7) / 8;
    switch (count % 8) do {
    case 0: *to++ = *from++;
    case 7: *to++ = *from++;
    case 6: *to++ = *from++;
    case 5: *to++ = *from++;
    case 4: *to++ = *from++;
    case 3: *to++ = *from++;
    case 2: *to++ = *from++;
    case 1: *to++ = *from++;
    } while (--n > 0);

    return mult(to, 2);
}

int main(int argc, char *argv[])
{
    double x[SIZE], y[SIZE];
    double *px = x;

    while (px < x + SIZE)
	*px++ = (px - x) * (SIZE + 1.0);

    return copy(y, x, SIZE);
}''';

final compileRegex = RegExp(
    r'[a-z]\(double\s+z\[\],\s*int\s+n\)\s*{'
    r'\s*int\s+i,\s*j;'
    r'\s*(i\s*=\s*0;\s*)?'
    r'for\s*\([^);]*;[^);]*;[^)]*\)\s*{'
    r'\s*i\s*=\s*i\s*\+\s*j\s*\+\s*1;'
    r'\s*z\[i\]\s*=\s*z\[i\]\s*\*\s*\(z\[0\]\s*\+\s*(1|0|1.0)\);'
    r'\s*}'
    r'\s*return\s+z\[n\];'
    r'\s*}',
    multiLine: true);

bool testCompile(String input) => compileRegex.hasMatch(input);

const gccOptionsExample = [
  '--ffloat-store',
  '--fno-default-inline',
  '--fno-defer-pop',
  '--fforce-mem',
  '--fforce-addr',
  '--fomit-frame-pointer',
  '--fno-inline',
  '--finline-functions',
  '--fkeep-inline-functions',
  '--fkeep-static-consts',
  '--fno-function-cse',
  '--ffast-math',
  '--fstrength-reduce',
  '--fthread-jumps',
  '--fcse-follow-jumps',
  '--fcse-skip-blocks',
  '--frerun-cse-after-loop',
  '--frerun-loop-opt',
  '--fgcse',
  '--fexpensive-optimizations',
  '--fschedule-insns',
  '--fschedule-insns2',
  '--ffunction-sections',
  '--fdata-sections',
  '--fcaller-saves',
  '--funroll-loops',
  '--funroll-all-loops',
  '--fmove-all-movables',
  '--freduce-all-givs',
  '--fno-peephole',
  '--fstrict-aliasing',
];

bool testGccOptions(List<String> input) =>
    input.contains('--fast-math') || input.contains('--fforce-addr');

void main() {
  print('-- perf compile');
  perf_compile();
  print('\n-- perf options');
  perf_options();
}

final simplifiers = [
  (entropy_debugging.SimplifierBuilder<String>(
          startWith: DeltaDebuggingWrapper())
        ..profile('delta debugging'))
      .finish(),
  (entropy_debugging.SimplifierBuilder<String>()
        ..presample()
        ..adaptiveConsume()
        ..profile('entropy debugging simplify')
        ..minimize()
        ..profile('entropy debugging minimize'))
      .finish(),
];

void perf_compile() {
  for (final simplifier in simplifiers) {
    StringSimplifier.sync(simplifier).simplify(gccCompileExample, testCompile);
  }
}

void perf_options() {
  for (final simplifier in simplifiers) {
    simplifier.simplify(gccOptionsExample, testGccOptions);
  }
  (entropy_debugging.SimplifierBuilder<String>(
          startWith: NonadaptiveSimplifier(
              MarkovModel(0.01, 1 / gccOptionsExample.length),
              (TreePlannerBuilder.huffmanLike()
                    ..basic(MarkovModel(0.1, 1 / gccOptionsExample.length)))
                  .finish()))
        ..minimize()
        ..profile('entropy debugging custom markov'))
      .finish()
      .simplify(gccOptionsExample, testGccOptions);
}
