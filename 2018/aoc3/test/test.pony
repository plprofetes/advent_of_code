use "ponytest"

use "../lib"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestLineReader)
    test(_TestOverlap)
    test(_TestParser)

class iso _TestLineReader is UnitTest
  fun name(): String => "line reader tests"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    try
      let lines = LineReader(h.env.root as AmbientAuth, "../in.txt" )
      h.assert_eq[USize](1353, lines.size())
    else
      h.fail("Could not read in.txt file")
    end

class iso _TestOverlap is UnitTest
  fun name(): String => "Overlap detector"
  fun apply(h: TestHelper) =>
    let p1 = recover val Patch(0,0,4,4) end
    let p2 = recover val Patch(3,3,1,1) end 
    let p3 = recover val Patch(5,0,2,3) end
    // better tests needed 
    let p4 = recover val Patch(10,10, 4,4) end
    let p5 = recover val Patch(8,8,4,4) end
    let p6 = recover val Patch(12,12, 4,4) end
    let p7 = recover val Patch(8,12, 4,4) end
    let p8 = recover val Patch(12,8, 4,4) end
    // inside out
    let p9 = recover val Patch(12,12, 1,2) end
    let p10 = recover val Patch(2,2, 100,100) end
    // from in.txt
    let p11 = recover val Patch(509,931, 11, 20) end
    let p12 = recover val Patch(522,934, 20, 13) end

    try
      h.assert_eq[U32](1, (p1.overlap(p2) as Patch).area())
      h.assert_eq[U32](16, (p1.overlap(p1) as Patch).area())
      h.assert_eq[U32](1, (p2.overlap(p2) as Patch).area())
      h.assert_eq[None](None, (p1.overlap(p3) as None))
      // diagonals
      h.assert_eq[U32](4, (p4.overlap(p5) as Patch).area())
      h.assert_eq[U32](4, (p4.overlap(p6) as Patch).area())
      h.assert_eq[U32](4, (p4.overlap(p7) as Patch).area())
      h.assert_eq[U32](4, (p4.overlap(p8) as Patch).area())
      h.assert_eq[None](None, p4.overlap(p1) as None)
      h.assert_eq[None](None, p1.overlap(p4) as None)
      // inside out
      h.assert_eq[U32](2, (p4.overlap(p9) as Patch).area())
      h.assert_eq[U32](2, (p9.overlap(p4) as Patch).area())
      h.assert_eq[U32](16, (p4.overlap(p10) as Patch).area())
      h.assert_eq[U32](16, (p10.overlap(p4) as Patch).area())
      // in.txt
      h.assert_eq[None](None, p11.overlap(p12) as None)
      h.assert_eq[None](None, p12.overlap(p11) as None)

    else
      h.fail("casting failed!")
    end

    h.assert_eq[USize](16, p1.points().size())
    h.assert_eq[USize](1, p2.points().size())
    
    let pts = p1.points()
    try
      let pt : Point = (3,3)
      h.assert_eq[U32](pt._1, pts(15)?._1)
      h.assert_eq[U32](pt._2, pts(15)?._2)
    else
      h.fail("Cannot get points from p1")
    end

class iso _TestParser is UnitTest
  fun name(): String => "Test parser"
  fun apply(h: TestHelper) =>
    try 
      let res = Parser("#123 @ 3,2: 5x4")?
      h.assert_eq[String]("#123", res._1)
      let p = res._2
      h.assert_eq[U32](3, p.x)
      h.assert_eq[U32](2, p.y)
      h.assert_eq[U32](5, p.w)
      h.assert_eq[U32](4, p.h)
    else
      h.fail("Could not parse string")      
    end