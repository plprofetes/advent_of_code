use "files"
use "itertools"
use "collections"
use "debug"
use "promises"
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

primitive CountLetters
  // @param str string to analyze
  // @param count desired count
  // @return check if any letter occurs given number of times
  fun apply(str : String val, count : U8) : Bool => 
    try
      var hashmap = Map[U8,U8]() //store letters there as chars

      for letter in str.clone().values() do
        hashmap.upsert(letter, 1, {(ex, nw) => ex + nw})?
      end
      // for kv in hashmap.pairs() do
      //   Debug.out(String.from_utf32(kv._1.u32()) + ": " + kv._2.string())
      // end
      Iter[U8](hashmap.values()).any({(cnt) => cnt == count })
    else
      false
    end

primitive EditDist
  // simplified edit distance of two strings
  // @return how many letters differ? -1 on error
  fun apply(str1 : String val, str2 : String val) : U32 =>
    if \unlikely\ str1.size() != str2.size() then
      Debug.err("strings size mismatch: " + str1.clone() + " and " + str2.clone() )
    end
    try
      var diff_chars : U32 = 0
      for i in Range(0, str1.size()) do
        if str1(i)? != str2(i)? then
          diff_chars = diff_chars + 1
        end
      end
      diff_chars
    else
      -1
    end

actor PatternActor
  let length : U8
  var counter : U32 = 0
  
  // @param len - desired pattern length
  new create(len : U8) =>
    length = len
  
  be push(str : String val) =>
    if CountLetters(str ,length) then
      counter = counter + 1
    end
  be debug() =>
    Debug.out("There were " + counter.string() + " lines that matched " + length.string() + " same letters")
  be report_counter(p: Promise[U32]) =>
    p(counter)

actor EditDistActor
  let base : String val
  var best : String val
  var dist : U32 val

  new create(base' : String val) =>
    base = base'
    best = base'
    dist = base.size().u32()  // first incoming str will be better
  
  be accept(str : String val) =>
    // short circut if str > base, so no results are duplicated
    if str <= base then
      return
    end

    let dst = EditDist(str, base)
    // if \unlikely\ dst == 0 then 
    //   return // short circut for same string
    // end 
    
    if (dst < dist) and (dst > 0)  then
      best = str
      dist = dst
    end

  be debug() =>
    Debug.out("[" + base + "] matches with min of " + dist.string())

  // return answer string if matches. fail promise otherwise
  be report(p : Promise[String val]) =>
    if dist != 1 then
      p.reject()
    else
      // compute the answer
      try 
        var to_delete_ndx : ISize = -1
        for i in Range(0,best.size()) do
          if base(i)? != best(i)? then
            to_delete_ndx = i.isize()
            break
          end
        end
        // Debug.out("Tryin to report success")
        p(recover val best.clone().>delete(to_delete_ndx, 1) end)

      else
        Debug.err("Cannot produce result answer!")
        p.reject()
      end
    end

