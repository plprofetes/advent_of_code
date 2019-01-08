use "files"
use "itertools"
use "assert"
use "debug"
use "collections"
use "promises"
use "buffered"

primitive LineReader
  fun apply(auth: AmbientAuth, path': String) : Reader iso^ =>
    let rb = Reader
    try
      let path = FilePath(auth, path')?
      let f = OpenFile(path) as File
      rb.append(f.read_string(f.size()))
    else
      // logger. error
      Debug("Could not initialize reader for file " + path')
    end
    rb
primitive LineReaderWithFilter
  fun apply(auth: AmbientAuth, path': String, filter: String) : Reader iso^ => 
    
    let rb = Reader
    try
      let path = FilePath(auth, path')?
      let f = OpenFile(path) as File

      let l1 = recover val String.from_utf32(filter(0)?.u32()) end
      let l2 = recover val String.from_utf32(filter(0)?.u32() - 32) end
      let reduced = recover val f.read_string(f.size()).>remove(l1).>remove(l2) end
      Debug("reading for " + filter + ". Reduced from " + f.size().string() + " to " + reduced.size().string() + " by removing " + l1 + " and " + l2)
      
      rb.append(reduced)
    else
      // logger. error
      Debug("Could not initialize reader for file " + path')
    end
    rb

class ref Decoder is Iterator[String]
  var _has_next : Bool = true
  let _r : Reader ref
  
  new create(r: Reader iso) =>
    _r = consume r

  fun ref has_next() : Bool =>
    _has_next

  fun ref next() : String =>
    let str = try 
      String.from_array(_r.block(1)?)
    else
      Debug("Could not read from reader!!") 
      ""
    end
    _has_next = _r.size() > 0
    str

class iso Result
  let _p : Promise[String]
  var _s : String iso

  new create(p: Promise[String]) =>
    _p = p
    _s = recover iso String(100) end

  fun ref append(str : String val) =>
    _s.append(str)

  fun ref commit() => // aka fulfill
    // polymer is reverse single-linked list, hence reverse
    // _p(_s.clone().reverse())
    _p(_s.clone())
  
  fun ref abort() => // aka reject
    _p.reject()

class iso StdOutReporter is Fulfill[String,None]
  let env: Env
  let prefix : String

  new create(env': Env, prefix': String) =>
    env = env'
    prefix = prefix'

  fun ref apply(res : String val) : None => 
    env.out.print(prefix + " " + res)
    None

primitive Reaction
  fun apply(left : String, right : String) : Bool =>
    try
      let mine = left(0)?
      let theirs = right(0)?
      if mine > theirs then
        (mine - theirs) == 32
      else
        (theirs - mine) == 32
      end
    else
      false
    end
primitive Skip
  fun apply(filter : String, tested : String) : Bool =>
    try
      let l1 = filter(0)?
      let l2 = l1 + 32
      let t1 = tested(0)?
      (t1 == l1) or (t1 == l2)
    else
      false
    end

primitive Next
primitive Prev
type Sibling is (Next | Prev)

actor ReactionWatcher
  var _current_reactions: U64 = 0
  var _reporting : Bool = false
  var _report_queued : Bool = false
  let _debug : Bool = false

  let _lambda_on_zero: {(Promise[Bool])} val

  new create(fn: {(Promise[Bool])} val) =>
    _lambda_on_zero = fn

  be inc() =>
    if _debug then Debug("++(" + _current_reactions.string() + ")") end
    _current_reactions = _current_reactions + 1
  
  be dec() =>
    if _debug then Debug("--(" + _current_reactions.string() + ")") end
    if _current_reactions == 0 then
      Debug("!! less then zero!")
    else
      _current_reactions = _current_reactions - 1
      if _current_reactions == 0 then
        _double_check() // forces actor to consume the rest of the incoming messages
        // if that's really 0 - next beh will be called immediately
      end
    end
   
  be _double_check() =>
    // check again, something could change!
    if _current_reactions == 0 then
      if _reporting then
        _report_queued = true
      else
        _reporting = true
        let p = Promise[Bool]
        p.next[None](recover this~_stopped_querying() end)
        _lambda_on_zero(p)
        _report_queued = false
      end
    else
      if _debug then Debug("fn call saved!") end
    end

  be _stopped_querying(b : Bool) =>
    if _report_queued then
      _double_check()
    end
    _reporting = false


// double linked list made of actors that organize themselves?
// how to implement reduction so agent can disappear?
// remember to have initiating actor, that's all that we need.
// any change on siblings triggers potential reactions

// So:
/*
AbB - triggers reaction, so when another letter is added it will link to the B, 
      when handshaking it should redirect to A
A__a - when adding - discover next left - pass message until something active is met. 
        Try reaction in the same action
____D - init message gets transferred to the left without effect

When adding letter by letter at most 1 reaction can be triggered.

*/
primitive Idle
primitive Reacting
primitive Reduced
type State is (Idle | Reacting | Reduced)


// TODO dont start with reaction? push reaction Tokens? And only those agents are allowed to look for pairs?
// introduce _next_alive and _prev_alive to reduce message passing?
// react on NEXT after hello() - then nodes are not blocked by default.
//   try to react with hello as well? do not lock if letters are different?
// token can be "reaction energy" that gets consumed, triggers another. If original energy is not consumed == end
// do not increase number of reactions. Can I reduce it somehow?
primitive LastUnit // last unit
actor Unit
  let _letter : String val
  let _watcher : ReactionWatcher

  var _state : State = Idle
  var _prev: (Unit tag | None) = None
  var _next: (Unit tag | LastUnit | None) = None
  var _pending_reaction : Bool = false // try_react got called when busy
  var _pinged_from_left : Bool = false // something got reduced on the left. try react!

  fun ref debug(str: String = "") =>
    let state = match _state
    | Idle => "Idl"
    | Reacting => "Rea"
    | Reduced => "Red"
    end
    // Debug("> " + _letter + " <(" + state + "): " + str)
    

  // a promise to call disable_me() as reaction callback  
  fun ref ff_promise() : Promise[State] =>
    let p = Promise[State]
    p.next[None]( 
      recover this~_disable_me() end , // partial application
      {()(_l = _letter) =>
      /* // Lambda catches vars on create? what is _state? a copy? Cannot set vals from lambda, must use behs!
        _state = Idle
        _watcher.dec()
      */
        Debug("! rejected but buggy " + _l)
      }) // end of list, become idle again
    p

  new create(l: String val, w: ReactionWatcher, prev: (Unit tag | None) = None) =>
    _letter = l
    _watcher = w
    match prev
    | let pu : Unit => 
        _prev = pu
        pu.hello(this, _letter) // get acquainted
    end

  new end_node(l: String val, w: ReactionWatcher, prev: (Unit tag | None) = None) =>
    _letter = l
    _watcher = w
    _next = LastUnit
    match prev
    | let pu : Unit => 
        _prev = pu
        pu.hello(this, _letter) // get acquainted
    end
  
  // let following nodes know that there may be something new to react on, if they tried to the left
  be handle_pending_reaction() =>
    if _state is Reacting then
      // debug("messaging while reacting!")
      return
    end
    if _pending_reaction then // try_react was called! notify forward
      // debug("notify others")
      match _next
      | let n : Unit =>
        _pending_reaction = false
        n.ping_from_left(this)
      | None =>
        debug("no next to call yet!")
        // do not clear the flag, will be handled after hello is received
      | LastUnit =>
        _pending_reaction = false
        debug("end of the list!")
      end
    end
    if _pinged_from_left then // some reaction requested, when busy
      _pinged_from_left = false
      if _state is Idle then
        // wrap this in state change!
        try //just react already!
          _state = Reacting // only if message sent
          _watcher.inc()
          (_prev as Unit).try_react(_letter, ff_promise())
          // dec is done in the callback 
        else
          // no prev - first node
          _state = Idle
          _watcher.dec()
        end
      end
      // if Reduced - ping from the left?
    end

  // _next actor says hello to his _prev one.  
  // TODO delayed hello stops polymerization
  // first be called on an actor may not be this one,
  // so when finally is - apply the changes that were computed when reacting
  // don't delay the reaction if possible
  be hello(u: Unit tag, letter: String) =>
    debug("< Nice to meet you, " + letter + "!")
    _next = u

    match _state
    | Reacting => 
      // do not test for reaction, let the other side do that
      _pending_reaction = true
    | Idle => 
      // if someone already asked, or potential reaction -
      if Reaction(_letter, letter) then
        u.ping_from_left(this) // react with me, plz!
       _pending_reaction = false
      else
        // if there was some rq earlier
        handle_pending_reaction()
      end
    | Reduced => 
      debug("Already reduced, do try further left")
      // hello delivered after this one reacted. 
      // so there may be a node to react further, if not notified by u, earlier
      // u.ping_from_left(this)  
      // _pending_reaction = false
      handle_pending_reaction()
    end

  be ping_from_left(src: Unit) =>
    // WARNING: quite possible it gets called before hello(). Behave accordingly!
    // The only problem is that _next may not be known yet?
    // but it's not a problem - when there's no next - it will react with left part of polymer
    match _state
    | Reacting =>
      // debug("impossible? old message? Try again?") 
      // when this reacting is done - react to the left, if still valid. Otherwise proxy it further?
      // may be called when there are cCcCcC combinations, 
      // called when waiting on callback after try_react
      _pinged_from_left = true
    | Idle =>
      // debug("got ping from the left")
      match _next
      | None => 
        debug("React before there's _next. React.") 
        // handle this on callback, can safely react now
      | LastUnit =>
        debug("idle end node pinged from the left")
        // let's react, since someone is asking
      else
        None
      end
      try //just react already!
        _state = Reacting // only if message sent
        _watcher.inc()
        (_prev as Unit).try_react(_letter, ff_promise())
        // dec is done in the callback 
      else
        // no prev - first node
        _state = Idle
        _watcher.dec()
      end
    | Reduced =>
      // debug("passing ping from the left")
      // just pass? pass with TTL? 
      // when reduced - next one may be interested, especially if left side just got reduced.
      // async stuff, _next may not be present yet
      match _next
      | let n : Unit =>
        n.ping_from_left(src) // optimistic scenario
      | LastUnit =>
        debug("no node to pass further")
        None  // no one to pass further
      | None =>
        debug("No next yet!!")
        _pending_reaction = true  // ping when hello is fulfilled
      end
    end
    // handle_pending_reaction() // too many tries? reduce this one?
  
  // called on left reagent. callback p on right one
  // is it guaranteed, that there's full patch to the nexts?
  be try_react(l: String, p: Promise[State]) =>
    if _next is None then
      debug("Try_react, but no next?")
    end
    match _state
    | Reacting => // Please try again later. 
      //debug("try react by: " + l + ", but already reacting.")
      _pending_reaction = true // let us ping back when we're done reacting and not reduced.
      // this get accumulated on the left side and then falls to reduced right side. too many!
      p(Reacting) // did not react just yet.       
    | Idle =>  // cool. can precede
      //debug("reacting letters: " + _letter + " and " + l)
      _state = Reacting
      _watcher.inc()
      if Reaction(_letter, l) then
        // debug("reaction successful of " + _letter + " and " + l)
        // annihilate me and sender
        _state = Reduced
        _pending_reaction = false // callback of p will trigger next reaction, since it can only happened from right to the left.
        p(Reduced)
      else
        _state = Idle
        p(Idle)
      end
      // convert to be? messages can be deduped!
      handle_pending_reaction() // if someone asked - try to answer. deduplicates multiple requests.
      _watcher.dec()
    | Reduced => // not active
      try // pass it further
        if _next is None then
          debug("RED ALERT!")
        end
        // Attention, may pass obsolete try_react if in the meantime src node got reduced.
        // debug("proxy letter " + l + " to the left, looking for reaction")
        (_prev as Unit).try_react(l, p)
      else
        // special case
        debug("reached start? tried to react with " + l)
        // p.reject()
        p(Idle)
      end 
    end

  // callback for right reagent
  // @param s [State] resolution of the reaction
  be _disable_me(s : State) => // callback
    if _next is None then
      debug("disable_me, but no next?")
      _pending_reaction = true
    end
    match _state
    | Idle => 
      debug("WTF? not reacting")
    | Reduced => 
      debug("double free!")
    | Reacting =>
      match s
      | Reduced =>
        // debug("disable me: reduced")
        _state = Reduced
        _pending_reaction = true
        // end // go go go! new potential reaction after this one.
      | Idle =>
        //debug("disable me: idle")
        // meh, nothing changed. maybe react if someone pinged from the left
        _state = Idle
      | Reacting =>
        //debug("disable me: reacting")
        // that one was busy, wait to be touched with ping.
        _state = Idle
      end
      _watcher.dec()
      handle_pending_reaction()
    end

  be report(res : Result iso) =>
    """
      fulfill or pass to the next
    """
    let result = consume res
    
    if (_state is Reacting) or _pending_reaction then
      // //debug("reporting on reacting polymer!")
      // report(consume result)
      // return // infinite loop - something was not reacted fully!
      // save report and send it again? can polymer on the right change again? YES!
      debug("I'm still reacting!!")
      result.abort() // try again
      return
    end

    match _state
    | Reduced => None
    | Idle => result.append(_letter)
    | Reacting =>
      //debug("reporting on reacting polymer!")
      result.abort() // try again, once returned
      return // short circuit.
    end
    
    match _next
    | let x : Unit =>
      x.report(consume result)
    | let x : LastUnit =>
      result.commit()
    | None =>
      debug("reporting, but no next received at all! Abort reporting.")
      result.abort()
    end




 // as Main, but standalone
 actor LetterFilter
  let env : Env
  var tries : U32 = 0
  var polymer: (Unit | None) = None  // start of the polymer
  let _letter : String val
  
  new create(env': Env, filter: String val, length_promise : Promise[U32]) =>
    env = env'
    _letter = filter

    let reader = try
      //  LineReaderWithFilter(env.root as AmbientAuth, "in.1.txt", filter )
       LineReaderWithFilter(env.root as AmbientAuth, "in.txt", filter )
    else
      Debug("Cannot read from input file. Exitting!")
      return
    end

    let d = Decoder(consume reader)
    let w = ReactionWatcher(recover val this~_finish_and_report2(filter, length_promise) end)

    let poly = Unit(d.next(), w)
    polymer = poly
    var last = poly
    for letter in d do
      // create new Unit
      let u = if d.has_next() then
        Unit(letter, w, last)
      else
        Unit.end_node(letter, w, last)
      end
      last = u
    end

  be _finish_and_report2(letter: String, length_promise: Promise[U32], cb : Promise[Bool]) =>

    let unit = try polymer as Unit else return end

    tries = tries + 1
    if tries > 200 then
      env.err.print("Error, too many attempts!")
      return
    end

    let p = Promise[String]
    p.next[None](
      {(str : String val) => 
        cb(true)

        length_promise(str.size().u32())
        env.out.print("Partial result for " + letter + ", length: " + str.size().string())
      },
      {() => 
        // Debug("Part2 rejected. Try again?")
        cb(false) // notify Watcher to try again
      }
    )

    let result_token = recover iso Result(p) end
    unit.report(consume result_token)
