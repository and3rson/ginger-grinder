require 'timers'

if Grinder == nil then
    Grinder = class({})
end

GRINDER_STATE_BEFORE_ALL_SPAWNED = 0
GRINDER_STATE_BEFORE_ROUND = 1
GRINDER_STATE_ROUND_IN_PROGRESS = 2
GRINDER_STATE_AFTER_ROUND = 3
GRINDER_STATE_POST_GAME = 4

MAX_PLAYERS = 6

MAX_SCORE = 25
MAX_LEVEL = 12
LEVEL_XP_DIFF = 100

XP_FOR_ASSIST = 25
XP_FOR_KILL = 50
XP_FOR_RUNE = 50

GOLD_FOR_ASSIST = 25
GOLD_FOR_KILL = 50
GOLD_FOR_RUNE = 50

function Grinder:InitGameMode()
    print(" > Grinder:InitGameMode()")
    print( "Grinder 80K is loaded." )
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:SetHeroRespawnEnabled(false)
    GameRules:SetCustomGameSetupTimeout(15)
    GameRules:SetPreGameTime(5)
    GameRules:SetPostGameTime(60)
    GameRules:SetStartingGold(0)
    GameRules:SetGoldPerTick(0)
--    ListenToGameEvent("take_damage", Dynamic_Wrap(Grinder, 'OnEntityHurt'), self)
    ListenToGameEvent("entity_killed", Dynamic_Wrap(Grinder, 'OnEntityKilled'), self)
    ListenToGameEvent("chat_new_message", Dynamic_Wrap(Grinder, 'OnChatNewMessage'), self)
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(Grinder, 'OnNPCSpawned'), self)

--    ListenToGameEvent("dota_player_gained_level", Dynamic_Wrap(Broadcaster, 'PlayerGainedLevel'), GameRules.broadcaster)
--    ListenToGameEvent("dota_player_learned_ability", Dynamic_Wrap(Broadcaster, 'PlayerLearnedAbility'), GameRules.broadcaster)
--    ListenToGameEvent("dota_player_used_ability", Dynamic_Wrap(Broadcaster, 'PlayerUsedAbility'), GameRules.broadcaster)

    local XP_PER_LEVEL_TABLE = {}
    XP_PER_LEVEL_TABLE[1] = 0
    for i = 2, MAX_LEVEL do
        XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + LEVEL_XP_DIFF
        if i > 4 then
            XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i] + (i - 4) * LEVEL_XP_DIFF / 2
        end
    end

    local gameModeEntity = GameRules:GetGameModeEntity()
    gameModeEntity:SetBuybackEnabled(false)
    gameModeEntity:SetTopBarTeamValuesOverride(true)
    gameModeEntity:ClearModifyExperienceFilter()
    gameModeEntity:ClearModifyGoldFilter()
    gameModeEntity:ClearBountyRunePickupFilter()
    gameModeEntity:SetModifyExperienceFilter(Grinder.ExperienceFilter, self)
    gameModeEntity:SetModifyGoldFilter(Grinder.GoldFilter, self)
    gameModeEntity:SetBountyRunePickupFilter(Grinder.BountyRunePickupFilter, self)
    gameModeEntity:SetAnnouncerDisabled(false)
    gameModeEntity:SetCustomHeroMaxLevel(MAX_LEVEL)
    gameModeEntity:SetUseCustomHeroLevels(true)
    gameModeEntity:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
    gameModeEntity:SetStashPurchasingDisabled(true)
    gameModeEntity:SetCustomGameForceHero('npc_dota_hero_windrunner')

    self.timers = {}
    self.delays = {}

    self.score_good = 0
    self.score_bad = 0

    self.current_round = 0

    GameRules.state = GRINDER_STATE_BEFORE_ALL_SPAWNED

    --

    GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 0 )
    self:UpdateScore()
end

function Grinder:OnNPCSpawned(keys)
--    local units = Entities:FindAllByName('npc_dota_hero_windrunner')
--    for _, unit in pairs(units) do
--        while unit:GetLevel() < 3 do
--            unit:AddExperience(500, 10, false, false)
--        end
--    end
    local unit = EntIndexToHScript(keys.entindex)
    if unit:IsRealHero() then
        while unit:GetLevel() < 3 do
            unit:AddExperience(LEVEL_XP_DIFF * 2, 10, false, false)
        end
        unit:AddNewModifier(unit, unit, 'modifier_stun', {duration=9})
        -- print(unit:)
    end
end

function Grinder:AllPlayersReady()
--    print(" > Grinder:AllPlayersReady()")

    local players = 0
    local ready = 0

    for i=0,DOTA_MAX_TEAM_PLAYERS-1,1 do
        player = PlayerResource:GetPlayer(i)
        if player then
            players = players + 1
        end
        if player and PlayerResource:HasSelectedHero(i) and (PlayerResource:GetSelectedHeroEntity(i) ~= nil) then
            ready = ready + 1
        end
    end
--    print ('Players: ' .. players .. ', ready: ' .. ready)
    return players > 0 and (players == ready)
end

function Grinder:GetPlayersCount()
    local players = 0

    for i=0,DOTA_MAX_TEAM_PLAYERS-1,1 do
        player = PlayerResource:GetPlayer(i)
        if player then
            players = players + 1
        end
    end
--    print ('Players: ' .. players .. ', ready: ' .. ready)
    return players
end
--            print(PlayerResource:GetSelectedHeroEntity(i))
--            print(PlayerResource:HasSelectedHero(i))
----            print('HAS SELECTED HERO?')
--            print()
--        end
--    end
----    local units = Entities:FindAllByName('npc_dota_hero_windrunner')
----    for _, unit in pairs(units) do
----        player = GetPlayer(unit)
----        print('HAS SELECTED HERO?')
----        print(player:HasSelectedHero())
----    end
--end

function Grinder:UpdateScore()
    print(" > Grinder:UpdateScore()")
    local gameModeEntity = GameRules:GetGameModeEntity()
    gameModeEntity:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, self.score_good)
    gameModeEntity:SetTopBarTeamValue(DOTA_TEAM_BADGUYS, self.score_bad)
end

function Grinder:StartNewRoundTimer()
    GameRules.state = GRINDER_STATE_BEFORE_ROUND

    local units = Entities:FindAllByName('npc_dota_hero_windrunner')
    for _, unit in pairs(units) do
        if unit:IsAlive() then
            unit:AddNewModifier(caster, nil, "modifier_stunned", {duration=5})
        end
    end

    self.time_remaining = 5
    After(0, self, 'NewRoundTimerTick')
--    EmitGlobalSound('ann_custom_item_alerts_02')
end

function Grinder:NewRoundTimerTick()
    if self.time_remaining == 0 then
        self.current_round = self.current_round + 1
        self:StartRound()
        return nil
    else
        -- EmitGlobalSound('ui.inv_ticket')
        -- EmitGlobalSound('ui.tick')
        EmitGlobalSound('ui.click_alt')
        if self.time_remaining == 5 then
            Notifications:TopToAll({text=' ', duration=5})
            Notifications:TopToAll({text='Next round in', duration=5})
        end
        Notifications:TopToAll({text=self.time_remaining, duration=1, style={["font-size"]="60px"}})
        self.time_remaining = self.time_remaining - 1
        return 1
    end
end

function Grinder:StartRound()
    print(" > StartRound()")

    GameRules.state = GRINDER_STATE_ROUND_IN_PROGRESS

    Notifications:TopToAll({text=' ', duration=3})
    Notifications:TopToAll({text='Round', duration=3, style={color='#FF7700'}})
    Notifications:TopToAll({text=self.current_round, duration=3, style={color='#FF7700', ["font-size"]="90px"}})

    GameRules.tracker:Reset()

    local units = Entities:FindAllByName('npc_dota_hero_windrunner')
    for _, unit in pairs(units)
    do
        unit:RespawnHero(false, false, false)
--        PlayerResource:SetCameraTarget(unit:GetPlayerID(), unit)
    end

    EmitGlobalSound('DOTA_Item.DoE.Activate')
end


function Grinder:GetPlayerCounts()
    local good_count = 0
    local bad_count = 0

    local last_good = nil
    local last_bad = nil

    local units = Entities:FindAllByName('npc_dota_hero_windrunner')

    for _, unit in pairs(units) do
        if unit:IsAlive() then
            if unit:GetTeam() == DOTA_TEAM_GOODGUYS then
                good_count = good_count + 1
                last_good = unit
            else
                bad_count = bad_count + 1
                last_bad = unit
            end
        end
    end

    return {
        good_count = good_count,
        bad_count = bad_count,
        last_good = last_good,
        last_bad = last_bad
    }
end

function Grinder:CheckRound()
    print(" > CheckRound()")
    if GameRules.state == GRINDER_STATE_ROUND_IN_PROGRESS then
        local counts = self:GetPlayerCounts()

--        local units = Entities:FindAllByName('npc_dota_hero_windrunner')

        local good_win = counts.good_count > 0 and counts.bad_count == 0
        local bad_win = counts.bad_count > 0 and counts.good_count == 0

        if good_win or bad_win then
            self:FinishRound(good_win)
        end

--        print('Good alive: ' .. good_count .. ', bad alive: ' .. bad_count)
    end
end

function Grinder:FinishRound(good_win)
    local units = Entities:FindAllByName('npc_dota_hero_windrunner')

    local winner_team

    if good_win then
        winner_team = DOTA_TEAM_GOODGUYS
    else
        winner_team = DOTA_TEAM_BADGUYS
    end

    for _, unit in pairs(units) do
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
    end

    Notifications:TopToAll({text=' ', duration=7})

    if good_win then
        Notifications:TopToAll({text="Radiant victory!", style={color='#AAAAFF'}, duration=7})
        self.score_good = self.score_good + 1
    else
        Notifications:TopToAll({text="Dire victory!", style={color='#AAAAFF'}, duration=7})
        self.score_bad = self.score_bad + 1
    end

    After(2, GameRules.tracker, 'PrintMVP')

    self:UpdateScore()

    AddFOWViewer(DOTA_TEAM_GOODGUYS, Vector(0, 0, 512), 5000, 7, false)
    AddFOWViewer(DOTA_TEAM_BADGUYS, Vector(0, 0, 512), 5000, 7, false)

    if self.score_good >= MAX_SCORE or self.score_bad >= MAX_SCORE then
        GameRules.state = GRINDER_STATE_POST_GAME
        self:EndGame()
    else
        GameRules.state = GRINDER_STATE_AFTER_ROUND
        After(7, self, 'StartNewRoundTimer')
    end
end

function Grinder:OnEntityHurt( keys )
--    local attacker = EntIndexToHScript(keys.entindex_attacker)
--    local victim = EntIndexToHScript(keys.entindex_killed)
--    local damage = keys.damagebits

--    ParticleManager:CreateParticle('particles/units/heroes/hero_legion_commander/legion_commander_duel_victory.vpcf', PATTACH_OVERHEAD_FOLLOW, victim)

    DeepPrintTable(keys)

--    print('Damage: ' .. damage)
end

function Grinder:OnEntityKilled( keys )
    print(" > Grinder:OnEntityKilled()")

    if keys.entindex_attacker == nil then
        return
    end

    local killer = EntIndexToHScript(keys.entindex_attacker)
    local victim = EntIndexToHScript(keys.entindex_killed)

    if killer:IsRealHero() and victim:IsRealHero() then
--        self:LevelUp(killer)
        killer:AddExperience(XP_FOR_KILL, 100, false, false)
        killer:ModifyGold(GOLD_FOR_KILL, true, 100)
        GameRules.tracker:LogKill(killer:GetPlayerID(), victim:GetPlayerID())

        local killer_id = killer:GetPlayerID()
        local killer_team = killer:GetTeam()

        for i=0,DOTA_MAX_TEAM_PLAYERS-1,1 do
            if i ~= killer_id then
                player = PlayerResource:GetPlayer(i)
                player_hero = PlayerResource:GetSelectedHeroEntity(i)
                if player and PlayerResource:HasSelectedHero(i) and player_hero and player:IsAlive() and (player:GetTeam() == killer_team) and (player_id ~= killer_id) then
                    player_hero:AddExperience(XP_FOR_ASSIST, 100, false, false)
                    player_hero:ModifyGold(GOLD_FOR_ASSIST, true, 100)
                end
            end
        end
    end

    self:CheckRound()
end

--function Grinder:LevelUp(entity)
--    local nextLevel = entity:GetLevel() + 1
--
--    if nextLevel > MAX_LEVEL then
--        return
--    end
--
--    while entity:GetLevel() < nextLevel do
--        entity:AddExperience(LEVEL_XP_DIFF, 10, false, false)
--    end
--end

function Grinder:ExperienceFilter(t)
    return false
--    print(' > Grinder:ExperienceFilter()')
--    if t['reason_const'] <= 4 then
--        return false
--    end
--    return t
end

function Grinder:GoldFilter(t)
    print(' > Grinder:GoldFilter()')
    return false
end

function Grinder:BountyRunePickupFilter(t)
    print(' > Grinder:BountyRunePickupFilter()')
    -- self:LevelUp(PlayerResource:GetSelectedHeroEntity(t.player_id_const))
    unit = PlayerResource:GetSelectedHeroEntity(t.player_id_const)
    unit:AddExperience(XP_FOR_RUNE, 100, false, false)
    unit:ModifyGold(GOLD_FOR_KILL, true, 100)
    return false
end

function Grinder:OnChatNewMessage( channel )
end

-- Evaluate the state of the game
function Grinder:OnThink()
--    print(" > Grinder:OnThink()")
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_HERO_SELECTION or GameRules:State_Get() <= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
--        print('Current state: ' .. self.state)
        if GameRules.state == GRINDER_STATE_BEFORE_ALL_SPAWNED then
            if self:AllPlayersReady() then
                mul = MAX_PLAYERS / self:GetPlayersCount()
                print("Players: " .. self:GetPlayersCount() .. "/" .. MAX_PLAYERS .. ", GOLD/XP multiplier = " .. mul)

                XP_FOR_ASSIST = XP_FOR_ASSIST * mul
                XP_FOR_KILL = XP_FOR_KILL * mul
                XP_FOR_RUNE = XP_FOR_RUNE * mul

                GOLD_FOR_ASSIST = GOLD_FOR_ASSIST * mul
                GOLD_FOR_KILL = GOLD_FOR_KILL * mul
                GOLD_FOR_RUNE = GOLD_FOR_RUNE * mul

                self:StartNewRoundTimer()

--                self:Poll()
            else
--                Notifications:TopToAll({text='Waiting for players...', color='yellow', duration=5.0})
            end
        end
--        self:CheckRound()
--        self:OnPlayerSpawn(0)
        -- Process timers
--        for i=#self.timers,1,-1 do
--            self.delays[i] = self.delays[i] - 0.25
--
--            if self.delays[i] == 0 then
--                self.timers[i](self)
--                table.remove(self.timers, i)
--                table.remove(self.delays, i)
--            else
--                print ('Will run function in ' .. self.delays[i] .. ' seconds')
--            end
--        end
        --print( "Template addon script is running." )
    elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        return nil
    end
    return 0.25
end


function Grinder:Poll()
    local ctx = self

    CreateHTTPRequest('GET', 'http://canihazip.com/s'):Send(function(result)
        for k,v in pairs( result ) do
            print( string.format( "%s : %s\n", k, v ) )
        end

        Timers:CreateTimer(1, function()
            ctx:Poll()
        end)
    end)
end


function Grinder:EndGame()
    if self.score_good >= MAX_SCORE then
        GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
    else
        GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
    end
end
