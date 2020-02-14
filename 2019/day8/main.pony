use "../common"

use "itertools"
use "collections"
use "buffered"
use "debug"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    let only_line : String = try 
      let strings = FileToStrings(env.root as AmbientAuth, "in1.txt")
      strings(0)?
    else
      env.out.print("Error in processing parts")
      return
    end

    let rb = Reader
    rb.append(only_line.clone()) // implicit consume

    let pixels: Array[U8] val = recover val
      let a : Array[U8] trn = recover trn Array[U8].create(rb.size()) end
      for i in Range[U32](0,rb.size().u32()) do
        try a.push(rb.u8()? - 48) else break end
      end
      a
    end
    Debug("pixels size: " + pixels.size().string())

    let width: U8 = 25
    let height: U8 = 6
    let size: USize = (width * height).usize()
    let layer_count = pixels.size() / size
    let layers = recover ref Array[Array[U8] val].create(layer_count) end
    for i in Range[USize](0,layer_count.usize()) do
      layers.push(pixels.trim(i * size, (i+1) * size))
    end

    Debug("There are layers: " + layers.size().string())
    var zeros : U8 = 200
    var layer_ndx : USize = 0

    for i in Range[USize](0,layer_count) do
      try
        let l =  layers(i)?
        // Debug(l)
        let z = Iter[U8](l.values()).fold[U8](0, { (sum, x) : U8 => 
          if x == 0 then 
            sum + 1
          else
            sum 
          end
        })
        Debug("there are " + z.string() + " zeros on layer " + i.string() )
        if z < zeros then
          zeros = z
          layer_ndx = i
        end
      else Debug("Could not fetch layer " + i.string())
      end
    end
    try 
      let l = layers(layer_ndx)?
      // TODO: optimize for 1 pass
      let o = Iter[U8](l.values()).fold[U8](0, { (sum, x) : U8 => 
          if x == 1 then 
            sum + 1
          else
            sum 
          end
        })
      // TODO: implement Iter2 with: min, max, group, count, accepting lambdas.
      let t = Iter[U8](l.values()).fold[U8](0, { (sum, x) : U8 => 
        if x == 2 then 
          sum + 1
        else
          sum 
        end
      })
      env.out.print("Part1, layer: " + layer_ndx.string() + ": "  + (o.u32() * t.u32()).string())
    else
      Debug("could not solve that.")
    end

    let img : Array[String] trn = recover trn Array[String].init("!", size) end
    for x in Range[USize](0,  size) do
      var computed_pixel = "!"
      try 
        for l in layers.values() do
          let px = l(x)?
          // if px == 2 then continue end
          if px == 0 then computed_pixel = " "; break end
          if px == 1 then computed_pixel = "#"; break end
        end
        img.update(x,computed_pixel)?
      end
    end
    let img2 : Array[String] val = consume img
    env.out.print("Part2:")
    for i in Range[USize](0, height.usize()) do
      env.out.print("".join( img2.trim(i * width.usize(), (i+1)*width.usize()).values() ))
    end

