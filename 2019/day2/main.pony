use "../common"
use "lib"

use "itertools"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    try 
      let strings = FileToStrings(env.root as AmbientAuth, "in1.txt")

      let only_line : String val = try strings(0)? else "" end
      
      let c = Computer(only_line)
      c.patch(1,12)
      c.patch(2,2)
      c.eval()
      env.out.print("Part1: " + try c(0)?.string() else "ERROR" end)

      // part 2
      var noun : U32 = 0 
      var verb : U32 = 0
      var done = false

      repeat
        repeat
          var d = Computer(only_line)
          d.patch(1,noun)
          d.patch(2,verb)
          d.eval()
          var res = try d(0)? else 0 end

          if res == 19690720 then
            env.out.print("Part2("+noun.string()+","+verb.string()+") = "+ res.string()+": " + ((100 * noun) + verb).string())
            done = true
            break
          end
          verb = verb + 1
        until verb > 99 end

        if done then break end

        noun = noun + 1
        verb = 0
      until noun > 99 end

    else
      env.out.print("Error in processing part1")
    end
  

