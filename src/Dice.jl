using StatsBase

export BLANK, HIT, CRIT, BLOCK
export NONE, LIGHT, HEAVY
export AttackDie, DefendDie, Weapon, AttackPool, DefenseDice
export RA, BA, WA, RD, WD, AAD, ADD
export dice, result, modCover
export spray, blast, highVelocity, pierce, impact, range

import Base.+
import Base.-

abstract type DieFace end

abstract type BLANK <: DieFace end
abstract type HIT <: DieFace end
abstract type CRIT <: DieFace end
abstract type BLOCK <: DieFace end

abstract type COVER end
abstract type NONE <: COVER end
abstract type LIGHT <: COVER end
abstract type HEAVY <: COVER end

const COVERS = [NONE, LIGHT, HEAVY]

function +(::Type{T}, y::Int) where {T<:COVER}
    i = findfirst(f->f==T, COVERS)
    i = y > 0 ? min(3, i + y) : max(1, i + y)
    return COVERS[i]
end

function -(y::Int, ::Type{T}) where {T<:COVER}
    i = findfirst(f->f==T, COVERS)
    return max(0, y - (i-1))
end


struct AttackDie
    hit::Int                # Number of hit symbols
    crit::Int               # Number of crit symbols
    surge::Int              # Number of surge symbols
    blank::Int              # Number of blank sides
end

struct DefendDie
    block::Int              # Number of block symbols
    surge::Int              # Number of surge symbols
    blank::Int              # Number of blank sides
end

const RA = AttackDie(5,1,1,1)
const BA = AttackDie(3,1,1,3)
const WA = AttackDie(1,1,1,5)

const AAD = [RA, BA, WA] # All Attack Dice

const RD = DefendDie(3,1,2)
const WD = DefendDie(1,1,4)

const ADD = [RD, WD] # All Defense Dice

struct Weapon
    dice::Vector{AttackDie} # List of attack dice
    spray::Bool             # If true, multiply no. of dice by no. of minis in defending unit
    blast::Bool             # If true, ignore defender's cover
    highVelocity::Bool      # If true, defender cannot spend dodge tokens
    pierce::Int             # Pierce <X> value (may cancel up to <X> BLOCK results on defender's dice)
    impact::Int             # Impact <X> value (up to <X> HIT results are not cancelled by Armor keyword)
    range::Vector{Int}      # [min , max] range values. If min = max = 0, then melee weapon
end

struct AttackPool
    weapons::Vector{Weapon} # List of weapons in attack pool # ? Weapons chosen outside of AttackPool logic
    surge::Union{Type{HIT}, Type{CRIT}, Type{BLANK}} # Type of Surge
    aim::Int                # Number of aim tokens spent # ? Decision to use aim tokens
    precise::Int            # Total Precise <X> value
    sharpshooter::Int       # Total Sharpshooter <X> value
end

spray(pool::AttackPool) = any([w.spray for w in pool.weapons])
blast(pool::AttackPool) = any([w.blast for w in pool.weapons])
highVelocity(pool::AttackPool) = any([w.highVelocity for w in pool.weapons])
pierce(pool::AttackPool) = sum([w.pierce for w in pool.weapons])
impact(pool::AttackPool) = sum([w.impact for w in pool.weapons])
range(pool::AttackPool) = [ minimum([w.range[1] for w in pool.weapons]) , maximum([w.range[2] for w in pool.weapons]) ]

struct DefenseDice
    dice::DefendDie         # Base defense die type
    coverMod::Int           # Innate cover modifier
    surge::Union{Type{BLOCK},Type{BLANK}} # Type of surge (none=0, block=1)
    dodge::Int              # Number of dodge tokens available to spend # ? Decision to use dodge tokens
    armor::Bool             # Cancel all hits (but not crits)
    impervious::Bool        # Roll <X> additional defense dice if attack pool has Pierce <X>
    immuneToPierce::Bool    # Attack pool Pierce <X> value reduced to 0
    deflect::Bool           # If dodge > 0, surge = BLOCK # ? Decision to use dodge token
    lowprofile::Bool        # If light cover, improve to heavy cover
    uncannyLuck::Int        # Reroll up to <X> defense dice
    minis::Int              # Number of minis in defending unit
end

"""
    dice(pool::AttackPool)

Build a dictionary with AttackDice as keys and total number of that die type in the AttackPool as values.
"""
function dice(pool::AttackPool)
    p = Dict{AttackDie, Int}()
    for w in pool.weapons, d in w.dice
        if haskey(p, d)
            p[d] += 1
        else
            p[d] = 1
        end
    end
    return p
end

"""
    result(AttackDie, T::{HIT,CRIT,BLANK})

Return the (array-based) result of the specified die side for the AttackDie type.
- HIT   : [1,0,0]
- CRIT  : [0,1,0]
- BLANK : [0,0,1]
"""
result(::Type{AttackDie}, T::Union{Type{HIT},Type{CRIT},Type{BLANK}}) = T == HIT ? [1,0,0] : ( T == CRIT ? [0,1,0] : [0,0,1] )

"""
    result(DefendDie, T::{BLOCK, BLANK})

Return the (array-based) result of the specified die side for the DefendDie.
- BLOCK : [1,0]
- BLANK : [0,1]
"""
result(::Type{DefendDie}, T::Union{Type{BLOCK}, Type{BLANK}}) = T == BLOCK ? [1,0] : [0,1]
