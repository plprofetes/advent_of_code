use "../common"
use "lib"

use "itertools"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    let only_line : String val = try 
      let strings = FileToStrings(env.root as AmbientAuth, "in1.txt")
      try strings(0)? else "" end
    else
      env.out.print("Error in processing parts")
      return
    end
      
    let c = Computer(only_line, 1)
    c.eval()
    env.out.print("Part1: " + c.output().string())
    
    let c2 = Computer(only_line, 5)
    c2.eval()
    env.out.print("Part2: " + c2.output().string())
  

