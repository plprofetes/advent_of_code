use "debug"
use "files"
use "itertools"
use "ponytest"
use "promises"

use "./lib"

/*
Ideas:
  * actors that count strings
  * promise to display results when no more input
  so: producer(strings), 2 consumers(counters), 1 (implicit) consumer for results via Promises

TODO in Pony stdlib:
# Iter.group_by : Map[k,Iter[v]]
# Promise.filter to propagate succesful ones only
# Iter.rewind()?

Afterthoughts:
* AOC1 and AOC2 can be actors, Main just fires and forgets
* some kind of sink/Promise needed to print the results in Main

*/

actor Main
  new create(env:Env) =>
    try
      var input = LineReader(env.root as AmbientAuth, "in.txt")
      AOC1(Iter[String val](input.values())).next[None]( {(x) => env.out.write("Part1: " + x.string() )})
      
      input = LineReader(env.root as AmbientAuth, "in.txt") // there's no rewind, use array in LineReader?
      for p in AOC2(input).values() do 
        // Debug.out("#") // 249 unnecessary promises to check...
        p.next[None]( { (x) => env.out.write("Part2: " + x )})
      end

    else
      Debug.err("Error in processing: file not read")
    end