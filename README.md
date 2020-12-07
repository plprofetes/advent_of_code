# advent_of_code

Not the prettiest, but solves the quiz.

Thanks https://adventofcode.com/ !

2017 - Ruby - just checking AoC
2018-2019 - Ponylang (because it's just cool)
2020 - C (because it's been 10 years since I last used it)

# Items of note about Pony

## Overall

### Nice things

* Unlimited ThreadPool-like approach when modelling problems
* Functional-like approach to extract static functions to primitives
* one does not need to worry about locks when writing counters
  * but needs to worry about data being en-route in queues - more caching, more state machines
  * data/actor races all the time! perfect for pipelines, terrible for grids

### How to make life easier?

* when concatenating strings, and item has trait Stringable, why not call .string() implicitly?
* autocasting up for comparison when comparing Numbers? ie. U8 -> U32, cannot screw that, right?
  * upcasting to USize or ISize would be handy as well
* C#'s async / await - on async keyword they pack the rest of the body in a promise, that is fulfilled later, magically. In Pony one has to deal with Promises, which is kinda cumbersome
* WARN if lambda has assignments on variables with the same names as local variables - they would not be changed! it may be misleading.
* debugger, any, really
* can constructor call another constructor?

## 2018 Day 2

* map and reduce pattern: https://playground.ponylang.io/?gist=a987e67f6ae804cc256a47736704f459 when there's only one successful Promise

## 2018 Day 4

* Missing proper Time and Date classes in Stdlib
* Missing SortBy accepting a lambda that transforms elements of array to something Comparable
  * allows writing convenient sorters using existing comparators
  * Ruby inspired
* Missing Seq.min, Seq.max methods, one has to type ```Iter[]...fold[]()``` code over and over
  * with additional param as value being compared, when different from whole basic type?

## 2018 Day 5

** Day5_mini - simplified, extracted code happened to be Pony GC stress test **

Fun first! Too complex approach to do a linked-list of actors and try to coordinate reactions.

* Highly parallel - with peak of a few thousands concurrent reactions!
  * May get sequential near the end when one reaction triggers just one following one.

~~Some kind of transaction must be figured out, such as a token, and reactions need to wait until token is received~~. First attempt with FSM.

Some kind of notifications must me sent to siblings when transaction is done. Each type of notification must be stored separately, eg.
* _pending_reaction
* _pinged_from_left

~~Two Phase Commit may be required here.~~

### Reporting

A state of whole reaction/no reaction is needed to determine when reactions are done. Implemented with ReactionWatcher. When number of active reactions drops to 0 it calls a lambda that checks if polymer is stable. If polymer is not stable - check is repeated again, when number of reactions drops to 0 again. Usually a few attempts are needed until polymer is stable. It's because message passing takes time and not all reactions are active at once. Similarly, reporting by traversing node-by-node also takes time.

I find this solution more elegant that firing Timer with check(), check(), check()... especially because it's hard to tell how long such reporting would take and having more than one pass at any given time is suboptimal.

Update after part2: This reporting is not good, because pessimistic scenario for letter 'sS' takes too long, and firing Report over and over, after each reaction - it's not optimal.

It another conditions to fire Reporting were found - Timer would not have been necessary.

I switched to Timers approach, it's not that reactive, async, fancy, low-latency etc., but it gets job done. And it's simpler to read.

### State machine conclusions

* ~~change state first, then message~~
* messages sent from try..end blocks cannot be unsent, even if block fails
* fun/be is single-threaded, ~~but still can by cut off the CPU in the middle of executing!~~, not preemptive (https://tutorial.ponylang.io/gotchas/scheduling.html) 
* messages can be deduped if reaction to them is in another behavior: flag can be set multiple times, but cleared once, the rest of reaction code is NOOP
* in agent's inbox there's a lot of historical messages, some of them may need to be redirected, some removed. Always check current state and process messages accordingly.
* make sure all connections are established correctly, actors can be launched in any order, causality might not be enough, since independent actors may scheduled at different order/time and still remain causal.
  * double linked list creation: before a node is called with hello, it may be called with ping_from_left (!?)
    * in current solution - delayed hello() call notifies siblings even if reaction was performed before that hello() call.
    * this is because Main is not producing Units in one transaction. Main continues to spawn actors, and  messages are already flowing. And until all actors in a list are created - there's at least one missing next - the one that is not spawned yet.
    * is this because actors may not finish their constructor when called, but actor creation is delayed? (no? https://tutorial.ponylang.io/gotchas/scheduling.html)
  * since my linked list requires being able to move to the right via _next, and that must be enforced in code. if there's no _next at the moment - wait/cache information until it comes
  * Unit may call try_react to the left without waiting for the next
    * effects may be sent as ping_from_left until no valid _next is present.

### Not tested, but sounds reasonable

* ~~state should be iso variable, not ref, for more resilient code, harder to break~~
* create a matrix of behaviors that call different behaviors and check that program behaves correctly when order of messages is not-optimistic

### Other conclusions

* When implementing a list - always use additional elements to mark beginning and end. This simplifies creation of such collection, allows all elements to be removed and always compute size.
  * enclose raw agent in some class/type for easier portability
* keep Main as simple as possible
* SortBy, Min, Max primitives are definitely needed.
* Actor waiting for actor waiting for actor (...) is just too much to pass promises to the very bottom. Use regular classes or find another way to go (Part2Runner)
  * performance issue may be related to how GC works.
  * notifier/listener pattern should still work.
  * use Timer to check periodically if something's done if it has highly async nature
* Memory consumption should be more debuggable, to help GC do it's job

