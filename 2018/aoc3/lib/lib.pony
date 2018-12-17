use "files"
use "itertools"
use "collections"
use "debug"
use "promises"


type Point is (U32, U32)

// https://playground.ponylang.io/?gist=a987e67f6ae804cc256a47736704f459
// Does FileLines do the same?
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

primitive Parser
  // return a tuple (id, Patch)
  fun apply(str : String val) : (String val, Patch val) ? =>
    // #123 @ 3,2: 5x4
    let chunks = str.split(" ")
    let id = chunks(0)?
    // Debug.out("id: " + id.clone())
    let start_point = chunks(2)?.clone().>remove(":").split(",")
    // Debug.out("len of start_point: " + start_point.size().string())
    let size = chunks(3)?.split("x")
    // Debug.out("len of size: " + size.size().string())

    let p = recover val Patch(
      start_point(0)?.u32()?,
      start_point(1)?.u32()?,
      size(0)?.u32()?,
      size(1)?.u32()?) end
    (id, p)

class val Patch
  let x: U32
  let y: U32
  let w: U32
  let h: U32

  new create(x': U32, y': U32, w': U32, h': U32) =>
    x = x'
    y = y'
    w = w'
    h = h'
  
  fun box string() : String val =>
    // https://patterns.ponylang.io/performance/limiting-string-allocations.html
    "[" + x.string() +","+y.string() + " " + w.string() + "x" + h.string() + "]"
  
  // todo primitive
  fun _in_range(x': U32, min: U32, max: U32) : Bool =>
    (x' <= max) and (x' >= min)
  
  fun _inside_box(x': U32, y': U32) : Bool =>
    _in_range(x', x, x+w) and _in_range(y', y, y+h)

  fun _min(a: U32, b: U32): U32 =>
    if a > b then
      b
    else
      a
    end
  fun _max(a: U32, b: U32): U32 =>
    if a > b then
      a
    else
      b
    end
  
  fun box area() : U32 =>
    h*w

  // compute number of squares that are shared
  // https://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other
  fun box overlap(other: Patch box) : (Patch val | None) =>
    // short circut for overlapping, then exact result
    // A's Left Edge to left of B's right edge, [RectA.Left < RectB.Right], and
    // A's right edge to right of B's left edge, [RectA.Right > RectB.Left], and
    // A's top above B's bottom, [RectA.Top > RectB.Bottom], and
    // A's bottom below B's Top [RectA.Bottom < RectB.Top]
    if (x < (other.x + other.w)) and
      ((x + w) > other.x) and 
      (y < (other.y + other.h)) and
      ((y + h) > other.y) then
      let ux =  _max(x, other.x) // upper x coord
      let uy = _max(y, other.y)  // upper y coord
      var p = recover val Patch(ux, uy,
        _min(x+w, other.x + other.w) - ux, // coords to size. Must not be < 0 => underflow!
        _min(y+h, other.y + other.h) - uy
      )
      end
      // if p.area() > 1000 then
      //   Debug.out("invalid overlap of " + this.string() + " and " + other.string() + ": " + p.string())
      // end
      p
    else
      None
    end 

    fun box points() : Array[Point val] val =>
      recover val
        let ary = Array[Point]((h*w).usize())
        for i in Range[U32](0, w) do
          for j in Range[U32](0, h) do
            ary.push( (x+i, y+j) )
          end
        end
        ary
      end

// TODO put that in my stdlib with some trait defined on actor (HasResults?)
class iso Reporter is Fulfill[None,None]
  let wip: AOC1 tag
  let env: Env
  
  new create(env': Env, wip': AOC1 tag ) =>
    env = env'
    wip = wip'
  
  fun ref apply(_:None) : None => 
    let p = Promise[U64] 
    // p.next[None]( {(cnt) => Debug("There are " + cnt.string() +  " shared sq inches") })
    p.next[None]( {(cnt) => env.out.print("There are " + cnt.string() +  " shared sq inches") })
    wip.results(p)
    None

actor OverlapFuncActor
  let patch : Patch
  let sink : Sink

  new create(patch': Patch, sink':  Sink) =>
    patch = patch'
    sink = sink'

  be accept(other : Patch) =>
    match patch.overlap(other)
    | let x : Patch => 
      sink.report(x)
      // DO NOT SPLIT THIS INTO ZILLION OF MESSAGES
    // else
      // Debug("Not matched expr! It must be None!")
    end
  be is_done(p : Promise[None] ) =>
    p(None)

// report collisions here
// TODO rework, array of U32 is sufficient to hold just Ys
actor Sink
  let sq_inches: Map[U32, Array[Point val]] ref  // naiive approach, indexed by X for faster traversal

  new create() =>
    sq_inches = Map[U32, Array[Point val] ]

  // report idempotently each patch, store points internally do avoid 
  // counting the same sq inch twice
  be report(xy: Patch val) =>
    for p in xy.points().values() do
        // Debug("reporting point (" + p._1.string() + "," + p._2.string() + ")")
        _insert(p)
    end
  
  fun ref _insert(xy : Point val) : None =>
    try
      let ary = sq_inches(xy._1)?
      // Debug("Inspecting key " + xy._1.string() + " with " + ary.size().string() + " objects")
      try
        ary.find(xy where predicate = {(one: Point, two: Point) =>  one._2 == two._2  })? // _1 are the same for sure
        // already present
        // Debug("item already reported: (" + xy._1.string() + "," + xy._2.string() + ")" )
      else
        // Debug("item no such item yet: (" + xy._1.string() + "," + xy._2.string() + ")" )
        ary.push(xy)
      end
    else
      try
        // Debug("New key: " + xy._1.string())
        sq_inches.insert(xy._1, [xy] )?
      else
        Debug("Could not insert key into hash!")
      end
    end

    be points_count(p : Promise[U64]) =>
      var cnt : U64 = Iter[Array[Point val]](sq_inches.values()).fold[U64](0, {(mem, ary) => mem + ary.size().u64()})
      Debug("Countting the results: " + cnt.string())
      p(cnt)
    
actor AOC1
  let workers : List[OverlapFuncActor tag] ref
  let sink : Sink tag

  new create() =>  
    workers = List[OverlapFuncActor tag]()
    sink = Sink
  
  be results(p: Promise[U64]) =>
    sink.points_count(p)

  be work(lines : Array[String val] val, done: Promise[None]) => //Array[Promise[String val] tag] =>
    // let's solve the quiz
    for line in lines.values() do
      try
        (let id, let patch) = Parser(line)?
        // Debug("Processing " + id + " of " + patch.string())
        // notify everybody so far about new patch
        // since relation of overlapping is bidirectional - it will be done only once per each pair
        for worker in workers.values() do
          worker.accept(patch)
        end
        // register new worker
        workers.push(OverlapFuncActor(patch, sink))
      else
        Debug("Could not process line: " + line)
      end
    end
    Debug.out("Created " + workers.size().string() + " work actors")
    // TODO wait on actors to finish

    // ugly end, how to ask all the actors and pass fulfilled promises only?
    Promises[None].join(
      Iter[OverlapFuncActor](workers.values())
        .map[Promise[None]](
        { 
          (worker) => 
            var p = Promise[None]
            worker.is_done(p)
            p
        }
      )
    ).next[None]( { (x) => 
                      Debug("All workers are done.")
                      done(None) 
                  } )
