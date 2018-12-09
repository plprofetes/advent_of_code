use "ponytest"

use "../lib"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestLineReader)
    test(_TestEditDist)
    test(_TestLetterCounter)

class iso _TestLineReader is UnitTest
  fun name(): String => "line reader tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    try
      let lines = LineReader(h.env.root as AmbientAuth, "../in.txt" )
      h.assert_eq[USize](250, lines.size())
    else
      h.fail("Could not read in.txt file")
    end

class iso _TestLetterCounter is UnitTest
  fun name() : String => "letter counter"
  fun apply(h : TestHelper) =>
    h.assert_false(CountLetters("abcdef", 2))
    h.assert_true(CountLetters("bababc", 3))
    h.assert_true(CountLetters("abbcde", 2))

class iso _TestEditDist is UnitTest
  fun name() : String => "simple edit distance between strings"
  fun apply(h : TestHelper) =>
    h.assert_eq[U32](-1, EditDist("abcd", "aac"))
    h.assert_eq[U32](1, EditDist("abc", "aac"))
    h.assert_eq[U32](3, EditDist("aaa", "bbb"))
    h.assert_eq[U32](0, EditDist("bbb", "bbb"))