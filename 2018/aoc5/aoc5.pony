use "lib"

use "itertools"
use "collections"
use "debug"
use "promises"

actor Main
  let env : Env
  var tries : U32 = 0

  new create(env': Env) =>
    env = env'
    work()

  be work() =>
    let reader = try
       LineReader(env.root as AmbientAuth, "in.2.txt" )
      //  LineReader(env.root as AmbientAuth, "in.txt" )
    else
      Debug("Cannot read from input file. Exitting!")
      return
    end
    let d = Decoder(consume reader)
    let polymer = Unit(d.next())
    var last = polymer
    for letter in d do
      // create new Unit
      let u = Unit(letter, last)
      last = u
    end

    let p = Promise[None]
    let call = recover val this~finish_and_report(polymer) end
    p.next[None]({(_) => 
      Debug("collecting results...")
      call() 
    })
    last.wait(p)    

    // finish_and_report(polymer)

    // polymer.react()

    // optimal non-actor approach:  walk the buffer and make a step back on reaction

    // push some token through polymer to do reactions?
    // Priority queue on sending messages about changes in topology?
    // only the end of a polymer can fluctuate?
    // report to Sink that polymer is stable?
    // how to further delay this? Try again?

  be finish_and_report(unit : Unit) =>   
    tries = tries + 1
    if tries > 200 then
      env.err.print("Error, too many attempts!")
      return
    end

    let p = Promise[String]
    let failed_pcall = recover val this~finish_and_report(unit) end
    p.next[None](
      {(str) => 
        env.out.print("Part1: " + str + ", length: " + str.size().string())
        // Debug("Part1: " + str + ", length: " + str.size().string())
      },
      {() => 
        // Debug("Part1 rejected. Try again?")
        failed_pcall()
      }
    )

    let result_token = recover iso Result(p) end
    // stuff keeps reacting
    unit.report(consume result_token)
    // if found reacted stuff - backtrack? 
    // save results? on success - play back to retry if state is reduced?
