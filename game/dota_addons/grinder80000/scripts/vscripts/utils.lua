function After(delay, context, fn)
    print(" > After()")
    GameRules:GetGameModeEntity():SetThink(fn, context, fn, delay)
end

function GetPlayerName(entity)
--    print(" > Grinder:GetPlayerName()")
    if entity == nil or entity:GetPlayerID() == -1 then
        return 'Bot'
    else
        return PlayerResource:GetPlayerName(entity:GetPlayerID())
    end
end
