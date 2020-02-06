use "../common"
use "lib"

use "itertools"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    let strings : Array[String val] = try
      FileToStrings(env.root as AmbientAuth, "in1.txt")
    else
      env.out.print("Error in reading file")
      return
    end
    
    let c = Cosmos(strings)
    env.out.print("Part1: " + c.orbits().string())
    env.out.print("Part2: " + c.transfer_cost("YOU", "SAN").string())

