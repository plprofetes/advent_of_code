use "ponytest"
use "../lib"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestLineReader)
    test(_TestParser)
    test(_TestTimestamp)

class iso _TestLineReader is UnitTest
  fun name(): String => "line reader tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    try
      let lines = LineReader(h.env.root as AmbientAuth, "../in.txt" )
      h.assert_eq[USize](1017, lines.size())
    else
      h.fail("Could not read in.txt file")
    end

class iso _TestParser is UnitTest
  fun name(): String => "Test parser"
  fun apply(h: TestHelper) =>
    try 
      let res = Parser("[1518-07-24 00:51] wakes up")?
      h.assert_eq[String]("wakes up", res._2)
      let ts = res._1
      h.assert_eq[U16](1518, ts.y)
      h.assert_eq[U8](7, ts.m)
      h.assert_eq[U8](24, ts.d)
      h.assert_eq[U8](0, ts.h)
      h.assert_eq[U8](51, ts.mm)
    else
      h.fail("Could not parse time")      
    end

    let res2 = Parser.extract_guard_id("Guard #10 begins shift")
    match res2
    | let r : String => h.assert_eq[String]("10", r)
    else
      h.fail("Should have parsed the string")
    end
    try
      h.assert_eq[None](None, Parser.extract_guard_id("falls asleep") as None)
    else
      h.fail("Should not have been parsed.")
    end
    try
      Parser.extract_state("falls asleep") as Asleep
      Parser.extract_state("wakes up") as Awake
    else
      h.fail("Should have been parsed.")
    end


class iso _TestTimestamp is UnitTest
  fun name(): String => "ts is comparable?"
  fun apply(h: TestHelper) =>
    let ts1 = Timestamp(2018,7,1,14,35)
    let ts2 = Timestamp(2018,7,1,14,36)
    let ts3 = Timestamp(2018,7,2,14,36)
    h.assert_true(ts1 < ts2)
    h.assert_false(ts1 == ts2)
    h.assert_true(ts1 < ts3)