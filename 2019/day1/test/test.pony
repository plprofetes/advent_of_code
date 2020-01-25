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

    h.assert_eq[U32](2, FuelCounter(12))
    h.assert_eq[U32](2, FuelCounter(14))
    h.assert_eq[U32](654, FuelCounter(1969))
    h.assert_eq[U32](33583, FuelCounter(100756))

class iso _TestOperations2 is UnitTest
  fun name(): String => "test input part 2"
  fun apply(h: TestHelper) =>

    h.assert_eq[U32](0, FuelCounter(2))
    h.assert_eq[U32](0, BetterFuelCounter(2))
    h.assert_eq[U32](2, BetterFuelCounter(14))
    h.assert_eq[U32](966, BetterFuelCounter(1969))
    h.assert_eq[U32](50346, BetterFuelCounter(100756))

