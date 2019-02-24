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

    sides = a.hit + a.crit + a.surge + a.blank

    n_hit = a.hit + (T == HIT ? a.surge : 0)
    p_hit = n_hit // sides

    n_crit = a.crit + (T == CRIT ? a.surge : 0)
    p_crit = n_crit // sides

    n_blank = sides - n_hit - n_crit
    p_blank = n_blank // sides

    return [p_hit, p_crit, p_blank]

end

"""
    EV(a::DefendDie, T::{BLOCK, BLANK})

Expected value (EV) of a DefendDie with SURGE results returning DieFace T.
"""
function EV(d::DefendDie, T::Union{Type{BLOCK}, Type{BLANK}})

    sides = d.block + d.surge + d.blank

    n_block = d.block + (T == BLOCK ? d.surge : 0)
    p_block = n_block // sides

    n_blank = sides - n_block
    p_blank = n_blank // sides

    return [p_block, p_blank]

end


"""
    EV(a::DefendDie, T::{BLOCK, BLANK})

Expected value (EV) of an AttackPool (STILL UNDER CONSTRUCTION)
"""
function EV(ap::AttackPool)

    hcb = [0//1 , 0//1 , 0//1]

    dap = dice(ap)

    for d in AAD
        if haskey(dap, d)
            nd = dap[d]
            hcbi = nd .* EV(d, ap.surge)
            hcb .+= hcbi
        end
    end

    return hcb

end
