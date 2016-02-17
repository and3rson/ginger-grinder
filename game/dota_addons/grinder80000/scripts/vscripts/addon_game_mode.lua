require "tracker"
require "broadcaster"
require "grinder"
require "utils"
require "notifications"

function Precache( context )
    print(" > Precache()")
    --[[
        Precache things we know we'll use.  Possible file types include (but not limited to):
            PrecacheResource( "model", "*.vmdl", context )
            PrecacheResource( "soundfile", "*.vsndevts", context )
            PrecacheResource( "particle", "*.vpcf", context )
            PrecacheResource( "particle_folder", "particles/folder", context )
    ]]
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_legion_commander.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_pudge.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
    PrecacheResource("soundfile", "particles/wr_block/wr_block.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_ui.vsndevts", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context)
    PrecacheResource("particle", "particles/units/heroes/hero_legion_commander/legion_commander_duel_victory.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_inground.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf", context)
--    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_puck.vsndevts", context)
end

-- Create the game mode when we activate
function Activate()
    print(" > Activate()")
    GameRules.tracker = Tracker()
    GameRules.tracker:Initialize()

    GameRules.broadcaster = Broadcaster()
    GameRules.broadcaster:Initialize()

    GameRules.grinder = Grinder()
    GameRules.grinder:InitGameMode()
end
