use "ponytest"

use "../lib"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestOperations1)
    test(_TestOperations2)

class iso _TestOperations1 is UnitTest
  fun name(): String => "test input part 1"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    
    let input : Array[String val] = ["COM)B";"B)C";"C)D";"D)E";"E)F";"B)G";"G)H";"D)I";"E)J";"J)K";"K)L"]

    var c = Cosmos(input)
    h.assert_eq[U32](42, c.orbits())


    let array : Array[String val] val = ["a"; "b"; "c"; "d"]
    let needle = "c"

    var ndx : U32 = 0
    for f in array.values() do
      if f == needle then break end
      ndx = ndx + 1
    end
    h.assert_eq[U32](2, ndx) //pass

    ndx = try
      array.find(
        needle
      )?.u32()
    else
      0
    end
    h.assert_eq[U32](2, ndx) // pass

    ndx = try
      array.find(
        needle,
        0,
        0, 
        { (x :String val, y : String val) : Bool => x == y }
      )?.u32()
    else
      0
    end
    h.assert_eq[U32](2, ndx) // pass


class iso _TestOperations2 is UnitTest
  fun name(): String => "test input part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    let input : Array[String val] = ["COM)B";"B)C";"C)D";"D)E";"E)F";"B)G";"G)H";"D)I";"E)J";"J)K";"K)L";"K)YOU";"I)SAN"]

    var c = Cosmos(input)
    h.assert_eq[U32](4, c.transfer_cost("YOU", "SAN"))

