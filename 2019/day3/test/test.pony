use "ponytest"

use "../../common"
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
    
    var b = Board.create()
    b.wire("R75,D30,R83,U83,L12,D49,R71,U7,L72", 0x1)
    b.wire("U62,R66,U55,R34,D71,R55,D58,R83", 0x2)
    h.assert_eq[I32](159, b.part1())

    b = Board.create()
    b.wire("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51", 0x1)
    b.wire("U98,R91,D20,R16,D67,R40,U7,R15,U6,R7", 0x2)
    h.assert_eq[I32](135, b.part1())


class iso _TestOperations2 is UnitTest
  fun name(): String => "test input part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    var b = Board.create()
    b.wire("R8,U5,L5,D3", 0x1)
    b.wire("U7,R6,D4,L4", 0x2)
    h.assert_eq[I32](30, b.part2())

    b = Board.create()
    b.wire("R75,D30,R83,U83,L12,D49,R71,U7,L72", 0x1)
    b.wire("U62,R66,U55,R34,D71,R55,D58,R83", 0x2)
    h.assert_eq[I32](610, b.part2())

    b = Board.create()
    b.wire("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51", 0x1)
    b.wire("U98,R91,D20,R16,D67,R40,U7,R15,U6,R7", 0x2)
    h.assert_eq[I32](410, b.part2())
