use "itertools"
use "collections"
use "debug"
use "../../common"


primitive Validator
  fun apply(num: String) : Bool =>
    var adj = false
    var dec = false
    
    for pos in Range[USize](1,num.size()) do
      try 
        if num(pos)? == num(pos-1)? then
          adj = true
        end
        if num(pos)? < num(pos-1)? then
          dec = true
        end
      end
      if adj and dec then
        break
      end
    end

    adj and not dec

primitive Validator2
  fun apply(num: String) : Bool =>
    var adj = false
    var dec = false
    let found = Set[U32].create()

    for pos in Range[USize](1,num.size()) do
      try 
        if num(pos)? == num(pos-1)? then
          found.set(num(pos)?.u32()) // if not present
          adj = true
        end
        if num(pos)? < num(pos-1)? then
          dec = true
        end
      end
      if adj then
        // group by nums and make sure there's at least one.
        let groupped = Iter[U8](num.values()).fold[Map[U32,U32]]( 
          Map[U32,U32].create(), 
          { 
            (map: Map[U32,U32], item: U8) : Map[U32,U32]^ =>
              map.upsert(item.u32(), 1, {(old, curr) => old + curr })
              map
          }
        )
        adj = Iter[U32](groupped.values()).any({ (x: U32) : Bool => x == 2})
      end
    end

    adj and not dec