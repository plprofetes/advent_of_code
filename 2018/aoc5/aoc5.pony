use "lib"

use "itertools"
use "collections"
use "debug"
use "promises"

actor Main
  let env : Env
  var tries : U32 = 0
  var polymer: (Unit | None) = None  // start of the polymer
  new create(env': Env) =>
    env = env'
    
    part1()
    part2()
    

  be part1() =>
    let reader = try
      //  LineReader(env.root as AmbientAuth, "in.1.txt" )
       LineReader(env.root as AmbientAuth, "in.txt" )
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
        cb(false) // notify Watcher to try again
      }
    )

    let result_token = recover iso Result(p) end
    unit.report(consume result_token)

  