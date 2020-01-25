primitive FuelCounter
  fun apply(mass: U32) : U32 => 
    ((mass / 3 ).f32().floor() - 2).u32()

primitive BetterFuelCounter
  fun apply(mass: U32, fuel': U32 = 0) : U32 =>
    let fuel = FuelCounter(mass + fuel')
    if fuel > 0 then
      fuel + BetterFuelCounter(0, fuel)
    else
      if fuel' == 0 then 0 else mass end
    end
  