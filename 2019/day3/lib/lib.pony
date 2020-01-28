use "itertools"
use "collections"
use "debug"
use "../../common"


class Board
  let _map : SparseArray[U8] ref = SparseArray[U8].create()

  fun ref wire(path: String, id: U8) =>
    let segments : Array[String] val = path.split(",") 
    var curr = Point(0,0)

    for s in segments.values() do // how to get from segments iso to iterator?
      // eg R991
      (let dir: String val, let offset: String val) = s.string().chop(1)
      // Debug([as String: "Chopped:"; dir; "+"; offset], " ")
      
      let off = try offset.i32()? else 0 end
      var nextPoint = match dir
      | "U" => Point(curr.x(), curr.y() + off)
      | "D" => Point(curr.x(), curr.y() - off)
      | "L" => Point(curr.x() - off, curr.y())
      | "R" => Point(curr.x() + off, curr.y())
      else
        curr
      end

      fill_or(curr, nextPoint, id)
      curr = nextPoint
    end

  // [from, to]
  fun ref fill_or(from: Point, to: Point, value: U8) : None =>
    Debug(["filling from"; from; "to"; to; "with"; value], " ")
    
    let xr = 
      if from.x() < to.x() then
        Range[I32](from.x(), to.x() + 1, 1)
      else
        Range[I32](to.x(), from.x() + 1, 1)
      end
      
    let yr = 
      if from.y() < to.y() then
        Range[I32](from.y(), to.y() + 1, 1)
      else
        Range[I32](to.y(), from.y() + 1, 1)
      end
      
      
      for i in xr do
        for j in yr do
          // Debug(["..puting"; Point(i,j)], " ")
          let prev = _map.put(Point(i,j), value)
          match prev
          | let p : U8 => 
            Debug(["Collision!"; i; "+";j; "prev:"; p; ", new"; value; "updated:"; value.op_or(p)]," ")
            _map.put(Point(i,j), value.op_or(p))
          | None => None
          end
        end
        yr.rewind()
      end

  // What is the Manhattan distance from the central port to the closest intersection?
  fun ref part1() : I32 => //303
    Debug(["there are "; _map.size(); "entries!"], " ")
    let points = Array[(Point, I32)].create()
    let central = Point(0,0)

    for pair in _map.pairs() do
      if (pair._2 == 3) and (pair._1 != central )then
        // Debug(["There's point with crossing: "; pair], " ")
        points.push( (pair._1, pair._1.manhattan(central)) )
        Debug([pair._1; pair._1.manhattan(central)], " ")
      end
    end
    try 
      let sorted = SortBy[(Point, I32), I32](points, { (x: (Point, I32)) => x._2 })?
      sorted(0)?._2 
    else
      -1
    end
  
  // the fewest combined steps the wires must take to reach an intersection
  fun ref part2() : I32 =>
    0

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
