--[[pod_format="raw",created="2025-08-22 01:47:13",modified="2025-08-22 01:47:13",revision=0]]
-- LANDER'S REVENGE
-- A lunar lander rogue-like game  
-- Tom Lander's quest to reclaim his throne

-- Include all game modules
include "config.lua"    -- Configuration and sprite settings
include "player.lua"    -- Player ship system
include "enemies.lua"   -- Enemy spawning and AI
include "terrain.lua"   -- World generation and terrain
include "ui.lua"        -- User interface elements
include "dialog.lua"    -- Story and dialog system
include "upgrades.lua"  -- Upgrade system
include "boss.lua"      -- Boss fight system
include "game.lua"      -- Core game logic

-- Picotron entry points
function _init()
    -- Set transparency for color 0 (black)
    palt(0, true)  -- Make color 0 transparent
    palt()         -- Reset other colors to opaque
    
    game_init()
end

function _update()
    game_update()
end

function _draw()
    game_draw()
end