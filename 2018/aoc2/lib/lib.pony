use "files"
use "itertools"
use "collections"
use "debug"
use "promises"
// Does FileLines do the same?
primitive LineReader
  fun apply(auth: AmbientAuth, path': String) : Iter[String val] =>
    try
      let path = FilePath(auth, path')?
      let f = OpenFile(path) as File
      let contents = f.read_string(f.size())
      Iter[String](contents.split("\n").values()).map[String]( { (l) => l.clone().>strip()  } )
    else
      // logger. error
      Iter[String]([].values())
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