use "itertools"
use "debug"

class val Command
  let _opcode: U32
  let _par1mode: U32
  let _par2mode: U32
  let _par3mode: U32

  fun val opcode(): U32 => _opcode
  fun val par1mode(): U32 => _par1mode
  fun val par2mode(): U32 => _par2mode
  fun val par3mode(): U32 => _par3mode

  new val build(code: U32) =>
    _opcode = code.mod(100)
    _par1mode = code.mod(1000) / 100
    _par2mode = code.mod(10000) / 1000
    _par3mode = code.mod(100000) / 10000
    
class ref Computer
  let _program : Array[I32 val] ref
  let _input : BoxedI32 ref
  let _output : BoxedI32 ref

  var _pos : USize = 0
  var _phase : (None | I32)
  var is_error : Bool = false

  // @param program - string of instructions, comma separated
  // @param phase - a phase to set on computer's start
  // @param input - container for current, single input signal
  // @param output - container for current, single output signal
  new create(program : String val, phase: I32, input: (I32|BoxedI32) = BoxedI32(0), output': BoxedI32 = BoxedI32(0) ) =>
    _program = recover ref
      let results = Array[I32 val]()
      Iter[String]( program.split(",").values() ).map[I32]( { (x: String) => try x.i32()? else 0 end }).collect(results)
      results
    end
    _phase = phase
    _input = try input as BoxedI32 else try BoxedI32(input as I32) else BoxedI32(0) end end // if is complete, could it not be interfered?
    _output = output'
  
  fun ref output() : I32 =>
    _output()

  fun ref eval() : U32 val =>
    // return last pos
    // run until running = false
    var cycles : U32 val = 0
    _pos = 0
    var running = true

    while running do
      // Debug("Running cycle " + cycles.string() + ", pos = " + _pos.string())
      cycles = cycles + 1
      running = step() != 99
    end
    cycles

  // @return last op executed. 99 for end of code
  fun ref step() : U32 =>
    let command_code = try 
      _program(_pos)? 
    else
      Debug.out("No value at " + _pos.string() + ", " + state())
      is_error = true
      return 99
    end

    if (command_code == 99) or is_error then
      if is_error then Debug.out("Error occured! Abnormal exit!") end
      return 99 // no op if called multiple times
    end

    let command = Command.build(command_code.u32())

    match command.opcode()
    | 1 => 
      try
        _opcode1(
          paramVal(1, command)?,
          paramVal(2, command)?,
          _program(_pos + 3)?.u32()
        )?
      else
        Debug.out("Error running opcode1")
        is_error = true
        return 99
      end
      _pos = _pos + 4
    | 2 =>
      try
        _opcode2(
          paramVal(1, command)?,
          paramVal(2, command)?,
          _program(_pos + 3)?.u32()
        )?
      else
        Debug.out("Error running opcode2")
        is_error = true
        return 99
      end
      _pos = _pos + 4
    | 3 => // input should be written at the address
      try
        _opcode3(
          _program(_pos + 1)?.usize() // WARNING, does it need to be starred?
        )?
      else
        Debug.out("Error running opcode3")
        is_error = true
        return 99
      end
      _pos = _pos + 2
    | 4 => // output to integer from address
      try
        _opcode4(
          // _program(_pos + 1)?.usize()
          paramVal(1, command)?
        )
      else
        Debug.out("Error running opcode4")
      end
      _pos = _pos + 2
    | 5 => // jump if true, if p1 > 0
      try
        _opcode5(
          paramVal(1, command)?,
          paramVal(2, command)?.usize()
        )
      else
        Debug.out("Error running opcode5")
      end
    | 6 => // jump if false, if p1 > 0
      try
        _opcode6(
          paramVal(1, command)?,
          paramVal(2, command)?.usize()
        )
      else
        Debug.out("Error running opcode6")
      end
    | 7 => // less than
      try
        _opcode7(
          paramVal(1, command)?,
          paramVal(2, command)?,
          _program(_pos + 3)?.usize()
        )?
      else
        Debug.out("Error running opcode7")
      end
      _pos = _pos + 4
    | 8 => // equals
      try
        _opcode8(
          paramVal(1, command)?,
          paramVal(2, command)?,
          _program(_pos + 3)?.usize()
        )?
      else
        Debug.out("Error running opcode8")
      end
      _pos = _pos + 4
    | 99 =>
      Debug.out("done at")
      return 99
    | 100000 =>
      Debug.out("cannot read opcode " + command_code.string())
      is_error = true
      return 99
    else
      Debug.out("Unknown opcode: " + command_code.string())
      is_error = true
      return 99
    end
    command.opcode()
  

  // @param ndx : U32, parameter index, 1..3
  fun ref paramVal(ndx : U32, cmd: Command) : I32 ? =>
    let mode : U32 = match ndx
    | 1 => cmd.par1mode()
    | 2 => cmd.par2mode()
    | 3 => cmd.par3mode()
    else
      Debug("Error parsing parameter number: " + ndx.string()) 
      0
    end
    if mode == 1 then
      // just read the value
      _program(_pos + ndx.usize())?
    else
      // pointer!
      star(
        _program(
          _pos + ndx.usize())?.u32()
      )
    end
  
  // * operation by index
  // should be inlined by compiler.
  // separated for debugging purposes
  fun ref star(pos: U32) : I32 =>
    try 
      _program(pos.usize())?
    else
      9999999
    end

  fun ref _opcode1(num1: I32, num2: I32, store_index: U32) : None ? =>
    // Debug.out("Write at " + store_index.string() + ": " + num1.string() + " + " + num2.string())
    _program.update(store_index.usize(), num1 + num2)?

  fun ref _opcode2(num1: I32, num2: I32, store_index: U32) : None ? =>
    // Debug.out("Write at " + store_index.string() + ": " + num1.string() + " * " + num2.string())
    _program.update(store_index.usize(), num1 * num2)?

  fun ref _opcode3(store_index: USize) : None ? =>
    let v = match _phase
    | let x : I32 => 
      // Debug("read phase: " + _phase.string())
      _phase = None
      x
    | None => _input() 
    end
    // Debug.out("Load at " + store_index.string() + ": " + v.string())
    _program.update(store_index, v)?

  fun ref _opcode4(value: I32) : None =>
    // Debug.out("\tOutput value of " + value.string())
    _output.set(value)
    // Debug.out("\t" + _output().string())
 
  fun ref _opcode5(num1: I32, new_pos: USize) : Bool =>
    if num1 != 0 then
      // Debug.out("Jump to " + new_pos.string())
      _pos = new_pos
      true
    else
      // Debug.out("No jump to " + new_pos.string())
      _pos = _pos + 3
      false
    end

  fun ref _opcode6(num1: I32, new_pos: USize) : Bool =>
    if num1 == 0 then
      // Debug.out("!Jump to " + new_pos.string())
      _pos = new_pos
      true
    else
      // Debug.out("No !jump to " + new_pos.string())
      _pos = _pos + 3
      false
    end

  fun ref _opcode7(num1: I32, num2: I32, store_index: USize) : None ? =>
    let value : I32 = if num1 < num2 then 1 else 0 end
    // Debug.out("Write7 at " + store_index.string() + ": " + value.string())
    _program.update(store_index, value)?

  fun ref _opcode8(num1: I32, num2: I32, store_index: USize) : None ? =>
    let value : I32 = if num1 == num2 then 1 else 0 end
    // Debug.out("Write8 at " + store_index.string() + ": " + value.string())
    _program.update(store_index, value)?
 
  fun ref state() : String val =>
    ",".join( _program.values() )

  // read the state at index
  fun ref apply(ndx: USize) : I32 val ? =>
    _program(ndx)?

  fun ref patch(pos: USize, value: I32) =>
    try
      _program.update(pos, value)?
    end

primitive Engine
  fun compute_thrust(program : String val, a: I32, b: I32, c: I32, d: I32, e: I32) : I32 =>
    // let amps : Array[Computer ref] ref = Array[Computer ref].create(5)
    // let seq = [a;b;c;d;e]
    // too much writing. too verbose. shouldnt it be inferrable?
    // for i in Range[U32](0,5) do
    
    let c1 = Computer(program, a, 0)
    c1.eval()
    let c2 = Computer(program, b, c1.output())
    c2.eval()
    let c3 = Computer(program, c, c2.output())
    c3.eval()
    let c4 = Computer(program, d, c3.output())
    c4.eval()
    let c5 = Computer(program, e, c4.output())
    c5.eval()
    c5.output()
  

  fun compute_fb_thrust(program : String val, a: I32, b: I32, c: I32, d: I32, e: I32) : I32 =>

    // The trick is to switch amplifier every time output is generated.
    // It was totally not obvious when reading the description of a task.

    let buf0 = BoxedI32(0)
    let buf1 = BoxedI32(0)
    let buf2 = BoxedI32(0)
    let buf3 = BoxedI32(0)
    let buf4 = BoxedI32(0)

    // for i in Range[U32](0,5) do
    let c1 = Computer.create(program, a, buf0, buf1)
    let c2 = Computer.create(program, b, buf1, buf2)
    let c3 = Computer.create(program, c, buf2, buf3)
    let c4 = Computer.create(program, d, buf3, buf4)
    let c5 = Computer.create(program, e, buf4, buf0)

    var is_done = false
    var cnt : U32 = 0
    
    var ret : U32 = 0
    while not is_done do
      // Debug("iter " + cnt.string())
      cnt = cnt + 1
      repeat
        ret = c1.step()
      until (ret == 99) or (ret == 4) end
      repeat
        ret = c2.step()
      until (ret == 99) or (ret == 4) end
      repeat
        ret = c3.step()
      until (ret == 99) or (ret == 4) end
      repeat
        ret = c4.step()
      until (ret == 99) or (ret == 4) end
      repeat
        ret = c5.step()
      until (ret == 99) or (ret == 4) end
      is_done = ret == 99
    end
    c5.output()

class BoxedI32
  var _i : I32
  new ref create(i': I32) =>
    _i = i'
  
  fun ref apply(): I32 =>
    // Debug(["read:"; _i], " ")
    _i
  
  fun ref set(i: I32) =>
    // Debug(["set:"; _i; "to"; i], " ")
    _i = i
