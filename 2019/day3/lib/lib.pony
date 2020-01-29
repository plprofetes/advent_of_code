use "itertools"
use "collections"
use "debug"
use "../../common"


class Board
  let _map : SparseArray[U8] ref = SparseArray[U8].create()
  let _dist : Map[Point,(I32,I32)] ref = Map[Point,(I32,I32)].create()

  fun ref wire(path: String, id: U8) =>
    let segments : Array[String] val = path.split(",") 
    var curr = Point(0,0)
    var length : I32 = 0  // compute total length of a wire and write that down in _dist

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

      fill_or(curr, nextPoint, id, length)
      curr = nextPoint
      length = length + off // for next start, fill_or did it internally 
      // Debug(["Segment used "; off ; "wires, cummulatively:"; length], " ")
    end

  // [from, to]
  fun ref fill_or(from: Point, to: Point, value: U8, current_wire_length: I32) : None =>
    Debug(["filling from"; from; "to"; to; "with"; value; "used wire so far:"; current_wire_length], " ")
    
    var cur_len = current_wire_length - 1

    let xr = 
      if from.x() < to.x() then
        Range[I32](from.x(), to.x() + 1, 1)
      else
        Range[I32](from.x(), to.x() - 1, -1)
      end
      
    let yr = 
      if from.y() < to.y() then
        Range[I32](from.y(), to.y() + 1, 1)
      else
        Range[I32](from.y(), to.y() - 1, -1)
      end
      
    for i in xr do
      for j in yr do

        cur_len = cur_len + 1
        // part2 logic, nasty, sorry. only first wire needs this in fact. todo?
        var length = _dist.get_or_else(Point(i,j), (0,0))
        if (length._1 == 0) or (length._2 == 0) then
          if (length._1 == 0) and (value == 0x1) then
            // uninitialized yet, update
            length = (cur_len, length._2)
          end
          if (length._2 == 0) and (value == 0x2) then
            // uninitialized yet, update
            length = (length._1, cur_len)
          end
          _dist.insert(Point(i,j), length)
          // Debug(["\tSaved wire length at"; Point(i,j); ":"; length._1; length._2; ", cur_len ="; cur_len], " ")
        end
        
        // part1 and part2
        // Debug(["..puting"; Point(i,j)], " ")
        let prev = _map.put(Point(i,j), value)
        match prev
        | let p : U8 =>
          // Debug(["Collision!"; i; "+";j; "prev:"; p; ", new"; value; "updated:"; value.op_or(p)]," ")
          _map.put(Point(i,j), value.op_or(p))
        | None => None
        end
      end
      yr.rewind()
    end

  // What is the Manhattan distance from the central port to the closest intersection?
  fun ref part1() : I32 => //303
    // Debug(["there are "; _map.size(); "entries!"], " ")
    let points = Array[(Point, I32)].create()
    let central = Point(0,0)

    for pair in _map.pairs() do
      if (pair._2 == 3) and (pair._1 != central )then
        // Debug(["There's point with crossing: "; pair], " ")
        points.push( (pair._1, pair._1.manhattan(central)) )
        // Debug([pair._1; pair._1.manhattan(central)], " ")
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
    // maintain additional information for each point how much wire was used to get to that point.
    // then evaluate all the crossings again, against that
    let points = Array[Point].create()
    let central = Point(0,0)

    for pair in _map.pairs() do
      if (pair._2 == 3) and (pair._1 != central ) then
        points.push( pair._1 )
      end
    end
    try 
      let sorted = SortBy[Point, I32](points, { (x: Point) => 
        let wires = try _dist(x)? else (10000,10000) end
        // Debug(["Dump crossing:"; x; wires._1; wires._2], " ")
        wires._1 + wires._2
      })?
      let closest = sorted(0)? 
      let wires = _dist(closest)?
      Debug(["shortest:"; closest; "with wires:"; wires._1; wires._2], " ")
      wires._1 + wires._2
    else
      -1
    end