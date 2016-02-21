if Waypoint == nil then
    Waypoint = class({})
    Waypoint.last_node_id = 0
end

function Waypoint:InitializeFromEntity(entity)
    Waypoint.last_node_id = Waypoint.last_node_id + 1
    self.id = entity:Attribute_GetIntValue('nodeid', Waypoint.last_node_id)
    self.vector = entity:GetAbsOrigin()
    self.friends = {}
    self.friend_count = 0
end

function Waypoint:GetPosition()
    return self.vector
end

function Waypoint:AddFriend(other)
    table.insert(self.friends, other)
    self.friend_count = self.friend_count + 1
end

function Waypoint:GetFriends()
    return self.friends
end

function Waypoint:GetRandomFriend(exclude)
    if exclude == nil then
        return self.friends[math.random(self.friend_count)]
    else
        selected = exclude
        while selected == exclude do
            selected = self.friends[math.random(self.friend_count)]
        end
        return selected
    end
end

function Waypoint:GetFriendCount()
    return self.friend_count
end

function Waypoint:ForEachFriend(callable)
    for _, friend in self.friends do
        callable(friend)
    end
end

function Waypoint:IsNear(vector)
    return Distance(self.vector, vector) < 32
end


if WaypointSystem == nil then
    WaypointSystem = class({})
end

function WaypointSystem:Initialize()
    wp_entities = Entities:FindAllByName('waypoint')
    self.waypoint_count = 0

    self.waypoints = {}

    for _, wp_entity in pairs(wp_entities) do
        wp = Waypoint()
        wp:InitializeFromEntity(wp_entity)
        table.insert(self.waypoints, wp)
        self.waypoint_count = self.waypoint_count + 1
    end

    for i=1,self.waypoint_count,1 do
        local wp1 = self.waypoints[i]
        pos1 = wp1:GetPosition()

        for j=i+1,self.waypoint_count,1 do
            local wp2 = self.waypoints[j]
            pos2 = wp2:GetPosition()

            if Distance(pos1, pos2) < 384 then
--                pid = ParticleManager:CreateParticle('particles/line2.vpcf', PATTACH_CUSTOMORIGIN, nil)
--                ParticleManager:SetParticleControl(pid, 0, pos1)
--                ParticleManager:SetParticleControl(pid, 1, pos2)
                wp1:AddFriend(wp2)
                wp2:AddFriend(wp1)
            end
        end
    end

    print('[AI] Initialized ' .. self.waypoint_count .. ' waypoints.')

    local errors = false
    for i, wp in pairs(self.waypoints) do
        if wp:GetFriendCount() < 2 then
            print('[AI] WARNING: Waypoint ' .. wp.id .. ' at position ' .. wp:GetPosition().x .. ';' .. wp:GetPosition().y .. ' has less than 2 friends!')
            errors = true
        end
    end
    if errors then
        return false
    end
    return true
end

function WaypointSystem:GetRandomWaypoint()
    return self.waypoints[math.random(self.waypoint_count)]
end

function WaypointSystem:FindWaypointNearPosition(vector)
    local min_range = -1
    local min_wp = self.waypoints[0]

    for _, wp in pairs(self.waypoints) do
        local dist = Distance(wp.GetPosition(), vector)
        if dist < min_range or min_range == -1 then
            min_range = dist
            min_wp = wp
        end
    end

    return min_wp
end
