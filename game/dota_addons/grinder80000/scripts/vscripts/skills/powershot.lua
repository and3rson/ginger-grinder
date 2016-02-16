require "timers"

--[[
    Author: kritth, Pizzalol
    Date: 01.10.2015.
    Initialize the data we require for the ability
]]
function powershot_initialize( keys )
    local caster = keys.caster
    local caster_location = caster:GetAbsOrigin()
    local ability = keys.ability
    local ability_level = ability:GetLevel() - 1
    local point = keys.target_points[1]

    if ability.used_times then
        ability.used_times = ability.used_times + 1
    else
        ability.used_times = 1
    end

    print('Ability was used ' .. tostring(ability.used_times) .. ' times')

    -- Ability variables
    ability.powershot_damage_percent = 0.0
    ability.powershot_traveled = 0
    ability.powershot_direction = (point - caster_location):Normalized()
    ability.powershot_source = caster_location
    ability.powershot_currentPos = caster_location
    ability.powershot_percent_movespeed = 100
    ability.powershot_units_array = {}
    ability.powershot_units_hit = {}

    ability.powershot_interval_damage =  ability:GetLevelSpecialValueFor("damage_per_interval", ability_level)

    -- +
    ability.powershot_interval_speed =  ability:GetLevelSpecialValueFor("speed_per_interval", ability_level)
    ability.powershot_interval_range =  ability:GetLevelSpecialValueFor("range_per_interval", ability_level)

    ability.powershot_interval_damage =  ability:GetLevelSpecialValueFor("damage_per_interval", ability_level)
    ability.powershot_max_range_initial = ability:GetLevelSpecialValueFor( "arrow_range", ability_level )
    ability.powershot_max_range = 0

    -- ability.powershot_max_movespeed = ability:GetLevelSpecialValueFor( "arrow_speed", ability_level )
    -- +
    ability.powershot_max_movespeed_initial = ability:GetLevelSpecialValueFor( "arrow_speed", ability_level )
    -- +

    ability.powershot_max_movespeed = ability.powershot_max_movespeed_initial / 2

    ability.powershot_radius = ability:GetLevelSpecialValueFor( "arrow_width", ability_level )
    ability.powershot_vision_radius = ability:GetLevelSpecialValueFor( "vision_radius", ability_level )
    ability.powershot_vision_duration = ability:GetLevelSpecialValueFor( "vision_duration", ability_level )
    ability.powershot_damage_reduction = ability:GetLevelSpecialValueFor( "damage_reduction", ability_level )
    ability.powershot_speed_reduction = ability:GetLevelSpecialValueFor( "speed_reduction", ability_level )
    ability.powershot_tree_width = ability:GetLevelSpecialValueFor("tree_width", ability_level) * 2 -- Double the radius because the original feels too small
end

--[[
    Author: kritth
    Date: 01.10.2015.
    Init: Charge the damage per duration
]]
function powershot_charge( keys )
    local ability = keys.ability

    -- Fail check
    if not ability.powershot_damage_percent then
        ability.powershot_damage_percent = 0.0
    end
    ability.powershot_damage_percent = ability.powershot_damage_percent + ability.powershot_interval_damage
    ability.powershot_max_movespeed = ability.powershot_max_movespeed + ability.powershot_max_movespeed_initial * ability.powershot_interval_speed / 2
    ability.powershot_max_range = ability.powershot_max_range + ability.powershot_max_range_initial * ability.powershot_interval_range
    -- print(ability.powershot_damage_percent, ability.powershot_max_movespeed, ability.powershot_max_range)
end

--[[
    Author: kritth
    Date: 5.1.2015.
    Init: Register units to become target
]]
function powershot_register_unit( keys )
    -- Variables
    local caster = keys.caster
    local ability = keys.ability
    local target = keys.target
    local index = keys.target:entindex()

    -- Register
    ability.powershot_units_array[ index ] = target
    ability.powershot_units_hit[ index ] = false
end

--[[
    Author: kritth, Pizzalol
    Date: 01.10.2015.
    Main: Start traversing upon timer while providing vision, reducing damage and speed per units hit, and also destroy trees
]]
function powershot_start_traverse( keys )
    -- Variables
    local caster = keys.caster
    local ability = keys.ability
    local startAttackSound = "Ability.PowershotPull"
    local startTraverseSound = "Ability.Powershot"
    local projectileNameGoodGuys = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf"
    local projectileNameBadguys = "particles/windrunner_spell_powershot_badguys/windrunner_spell_powershot.vpcf"

    -- Stop sound event and fire new one, can do this in datadriven but for continuous purpose, let's put it here
    StopSoundEvent( startAttackSound, caster )
    StartSoundEvent( startTraverseSound, caster )

    local projectileName;
    if caster:GetTeam() == DOTA_TEAM_GOODGUYS then
        projectileName = projectileNameGoodGuys
    else
        projectileName = projectileNameBadguys
    end

    print(projectileName)

    -- Create projectile
    local projectileTable =
    {
        EffectName = projectileName,
        Ability = ability,
        vSpawnOrigin = ability.powershot_source,
        vVelocity = Vector(ability.powershot_direction.x * ability.powershot_max_movespeed, ability.powershot_direction.y * ability.powershot_max_movespeed, 0),
        fDistance = ability.powershot_max_range,
        fStartRadius = ability.powershot_radius,
        fEndRadius = ability.powershot_radius,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        iVisionRadius = ability.powershot_vision_radius,
        iVisionTeamNumber = caster:GetTeamNumber()
    }
    caster.powershot_projectileID = ProjectileManager:CreateLinearProjectile( projectileTable )

    -- Register units around caster
    local units = FindUnitsInRadius( caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, ability.powershot_radius,
            DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
--    for k, v in pairs( units ) do
--        local index = v:entindex()
--        caster.powershot_units_array[ index ] = v
--        caster.powershot_units_hit[ index ] = false
--    end

    local context = {
        used_times=ability.used_times,
        powershot_projectileID=caster.powershot_projectileID,
        powershot_currentPos=ability.powershot_currentPos,
        powershot_direction=ability.powershot_direction,
        powershot_percent_movespeed=ability.powershot_percent_movespeed,
        powershot_max_movespeed=ability.powershot_max_movespeed,
        powershot_traveled=ability.powershot_traveled,
        powershot_units_array=ability.powershot_units_array,
        powershot_units_hit=ability.powershot_units_hit,
        powershot_radius=ability.powershot_radius,
        powershot_damage_percent=ability.powershot_damage_percent,
        powershot_damage_reduction=ability.powershot_damage_reduction,
        powershot_speed_reduction=ability.powershot_speed_reduction,
        powershot_tree_width=ability.powershot_tree_width,
        powershot_vision_radius=ability.powershot_vision_radius,
        powershot_vision_duration=ability.powershot_vision_duration,
        powershot_max_range=ability.powershot_max_range
    }

    -- Traverse
    Timers:CreateTimer( function()
            -- Traverse the point
            context.powershot_currentPos = context.powershot_currentPos + ( context.powershot_direction * context.powershot_percent_movespeed/100 * context.powershot_max_movespeed * 1/30 )
            context.powershot_traveled = context.powershot_traveled + context.powershot_max_movespeed * 1/30

            -- Loop through the units array
            for k, v in pairs( context.powershot_units_array ) do
                -- Check if it never got hit and is in radius
                if context.powershot_units_hit[ k ] == false and powershot_distance( v:GetAbsOrigin(), context.powershot_currentPos ) <= context.powershot_radius then
                    -- Deal damage
                    victimOriginBeforeDeath = v:GetAbsOrigin()
                    print(victimOriginBeforeDeath.x)
                    local damageTable =
                    {
                        victim = v,
                        attacker = caster,
                        damage = ability:GetAbilityDamage() * context.powershot_damage_percent,
                        damage_type = ability:GetAbilityDamageType()
                    }
                    if v:HasModifier('modifier_wr_magic_immunity') then
                        ProjectileManager:DestroyLinearProjectile(context.powershot_projectileID)
                        StartSoundEvent('Hero_WitchDoctor.Paralyzing_Cask_Bounce', v)

                        local victimOrigin = v:GetAbsOrigin()
                        local arrowOrigin = context.powershot_currentPos

                        local reflectedVelocity = (context.powershot_currentPos - victimOrigin):Normalized() * ability.powershot_max_movespeed
--                        print(reflectedDirection.x .. ', ' .. reflectedDirection.y)
--                        local reflectedVelocity

                        local reflectedProjectileTable =
                        {
                            EffectName = projectileName,
                            Ability = ability,
                            vSpawnOrigin = context.powershot_currentPos,
                            vVelocity = reflectedVelocity,
--                            vVelocity = -Vector(ability.powershot_direction.x * ability.powershot_max_movespeed, ability.powershot_direction.y * ability.powershot_max_movespeed, 0),
                            fDistance = ability.powershot_max_range - context.powershot_traveled,
                            fStartRadius = ability.powershot_radius,
                            fEndRadius = ability.powershot_radius,
                            Source = caster,
                            bHasFrontalCone = false,
                            bReplaceExisting = true,
                            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
                            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                            iVisionRadius = ability.powershot_vision_radius,
                            iVisionTeamNumber = caster:GetTeamNumber()
                        }
                        caster.powershot_projectileID = ProjectileManager:CreateLinearProjectile( reflectedProjectileTable )

                        return nil
                    else
                        ApplyDamage( damageTable )
                        -- Reduction
                        context.powershot_damage_percent = context.powershot_damage_percent * ( 1.0 - context.powershot_damage_reduction )
                        context.powershot_percent_movespeed = context.powershot_percent_movespeed * ( 1.0 - context.powershot_speed_reduction )
                        -- Change flag
                        context.powershot_units_hit[ k ] = true
                        -- Fire sound
--                        StartSoundEvent( "Hero_Windrunner.PowershotDamage", v )
                        StartSoundEvent( "Hero_Enchantress.ImpetusDamage", v )
                        -- ParticleManager:SetParticleControlOrientation(blood_particle_id, 1, -ability.powershot_direction, Vector(0, 1, 0), Vector(0, 0, 1))
                        if v:IsAlive() ~= true then
                            StartSoundEvent('Hero_PhantomAssassin.CoupDeGrace', v)
                            -- local blood_particle_id = ParticleManager:CreateParticle('particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf', PATTACH_POINT, v)
                            local blood_particle_id = ParticleManager:CreateParticle('particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf', PATTACH_CUSTOMORIGIN, nil)
                            ParticleManager:SetParticleControl(blood_particle_id, 0, victimOriginBeforeDeath + Vector(10, 0, 0))
                            ParticleManager:SetParticleControl(blood_particle_id, 1, victimOriginBeforeDeath + Vector(10, 0, 0))
                            ParticleManager:SetParticleControlOrientation(blood_particle_id, 1, -ability.powershot_direction, Vector(0, 1, 0), Vector(0, 0, 1))
                        else
                            -- local sparks_particle_id = ParticleManager:CreateParticle('particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_sparks_lv.vpcf', PATTACH_POINT_FOLLOW, v)
                            local sparks_particle_id = ParticleManager:CreateParticle('particles/units/heroes/hero_pudge/pudge_meathook_impact_droplets.vpcf', PATTACH_POINT, v)
                            ParticleManager:CreateParticle('particles/units/heroes/hero_bloodseeker/bloodseeker_bloodritual_impact_c.vpcf', PATTACH_POINT, v)
                            print(v:GetAbsOrigin().x)

                            v:AddNewModifier(caster, ability, "modifier_stunned", {duration=0.25})
--                            ability:ApplyDataDrivenModifier(caster, victim, 'modifier_powershot_stun', {})
--                            ParticleManager:SetParticleControl(blood_particle_id, 0, victimOriginBeforeDeath + Vector(10, 0, 0))
--                            ParticleManager:SetParticleControl(blood_particle_id, 1, victimOriginBeforeDeath + Vector(10, 0, 0))
--                            ParticleManager:SetParticleControlOrientation(sparks_particle_id, 1, -ability.powershot_direction, Vector(0, 1, 0), Vector(0, 0, 1))
                        end
                    end
                end
            end

            -- Check for nearby trees, destroy them if they exist
            if GridNav:IsNearbyTree( context.powershot_currentPos, context.powershot_radius, true ) then
                GridNav:DestroyTreesAroundPoint(context.powershot_currentPos, context.powershot_tree_width, false)
            end

            -- Create visibility node
            AddFOWViewer(caster:GetTeamNumber(), context.powershot_currentPos, context.powershot_vision_radius, context.powershot_vision_duration, false)

            -- Check if damage point reach the maximum range, if so, delete the timer
            if context.powershot_traveled < context.powershot_max_range then
                return 1/30
            else
                return nil
            end
        end
    )
end

--[[
    Author: kritth
    Date: 5.1.2015.
    Helper: Calculate distance between two points
]]
function powershot_distance( pointA, pointB )
    local dx = pointA.x - pointB.x
    local dy = pointA.y - pointB.y
    return math.sqrt( dx * dx + dy * dy )
end
