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

// TODO put that in my stdlib with some trait defined on actor (HasResults?)
class iso Reporter is Fulfill[None,None]
  let wip: AOC1 tag
  let env: Env
  
  new create(env': Env, wip': AOC1 tag ) =>
    env = env'
    wip = wip'
  
  fun ref apply(_:None) : None => 
    let p = Promise[U64] 
    // p.next[None]( {(cnt) => Debug("There are " + cnt.string() +  " shared sq inches") })
    p.next[None]( {(cnt) => env.out.print("There are " + cnt.string() +  " shared sq inches") })
    wip.results(p)
    None

  
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
      // [None]( 
      //   { (_) =>
      //     let p = Promise[U64] 
      //     // p.next[None]( {(cnt) => Debug("There are " + cnt.string() +  " shared sq inches") })
      //     p.next[None]( {(cnt) => Debug("There are " + cnt.string() +  " shared sq inches") })
      //     part1.results(p)
      //   }
      // )

      part1.work(input, done) //.next[None]( this~_print() ) // {(x) => env.out.write("Part1: " + x.string() )}
      // input = LineReader(env.root as AmbientAuth, "in.txt") // there's no rewind, use array in LineReader?
      // for p in AOC2(input).values() do 
      //   // Debug.out("#") // 249 unnecessary promises to check...
      //   p.next[None]( { (x) => env.out.write("Part2: " + x )})
      // end

    else
      Debug.err("Error in processing: file not read")
    end

  be print_part1_solution(cnt : U64) =>
    env.out.print("There are " + cnt.string() +  " shared sq inches")