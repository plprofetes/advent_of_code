use "debug"
use "itertools"
use "promises"

class AOC1
  // create 2 working agents and results via Promise
  
  let twos : PatternActor tag 
  let threes : PatternActor tag 

  new create() =>  
    twos = PatternActor(2)
    threes = PatternActor(3)
  
  fun apply(lines : Iter[String val]) : Promise[U32 val] tag =>
    // let's solve the quiz
    for line in lines do
      twos.push(line)
      threes.push(line)
    end

    twos.debug()
    threes.debug()

    let prom2 = Promise[U32]
    let prom3 = Promise[U32]

    let pp = Promises[U32].join([prom2; prom3].values())
      .next[U32]( { 
        (vals : Array[U32 val] val) => 
          Iter[U32](vals.values()).fold[U32](1, {
            (mem, v) => 
            Debug("v:" + v.string())
            mem * v 
          })
      })

    twos.report_counter(prom2)
    threes.report_counter(prom3)    
    pp
