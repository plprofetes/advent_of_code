use "files"
use "itertools"
use "assert"
use "debug"
use "collections"
use "promises"

// Missing in Pony:
// SortBy - sorting by provided lambda that implements Comparable.compare (via hashmap?)
// Time and Date lib

primitive LineReader
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

// what a waste of space!
class val Timestamp is (Comparable[Timestamp box] & Equatable[Timestamp box])
  let y: U16
  let m: U8
  let d: U8
  let h: U8
  let mm: U8

  new create(y': U16, m': U8, d': U8, h': U8, mm': U8) =>
    y = y'
    m = m'
    d = d'
    h = h'
    mm = mm'

  fun box string() : String =>
    "-".join([y;m;d;h;mm].values())
  fun box hash() : USize =>
    this.string().hash()

  fun lt(that: Timestamp box): Bool =>
    if y < that.y then
      return true
    end
    if y > that.y then
      return false
    else
      if m < that.m then
        return true
      end
      if m > that.m then
        return false
      else
        if d < that.d then
          return true
        end
        if d > that.d then
          return false
        else
          if h < that.h then
            return true
          end
          if h > that.h then
            return false
          else
            if mm < that.mm then
              return true
            else
              return false
            end      
          end      
        end      
      end      
    end

  fun eq(that: Timestamp box): Bool =>
    (y == that.y) and
    (m == that.m) and    
    (d == that.d) and    
    (h == that.h) and    
    (mm == that.mm)

  fun ne(that: Timestamp box): Bool => not eq(that)
  fun le(that: Timestamp box): Bool => lt(that) or eq(that)
  fun ge(that: Timestamp box): Bool => not lt(that)
  fun gt(that: Timestamp box): Bool => not le(that)

type Line is (Timestamp val, String val)

primitive Parser
  fun apply(str : String val) : Line ? =>
    // [1518-10-12 23:58] Guard #421 begins shift
    let ts = recover val Timestamp(
      str.trim(1,5).u16()?,
      str.trim(6,8).u8()?,
      str.trim(9,11).u8()?,
      str.trim(12,14).u8()?,
      str.trim(15,17).u8()?
    )
    end
    let chunks = str.split("]")

    (ts, recover val chunks(1)?.clone().>strip() end)
  fun extract_guard_id(str : String val) : (None | String) =>
    try
      str.split("#")(1)?.split(" ")(0)?
    end
  fun extract_state(str : String val) : (None | State) =>
    // String.contains is a safe method, refactor
    try
      str.find("wakes")?
      Awake
    else
      try
        str.find("asleep")?
        Asleep
      else
        None
      end
    end

primitive SortBy
  // todo extract to stdlib, accept function as a param
  // sort in place
  fun apply(a: Array[Line]): Array[Line] ? =>
    """
    Sort the given seq. in place
    """
    var hmap = Map[Timestamp val, String val](a.size())
    for item in a.values() do
      hmap.insert(item._1, item._2)?
    end

    var sorted_keys = Array[Timestamp val](hmap.size())
    Iter[Timestamp val](hmap.keys()).collect(sorted_keys)

    Sort[Array[Timestamp val], Timestamp](sorted_keys)

    var new_ary = Array[Line](a.size())
    for key in sorted_keys.values() do
      try
        // Debug("key: " + key.string())
        new_ary.push((key, hmap(key)?))
      else
        Debug("Cannot find val for key " + key.string())
      end
    end
    new_ary

primitive Awake
primitive Asleep
type State is (Awake | Asleep)

// Guard id, total slept, top asleep minute, most freq minute counter
type Result is (String val, U16 val, U16 val, U16 val)

actor Guard
  let _id : String
  let _asleep : Array[U16]
  
  var _state : State
  var _last_min : U8 = 0
  var _offset : U16 = 0
   
  new create(id : String val) =>
    _id = id
    _state = Awake
    _asleep = Array[U16](60) // per every minute
    // try
      for i in Range[USize](0,60) do
        _asleep.push(0)
      end
    // end
    try
      Assert(_asleep.size() == 60, "Improper array init, " + _asleep.size().string() + " vs 60")?
      Assert(_asleep(59)? == 0, "Improper array val at ndx of 59, " + _asleep(59)?.string() + " vs 0" )?
    end
  be accept_action(ts: Timestamp val, state: State) =>
    """
    Accept a note about asleep/awake changes, with time
    """
    try Assert(ts.h == 0, "Weird hour here: " + ts.string())? end
    // I assumed they are awake when shift starts and ends
    _maybe_reset(ts)

    match state
    | Awake =>
      _process_awake(ts)
    | Asleep =>
      _process_asleep(ts)
    end

  be report(p : Promise[Result val]) =>
    var best_minute : USize = 0
    try
      for i in Range(0,_asleep.size()) do
        if _asleep(i)? > _asleep(best_minute)? then
          best_minute = i
        end
      end
    else
      Debug("Iterating in a wrong way!")
    end
    let total_minutes : U16 = Iter[U16](_asleep.values()).fold[U16](0,
      {
        (mem, curr) =>
          mem + curr
      }
    )
    let most_freq_minute_cnt : U16 = Iter[U16](_asleep.values()).fold[U16](0,
      {
        // max
        (mem, curr) =>
          if mem < curr then
            curr
          else
            mem
          end
      }
    )
    p( (_id, total_minutes, best_minute.u16(), most_freq_minute_cnt) )
  
  fun ref _maybe_reset(ts : Timestamp) : None =>
    let offset = ts.y + ts.m.u16() + ts.d.u16()
    if offset > _offset then
      try Assert(_state is Awake, "Overslept the shift?")? end
      
      _offset = offset
      // reset stuff:
      _state = Awake // TODO fix, if slept till the end of the shift
      _last_min = 0
    end

  fun ref _process_asleep(ts : Timestamp) =>
    _last_min = ts.mm // start counting time as sleeping
    _state = Asleep
    
  fun ref _process_awake(ts : Timestamp) =>
    _state = Awake
    try
      _report_sleep_until(ts.mm)?
    else
      Debug("cannot update sleep time!")
    end

  // without minute of 'minute'
  fun ref _report_sleep_until(minute: U8) ? =>
    for curr_minute in Range[USize](_last_min.usize(), minute.usize()) do
      _asleep.update(curr_minute.usize(), 1 + _asleep(curr_minute)?)?
    end
