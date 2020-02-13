use "ponytest"
use "buffered"

// use "../lib"

actor Main is TestList
  let env : Env
  new create(env': Env) =>
    env = env'
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestOperations1)
    test(_TestOperations2)
    test(_TestReader)
    

class iso _TestReader is UnitTest
  fun name(): String => "test reader"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    let r = Reader
    r.append("12345678")
    let i1 : U8 = try r.block(1)?(0)? else 0 end
    h.assert_eq[U8](49, i1) // it byte value for char "1"
    h.assert_eq[U8](1, i1 - 48) // shift it to get proper numeric value of 1

class iso _TestOperations1 is UnitTest
  fun name(): String => "test thrust part 1"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

class iso _TestOperations2 is UnitTest
  fun name(): String => "test thrust part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
