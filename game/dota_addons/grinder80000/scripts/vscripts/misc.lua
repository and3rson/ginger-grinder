function OnDealDamage(data)
    if IsServer() then
        GameRules.tracker:LogDamage(data.caster:GetPlayerID(), data.unit:GetPlayerID(), data.Damage)
    end
end
