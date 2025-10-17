-- Space Shooter Game - Main File with weapon selection and rogue-like progression

local player_mod = include "player_mod.lua"
local enemies_mod = include "enemies_mod.lua"
local bullets_mod = include "bullets_mod.lua"
local asteroids_mod = include "asteroids_mod.lua"
local collision_mod = include "collision_mod.lua"
local background_mod = include "background_mod.lua"
local levelup_mod = include "levelup_mod.lua"

function _init()
    -- Game state
    game_state = "weapon_select"  -- weapon_select, playing, level_up, game_over
    
    -- Initialize subsystems
    player_obj.init_player()
    bullets_mod.init_bullets()
    asteroids_mod.init_asteroids()
    enemies_mod.init_enemies()
    background_mod.init_background()
    levelup_mod.init_levelup()
    init_weapon_select()
end

function _update()
    if game_state == "weapon_select" then
        update_weapon_select()
    elseif game_state == "playing" then
        player_obj.update_player()
        bullets_mod.update_bullets()
        asteroids_mod.update_asteroids()
        enemies_mod.update_enemies()
        background_mod.update_background()
        collision_mod.check_all_collisions()
    elseif game_state == "level_up" then
        levelup_mod.update_levelup()
    elseif game_state == "game_over" then
        if btnp(4) then
            _init()
        end
    end
end

function _draw()
    if game_state == "weapon_select" then
        draw_weapon_select()
    elseif game_state == "playing" then
        cls(0)
        background_mod.draw_background()
        player_obj.draw_player()
        bullets_mod.draw_bullets()
        asteroids_mod.draw_asteroids()
        enemies_mod.draw_enemies()
        draw_ui()
    elseif game_state == "level_up" then
        levelup_mod.draw_levelup()
    elseif game_state == "game_over" then
        draw_game_over()
    end
end

function draw_ui()
    local player_obj = player_mod.get_player()
    
    -- Player stats
    print("shields: " .. flr(player_obj.shields) .. "/" .. player_obj.max_shields, 10, 10, 7)
    print("level: " .. player_obj.level, 10, 20, 7)
    print("xp: " .. player_obj.xp .. "/" .. (player_obj.level * 100), 10, 30, 7)
    print("kills: " .. player_obj.kills, 10, 40, 7)
    
    -- Weapon indicators
    local weapon_y = 10
    for i, weapon in ipairs(player_obj.weapons) do
        local weapon_char = "?"
        local weapon_color = 7
        
        if weapon.type == "front_turret" then
            weapon_char = "F"
            weapon_color = 10
        elseif weapon.type == "multi_turret" then
            weapon_char = "M"
            weapon_color = 9
        elseif weapon.type == "shotgun_turret" then
            weapon_char = "S"
            weapon_color = 14
        end
        
        print(weapon_char, 460 + (i-1) * 10, weapon_y, weapon_color)
    end
    
    -- Drone count
    if #player_obj.drones > 0 then
        print("drones: " .. #player_obj.drones, 400, 20, 11)
    end
    
    -- XP bar
    local xp_ratio = player_obj.xp / (player_obj.level * 100)
    local bar_width = 100
    local bar_x = 350
    local bar_y = 250
    
    -- Background
    rect(bar_x, bar_y, bar_x + bar_width, bar_y + 4, 5)
    
    -- XP fill
    if xp_ratio > 0 then
        rectfill(bar_x + 1, bar_y + 1, bar_x + bar_width * xp_ratio, bar_y + 3, 10)
    end
end

function draw_game_over()
    cls(0)
    local player_obj = player_mod.get_player()
    
    local text = "GAME OVER"
    local text_w = #text * 8
    print(text, (480 - text_w) / 2, 100, 8)
    
    print("Final Level: " .. player_obj.level, 200, 130, 7)
    print("Total Kills: " .. player_obj.kills, 200, 140, 7)
    
    print("Press Z to restart", 180, 180, 6)
end

-- Weapon selection screen
function init_weapon_select()
    weapon_select_choice = 1
    weapon_select_options = {
        {type = "front_turret", name = "Front Turret", desc = "Fires forward"},
        {type = "multi_turret", name = "Multi Turret", desc = "Fires in 4 directions"},
        {type = "shotgun_turret", name = "Shotgun", desc = "Spread shot at enemies"},
        {type = "drone", name = "Defense Drone", desc = "Orbiting protection"}
    }
end

function update_weapon_select()
    if btnp(2) then  -- up
        weapon_select_choice = max(1, weapon_select_choice - 1)
    elseif btnp(3) then  -- down
        weapon_select_choice = min(#weapon_select_options, weapon_select_choice + 1)
    elseif btnp(4) then  -- z
        -- Clear default weapon and add selected
        player_mod.get_player().weapons = {}
        player_mod.add_weapon_to_player(weapon_select_options[weapon_select_choice].type)
        game_state = "playing"
    end
end

function draw_weapon_select()
    cls(0)
    
    -- Title
    local title = "CHOOSE YOUR STARTING WEAPON"
    local title_w = #title * 8
    print(title, (480 - title_w) / 2, 60, 10)
    
    -- Weapon options
    for i, option in ipairs(weapon_select_options) do
        local y = 120 + (i - 1) * 30
        local color = (i == weapon_select_choice) and 11 or 7
        local bg_color = (i == weapon_select_choice) and 1 or 0
        
        -- Background for selected option
        if i == weapon_select_choice then
            rectfill(80, y - 5, 400, y + 20, bg_color)
            rect(80, y - 5, 400, y + 20, color)
        end
        
        -- Weapon name and description
        print(option.name, 90, y, color)
        print(option.desc, 90, y + 10, 6)
    end
    
    -- Controls
    print("Use arrow keys to select, Z to confirm", 120, 230, 5)
end