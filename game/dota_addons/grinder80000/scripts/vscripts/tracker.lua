require 'notifications'
require 'utils'

if Tracker == nil then
    Tracker = class({})
end

function Tracker:Initialize()
    self:Reset()
end

function Tracker:Reset()
    self.frags = {}
    self.damageDone = {}
    self.good_luck_wished = false
end

function Tracker:LogKill(killer_id, victim_id)
--    Notifications:TopToAll({text='id=' .. killer_id .. ' killed id=' .. victim_id, color='yellow', duration=5.0})

    local killer_id_str = tostring(killer_id)

    local n = self.frags[killer_id_str]
    if n then
        self.frags[killer_id_str] = n + 1
    else
        self.frags[killer_id_str] = 1
    end

    counts = GameRules.grinder:GetPlayerCounts()

    if counts.good_count == 1 and counts.bad_count > 1 and self.good_luck_wished == false then
--        EmitGlobalSound('pudge_pud_ability_devour_06')
        EmitSoundOnClient('pudge_pud_ability_devour_06', counts.last_good)

        victim_id = counts.last_good:GetPlayerID()

        Notifications:Top(victim_id, {text=' ', duration=4})
        Notifications:Top(victim_id, {text=GetPlayerName(counts.last_good) .. ', you are now on your own versus ' .. counts.bad_count .. ' enemies.', style={color='#FF0000'}, duration=4.0})
        Notifications:Top(victim_id, {text='Good luck!', color='#FFFF00', duration=4.0})
        self.good_luck_wished = true
    elseif counts.good_count > 1 and counts.bad_count == 1 and self.good_luck_wished == false then
        EmitSoundOnClient('pudge_pud_ability_devour_06', counts.last_bad)

        victim_id = counts.last_bad:GetPlayerID()

        Notifications:Top(victim_id, {text=' ', duration=4})
        Notifications:Top(victim_id, {text=GetPlayerName(counts.last_bad) .. ', you are now on your own versus ' .. counts.good_count .. ' enemies.', style={color='#FF0000'}, duration=4.0})
        Notifications:Top(victim_id, {text='Good luck!', color='#FFFF00', duration=4.0})
        self.good_luck_wished = true
    end
end

--function Tracker:LogCast(caster_id)
--
--end

function Tracker:LogDamage(killer_id, victim_id, damage)
    local killer_id_str = tostring(killer_id)

    local n = self.damageDone[killer_id_str]
    if n then
        self.damageDone[killer_id_str] = n + damage
    else
        self.damageDone[killer_id_str] = damage
    end
end

function Tracker:PrintMVP()
    local most_frags_player_id = nil
    local most_frags_value = 0
    local most_frags_multiple_players = false

    for player_id, frags in pairs(self.frags) do
        if frags > most_frags_value then
            most_frags_value = frags
            most_frags_player_id = tonumber(player_id)
            most_frags_multiple_players = false
        elseif frags == most_frags_value then
            most_frags_multiple_players = true
        end
    end

    local most_dmg_player_id = nil
    local most_dmg_value = 0

    for player_id, dmg in pairs(self.damageDone) do
        if dmg > most_frags_value then
            most_dmg_value = dmg
            most_dmg_player_id = tonumber(player_id)
        end
    end

    Notifications:TopToAll({text=' ', duration=5})
    Notifications:TopToAll({image="file://{images}/custom_game/mvp.png", duration=5.0})

    if (most_frags_player_id ~= nil) and (most_frags_multiple_players == false) then
        Notifications:TopToAll({continue=true, text="MVP: " .. GetPlayerName(PlayerResource:GetPlayer(most_frags_player_id)) .. " killed " .. most_frags_value .. " enemies this round.", duration=5, style={color='yellow', ["font-size"]="20px"}})
        mvp_id = most_frags_player_id
    elseif most_dmg_player_id ~= nil then
        Notifications:TopToAll({continue=true, text="MVP: " .. GetPlayerName(PlayerResource:GetPlayer(most_dmg_player_id)) .. " did " .. math.floor(most_dmg_value) .. " damage this round.", duration=5, style={color='yellow', ["font-size"]="20px"}})
        mvp_id = most_dmg_player_id
    else
        Notifications:TopToAll({continue=true, text="No MVP this round.", duration=5, style={["font-size"]="20px"}})
        mvp_id = nil
    end

    if mvp_id ~= nil then
        unit = PlayerResource:GetSelectedHeroEntity(mvp_id)
--        particle_id = ParticleManager:CreateParticle('particles/wr_block/wr_block.vpcf', PATTACH_ROOTBONE_FOLLOW, unit)
        particle_id = ParticleManager:CreateParticle('particles/mvp/mvp.vpcf', PATTACH_OVERHEAD_FOLLOW, unit)

        Timers:CreateTimer(5, function()
            ParticleManager:DestroyParticle(particle_id, false)
            return nil
        end)
    end
end
