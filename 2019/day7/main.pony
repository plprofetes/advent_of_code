use "../common"
use "lib"

use "itertools"
use "collections"

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
    
    var max_thrust : I32 = 0
    for a in Range[I32](0,5) do
      for b in Range[I32](0,5) do
        for c in Range[I32](0,5) do
          for d in Range[I32](0,5) do
            for e in Range[I32](0,5) do
              // remove dups
              let s = Set[I32].create(5)
              s.set(a)
              s.set(b)
              s.set(c)
              s.set(d)
              s.set(e)
              if s.size() != 5 then continue end

              let thrust = Engine.compute_thrust(only_line, a, b, c, d, e)
              if thrust > max_thrust then
                max_thrust = thrust
              end
            end
          end
        end
      end
    end
    env.out.print("Part1: " + max_thrust.string())

    max_thrust = 0
    for a in Range[I32](5,10) do
      for b in Range[I32](5,10) do
        for c in Range[I32](5,10) do
          for d in Range[I32](5,10) do
            for e in Range[I32](5,10) do
              // remove dups
              let s = Set[I32].create(5)
              s.set(a)
              s.set(b)
              s.set(c)
              s.set(d)
              s.set(e)
              if s.size() != 5 then continue end

              let thrust = Engine.compute_fb_thrust(only_line, a, b, c, d, e)
              if thrust > max_thrust then
                max_thrust = thrust
              end
            end
          end
        end
      end
    end
    env.out.print("Part2: " + max_thrust.string())
