if Broadcaster == nil then
    Broadcaster = class({})
end

function Broadcaster:Initialize()
end

function Broadcaster:PlayerGainedLevel(keys)
    print('PlayerGainedLevel')
    DeepPrintTable(keys)
end

function Broadcaster:PlayerLearnedAbility(keys)
    print('PlayerLearnedAbility')
    DeepPrintTable(keys)
end

function Broadcaster:PlayerUsedAbility(keys)
    print('PlayerUsedAbility')
    DeepPrintTable(keys)
end
