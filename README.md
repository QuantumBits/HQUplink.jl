# HQUplink.jl
Calculate probabilities and roll dice in the Star Wars: Legion tabletop game!

To install, run the following command from the pkg interface in Julia:

```
pkg> add https://github.com/QuantumBits/HQUplink.jl
```

For example, if you'd like to roll Palpatine's Force Lightning ability, you first start by creating a `Weapon` object:

```julia
julia> force_lightning = Weapon([RA, RA, BA, BA, WA, WA], false, false, false, 0, 0, [0,2])
```

...where the arguments are:

- Array of `AttackDice` types (`RA`, `BA`, and `WA` are red dice, black dice and white dice, respectively)
- Boolean for "spray" keyword (not yet implemented)
- Boolean for "blast" keyword (not yet implemented for EV)
- Boolean for "high velocity" keyword (not yet implemented for EV)
- "Pierce X" keyword value (not yet implemented for EV)
- "Impact X" keyword value (not yet implemented for EV)
- Weapon range [min, max] (not yet implemented)

The next step is to create an attack pool using your weapon(s):

```julia
julia> palpatine = AttackPool([force_lightning], CRIT, 1, 0, 0)
```

...where the arguments are:

- Array of `Weapon` types (you may have any number of weapons in an attack pool)
- Surge type. For example, use `CRIT` for crits, `HIT` for hits, and `BLANK` for no surge.
- Number of "aim" tokens
- "Precise X" value
- "Sharpshooter X" value (not yet implemented)

Next you'll want to create your defender (not yet implemented for EV). For example, Han Solo:

```julia
julia> hansolo = DefenseDice(WD, 0, BLOCK, 1, false, false, false, false, true, 3, 1)
```

...where the arguments are:

- Type of defense die (i.e. RD or "Red Defense", WD or "White Defense")
- "Cover X" keyword value (e.g. see Snowspeeder)
- Surge type (i.e. NONE or BLOCK)
- Number of dodge tokens to use
- Boolean for "armor" keyword
- Boolean for "impervious" keyword
- Boolean for "immune to pierce" keyword
- Boolean for "deflect" keyword
- Boolean for "low profile" keyword
- "Uncanny Luck X" keyword value
- Number of minis in the unit

Now you can do one of two things; roll an attack against your defender with cover to get the total number of wounds inflicted:

```julia
julia> mean([ roll(palpatine, hansolo, LIGHT) for i in 1:100_000 ])
1.00208
```

*or* you can get an expected value of your Attack Pool:

```julia
julia> EV(palpatine)
3-element Array{Rational{Int64},1}:
9//4
3//2
9//4
```