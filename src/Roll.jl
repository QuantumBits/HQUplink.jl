export roll, defend

"""
    roll(a::AttackDie, S::{HIT, CRIT, BLANK}, n::Int = 1)

Result of rolling n AttackDie with SURGE results returning DieFace S.
"""
function roll(a::AttackDie, S::Union{Type{HIT},Type{CRIT},Type{BLANK}}, n::Int=1) 
    x = [ zeros(Int, 3) for i in 1:n ]
    r = result.(AttackDie,[HIT,CRIT,S,BLANK])
    w = FrequencyWeights([a.hit,a.crit,a.surge,a.blank])
    sample!(r, w, x)
    return [ sum(xi[j] for xi in x) for j in 1:3 ]
end

"""
    roll(a::DefendDie, S::{BLOCK, BLANK}, n::Int = 1)

Result of rolling n DefendDie with SURGE results returning DieFace S.
"""
function roll(d::DefendDie, S::Union{Type{BLOCK}, Type{BLANK}}, n::Int=1)
    x = [ zeros(Int, 2) for i in 1:n ]
    r = result.(DefendDie,[BLOCK,S,BLANK])
    w = FrequencyWeights([d.block, d.surge, d.blank])
    sample!(r, w, x)
    return [ sum(xi[j] for xi in x) for j in 1:2 ]
end

"""
    roll(ap::AttackPool, dd::DefenseDice)

Result of rolling all the dice associated with an AttackPool
Implemented:
- Aim tokens
- Precise
"""
function roll(ap::AttackPool, dd::DefenseDice, ::Type{cover}) where {cover<:COVER}

    # Gather all dice in AttackPool
    dap = dice(ap)

    # Initialize the result pool
    rp = Dict{AttackDie, Vector{Int}}()
    for d in AAD
        rp[d] = zeros(Int, 3)
    end

    # Initial Roll:
    # For each type of attack die...
    for d in keys(dap)
        # Add to rp
        rp[d] = roll(d, ap.surge, dap[d])
    end

    # Reroll aims
    for aim in 1:ap.aim

        # Determine number of rerolls
        rerolls = 2 + ap.precise

        # For each type of attack die (in order of best to worst performing dice)...
        for d in AAD
            if haskey(rp, d)
                # Decide whether to reroll
                # IDEA: Resolve attack dice here
                nblanks = rp[d][3] # + (dd.armor ? rp[d][1] : 0)
                if nblanks >= rerolls
                    rp[d] .-= rerolls * result(AttackDie, BLANK)
                    rp[d] .+= roll(d, ap.surge, rerolls)
                    break
                elseif nblanks > 0
                    rp[d] .-= nblanks * result(AttackDie, BLANK)
                    rp[d] .+= roll(d, ap.surge, nblanks)
                    rerolls -= nblanks
                end
            end
        end
    end
    
    hcb = zeros(Int, 3)
    for d in keys(rp), k in 1:3
        hcb[k] += rp[d][k]
    end


    return defend(ap, dd, cover, hcb)

end

"""
    defend(ap::AttackPool, dd::DefenseDice, ::Type{cover}, hitCritsBlocks::Vector{Int}) where {cover<:COVER}

Evaluate how many wounds the number of hits and crits, the AttackPool and cover (0,1,2) result in versus the given DefenseDice

Defender Keywords Implemented:
- Cover <X>
- Dodge tokens
- Armor
- Impervious
- Immune to Pierce
- Deflect (only SURGE -> BLOCK)
- Low Profile
- Uncanny Luck <X>

Attacker Keywords Implemented:
- Blast
- High Velocity
- Pierce <X>
- Impact <X>

"""
function defend(ap::AttackPool, dd::DefenseDice, ::Type{T}, HCB::Vector{Int}) where {T<:COVER}

    hits = HCB[1]
    crits = HCB[2]
    cover = T

    # If no hits and no crits, then no wounds
    if hits <= 0 && crits <= 0
        return 0
    else

        if hits > 0
            # If attacker has Blast keyword, reduce cover to zero
            if blast(ap)
                cover = NONE
            else
                # If defender has Cover <X> keyword, improve cover by <X>
                cover += dd.coverMod

                # If defender has Low Profile keyword and light cover (1), improve to heavy cover (2)
                cover = (cover == LIGHT && dd.lowprofile) ? HEAVY : cover

                # If attack has Sharpshooter <X> keyword, reduce cover by <X>
                cover += (-ap.sharpshooter)
            end

            # Apply cover to remove HIT results
            hits -= cover


            # Spend dodge tokens (unless attacker has High Velocity keyword)
            if !highVelocity(ap)
                hits = max(0, hits - dd.dodge) # Spend dodge tokens to reduce hits
            end

            # If defender has Armor keyword
            if dd.armor

                # Turn up to Impact <X> HIT results into CRIT results
                crits += min(hits, impact(ap))

                # Remove remaining hits
                hits = 0

            end

        end

        
        wounds = hits + crits
        
        # If no wounds ended up being delt, return
        if wounds == 0
            
            return wounds
            
        else
            # Roll defense dice!

            # If defender can spend a dodge tocken and has Deflect Keyword, surge to BLOCK
            ddsurge = (!highVelocity(ap) && dd.dodge > 0 && dd.deflect) ? BLOCK : dd.surge
            
            # Roll dice equal to number of wounds plus Pierce <X> if defender has Impervious keyword
            ndice = wounds + (dd.impervious ? pierce(ap) : 0)

            # Roll defense dice!
            res = roll(dd.dice, ddsurge, ndice)

            # If defender has Uncanny Luck <X> keyword, reroll up to <X> blank results
            if dd.uncannyLuck > 0 && res[2] > 0
                blanks = res[2]
                res[2] = max(0, res[2] - min(blanks, dd.uncannyLuck))
                res .+= roll(dd.dice, ddsurge, min(blanks, dd.uncannyLuck))
            end

            # If attacker has Pierce <X> and defender does not have Immune to Pierce keyword, remove up to <X> BLOCK results
            if pierce(ap) > 0 && !dd.immuneToPierce
                res[1] = max(0, res[1] - pierce(ap))
            end

            return wounds - res[1]

        end
    end

end
