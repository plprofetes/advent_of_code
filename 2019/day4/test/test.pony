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

    h.assert_true(Validator("111111"))
    h.assert_false(Validator("223450"))
    h.assert_false(Validator("123789"))

class iso _TestOperations2 is UnitTest
  fun name(): String => "test input part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    h.assert_true(Validator2("112233"))
    h.assert_false(Validator2("123444"))
    h.assert_true(Validator2("111122"))

