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
to be in clusters. Clearly 
