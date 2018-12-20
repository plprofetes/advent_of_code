use "lib"

use "itertools"
use "collections"
use "debug"
use "promises"

actor Main
  let env : Env
  var actorLedger : Map[String val, Guard tag] ref

  new create(env': Env) =>
    env = env'
    actorLedger = Map[String val, Guard tag]()

    let sorted = try
      // let lines = LineReader(env.root as AmbientAuth, "in.1.txt" )
      let lines = LineReader(env.root as AmbientAuth, "in.txt" )
      let parsed_lines = Array[Line](lines.size())
      for line in Iter[String](lines.values()).map[(Line|None)]({
        (x) => 
        try
          Parser(x)?
        else
          Debug("Cannot parse line " + x)
        end
      }) do
        match line
        | let l : Line => parsed_lines.push(l)
        end
      end
      Debug("Ate file with " + parsed_lines.size().string() + " lines.")
      // that was complicated, shit!
      try
        SortBy(parsed_lines)?
      else
        Array[Line]()
      end
    else
      "Cannot init computations. Exitting"
      return
    end

    // for line in sorted.values() do
    //   Debug("\t" + line._1.string() + ": " + line._2.string())
    // end
    try 
      // Debug("first line: " + sorted(0)?._2)
      var curr_agent = get_or_create_agent(Parser.extract_guard_id(sorted(0)?._2) as String )
      for l in sorted.values() do
        (let ts, let str) = l
        try
          var gid = Parser.extract_guard_id(str) as String
          curr_agent = get_or_create_agent(gid)
        else
          // there was no info in the line about guard
          var state = Parser.extract_state(str)
          match state
          | let s : Awake => curr_agent.accept_action(ts, s)
          | let s : Asleep => curr_agent.accept_action(ts, s)
          else
            Debug("Cannot process line:" + str)
          end
        end
      end
    else
      Debug("Cannot process lines.")
      return
    end

    // promise agents to return their best
    Promises[Result val].join(
      Iter[Guard](actorLedger.values()).map[Promise[Result val]](
        { 
          (worker) => 
            var p = Promise[Result val]
            worker.report(p)
            p
        }
      )
    ).next[None]( {
      (x : Array[Result val] val) => 
        Debug("All done, computing the final results from " + x.size().string() + " actors:")
        let max_total_slept = Iter[Result](x.values()).fold[Result]( ("fake", 0, 0, 0), {
          (mem, res) => // min lambda, extract to stdlib as MinBy[A: Array[B], f: {a : A} : B^]
            
            Debug(
              "\tGuard " + res._1 + 
              " slept the most (" + res._2.string() + " minutes)" + 
              ", top at " + res._3.string() + " or " + res._4.string() + "."
            )

            if res._2 > mem._2 then
              res
            else
              mem
            end
        })
        let most_freq_min = Iter[Result](x.values()).fold[Result]( ("fake", 0, 0, 0), {
          (mem, res) => // min lambda, extract to stdlib as MinBy[A: Array[B], f: {a : A} : B^]
            
            if res._4 > mem._4 then
              res
            else
              mem
            end
        })
        Debug(
          "Guard " + max_total_slept._1 + 
          " slept the most (" + max_total_slept._2.string() + " minutes)" + 
          ", top at " + max_total_slept._3.string() + "."
        )
        Debug(
          "Guard " + most_freq_min._1 + 
          " slept the most (" + most_freq_min._2.string() + " minutes)" + 
          ", top at " + most_freq_min._3.string() + "."
        )
          // TODO call proper method of Main with result to the quiz
        try
          // TODO: why no autocast to string?
          Debug("Part 1 answer = " + (max_total_slept._1.u32()? * max_total_slept._3.u32()).string())
          Debug("Part 2 answer = " + (most_freq_min._1.u32()? * most_freq_min._3.u32()).string())
        else
          Debug("Error! Cannot print results!")
        end
      })

    fun ref get_or_create_agent(id : String val) : Guard tag =>
      try
        actorLedger(id)?
      else
        let guard = Guard(id)
        try actorLedger.insert(id,guard)? end
        guard
      end