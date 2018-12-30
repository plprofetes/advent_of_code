# advent_of_code

Not the prettiest, but solves the quiz.

Thanks https://adventofcode.com/ !


# Items of note about Pony

## Overall

### Nice things

* Unlimited ThreadPool-like approach when modelling problems
* Functional-like approach to extract static functions to primitives

### How to make life easier?

* when concatenating strings, and item has trait Stringable, why not call .string() implicitly?
* autocasting up for comparison when comparing Numbers? ie. U8 -> U32, cannot screw that, right?
  * upcasting to USize or ISize would be handy as well
* C#'s async / await - on async keyword they pack the rest of the body in a promise, that is fulfilled later, magically. In Pony one has to deal with Promises, which is kinda cumbersome

## Day 2

* map and reduce pattern: https://playground.ponylang.io/?gist=a987e67f6ae804cc256a47736704f459 when there's only one successful Promise


## Day 4

* Missing proper Time and Date classes in Stdlib
* Missing SortBy accepting a lambda that transforms elements of array to something Comparable
  * allows writing convenient sorters using existing comparators
  * Ruby inspired
* Missing Seq.min, Seq.max methods, one has to type ```Iter[]...fold[]()``` code over and over
  * with additional param as value being compared, when different from whole basic type?

## Day 5

Fun first! Too complex approach to do a linked-list of actors and try to coordinate reactions.

Some kind of transaction must be figured out, such as a token, and reactions need to wait until token is received. First attempt with FSM.

Some kind of notifications must me sent to siblings when transaction is done.

Two Phase Commit may be required here.

### State machine conclusions

* change state first, then message
* messages sent from try..end blocks cannot be unsent, even if block fails
* method is single-threaded, but still can by cut off the CPU in the middle of executing!
  * try_react -> when Idle - always set the state properly before Reacting
* messages can be deduped if reaction to them is in another behavior: flag can be set multiple times, but cleared once, the rest of reaction code is NOOP
* in agent's inbox there's a lot of historical messages, some of them may need to be redirected, always check current state

### Not tested, but sounds reasonable

* state should be iso variable, not ref, for more resilient code, harder to break