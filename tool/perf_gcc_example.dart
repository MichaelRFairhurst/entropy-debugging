import 'dart:io';

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

int testCounter = 0;
bool testCompile(List<String> input) {
  testCounter++;
  return RegExp(
          r'[a-z]\(double\s+z\[\],\s*int\s+n\)\s*{\s*int\s+i,\s*j;\s*(i\s*=\s*0;\s*)?for\s*\([^);]*;[^);]*;[^)]*\)\s*{\s*i\s*=\s*i\s*\+\s*j\s*\+\s*1;\s*z\[i\]\s*=\s*z\[i\]\s*\*\s*\(z\[0\]\s*\+\s*(1|0|1.0)\);\s*}\s*return\s+z\[n\];\s*}',
          multiLine: true)
      .hasMatch(input.join(''));
}

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

bool testGccOptions(List<String> input) {
  testCounter++;
  return input.contains('--fast-math') || input.contains('--fforce-addr');
}

void main() {
  print('-- perf compile');
  perf_compile();
  print('\n-- perf options');
  perf_options();
}

void perf_compile() {
  final simplifiers = {
    'delta debugging': DeltaDebuggingWrapper(testCompile),
    'entropy debugging': entropy_debugging.simplifier(testCompile),
    'entropy debugging (min)': entropy_debugging.minimizer(testCompile),
  };

  for (final entry in simplifiers.entries) {
    testCounter = 0;
    final start = DateTime.now();
    final result = entry.value.simplify(gccCompileExample.split(''));
    final duration = DateTime.now().difference(start);
    print(
        '${entry.key} ran $testCounter tests in ${duration.inMicroseconds} microseconds, and got ${result.join('')}');
  }
}

void perf_options() {
  final simplifiers = {
    'delta debugging': DeltaDebuggingWrapper(testGccOptions),
    'entropy debugging': entropy_debugging.simplifier(testGccOptions),
    'entropy debugging (min)': entropy_debugging.minimizer(testGccOptions),
  };

  for (final entry in simplifiers.entries) {
    testCounter = 0;
    final start = DateTime.now();
    final result = entry.value.simplify(gccOptionsExample);
    final duration = DateTime.now().difference(start);
    print(
        '${entry.key} ran $testCounter tests in ${duration.inMicroseconds} microseconds, and got ${result.join('')}');
  }
}
