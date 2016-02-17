require "timers"

function place_trap(keys)
    local caster = keys.caster
    local caster_location = caster:GetAbsOrigin()
    local ability = keys.ability
    local ability_level = ability:GetLevel() - 1
    local point = keys.target_points[1]

    local activation_range = ability:GetLevelSpecialValueFor("activation_range", ability_level)
    local life_duration = ability:GetLevelSpecialValueFor("life_duration", ability_level)
    local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
    local damage = ability:GetLevelSpecialValueFor("damage", ability_level)

    if ability.enemies == nil then
        ability.enemies = {}
        for _, unit in pairs(Entities:FindAllByName('npc_dota_hero_windrunner')) do
            if unit:GetTeam() ~= caster:GetTeam() then
                table.insert(ability.enemies, unit)
            end
        end
    end

--    EmitSoundOn('', info.caster)
--[[    for _, unit in pairs(units) do
        if unit:GetTeam() == winner_team then
            -- This unit won
            EmitSoundOnClient('Hero_LegionCommander.Duel.Victory', PlayerResource:GetPlayer(unit:GetPlayerID()))
            if unit:IsAlive() then
                -- This unit is still alive
                ParticleManager:CreateParticle('particles/units/heroes/hero_legion_commander/legion_commander_duel_victory.vpcf', PATTACH_OVERHEAD_FOLLOW, unit)
            end
        else
            -- This unit lost
            EmitSoundOnClient('pudge_pud_ability_rot_07', PlayerResource:GetPlayer(unit:GetPlayerID()))
        end
    end]]--

    local trap_id = ParticleManager:CreateParticleForTeam('particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_inground.vpcf', PATTACH_CUSTOMORIGIN, nil, caster:GetTeam())
    ParticleManager:SetParticleControl(trap_id, 0, point)

    i = 0

    Timers:CreateTimer(0, function()
        for _, unit in pairs(ability.enemies) do
            if Distance(unit:GetAbsOrigin(), point) <= activation_range then
                ParticleManager:DestroyParticle(trap_id, false)

                stun_id = ParticleManager:CreateParticle('particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf', PATTACH_CUSTOMORIGIN, unit)
                ParticleManager:SetParticleControl(stun_id, 0, point)
                ParticleManager:SetParticleControl(stun_id, 1, unit:GetAbsOrigin())
                AddFOWViewer(caster:GetTeam(), unit:GetAbsOrigin(), 150, 3.25, false)

                Timers:CreateTimer(0.25, function()
                    if unit:HasModifier('modifier_wr_magic_immunity') == false then
                        unit:AddNewModifier(caster, ability, "modifier_stunned", {duration=3})
                        ApplyDamage({
                            victim = unit,
                            attacker = caster,
                            damage = damage,
                            damage_type = DAMAGE_TYPE_PURE
                        })
                    end
                    return nil
                end)

                return nil
            end
        end
        i = i + 1
        if i >= life_duration * 25 then
            return nil
        end
        if i % 25 == 0 then
            AddFOWViewer(caster:GetTeam(), point, 50, 1, true)
        end
        return 1/25
    end)
end

function Distance(A, B)
    local dx = A.x - B.x
    local dy = A.y - B.y
    return math.sqrt( dx * dx + dy * dy )
end
