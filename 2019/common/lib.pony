use "debug"
use "files"
use "itertools"
use "collections"


/// Notes
// Tuples are not Equatable. Can I create a Map of a tuple?

primitive Okay
  fun apply() =>
    Debug.out("Okay!")

primitive FileToStrings
  fun apply(auth: AmbientAuth, path': String) : Array[String val] =>
    try
      let path = FilePath(auth, path')?
      let f = OpenFile(path) as File
      let contents = f.read_string(f.size())
      let results = Array[String val]()
      Iter[String](contents.split("\n").values()).map[String]( { (l) => l.clone().>strip()  } ).collect(results)
    else
      // logger. error
      []
    end

// Does that include identity?
class val Point is (Stringable & Equatable[Point] & Hashable)
  var _x: I32
  var _y: I32

  new val create(x': I32, y': I32) =>
    _x = x'
    _y = y'

  fun box x() : I32 =>
    _x
  fun box y() : I32 =>
    _y

  fun box eq(that: box->Point): Bool =>
    (_x == that.x()) and (_y == that.y())

  fun box ne(that: box->Point): Bool =>
    not eq(that)
  
  fun box string() : String iso^ =>
    let str = recover String( 3 + _x.string().size() + _y.string().size()) end
    str.append("(")
    str.append(_x.string())
    str.append(",")
    str.append(_y.string())
    str.append(")")

    str.string()
  
  fun box hash() : USize =>
    string().hash()

  fun box manhattan(that: box -> Point) : I32 =>
    ((that.x() - _x).abs() + (that.y() - _y).abs()).i32()

type MaybePoint is (Point | None)


// https://stackoverflow.com/questions/4306/what-is-the-best-way-to-create-a-sparse-array-in-c
class SparseArray[K: Any #read]
  /// grid is 2 dimensional space, with central point 0,0. 
  /// 1st coord is along X axis, second is Y axis
  /// parametrize for contained type?
  /// provide api for easier access.
  let _map : Map[Point, K]

  new create() =>
    _map = Map[Point, K].create()

  // returns previous value
  fun ref put(pos: Point, value: K) : (K | None) =>
    let existing = try _map(pos)? else None end
    _map.insert(pos, value)
    existing
  
  fun ref apply(pos: Point) : (K | None) =>
    try _map(pos)? else None end

  fun ref pairs() : MapPairs[Point, K, HashEq[Point] val, Map[Point, K] ] =>
    _map.pairs()

  fun ref size() : USize=>
    _map.size()

primitive SortBy[K, C: (Comparable[C] #read & Hashable #read & Equatable[C] ) ]
  // todo extract to stdlib, accept function as a param
  // todo sort in place?
  fun apply(a: Array[K], by: { (K!) : C }) : Array[K!] ref^ ? =>
    """
    Sort the given seq in ASC order, by results of provided lambda
    """
    var hmap = Map[C, Array[K!]](a.size())
    for item in a.values() do
      // TODO upsert!
      let key = by(item)
      let current = hmap.get_or_else(key, Array[K!].create())
      current.push(item)
      hmap.update( key, current )
    end

    var sorted_keys = Array[C](hmap.size())
    Iter[C](hmap.keys()).collect(sorted_keys)

    Sort[Array[C], C](sorted_keys)

    var new_ary = Array[K!](a.size())
    for key in sorted_keys.values() do
      new_ary.concat(hmap(key)?.values())  
    end
    new_ary
