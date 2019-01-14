use "lib"

use "itertools"
use "collections"
use "debug"
use "promises"
use "time"

// use @sleep[U32](seconds: U32)

actor Main
  let env : Env
  var tries : U32 = 0
  var polymer: (Unit | None) = None  // start of the polymer

  new create(env': Env) =>
    env = env'
    Noop("start", env).ssize()
    part1()
    part2()
    Noop("middle", env).ssize()
    

  be part1() =>
    let reader = try
       LineReader(env.root as AmbientAuth, "in.txt" )
      //  LineReaderWithFilter(env.root as AmbientAuth, "in.txt", "s" )
    else
      Debug("Cannot read from input file. Exiting!")
      return
    end
    let d = Decoder(consume reader)
    let w = ReactionWatcher(recover val this~finish_and_report() end)
    
    let poly = Unit(d.next(), w)
    polymer = poly
    var last = poly
    for letter in d do
      // create new Unit
      let u = if d.has_next() then
        Unit(letter, w, last)
      else
        Unit.end_node(letter, w, last)
      end
      last = u
    end
    
  be part2() =>
    // is there problem with GC - why are actors/resources not freed?
    Part2Runner(env)
    // None

  // for part1
  be finish_and_report(cb : Promise[Bool]) =>
    let unit = try polymer as Unit else return end

    tries = tries + 1
    if tries > 200 then
      env.err.print("Error, too many attempts!")
      return
    end

    let p = Promise[String]
    p.next[None](
      {(str : String val) => 
        cb(true)
        env.out.print("Part1: ___" + ", length: " + str.size().string())
        // 10978
      },
      {() => 
        // Debug("Part1 rejected. Try again?")
        // nasty hack for Ss letters, should be rewritten into Timer to pass results based on that, not on Reactions count
        // because reactions == 0 are too frequent.
        // And GC seems to have problems with lots of Result roaming around
        // NOTE: for Ss case (total reduction) it takes a while. Because it's totally linear/sequential
        // NOTE: Did not work, Pony RT is not waiting for that and program exits without reporting
        // @sleep(5)
        cb(false) // notify Watcher to try again
      }
    )

    let result_token = recover iso Result(p) end
    unit.report(consume result_token)
