# Entropy Debugging

This is a Dart implementation of the algorithm "Entropy Debugging" conceived of
by Mike Fairhurst and hopefully to be published. It is a response to the
algorithm "Delta Debugging," which is useful for fuzz testers, for example, in
reducing a crash reproduction down to something reasonably small in a reasonable
amount of time.

## Overview

Entropy debugging is based on entropy. In statistics, entropy is the minimum
number of questions that must be asked to decode information. In this case, the
information we are decoding is "which characters are unnecessary for this
reproduction" and the questions are a potentially slow arbitrary function to
call out to as few times as possible.

We can see immediately here the problem with Delta Debugging. Delta Debugging
*assumes* a very low entropy sample. For higher entropy samples, it does not
perform ideally, and the authors have not analyzed what conditions it is suited
for in any sort of precise way.

Entropy debugging aims to measure and react to entropy on the fly, or operate on
a pre-specified entropy, to deliver close to the minimum number of possible
questions (tests) to be asked (performed) to get to a reasonably minumal sample
as possible.

### Statistical model

Entropy is not a quality of data itself, but of a statistical model.

Not all statistical models lend themselves to performant application in this
algorithm; future work could be to integrate better statistical models (such as
machine learning models) into this algorithm, or to come up with better
algorithms that can integrate such models. As long as entropy debugging relies
upon primitive models, the choices it can make will be limited to being
equally primitive.

The simplest statistical model we could use is simply "*what is the odds that
any given character is waste?*" This is obviously limited. If this were
estimated at 50%, there would be no faster way to simplify a result that to try
to remove each character individually.

This is because a simple 50/50 probability has *maximum entropy*. This is true
regardless of what sample of code you are given.

But many real world examples have no more than 50% waste, and that waste tends
to be in clusters. Clearly this statistical model would not lead to amazing
gains in performance.

So we use a markov model. We have two states, _important_ and _unimportant_, and
we track their underlying probabilities (the chance that any random item in the
input is _important_ or _unimportant_) as well as their transition
probabilities (the odds _important_ is followed by _unimportant_ and vice
versa).

### Simplification as Compression

We model the simplification as a compression algorithm as follows.

We observe a stream of events, and want to optimally encode the stream.

The stream consists of the following possibilities: an important event, or a
sequence of `n` unimportant events followed by an important event, or a sequence
of `n` unimportant events where `n` is the remaining events the stream will
send.

In this case, an input like `iuuuuuuiuuuiuuiuuu` would be modeled as a stream
`i`' `u*6+i`, `u*3+i`, `u*2+i`, `u*3+i`.

The simplest encoding for this is simply `100000010001001000`. And for some
probability model, that is in fact optimal. However, given the relative rarity
of `i` in this stream, we might instead encode it as, for instance, `10`=`i`,
`11`=`u*6+i`, `01`=`u*3+i`, and `00`=`u*2+i`.  This gives us a compressed result
of `1011010001`, saving 8 bits of data.

When modeled properly, this bitwise encoding corresponds to a set of tests to
run against the input function, where 0 and 1 correspond to the function
accepting or rejecting our test. Thus, an encoding of length 10 is equivalent to
simplifying the input in 10 questions.

There exists an optimal encoding for this type of stream, and it can be modeled
by decision trees.

### Decision Trees

Now that we have a probability model and a set of events we wish to distinguish,
we can build a huffman tree to find the optimal encoding.

Unfortunately, huffman coding does not work in our case. Huffman coding will
produce trees which we cannot traverse efficiently with real world questions.

For instance, take `i`=0.01, `u+i`=0.9, `u*2+i`=0.09. Huffman coding produces
the encoding: `u+i`=0, `i`=11, `u*2+i`=00. This means that our first bit
distinguishes between `u+i` and (`i` OR `u*2+i`). However, there is no test that
we can run that distinguishes between these. We can remove a single character
and see if that fails, but that distinguishes between `i` vs (`u+i` OR `u*2+i`).
We can try removing two characters and see if that fails, but that distinguishes
between `u*2+i` vs (`i` OR `u*2+i`).

Thus we need a different algorithm to build the decision tree.

Specifically, we must build an _ordered_ decision tree. For any test we can run,
we distinguish between `u*n+i` and `u+(n+1)+i` for some `n` (including 0). This
is equivalent to the set of events having some ordering, and our tests being a
bisection at some point in that ordering. Therefore, the leaves of the decision
tree must stay in the same order as when they are given to the decision tree
building function.

The algorithm to brute force this is `O(n!)`. The first possible bisection in an
input of length `n` has `n-1` possible bisections. In the worst case, one of the
branches will have `n-1` new inputs. Since we are building combinations, these
complexities are multiplicative and this yields `(n-1)*(n-2)*(n-3)*...` for `n`,
thus giving a complexity class of `O(n!)`.

This is not a problem for small trees, (for instance, n=10), so we can still at
times build an optimal tree and get an optimal result. However, for larger
input sets, we need a more efficient means of doing this.

At the time, looking for a performant optimal solution to this problem is worthy
of additional research.

The proposed alternative is to do _ordered huffman coding_. The algorithm is
simple.

```
oh(n0, n1, ... ns, ns+1, ... nq-1, nq) = oh(n0, ... ns-1, Branch(ns, ns+1), ns+2, ... nq -1, nq)
where p(ns) + p(ns+1) is minimized for s.
```

Empirical tests comparing this algorithm to the optimal shows little loss in
efficiency.

This decision tree can then be used to guide the simplifier in making optimal or
near optimal decisions against the given framework.

### Sampling

To build an optimal decision tree requires knowing the exact probability
distribution of the encoded decisions. This is not possible to have. Worse,
collecting samples requires running tests, which adds a cost to the algorithm.

Sampling random individual items ahead of time is essentially free for high
entropy inputs, but expensive for lower entropy inputs. Therefore we sample
minimally, currently only 5 times, of random events + their neighbors, to build
an initial markov model.

Bayesian probability inference is used, so that if `n` out of `s` observations
occur, we assume the most likely underlying probability of `n` is `n+1/s+2`.

### Adapting

While random sampling protects the algorithm from making invalid conclusions on
the input due to sampling error, it is expensive, and so adapting in the middle
of simplification is the preferred strategy.

As the input is simplified, the observed events are fed back into the model to
improve the continuing simplification process. This is vulnerable to sampling
error but in real world cases it seems to still lead to good results. The
algorithm is currently fine tunable, where more random sampling can be done up
front to avoid this. It is also possible to disable adapting entirely during
simplification, so that there is no sample bias at all. In our tests, these do
not seem to be generally good options, but they are part of the API for those
who wish them.

### Minimizing

Lastly, confirm an input is _1-minimal_ we must try removing each character and
find it true. This is a last step that is optional: _simplification_ is a
precursor to _minimization_. It is assumed that a simplified result will have
high entropy during the minimization process, and therefore a simple character
by character search is done until no progress is made.

## Performance

For 2/3 examples given in the original "delta debugging" paper, entropy
debugging is faster at two of them (by ~50% and ~20%). It is slower in the
third, because the sample is too short (31 entries) for entropy debugging to
find a good probability model before simplification is completed.

In generated data based on markov models, this algorithm is faster than delta
debugging all the way down past the point where 99.5% of an input is waste and
99.5% of waste is followed by more waste. It is over 4x faster than delta
debugging in more normal probability ranges, such as when half of the input is
not waste.

A hypothetical optimum has been estimated by running a variant of the algorithm
with optimally built trees (despite the build cost), and by giving it insight
into the true probability distribution of the sample. This is only estimated
down to a small number, because large optimal trees are too expensive to build.
This algorithm is within 10% of optimal for those ranges, with an input size of
500.

As the percentage of waste in the sample gets higher and higher, the algorithm
begins to lose to delta debugging for three reasons. One is that the cost of
sampling becomes a higher proportion of the hypothetical minimum tests. Another
is that it becomes harder and harder to measure the extremely low probabilities.
Lastly, delta debugging is essentially hardcoded to perform optimally in low
entropy data, while this algorithm waits to see there is low entropy before
taking advantage of it. The exact inflection point is very low, at least below
99.5% waste.

While not explored in this paper, it is possible to give the algorithm some
input probability data such that it should be able to match delta debugging when
there truly is cause to believe the sample is expected to be low entropy. It is
also possible to turn off random sampling.

### Optimality

This general approach leads us to generally be able to understand what is
optimal, what is close to optimal, and what has not been proven optimal.

We know that the optimal scenario for minimizing an already minimized sample is
`O(n)`. We can also know the optimal decision tree for decoding the input sample
as if it were a data stream. We also know that the optimal decision tree is too
expensive to build, and we know that our approximate algorithm is close to
optimal in tests.

We do not know if there exists a better approach than treating the
simplification process as an encoding of an event stream. In theory, similar
approaches could be used that encode the entire possiblity set into one optimal
encoding rather than sequences of events (similar to how huffman coding is an
optimal character encoding but not an optimal sample encoding). This is likely
to be intractable, as `2^n` possible combinations of `u` and `i` exist for an
input of length `n`, so even creating such a tree would be exponential in cost.

We know this algorithm is not necessarily optimal for a whitebox function.

We do not know how optimal our probability model building is. It is possible
that other approaches that do not need to estimate underlying probabilities
could have better performance than this algorithm.

We do not know if the markov model is a reasonable model for the input. When it
is not, an algorith using a better probability model could outperform this
algorithm. Similarly, this algorithm can underperform its average case
performance when the markov model is significantly different than the true
input's distribution, either by making poor decisions, or by inferring an
incorrect markov model due to sample bias.

Future research could find various probabilty models that are superior to a
markov model in this algorithm.

We also make no claims about optimality of minimization, as minimization only
differs from simplification when there are interactions between the black box
function and the input. In this case, we assume that simplification produces a
high entropy output that must be simplified character by character and that that
cannot be beaten. However, this is not true for all blackbox functions. Removing
a character may change the input from low entropy to high entropy and back again
at later stages. In this case, this algorithm will perform no better than a
brute force search (though it certainly is a good thing that it will not perform
worse than a brute force search).

## Future work

There is a lot of potential future work based on this algorithm.

More tests on real world data are needed to confirm these findings apply to true
problems given the infinite variety of blackbox functions.

Not much is done in terms of improving the search for n-minimal results. I think
a better approach would be to have a statistical ending criteria rather than a
1-minimal end point which may take O(n^2) operations and in real world scenarios
seems to often only remove trivial amounts of entries from the sample in an
overwhelmingly large number of tests. This alternate ending has not been
explored.

One challenge is to find an algorithm that can build an optimal ordered decision
tree algorithm in polynomial time. This could replace the ordered huffman
algorithm which returns a close to optimal decision tree.

The markov model used to generate underlying probabilities is a very simple
model. Work could be done to try more advanced models, for instance, RNNs. These
likely would be slower to build, but even so, could be useful for simplifying
large enough data sets.

The decision tree is also built and executed in entirety before the markov
model is updated. This simplifies bayesian inference to `(n+1)/(s+2)`. However,
some performance may be possible to gain by rebuilding subtrees based on failed
tests. This is a more complicated probability inference problem.

The algorithm may be improvable by changing the stream to remove from random
locations in the middle of the sample. This may produce a worse result as it may
increase quantization error etc. to start reducing at random locations in the
file. However, it also may result in lower sampling bias.

Lastly, further work to prove the lower and upper bound of this algorithm and
what the true optimal search is could yield light about how much this algorithm
leaves to be improved and where it could be improved most specifically.

# TODO

- Sampling bug (can sample same input too much)
- Compare to afl-tmin
- Prove *some* lower bound, compare to it
- Benchmark relative to input size
- Remove nonsense markov benchmarks better
- Randomize order in adaptive simplifier
- Create a SimplifierBuilder
- make `lastDeletedOffset` part of Simplifier API
- Make caching work for adaptive model
- Compare extreme inputs with a predisposition to low entropy
- Make DeltaDebugging allow async
- code share async/non async using Future API.
