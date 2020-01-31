use "../common"
use "lib"

use "itertools"
use "collections"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    let strings = try FileToStrings(env.root as AmbientAuth, "in1.txt") else Array[String]() end
    
    let ranges : Array[String val] val = try 
      strings(0)?.split_by("-") 
    else 
      env.out.print("Cannot read files!")
      return
    end
    
    
    let start = try ranges(0)?.u32()? else 0 end
    let finish = try ranges(1)?.u32()? else 0 end
    if (start == 0) or (finish == 0) then
      env.out.print("Cannot parse strings: " + recover val ",".join(ranges.values()) end)
      return
    end

    env.out.print("Brute force from " + start.string() + " to " + finish.string())

    var matched : U32 = 0
    var matched2 : U32 = 0
    for i in Range[U32](start, finish + 1, 1) do
      if Validator(i.string()) then matched = matched + 1 end
      if Validator2(i.string()) then matched2 = matched2 + 1 end
    end

    // var res = b.part1()
    env.out.print("Part1: " + matched.string())
    env.out.print("Part2: " + matched2.string())

    // res = b.part2()
    // env.out.print("Part2: " + res.string())
