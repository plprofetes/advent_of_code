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
* Missing SortBy accepting a labda that transforms elements of array to something Comparable
  * allows writing convenient sorters using existing comparators
  * Ruby inspired
* Missing Seq.min, Seq.max methods, one has to type ```Iter[]...fold[]()``` code over and over

