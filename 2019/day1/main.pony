use "../common"
use "lib"

use "itertools"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    try 
      let strings = FileToStrings(env.root as AmbientAuth, "in1.txt")
  
      // part 1
      let all = Iter[String](strings.values()).fold[U32](0, {(sum, x) => sum + FuelCounter( try x.u32()? else 0 end )})
      env.out.print("total fuel needed: " + all.string())

      // part 2
      let all2 = Iter[String](strings.values()).fold[U32](0, {(sum, x) => sum + BetterFuelCounter( try x.u32()? else 0 end )})
      env.out.print("total fuel needed: " + all2.string())
    else
      env.out.print("Error in processing part1")
    end

