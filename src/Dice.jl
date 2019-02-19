using StatsBase

export BLANK, HIT, CRIT, BLOCK
export AttackDie, DefendDie, Weapon, AttackPool, DefenseDice
export RA, BA, WA, RD, WD
export dice, result, roll, EV



abstract type DieFace end

abstract type BLANK <: DieFace end
abstract type HIT <: DieFace end
abstract type CRIT <: DieFace end
abstract type BLOCK <: DieFace end

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

const RD = DefendDie(3,1,2)
const WD = DefendDie(1,1,4)

struct Weapon
    dice::Vector{AttackDie} # List of attack dice
    spray::Bool             # If true, multiply no. of dice by no. of minis in defending unit
    blast::Bool             # If true, ignore defender's cover
    highVelocity::Bool      # If true, defender cannot spend dodge tokens
    pierce::Int             # Pierce <X> value
    impact::Int             # Impact <X> value
end

struct AttackPool
    weapons::Vector{Weapon} # List of weapons in attack pool
    surge::Union{Type{HIT}, Type{CRIT}, Type{BLANK}} # Type of Surge
    aim::Int                # Number of aim tokens spent
    precise::Int            # Total Precise <X> value
    sharpshooter::Int       # Total Sharpshooter <X> value
end

struct DefenseDice
    dice::DefendDie         # Base defense die type
    cover::Int              # Type of cover (none=0, light=1, heavy=2)
    surge::Union{Type{BLOCK},Type{BLANK}} # Type of surge (none=0, block=1)
    dodge::Int              # Number of dodge tokens spent
    armor::Bool             # Cancel all hits (but not crits)
    impervious::Bool        # Roll <X> additional defense dice if attack pool has Pierce <X>
    immuneToPierce::Bool    # Attack pool Pierce <X> value reduced to 0
    deflect::Bool           # If dodge > 0, surge = 1
end

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

result(::Type{AttackDie}, T::Union{Type{HIT},Type{CRIT},Type{BLANK}}) = T == HIT ? [1,0,0] : ( T == CRIT ? [0,1,0] : [0,0,1] )
result(::Type{DefendDie}, T::Union{Type{BLOCK}, Type{BLANK}}) = T == BLOCK ? [1,0] : [0,1]

function roll(a::AttackDie, S::Union{Type{HIT},Type{CRIT},Type{BLANK}}, n::Int=1) 
    x = [ zeros(3) for i in 1:n ]
    r = result.(AttackDie,[HIT,CRIT,S,BLANK])
    w = FrequencyWeights([a.hit,a.crit,a.surge,a.blank])
    sample!(r, w, x)
    return [ sum(xi[j] for xi in x) for j in 1:3 ]
end
function roll(d::DefendDie, S::Union{Type{BLOCK}, Type{BLANK}}, n::Int=1) 
    x = [ zeros(2) for i in 1:n ]
    r = result.(DefendDie,[BLOCK,S,BLANK])
    w = FrequencyWeights([d.block, d.surge, d.blank])
    sample!(r, w, x)
    return [ sum(xi[j] for xi in x) for j in 1:2 ]
end

spray(pool::AttackPool) = any([w.spray for w in pool.weapons])
blast(pool::AttackPool) = any([w.blast for w in pool.weapons])
highVelocity(pool::AttackPool) = any([w.highVelocity for w in pool.weapons])
pierce(pool::AttackPool) = sum([w.pierce for w in pool.weapons])
impact(pool::AttackPool) = sum([w.impact for w in pool.weapons])

function roll(pool::AttackPool)
   
    x = [0, 0, 0]
    
    d = dice(pool)
    
    for k in keys(d)
        res = roll(k, pool.surge, d[k])
        x .+= res
    end
    
    return x

end

P(n::Int, k::Int, p::Real) = binomial(n, k) * p^k * (1-p)^(n-k)

function EV(a::AttackDie, T::Union{Type{HIT}, Type{CRIT}, Type{BLANK}})
    
    sides = a.hit + a.crit + a.surge + a.blank
    
    n_hit = a.hit + (T == HIT ? a.surge : 0)
    p_hit = n_hit // sides
    
    n_crit = a.crit + (T == CRIT ? a.surge : 0)
    p_crit = n_crit // sides
    
    n_blank = sides - n_hit - n_crit
    p_blank = n_blank // sides
    
    return [p_hit, p_crit, p_blank]
end

function EV(d::DefendDie, T::Union{Type{BLOCK}, Type{BLANK}})
    
    sides = d.block + d.surge + d.blank
    
    n_block = d.block + (T == BLOCK ? d.surge : 0)
    p_block = n_block // sides
    
    n_blank = sides - n_block
    p_blank = n_blank // sides
    
    return [p_block, p_blank]
end

function EV(ap::AttackPool)
    
    hits = 0//1
    crits = 0//1
    blocks = 0//1
    
    for w in ap.weapons, d in w.dice
        hci = EV(d, ap.surge)
        hits += hci[1]
        crits += hci[2]
        blocks += hci[3]
    end
    
    return [hits , crits, blocks]
end

