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

    var c = Computer("1,9,10,3,2,3,11,0,99,30,40,50")
    c.patch(1,11)
    h.assert_eq[U32](11, try c(1)? else 10000 end)


    c = Computer("1,9,10,3,2,3,11,0,99,30,40,50").>eval()
    h.assert_eq[String]("3500,9,10,70,2,3,11,0,99,30,40,50", c.state())
    
    c = Computer("2,4,4,5,99,0").>eval()
    h.assert_eq[String]("2,4,4,5,99,9801", c.state())
    
    c = Computer("1,1,1,4,99,5,6,0,99").>eval()
    h.assert_eq[String]("30,1,1,4,2,5,6,0,99", c.state())

class iso _TestOperations2 is UnitTest
  fun name(): String => "test input part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)


