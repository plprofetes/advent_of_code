use "itertools"
use "debug"

class ref Computer
  let _program : Array[U32 val] ref
  var _pos : USize = 0

  new create(input : String val) =>
    _program = recover ref
      let results = Array[U32 val]()
      Iter[String]( input.split(",").values() ).map[U32]( { (x: String) => try x.u32()? else 0 end }).collect(results)
      results
    end

  // @return cycles used
  fun ref eval() : U32 val =>
    _pos = 0
    var cycles : U32 val = 0
    var running = true
    var opcode : U32 = 100


    while running do
      cycles = cycles + 1
      Debug.out("Program(" + _pos.string() + "): " + state())
      
      opcode = try _program(_pos)? else 100 end
      match opcode
      | 1 => 
        try
          _opcode1(
            star(_program(_pos + 1)?),
            star(_program(_pos + 2)?),
            _program(_pos + 3)?
          )?
        else
          Debug.out("Error running opcode1 cycle " + cycles.string())
          running = false
        end
        _pos = _pos + 4
      | 2 =>
        try
          _opcode2(
            star(_program(_pos + 1)?),
            star(_program(_pos + 2)?),
            _program(_pos + 3)?
          )?
        else
          Debug.out("Error running opcode2 cycle " + cycles.string())
          running = false
        end
        _pos = _pos + 4
      | 99 =>
        Debug.out("done at cycle " + cycles.string())
        running = false
      | 100 =>
        Debug.out("cannot read opcode at cycle " + cycles.string())
        running = false
      else
        Debug.out("Unknown opcode at cycle " + cycles.string() + " : " + opcode.string())
        running = false
      end
    end
    cycles


  // * operation by index
  // should be inlined by compiler.
  // separated for debugging purposes
  fun ref star(pos: U32) : U32 =>
    try 
      _program(pos.usize())?
    else
      9999999
    end

  fun ref _opcode1(num1: U32, num2: U32, store_index: U32) : None ? =>
    Debug.out("Write at " + store_index.string() + ": " + num1.string() + " + " + num2.string())
    _program.update(store_index.usize(), num1 + num2)?

  fun ref _opcode2(num1: U32, num2: U32, store_index: U32) : None ? =>
    Debug.out("Write at " + store_index.string() + ": " + num1.string() + " * " + num2.string())
    _program.update(store_index.usize(), num1 * num2)?

  fun ref state() : String val =>
    ",".join( _program.values() )

  // read the state at index
  fun ref apply(ndx: USize) : U32 val ? =>
    _program(ndx)?

  fun ref patch(pos: USize, value: U32) =>
    try
      _program.update(pos, value)?
    end
