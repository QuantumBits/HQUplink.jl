# HQUplink.jl
Calculate probabilities and roll dice in the Star Wars: Legion tabletop game!

To install, run the following command from the pkg interface in Julia:

```
pkg> add https://github.com/QuantumBits/HQUplink.jl
```

For example, if you'd like to roll Palpatine's Force Lightning ability, you first start by creating a `Weapon` object:

```julia
julia> force_lightning = Weapon([RA, RA, BA, BA, WA, WA], false, false, false, 0, 0)
```

Where the arguments are:

- Array of `AttackDice` types (`RA`, `BA`, and `WA` are red dice, black dice and white dice, respectively)
- Boolean for "spray" ability (not yet implemented)
- Boolean for "blast" ability (not yet implemented)
- Boolean for "high velocity" ability (not yet implemented)
- "Pierce X" value (not yet implemented)
- "Impact X" value (not yet implemented)

The next step is to create an attack pool using your weapon(s):

```julia
julia> palpatine = AttackPool([force_lightning], CRIT, 1, 0, 0)
```

Where the arguments are:

- Array of `Weapon` types (you may have any number of weapons in an attack pool)
- Surge type. For example, use `CRIT` for crits, `HIT` for hits, and `BLANK` for no surge.
- Number of "aim" tokens
- "Precise X" value
- "Sharpshooter X" value (not yet implemented)

Now you can do one of two things; roll an attack:

```julia
julia> roll(palpatine)
3-element Array{Int64,1}:
0
4
2
```

*or* you can get an expected value of such a roll (does not yet include Precise or aim tokens):

```julia
julia> EV(palpatine)
3-element Array{Rational{Int64},1}:
9//4
3//2
9//4
```