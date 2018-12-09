use "ponytest"
use "itertools"
use "debug"
use "files"
use "collections"

// TODO use a cmd switch to choose between tests and computations
actor Main is TestList
  let env : (Env | None)

  new create(env': Env) =>
    PonyTest(env', this)
    env = env'

    try
      let file_contents = match env'.root
      | let x : AmbientAuth => 
          let path = FilePath(x, "in.txt")?
          let f = OpenFile(path) as File
          f.read_string(f.size())
      | None => 
        Debug.err("AmbientAuth not availabile")
        ""
      end
      Debug("Part1: " + AOC1(file_contents).string())
      Debug("Part2: " + AOC2(file_contents).string())
    else
      Debug.err("Cannot read a file")
    end


  new make() =>
    None
    env = None

  fun tag tests(test: PonyTest) =>
    test(_TestPart1)
    test(_TestPart2)

class AOC1
  fun apply(str: String) : I64 =>
      Iter[String](str.split("\n").values()).fold[I64](0, { 
        (sum, x) => 
            // cannot do that as ref, since I cannot send it to STDOUT?
            var y : String iso = x.clone()
          try
            // Debug.out("cloned " + y.size().string() + "chars: " + y.clone())
            if y(0)? == '+' then
              // Debug.out("Removing first char: " + String.from_utf32(y(0)?.u32()))
              y.delete(0,1)
              // Debug.out("Removed first char: " + y.clone())
            end
            sum + y.i64()?
          else
            Debug.err("Cannot do that.")
            0
          end
      })

class AOC2
  // TODO: allow GC via behaviors
  // TODO: use sorted array and binary search. Is it in Pony at all?
  fun apply(str: String): I64 =>

    let history = recover ref Array[I64]() end
    history.push(0)
    var sum : I64 = 0

    for dfreq in Iter[String](str.split("\n").values()).cycle() do
      if history.size() > 1000000 then
        return -999999
      end 
      let y : String iso = dfreq.clone()
      try 
        if y(0)? == '+' then
          y.delete(0,1)
        end
        sum = sum + y.i64()?
        try 
          let ndx = history.find(sum)?
          Debug("Found answer at ndx of " + ndx.string())
          return sum
        else
          // not found
          history.push(sum)
        end
      else
        Debug.err("Cannot do that.")
      end
    end
    -1000000000

class iso _TestPart1 is UnitTest
  fun name(): String => "part1 tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[I64](AOC1("+1\n+1\n+1"), 3)
    h.assert_eq[I64](AOC1("+1\n+1\n-2"), 0)
    h.assert_eq[I64](AOC1("-1\n-2\n-3"), -6)


class iso _TestPart2 is UnitTest
  fun name(): String => "part2 tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[I64](AOC2("+1\n-1"), 0)
    h.assert_eq[I64](AOC2("+3\n+3\n+4\n-2\n-4"), 10)
    h.assert_eq[I64](AOC2("-6\n+3\n+8\n+5\n-6"), 5)
    h.assert_eq[I64](AOC2("+7\n+7\n-2\n-7\n-4"), 14)
