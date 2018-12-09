use "ponytest"

use "../lib"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestLineReader)
    test(_TestPart1)
    test(_TestPart2)
    test(_TestLetterCounter)

class iso _TestLineReader is UnitTest
  fun name(): String => "line reader tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    try
      let lines = LineReader(h.env.root as AmbientAuth, "../in.txt" )
      h.assert_eq[USize](250, lines.count())
    else
      h.fail("Could not read in.txt file")
    end

class iso _TestLetterCounter is UnitTest
  fun name() : String => "letter counter"
  fun apply(h : TestHelper) =>
    h.assert_false(CountLetters("abcdef", 2))
    h.assert_true(CountLetters("bababc", 3))
    h.assert_true(CountLetters("abbcde", 2))

class iso _TestPart1 is UnitTest
  fun name() : String => "part 1 test"

  fun apply(h : TestHelper) =>
    h.assert_eq[U8](1,1)

    try
      let lines = LineReader(h.env.root as AmbientAuth, "in.txt" )
      // h.assert_eq[USize](250, lines.count())
      AOC1(lines)
    else
      h.fail("Could not read in.txt file")
    end


class iso _TestPart2 is UnitTest
  fun name() : String => "part 2 test"

  fun apply(h : TestHelper) =>
    h.assert_eq[U8](1,1)
    // AOC2()