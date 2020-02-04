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



class iso _TestOperations2 is UnitTest
  fun name(): String => "test input part 2"
  fun apply(h: TestHelper) =>
    h.assert_eq[U8](1,1)

    var comp = Computer.create("3,9,8,9,10,9,4,9,99,-1,8", 8)
    comp.eval()
    h.assert_eq[I32](1, comp.output(), "pos eq 8")
    comp = Computer.create("3,9,8,9,10,9,4,9,99,-1,8", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output(), "pos eq 8")
    
    comp = Computer.create("3,9,7,9,10,9,4,9,99,-1,8", 7)
    comp.eval()
    h.assert_eq[I32](1, comp.output(), "pos lt 8")
    comp = Computer.create("3,9,7,9,10,9,4,9,99,-1,8", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output(), "pos eq 8")
    
    comp = Computer.create("3,3,1108,-1,8,3,4,3,99", 8)
    comp.eval()
    h.assert_eq[I32](1, comp.output(), "imm eq 8")
    comp = Computer.create("3,3,1108,-1,8,3,4,3,99", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output(), "imm eq 8")
    
    comp = Computer.create("3,3,1107,-1,8,3,4,3,99", 7)
    comp.eval()
    h.assert_eq[I32](1, comp.output(), "imm lt 8")
    comp = Computer.create("3,3,1107,-1,8,3,4,3,99", 9)
    comp.eval()
    h.assert_eq[I32](0, comp.output(), "imm eq 8")
    
    comp = Computer.create("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9", 0)
    comp.eval()
    h.assert_eq[I32](0, comp.output(), "pos jump mode")
    
    comp = Computer.create("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9", 1)
    comp.eval()
    h.assert_eq[I32](1, comp.output(), "pos jump mode")
    
    comp = Computer.create("3,3,1105,-1,9,1101,0,0,12,4,12,99,1", 0)
    comp.eval()
    h.assert_eq[I32](0, comp.output(), "imm jump")
    
    comp = Computer.create("3,3,1105,-1,9,1101,0,0,12,4,12,99,1", 1)
    comp.eval()
    h.assert_eq[I32](1, comp.output(), "imm jump")
    
    h.log("now", false)
    comp = Computer.create("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99", 1)
    comp.eval()
    h.assert_eq[I32](999, comp.output())
    
    comp = Computer.create("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99", 8)
    comp.eval()
    h.assert_eq[I32](1000, comp.output())
    
    comp = Computer.create("3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99", 10)
    comp.eval()
    h.assert_eq[I32](1001, comp.output())


