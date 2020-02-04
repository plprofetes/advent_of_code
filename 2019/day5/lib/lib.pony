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
  var _pos : USize = 0
  var _output : I32 = 0
  let _input : I32

  new create(program : String val, input: I32 = 0) =>
    _program = recover ref
      let results = Array[I32 val]()
      Iter[String]( program.split(",").values() ).map[I32]( { (x: String) => try x.i32()? else 0 end }).collect(results)
      results
    end
    // _output = Array[I32 val].create()
    _input = input
  
  fun output() : I32 =>
    _output

  // @return output value
  fun ref eval() : U32 val =>
    _pos = 0
    var cycles : U32 val = 0
    var running = true
    var opcode : U32 = 100000

    while running do
      cycles = cycles + 1
      Debug.out("Program(" + _pos.string() + "): ") // + state())
      
      let command_code = try 
        _program(_pos)? 
      else 
        Debug.out("No value at " + _pos.string() + ", " + state())
        100000 
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
          Debug.out("Error running opcode1 cycle " + cycles.string())
          running = false
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
          Debug.out("Error running opcode2 cycle " + cycles.string())
          running = false
        end
        _pos = _pos + 4
      | 3 => // input should be written at the address
        try
          _opcode3(
            _program(_pos + 1)?.usize() // WARNING, does it need to be starred?
          )?
        else
          Debug.out("Error running opcode3 cycle " + cycles.string())
          running = false
        end
        _pos = _pos + 2
      | 4 => // output to integer from address
        try
          _opcode4(
            // _program(_pos + 1)?.usize()
            paramVal(1, command)?
          )
        else
          Debug.out("Error running opcode4 cycle " + cycles.string())
        end
        _pos = _pos + 2
      | 5 => // jump if true, if p1 > 0
        try
          _opcode5(
            paramVal(1, command)?,
            paramVal(2, command)?.usize()
          )
        else
          Debug.out("Error running opcode5 cycle " + cycles.string())
        end
      | 6 => // jump if false, if p1 > 0
        try
          _opcode6(
            paramVal(1, command)?,
            paramVal(2, command)?.usize()
          )
        else
          Debug.out("Error running opcode6 cycle " + cycles.string())
        end
      | 7 => // less than
        try
          _opcode7(
            paramVal(1, command)?,
            paramVal(2, command)?,
            _program(_pos + 3)?.usize()
          )?
        else
          Debug.out("Error running opcode7 cycle " + cycles.string())
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
          Debug.out("Error running opcode8 cycle " + cycles.string())
        end
        _pos = _pos + 4
      | 99 =>
        Debug.out("done at cycle " + cycles.string())
        running = false
      | 100000 =>
        Debug.out("cannot read opcode " + opcode.string() + "at cycle " + cycles.string())
        running = false
      else
        Debug.out("Unknown opcode at cycle " + cycles.string() + " : " + opcode.string())
        running = false
      end
    end
    cycles


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
    Debug.out("Write at " + store_index.string() + ": " + num1.string() + " + " + num2.string())
    _program.update(store_index.usize(), num1 + num2)?

  fun ref _opcode2(num1: I32, num2: I32, store_index: U32) : None ? =>
    Debug.out("Write at " + store_index.string() + ": " + num1.string() + " * " + num2.string())
    _program.update(store_index.usize(), num1 * num2)?

  fun ref _opcode3(store_index: USize) : None ? =>
    Debug.out("Load at " + store_index.string() + ": " + _input.string())
    _program.update(store_index, _input)?

  fun ref _opcode4(value: I32) : None =>
    Debug.out("\tOutput value of " + value.string())
    _output = value
    // Debug.out("\t" + _output.string())
 
  fun ref _opcode5(num1: I32, new_pos: USize) : Bool =>
    if num1 != 0 then
      Debug.out("Jump to " + new_pos.string())
      _pos = new_pos
      true
    else
      Debug.out("No jump to " + new_pos.string())
      _pos = _pos + 3
      false
    end

  fun ref _opcode6(num1: I32, new_pos: USize) : Bool =>
    if num1 == 0 then
      Debug.out("!Jump to " + new_pos.string())
      _pos = new_pos
      true
    else
      Debug.out("No !jump to " + new_pos.string())
      _pos = _pos + 3
      false
    end

  fun ref _opcode7(num1: I32, num2: I32, store_index: USize) : None ? =>
    let value : I32 = if num1 < num2 then 1 else 0 end
    Debug.out("Write7 at " + store_index.string() + ": " + value.string())
    _program.update(store_index, value)?

  fun ref _opcode8(num1: I32, num2: I32, store_index: USize) : None ? =>
    let value : I32 = if num1 == num2 then 1 else 0 end
    Debug.out("Write8 at " + store_index.string() + ": " + value.string())
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
