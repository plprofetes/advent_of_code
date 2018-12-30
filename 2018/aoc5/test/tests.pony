use "ponytest"
use "buffered"
use "collections"

use "../lib"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestLineReader)
    test(_TestDecoder)
    test(_ReactionTest)

class iso _TestLineReader is UnitTest
  fun name(): String => "line reader tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    
    try
      let lines = LineReader(h.env.root as AmbientAuth, "../in.txt" )
      h.assert_true(0 < lines.size())
    else
      h.fail("Could not read in.txt file")
    end

class iso _TestDecoder is UnitTest
  fun name(): String => "Test parser"
  fun apply(h: TestHelper) =>
    let r = recover iso Reader end
    r.append("dabAcCaCBAcCcaDA")
    let d = Decoder(consume r)
    
    h.assert_true(d.has_next())
    h.assert_eq[String]("d", d.next())
    h.assert_eq[String]("a", d.next())
    h.assert_eq[String]("b", d.next())
    h.assert_true(d.has_next())

class iso _ReactionTest is UnitTest
  fun name(): String => "reaction tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](97,'a')
    h.assert_eq[U8](65,'A')
    h.assert_eq[U8](32, 'a' - 'A')
    
    h.assert_true(Reaction("a", "A"))
    h.assert_true(Reaction("A", "a"))
    h.assert_false(Reaction("A", "A"))
    h.assert_false(Reaction("a", "a"))
    h.assert_false(Reaction("a", "b"))
    h.assert_false(Reaction("A", "b"))