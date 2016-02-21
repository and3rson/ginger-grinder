require 'ai/waypoints'
require 'timers'

if AI == nil then
    AI = class({})
end


if Bot == nil then
    Bot = class({})
end


BOT_MODE_ROAM = 0
BOT_MODE_CHASE = 1
BOT_MODE_ATTACK = 2
BOT_MODE_GRAB_RUNE = 3

MODES_R = {
    [BOT_MODE_ROAM] = 'BOT_MODE_ROAM',
    [BOT_MODE_CHASE] = 'BOT_MODE_CHASE',
    [BOT_MODE_ATTACK] = 'BOT_MODE_ATTACK',
    [BOT_MODE_GRAB_RUNE] = 'BOT_MODE_GRAB_RUNE',
}


function AI:Initialize()
--    if state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
--        Tutorial:AddBot('npc_dota_hero_windrunner', '', '', false)
--        Tutorial:AddBot('npc_dota_hero_windrunner', '', '', false)
--        Tutorial:AddBot('npc_dota_hero_windrunner', '', '', false)
--        Tutorial:AddBot('npc_dota_hero_windrunner', '', '', false)

--        Timers:CreateTimer(1, function()
--            local gameModeEntity = GameRules:GetGameModeEntity()
--            gameModeEntity:SetCustomGameForceHero('npc_dota_hero_windrunner')
--        end)

--        math.randomseed(os.time())

        players_per_team = MAX_PLAYERS / MAX_TEAMS
--        players_per_team = 1

        while PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) < players_per_team do
            print('Adding good bot')
            Tutorial:AddBot('npc_dota_hero_windrunner', 'a', 'b', true)
            print('Counts: good=' .. PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) .. ', bad='.. PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS))
        end

        while PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) < players_per_team do
            print('Adding bad bot')
            Tutorial:AddBot('npc_dota_hero_windrunner', 'c', 'd', false)
            print('Counts: good=' .. PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) .. ', bad='.. PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS))
        end

        for i=0,9,1 do
            player = PlayerResource:GetPlayer(i)
            if player ~= nil then
                print(player:GetAssignedHero())
            end
        end

        self.waypoint_system = WaypointSystem()
        if not self.waypoint_system:Initialize() then
            return
        end

        players_per_team = MAX_PLAYERS / MAX_TEAMS


        for i=0,9,1 do
            player = PlayerResource:GetPlayer(i)
            if player ~= nil and PlayerResource:GetConnectionState(i) == 1 then
                local bot = Bot()
                bot:Initialize(self, player)
            end
        end
end


--[[function Bot:GetTopWill()
    local max_behavior = BOT_BEHAVIOR_ROAMING
    local max_will = 0

    for behavior, will in pairs(self.wills) do
        if will > max_will then
            max_will = will
            max_behavior = behavior
        end
    end

    return max_behavior
end]]--


function Bot:Initialize(ai, player)
    self.behavior = BOT_BEHAVIOR_ROAMING

    self.previous_wp = nil
    self.current_wp = ai.waypoint_system:GetRandomWaypoint()

--    self.entity = CreateUnitByName('npc_dota_hero_windrunner', self.current_wp:GetPosition(), false, PlayerResource:GetPlayer(0), PlayerResource:GetPlayer(0), DOTA_TEAM_BADGUYS)
--    self.entity = CreateUnitByName('npc_dota_hero_windrunner', self.current_wp:GetPosition(), false, nil, nil, team)
--    self.entity = CreateUnitByName('npc_dota_hero_windrunner', self.current_wp:GetPosition(), false, nil, nil, 1)
--    self.entity:SetIdleAcquire(false)
--    self.entity:SetAcquisitionRange(0)

--    player.ai_def = {think_interval = 0.1}

    self.entity = CreateHeroForPlayer('npc_dota_hero_windrunner', player)

--    self.player = player

--    DeepPrintTable(self.player)

--    Timers:CreateTimer(1, function()
--        self:Start()
--    end)

--    print('Bot team: ' .. player:GetTeam())
--end

--function Bot:Start()
--    self.entity = self.player:GetControlledRPGUnit()

--[[    self.wills = {
        [BOT_BEHAVIOR_ROAMING] = 1.0,
        [BOT_BEHAVIOR_ATTACKING] = 0.25,
        [BOT_BEHAVIOR_DEFENDING] = 0.25,
        [BOT_BEHAVIOR_SEEK_AND_DESTROY] = 0.40,
        [BOT_BEHAVIOR_GRAB_RUNE] = 0.15
    }--]]

    self.mode = BOT_MODE_ROAM

--    self.chase_target = nil

    self.left_to_upgrade = 3

    self.last_level = 3

    self.next_attack_in = 0

    self.skills = {
        projectile=self.entity:FindAbilityByName('pure_skill_wr_projectile'),
        block=self.entity:FindAbilityByName('pure_skill_wr_block'),
        rush=self.entity:FindAbilityByName('pure_skill_wr_rush')
    }

--    print(self.entity:IsHero())
--    print(self.entity:IsRealHero())
--    print(self.entity:GetPlayerID())
--    print('.')

    self.skills.projectile:UpgradeAbility(false)
    self.skills.block:UpgradeAbility(false)
    self.skills.rush:UpgradeAbility(false)

    -- TODO: This crashes for non-hero units :(
--    self.entity:UpgradeAbility(self.projectile)
--    self.entity:UpgradeAbility(self.block)
--    self.entity:UpgradeAbility(self.rush)

    Timers:CreateTimer(1, function()
        local debug_data = {
            {'Current bot mode', MODES_R[self.mode]},

            {''}
        }

        print(self.entity:GetAbilityPoints())

        while self.last_level < self.entity:GetLevel() and self.left_to_upgrade > 0 do
            self.skills.projectile:UpgradeAbility(false)
            self.skills.last_level = self.skills.last_level + 1
            self.left_to_upgrade = self.left_to_upgrade - 1
        end

        self.next_attack_in = self.next_attack_in - 1

--        self.skills.projectile:UpgradeAbility(true)
--        self.skills.block:UpgradeAbility(true)
--        self.skills.rush:UpgradeAbility(true)

        if self.mode == BOT_MODE_ROAM then
            -- ROAM MODE

            closest_enemy = self:FindClosestEnemy()

            if closest_enemy ~= nil and self.skills.projectile:IsOwnersManaEnough() and self.next_attack_in <= 0 then
                if math.random(1,10) == 1 then
                    self.mode = BOT_MODE_CHASE
                end
            else
                if self.current_wp:IsNear(self.entity:GetAbsOrigin()) then
                    print('Reached waypoint, selecting next.')
                    -- Reached waypoint - move further.
                    local next_wp = self.current_wp:GetRandomFriend(self.previous_wp)
                    self.previous_wp = self.current_wp
                    self.current_wp = next_wp

                end

                -- !!!
                self.entity:MoveToPosition(self.current_wp:GetPosition())

                local current_wp_id = self.current_wp.id
                local previous_wp_id = 'NONE'
                if self.previous_wp ~= nil then
                    previous_wp_id = self.previous_wp.id
                end

                -- Check if any enemies is visible
    --            for _, unit in pairs(Entities:FindAllByClassname('npc_dota_hero_windrunner')) do

                table.insert(debug_data, {'Current path:', previous_wp_id .. ' -> ' .. current_wp_id})
                table.insert(debug_data, {'Distance to next wp:', math.floor(tonumber(Distance(self.entity:GetAbsOrigin(), self.current_wp:GetPosition())))})
            end

--            print (':)')
        elseif self.mode == BOT_MODE_CHASE then
            -- CHASE MODE
--            print('Can see enemy: ' .. tostring(self.entity:CanEntityBeSeenByMyTeam(self.chase_target)) .. ', enough mana: ' .. tostring(self.skills.projectile:IsOwnersManaEnough()))
            closest_enemy = self:FindClosestEnemy()

            if closest_enemy ~= nil and self.entity:CanEntityBeSeenByMyTeam(closest_enemy) and self.skills.projectile:IsOwnersManaEnough() then
                if self:HasEnoughDistanceForNuke(self.entity:GetAbsOrigin()) then
                    self.entity:CastAbilityOnPosition(closest_enemy:GetAbsOrigin(), self.skills.projectile, -1)

--                    CustomGameEventManager:Send_ServerToAllClients('on_debug_message', debug_data)
                    self.mode = BOT_MODE_ROAM
                    self.next_attack_in = math.random(10, 50)
                    return 1.1
                else
                    self.entity:MoveToPosition(self.chase_target:GetAbsOrigin())
                end
            else
                self.mode = BOT_MODE_ROAM
            end
        else
            local foo = 'bar'
            -- TODO: Implement other behaviors
        end

        CustomGameEventManager:Send_ServerToAllClients('on_debug_message', debug_data)

        return 1/25
    end)

--    Timers:CreateTimer(0, function()
--        return nil
--        next_wp = self.current_wp:GetRandomFriend(self.previous_wp)
--        self.previous_wp = self.current_wp
--        self.current_wp = next_wp
--        self.entity:MoveToPosition(self.current_wp:GetPosition())
--        return 3
--    end)

--    pid = ParticleManager:CreateParticle('particles/line.vpcf', PATTACH_CUSTOMORIGIN, nil)
--    ParticleManager:SetParticleControl(pid, 0, Vector(-100, 0, 200))
--    ParticleManager:SetParticleControl(pid, 1, Vector(100, 0, 200))

end


function Bot:FindClosestEnemy()
    local enemies = FindUnitsInRadius(self.entity:GetTeamNumber(), Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

    for _, enemy in pairs(enemies) do
        -- Is enemy visible?
        if self.entity:CanEntityBeSeenByMyTeam(enemy) == true then
            return enemy
--                    table.insert(debug_data, {'I see', enemy:GetClassname() .. ' on ' .. enemy:GetAbsOrigin().x .. ';' .. enemy:GetAbsOrigin().y})
--                    local nuke = self.entity:FindAbilityByName('pure_skill_wr_projectile')
--                    print(self.skills.projectile:GetLevel())
--                    self.entity:CastAbilityOnPosition(enemy:GetAbsOrigin(), self.skills.projectile, -1)
--                    return 1.5
        end
    end
end


function Bot:HasEnoughDistanceForNuke(vector)
    local current_distance = Distance(self.entity:GetAbsOrigin(), vector)
    local required_distance = self.skills.projectile:GetLevelSpecialValueFor("arrow_range", self.entity:GetLevel() - 1) - 75
--    print('Has enough distance? current = ' .. current_distance .. ', required = ' .. current_distance)
    return current_distance <= required_distance
end


function Distance(A, B)
    local dx = A.x - B.x
    local dy = A.y - B.y
    return math.sqrt( dx * dx + dy * dy )
end
