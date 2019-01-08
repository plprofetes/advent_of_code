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
      Debug("Cannot read from input file. Exitting!")
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
    let jobs = recover ref Array[Promise[U32]] end

    for l in Range[U8]('a', 'z' + 1) do
      let str = recover val String.from_utf32(l.u32()) end
      let p = Promise[U32]
      jobs.push(p)
      _part2(str, p)  // do not monopolize the CPU. Or does it?
    end
    let pall = Promises[U32].join(jobs.values())
    pall.next[None]( {
      // collect the partial results, pick minimum
      (ary : Array[U32] val) =>
        let min = Iter[U32](ary.values()).fold[U32](10000000, {(count, mem) => if count < mem then count else mem end })
        env.out.print("Part 2: " + min.string() )
    })

  be _part2(str : String, p : Promise[U32]) =>
    Debug("starting to process filtered run with: " + str)
    LetterFilter(env, str, p)

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

  