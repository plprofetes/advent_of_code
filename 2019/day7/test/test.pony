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
    test(_TestComputer1)
    test(_TestComputer2)

class iso _TestOperations1 is UnitTest
  fun name(): String => "test thrust part 1"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    let th = Engine.compute_thrust("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0", 4,3,2,1,0)
    h.assert_eq[I32](43210, th)

class iso _TestOperations2 is UnitTest
  fun name(): String => "test thrust part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)
    var th = Engine.compute_fb_thrust(
      "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5", 
      9,8,7,6,5)
    h.assert_eq[I32](139629729, th)

    th = Engine.compute_fb_thrust(
      "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10",
      9,7,8,5,6)
    h.assert_eq[I32](18216, th)

class iso _TestComputer1 is UnitTest
  fun name(): String => "test input part 1"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    var cmd = Command.build(1002)
    h.assert_eq[U32](2,cmd.opcode())
    h.assert_eq[U32](0,cmd.par1mode())
    h.assert_eq[U32](1,cmd.par2mode())
    h.assert_eq[U32](0,cmd.par3mode())

    cmd = Command.build(10122)
    h.assert_eq[U32](22,cmd.opcode())
    h.assert_eq[U32](1,cmd.par1mode())
    h.assert_eq[U32](0,cmd.par2mode())
    h.assert_eq[U32](1,cmd.par3mode())

    var comp = Computer.create("1002,4,3,4,33", 0)
    comp.eval()
    h.assert_eq[String]("1002,4,3,4,99", comp.state())

    comp = Computer.create("3,2,0", 99)
    comp.eval()
    h.assert_eq[String]("3,2,99", comp.state())

    comp = Computer.create("4,2,99", 0)
    var res = comp.eval()
    h.assert_eq[String]("4,2,99", comp.state())
    h.assert_eq[I32](99, comp.output())

    comp = Computer.create("3,0,4,0,99", -100)
    res = comp.eval()
    h.assert_eq[String]("-100,0,4,0,99", comp.state())
    h.assert_eq[I32](-100, comp.output())

    comp = Computer.create("104,5,99", 0)
    res = comp.eval()
    h.assert_eq[String]("104,5,99", comp.state())
    h.assert_eq[I32](5, comp.output())

class iso _TestComputer2 is UnitTest
  fun name(): String => "test input part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    var comp = Computer.create("3,9,8,9,10,9,4,9,99,-1,8", 8)
    comp.eval()
    h.assert_eq[I32](1, comp.output())
    comp = Computer.create("3,9,8,9,10,9,4,9,99,-1,8", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output())
    
    comp = Computer.create("3,9,7,9,10,9,4,9,99,-1,8", 7)
    comp.eval()
    h.assert_eq[I32](1, comp.output())
    comp = Computer.create("3,9,7,9,10,9,4,9,99,-1,8", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output())
    
    comp = Computer.create("3,3,1108,-1,8,3,4,3,99", 8)
    comp.eval()
    h.assert_eq[I32](1, comp.output())
    comp = Computer.create("3,3,1108,-1,8,3,4,3,99", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output())
    
    comp = Computer.create("3,3,1107,-1,8,3,4,3,99", 7)
    comp.eval()
    h.assert_eq[I32](1, comp.output())
    comp = Computer.create("3,3,1107,-1,8,3,4,3,99", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output())
    
    comp = Computer.create("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9", 0)
    comp.eval()
    h.assert_eq[I32](0, comp.output())
    
    comp = Computer.create("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9", 1)
    comp.eval()
    h.assert_eq[I32](1, comp.output())
    
    comp = Computer.create("3,3,1105,-1,9,1101,0,0,12,4,12,99,1", 0)
    comp.eval()
    h.assert_eq[I32](0, comp.output())
    
    comp = Computer.create("3,3,1105,-1,9,1101,0,0,12,4,12,99,1", 1)
    comp.eval()
    h.assert_eq[I32](1, comp.output())
    
    h.log("now", false)
    comp = Computer.create(
      "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99",
      1)
    comp.eval()
    h.assert_eq[I32](999, comp.output())
    
    comp = Computer.create(
      "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99",
      8)
    comp.eval()
    h.assert_eq[I32](1000, comp.output())
    
    comp = Computer.create(
      "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99",
      10)
    comp.eval()
    h.assert_eq[I32](1001, comp.output())
