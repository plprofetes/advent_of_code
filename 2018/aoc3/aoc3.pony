use "debug"
use "files"
use "itertools"
use "ponytest"
use "promises"

use "./lib"

/*
Ideas:
  * brute force: actors that represent each unit of fabric (250MB + ids)
    * more nice - actors represent patches, and they get acquainted when new patch if filed.
    * then they negotiate with their neighbors only to find overlapping units of fabric
  * decode patches, notify all actors that have something with that patch
  * decide when all processing is done (promise saved for later?)
  * promise to display results when no more input
  so: producer(strings) from file, patch decoder, lots of consumers(patches), 1 (implicit) consumer for results via Promises

Simplest approach:
* a list of all fabric pieces, binary mask, when overflows - report

*/

actor Main
  let env : Env

  new create(env':Env) =>
    env = env'
    try
      Debug("hello!")
      var input = recover val LineReader(env.root as AmbientAuth, "in.txt") end
      let part1 = AOC1

      let done = Promise[None]
      done.next[None](recover Reporter(env,part1) end, recover RejectAlways[None] end)
      part1.work(input, done) //.next[None]( this~_print() ) // {(x) => env.out.write("Part1: " + x.string() )}

    else
      Debug.err("Error in processing: file not read")
    end

  be print_part1_solution(cnt : U64) =>
    env.out.print("There are " + cnt.string() +  " shared sq inches")