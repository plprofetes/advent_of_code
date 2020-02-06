use "itertools"
use "collections"
use "debug"


class Cosmos
  let _planets: Map[String val, Array[String val] ref] ref
  let _parents: Map[String val, String val] ref
  let _center : String val = "COM"

  new create(defs: Array[String val]) =>
    _planets = Map[String val, Array[String val] ref ].create()
    _parents = Map[String val, String val].create()

    _planets.insert(_center, Array[String val].create())

    for d in defs.values() do
      let elements : Array[String val] val = d.clone().split_by(")")
      if elements.size() != 2 then
        Debug("Invalid number of elements: "; d, "")
        return
      end
      let parent = try elements(0)? else "ERR" end
      let child = try elements(1)? else "ERR" end
      Debug([child; " orbits "; parent], "")

      _parents.insert(child, parent)

      var collection = _planets.get_or_else(parent, Array[String val].create())
      collection.push(child)
      if collection.size() == 1 then
        _planets.insert(parent, collection) // insert is needed, because of new array.
        // otherwise reference is held correctly?
      end
    end
    Debug(["Constructed cosmos with "; _planets.size(); "/"; _parents.size(); " planets/elements"], "")
  
  fun ref orbits() : U32 =>
    _count_orbits_of(_center, 0)
  
  fun ref _count_orbits_of(id: String val, depth: U32) : U32 =>
    var sum : U32 = depth
    let children = try _planets(id)? else Array[String val].create() end
    for c in children.values() do
      sum = sum + _count_orbits_of(c, depth + 1)
    end
    sum

  fun ref transfer_cost(from : String val, to: String val) : U32 =>
    let path_from = _path(from)
    let path_to = _path(to)
    
    // iterate and find first crossing? naiive, but only possible way?
    Debug("<-".join(path_from.values()))
    Debug("<-".join(path_to.values()))

    let diff = Set[String val].create()

    for f in path_from.values() do
      diff.set(f)
    end
    Debug(["Set size: "; diff.size()], "")

    var distance : U32 = 0
    
    for f in path_to.values() do
      if diff.contains(f) then 
        Debug(["Found! "; f], "")
        break 
      end
      distance = distance + 1
    end
    let common_item = try path_to(distance.usize())? else "err" end
    Debug(["Common item: "; common_item; ", |SAN-x|="; distance], "")
    Debug(["Looking for "; common_item; " in "; ",".join(path_from.values())], "")

    // basic version
    // var from_dist : U32 = 0
    // for f in path_from.values() do
    //   if f == common_item then break end
    //   from_dist = from_dist + 1
    // end
    
    // better one?
    var from_dist : USize = try  
      path_from.find(
        common_item,
        0,
        0, 
        { (x :String val, y : String val) : Bool => x == y }
      )?
    else
      99999
    end
    Debug(["|YOU-x|="; from_dist], "")

    -2 + distance + from_dist.u32()

  // path from id to _center
  fun ref _path(id : String val) : Array[String val] val =>
    let path : Array[String val] trn = recover trn Array[String val].create() end

    var current = id
    while current != "" do
      path.push(current)
      current = try _parents(current)? else "" end
    end
    consume path
