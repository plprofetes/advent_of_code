use "../common"
use "lib"

use "itertools"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    let strings = try FileToStrings(env.root as AmbientAuth, "in1.txt") else Array[String]() end
    
    let red : String val = try strings(0)? else "" end
    let green : String val = try strings(1)? else "" end
    
    if (red == "") or (green == "") then
      env.out.print("Cannot read files!")
      return
    end

    let b = Board.create()
    b.wire(red, 0x1)
    b.wire(green, 0x2)

    var res = b.part1()
    env.out.print("Part1: " + res.string())

    res = b.part2()
    env.out.print("Part2: " + res.string())
