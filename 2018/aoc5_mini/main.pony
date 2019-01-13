use "itertools"
use "collections"
use "promises"

use @puts[I32](str: Pointer[U8] tag)
use @sleep[U32](seconds: U32)

// mini case
// spawn actors that accept a optional Promise. actors can be notified to negotiate minimum. only local minimums compare further
// spawn a lot
// report via promise or not => bug happens here?

// CONFIG:
primitive Coords
  fun apply() : U32 => 100000 // with 3GB of ram 200000x10 is enough the get killed by OOM
primitive Noops
  fun apply() : U32 => 1

actor Noop
  """
  No operation actor, just to see if it get GCed.
  When done - let Coordinator know by sending a message.
  """
  let _s : String
  let _e : Env
  let _c : Coordinator

  new create(e: Env, s: String, c : Coordinator) =>
    _s = s
    _e = e
    _c = c
  be ssize() =>
    """
    The only behavior, called once in a lifetime of that actor.
    """
    // _e.out.print(_s + " is size of " + _s.size().string()) // fake work
    _c.signal_done()  // nothing else ever happens after that.
  
  // this generates a lot of output, let's have that commented out.
  // fun _final() =>
  //   @puts("GCing Noop".cstring())

actor Coordinator
"""
 Spawn a few actors, collect results by receiving signal_done() messages.
 When all Noop sub-actors are done - report success via promise given in the constructor.
 Then it can get GCed, since nothing ever happens.
""" 
  let _env : Env
  // let _cnt : U32 = 100 // number of Noops to spawn
  let _cb : (Promise[Bool] | None)  // call this when done
  let _id : U32 // for display purposes
  var _done : U32 = 0 // counter of completed sub-actors
  
  new create(env: Env, id : U32, cb : (Promise[Bool] | None) = None) =>
    _env = env
    _id = id
    _cb = cb

    for i in Range[U32](0,Noops()) do
      let n = Noop(env, "Noop no " + i.string(), this)  // no reference to Noop is kept. Noop has one to this.
      n.ssize()
    end
  fun _final() =>
    @puts(("GCing Coordinator " + _id.string()).cstring())

  be signal_done() =>
    """
      Explicit way to collect the results from Noops created earlier.
    """
    _done = _done + 1
    if _done == Noops() then
      // _env.out.print("Coordinator " + _id.string() + " is complete")
      match _cb
      | let p : Promise[Bool] => p(true)  // last thing ever done here. Should be GCed?
      end
    end

actor Main
  """
    Run with --ponygcinitial 1 --ponygcfactor 1
    Test cases (C=Coordinators, N=Noops)
    Cycle size is 1 Coordinator + N*Noops + 1 Promise = N + 2 actors.
      * 10C x 1N = 10 cycles of 3 actors      => gets GCed (always)
      * 10C x 10N = 10 cycles of 12 actors    => gets GCed (most of the time)
      * 10C x 100N = 10 cycles of 102 actors  => does not get GCed
      * 100C x 10N = 100 cycles of 12 actors  => does not get GCed
    NOTE: All GC is ever done AFTER message "Done: \d+ jobs(...)".
  """
  let env: Env
  let _jobs : Array[Promise[Bool]]
  let _cnt : U32 = Coords() 

  new create(env': Env) =>
    env = env'
    _jobs = Array[Promise[Bool]](_cnt.usize())  // this is the reason no Coordinator can ever be GCed?
    env.out.print("Hello, let's spawn lots of actors(" + _cnt.string() + ") with many Noops(" + Noops().string() + ")")
    env.out.print("That's " + Coords().string() + " cycles, each with " + (Noops() + 2).string() + " actors.")

    if true then // with promises      
      for i in Range[U32](0,_cnt) do
        let p = Promise[Bool]
        _jobs.push(p)
        Coordinator(env, i, p)  // no reference hold explicitly, implicit via promise
        None  // explicit none as returned value
      end

      let all_done = Promises[Bool].join(_jobs.values())
      all_done.next[None]( { 
        // do we really need to keep Coordinators alive until now?
        // Messages are one-way, so even if I have a promise - I cannot contact the sender.
        (jobs : Array[Bool val] val) => 
          env.out.print("Fake work is done: " + jobs.size().string() + " jobs. Nothing at all should stop GC from working.")
      })

    else
      for i in Range[U32](0,_cnt) do
        Coordinator(env, i)  // no reference hold explicitly, no promise
        None  // explicit none as returned value
      end
      // now wait 10 sec for any GC...
    end

    _done() // let scheduler work

  be _done() =>
    """ 
      Fake delay to let GC work and find cycles. 
      At some point all_done is fulfilled, maybe then GC can work?
    """
    env.out.print("Main is sleeping for 10 secs. Should see some GC now?")
    @sleep(10)
    env.out.print("^------ Sleep is over. Was there any GC before? Next ones are caused by mass GCing before exit.")
    // Messages there indicate mass GCing before exit.
