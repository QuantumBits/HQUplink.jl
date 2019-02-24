export EV

"""
    P(n::Int, k::Int, p::Real)

Probability of k successes in n trials with propability p
"""
P(n::Int, k::Int, p::Real) = binomial(n, k) * p^k * (1-p)^(n-k)


"""
    EV(a::AttackDie, T::{HIT, CRIT, BLANK})

Expected value (EV) of an AttackDie with SURGE results returning DieFace T.
"""
function EV(a::AttackDie, T::Union{Type{HIT}, Type{CRIT}, Type{BLANK}})


    n_hit = a.hit + (T == HIT ? a.surge : 0)
    n_crit = a.crit + (T == CRIT ? a.surge : 0)
    n_blank = a.blank

    return [n_hit, n_crit, n_blank] .// (a.hit + a.crit + a.surge + a.blank)

end

"""
    EV(a::DefendDie, T::{BLOCK, BLANK})

Expected value (EV) of a DefendDie with SURGE results returning DieFace T.
"""
function EV(d::DefendDie, T::Union{Type{BLOCK}, Type{BLANK}})


    n_block = d.block + (T == BLOCK ? d.surge : 0)

    n_blank = d.blank

    return [p_block, p_blank] .// (d.block + d.surge + d.blank)

end


"""
    EV(a::DefendDie, T::{BLOCK, BLANK})

Expected value (EV) of an AttackPool (STILL UNDER CONSTRUCTION)
"""
function EV(ap::AttackPool)

    dp = dice(ap)

    rp = Dict{AttackDie, Vector{Rational{Int}}}()

    for d in keys(dp)
        rp[d] = EV(d, ap.surge) .* dp[d]
    end

    

    return rp

end
