use "debug"
use "itertools"
use "promises"
use "collections"

class AOC2
  // TODO: field in this class is not required, so class does not need to be ref
  // How the fuck return one successful promise?
  
  let workers : List[EditDistActor tag] ref

  new create() =>  
    workers = List[EditDistActor tag]()
    // workers = recover ref List[EditDistActor tag]() end
  
  fun ref apply(lines : Array[String val]) : Array[Promise[String val] tag] =>

    // let's solve the quiz
    for line in lines.values() do
      workers.push(EditDistActor(line))
    end
    // Debug.out("Created " + workers.size().string() + " work actors")
    // and again. not optimized for short-circutting
    for line in lines.values() do
      for worker in workers.values() do
        worker.accept(line)
      end
    end

    // ugly end, how to ask all the actors and pass fulfilled promises only?
    let p = Array[Promise[String val]](workers.size())
    Iter[EditDistActor](workers.values())
      .map[Promise[String val]](
      { 
        (worker) => 
          var p = Promise[String val]
            // .next[(String val)]({(x) => x }) // filter succesful? consume at callee level?
          worker.report(p)
          p
      }
    ).collect(p)
    p
