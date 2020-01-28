
use "ponytest"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(PointTest)
    test(SparseArrayTest)
    test(SortByTest)


class iso SparseArrayTest is UnitTest
  fun name(): String => "test SparseArray"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    let a = SparseArray[U8].create()

    h.assert_true( a( Point(0,0) ) is None  )

    try
      h.assert_true( a.put( Point(0,0), 150 ) as None == None  )
    else
      h.log("proper throw")
    end
    try
      h.assert_eq[U8](150, (a.put( Point(0,0), 190 ) as U8))
    else
      h.fail("Should not be here")
    end



class iso PointTest is UnitTest
  fun name(): String => "test Point"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    h.assert_eq[Point](
      Point(1,2),
      Point(1,2)
    )
    h.assert_ne[Point](
      Point(1,2),
      Point(2,1)
    )

    h.assert_eq[I32](2, Point(2,2).manhattan(Point(3,3)))
    h.assert_eq[I32](1, Point(2,2).manhattan(Point(2,3)))
    h.assert_eq[I32](1, Point(2,2).manhattan(Point(3,2)))


class iso SortByTest is UnitTest
  fun name() : String => "test SortBy"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    let input = ["aaa"; "a"; "aa"; "aaa"; "aaaa"; "aa"; "a"]

    try 
      let sorted = SortBy[String, USize](input, {(x : String) : USize => x.size() } )?
      h.assert_eq[USize](input.size(), sorted.size())
      h.assert_eq[String]("a", try sorted(0)? else "" end) 
      h.assert_array_eq[String](
        ["a"; "a"; "aa"; "aa"; "aaa"; "aaa"; "aaaa"],
        sorted
      )
    else
      h.fail("Should not come here")
    end