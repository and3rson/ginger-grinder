require 'timers'

function block_start(keys)
    local caster = keys.caster
    local ability_level = keys.ability:GetLevel() - 1
    local duration = keys.ability:GetLevelSpecialValueFor('duration', ability_level)

--    StartSoundEvent('Hero_Puck.Phase_Shift', caster)
    StartSoundEvent('Item.CrimsonGuard.Cast', caster)

    Timers:CreateTimer(duration, function()
--        StopSoundEvent('Hero_Puck.Phase_Shift', caster)
        StopSoundEvent('Item.CrimsonGuard.Cast', caster)
        return nil
    end)
end
