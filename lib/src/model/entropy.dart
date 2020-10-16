import 'dart:math';

double entropy(double eventProbability) =>
    eventProbability * -log2(eventProbability);

double log2(x) => log(x) / log(2);
