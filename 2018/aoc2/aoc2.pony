use "debug"
use "files"
use "itertools"
use "ponytest"
use "promises"

use "./lib"

/*
Ideas:
  * logger
  * actors that count strings
  * promise to display results when no more input

  so: producer(strings), 2 consumers(counters), 1 (implicit) consumer for results

  # TODO in Pony:
  # iter.group_by : Map[k,Iter[v]]
*/

actor Main
  new create(env:Env) =>
    try
      var input = LineReader(env.root as AmbientAuth, "in.txt")
      AOC1(input).next[None]( {(x) => env.out.write("Part1: " + x.string() )})
      // Debug("Part2: " + AOC2(file_contents).string())
    else
      Debug.err("Error in processing: file not read")
    end