import 'dart:math';

double entropy(double eventProbability) =>
    eventProbability * -_log2(eventProbability);

double _log2(x) => log(x) / log(2);
