use "debug"
use "files"
use "itertools"

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