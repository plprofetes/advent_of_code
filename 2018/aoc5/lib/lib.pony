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

primitive Next
primitive Prev
type Sibling is (Next | Prev)

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
No sense in using actors at all, execept training of async double linked list pattern

*/
primitive Idle
primitive Reacting
primitive Reduced
type State is (Idle | Reacting | Reduced)


// TODO dont start with reaction? push reaction Tokens? And only those agents are allowed to look for pairs?
// intruduce _next_alive and _prev_alive to reduce message passing?
// react on NEXT after hello() - then nodes are not blocked by default.
//   try to react with hello as well? do not lock if letters are different?
// token can be "reaction energy" that gets consumed, triggers another. If original energy is not consumed == end
// do not increase number of reactions. Can I reduce it somehow?
// TODO: if no next - play wait() promise
actor Unit
  let _letter : String val

  var _state : State = Idle
  var _prev: (Unit tag | None) = None
  var _next: (Unit tag | None) = None
  var _finish_cb : (None | Promise[None]) = None // buggy, hook for when Unit is "done"
  var _pending_reaction: Bool = false // was there attempt on another reaction?

  fun ref debug(str: String = "") =>
    let state = match _state
    | Idle => "Idl"
    | Reacting => "Rea"
    | Reduced => "Red"
    end
    Debug("> " + _letter + " <(" + state + "): " + str)

  new create(l: String val, prev: (Unit tag | None) = None) =>
    _letter = l
    match prev
    | let pu : Unit => 
        _prev = pu
        pu.hello(this, _letter) // get acquainted
        // _state = Reacting
        // pu.try_react(_letter, ff_promise())
        // handle_pending_reaction()

    end
  
  fun ref ff_promise() : Promise[State] =>
    let p = Promise[State]
    p.next[None]( 
      recover this~_disable_me() end , // partial application
      {() =>
        _state = Idle
        Debug("rejected!")
      }) // end of list, become idle again
    p
  
  be handle_pending_reaction() =>
    if _pending_reaction then
      //debug("notify others")
      _pending_reaction = false
      // try (_prev as Unit).ping_from_right() end
      try
        (_next as Unit).ping_from_left(this)
      // else 
        //debug("no next to call!")
       end
    // else
      //debug("No pending reaction")
    end
    
  
  be hello(u: Unit tag, letter: String) =>
    debug("< Nice to meet you, " + letter + "!")
    _next = u
    if _pending_reaction or Reaction(_letter, letter) then
      // _state = Reacting
      // pu.try_react(_letter, ff_promise())
      // handle_pending_reaction()
      // debug("could react....")
      // if _state is Idle then
      u.ping_from_left(this)
    end

  be ping_again() =>
    try (_next as Unit).ping_from_left(this) end

  // prone to interleaving messages (try_react vs ping_from_left)?
  // add TTL, useful with 1
  be ping_from_left(src: Unit) =>
    // The only problem is that _next may not be known yet?
    // but it's not a problem - when there's no next - it will react on addition
    match _state
    | Reacting =>
      debug("impssible? old message? Try again?") 
      // when this reacting is done - react to the left, if still valid. Otherwise proxy it further?
      // called when waiting on callback after try_react
      // _pending_reaction = true // impossible? 
      // ping_from_left() // wait until more messages is consumed.
      _pending_reaction = true
    | Idle =>
      debug("got ping from the left")
      try 
        _state = Reacting // only if message sent
        (_prev as Unit).try_react(_letter, ff_promise()) 
      else
        // no prev
        _state = Idle
      end
    | Reduced =>
      //debug("passing ping from the left")
      // just pass? pass with TTL? 
      // Passing may not be required, since if reacting - it'll ping later. If Idle - not it's reacting.
      // when reduced - next one may be interested, especially if left side just got reduced.
      try (_next as Unit).ping_from_left(src) end // required?
    end
    

  // called on left reagent. callback on right one
  be try_react(l: String, p: Promise[State]) =>
    match _state
    | Reacting => // Please try again later. 
      //debug("try react by: " + l + ", but already reacting.")
      _pending_reaction = true // let us ping back when we're done reacting and not reduced.
      // this get accumulated on the left side and then falls to reduced right side. too many!
      p(Reacting) // did not react just yet.       
    | Idle =>  // cool. can procede
      //debug("reacting letters: " + _letter + " and " + l)
      _state = Reacting
      if Reaction(_letter, l) then
        Debug("reaction successful of " + _letter + " and " + l)
        // anihilate me and sender
        _state = Reduced
        _pending_reaction = false // callback of p will trigger next reaction, since it can only happend to the left.
        p(Reduced)
      else
        _state = Idle        
        p(Idle)
      end
      // convert to be? messages can be deduped!
      handle_pending_reaction() // if someone asked - try to answer. deduplicates multiple requests.
    | Reduced => // not active
      try // pass it further
        //debug("proxy letter " + l + " to the left")
        (_prev as Unit).try_react(l, p)
      else
        //debug("reached start?")
        p.reject()
        // special case
      end 
    end

    
 
  // hook for waiting until all data is added an processed
  be wait(p : Promise[None]) =>
      // _finish_cb = p
      p(None) // effectively - can be modelled as another message in inbox

  // dir: from which direction from this pov the request came. notify the other side!
  // right reagent
  be _disable_me(s : State) => // callback
    match _state
    | Idle => debug("WTF? not reacting")
    | Reduced => debug("double free!")
    | Reacting =>
      match s
      | Reduced =>
        debug("disable me: reduced")
        _state = Reduced
        // try 
          // (_next as Unit).ping_from_left(this) 
        // else
          _pending_reaction = true
        // end // go go go! new potential reaction after this one.
      | Idle =>
        //debug("disable me: idle")
        // meh, nothing changed
        _state = Idle
      | Reacting =>
        //debug("disable me: reacting")
        // that one was busy, wait to be touched with ping.
        _state = Idle
      end
      handle_pending_reaction()

      try // only last one. Warning, may occur earlier as false positive due to message processing.
        (_finish_cb as Promise[None])(None)
        _finish_cb = None
        Debug("Polymer got stabilized.")  
      end // polymer is now stable
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
      result.abort() // try again
      return
    end

    match _state
    | Reduced => None
    | Idle => result.append(_letter)
    | Reacting =>
      //debug("reporting on reacting polymer!")
      result.abort() // try again, once returned
      return // short circut.
    end
    
    match _next
    | let x : Unit =>
      x.report(consume result)
    | None =>
      result.commit()
    end
