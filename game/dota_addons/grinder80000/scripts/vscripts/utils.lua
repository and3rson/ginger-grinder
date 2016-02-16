function After(delay, context, fn)
    print(" > After()")
    GameRules:GetGameModeEntity():SetThink(fn, context, fn, delay)
end

function GetPlayerName(entity)
    print(" > Grinder:GetPlayerName()")
    return PlayerResource:GetPlayerName(entity:GetPlayerID())
end
