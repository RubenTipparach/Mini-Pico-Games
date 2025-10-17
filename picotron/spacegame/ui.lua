-- ui.lua - user interface system

ui = {}

function ui.init()
    -- any ui initialization
end

function ui.draw()
    -- health bar (top left)
    ui.draw_health_bar()
    
    -- xp bar (bottom)
    ui.draw_xp_bar()
    
    -- wave info (top right)
    ui.draw_wave_info()
    
    -- score (top center)
    ui.draw_score()
    
    -- weapon display (left side)
    ui.draw_weapons()
end

function ui.draw_health_bar()
    local x, y = 10, 10
    local w, h = 100, 8
    
    -- background
    rect(x, y, x + w, y + h, 5)
    
    -- health fill
    local health_percent = player.health / player.max_health
    local fill_w = w * health_percent
    local color = health_percent > 0.5 and 11 or (health_percent > 0.25 and 9 or 8)
    rectfill(x, y, x + fill_w, y + h, color)
    
    -- text
    print("Health", x, y - 8, 7)
    print(flr(player.health) .. "/" .. player.max_health, x + w + 5, y, 7)
end

function ui.draw_xp_bar()
    local x, y = 10, sh - 20
    local w, h = sw - 20, 6
    
    -- background
    rect(x, y, x + w, y + h, 5)
    
    -- xp fill
    local xp_percent = xp.get_xp_percent()
    local fill_w = w * xp_percent
    rectfill(x, y, x + fill_w, y + h, 10)
    
    -- text
    print("Level " .. xp.level, x, y - 8, 7)
    print("XP: " .. xp.current_xp .. "/" .. xp.xp_to_next, x + 60, y - 8, 6)
end

function ui.draw_wave_info()
    local info = waves.get_wave_info()
    local x, y = sw - 120, 10
    
    print("Wave " .. info.wave, x, y, 7)
    
    if info.is_endless then
        print("Endless Mode", x, y + 8, 6)
    else
        print("Enemies: " .. info.enemies_left, x, y + 8, 6)
    end
end

function ui.draw_score()
    local x = sw/2 - 30
    local y = 10
    
    print("Score: " .. game.score, x, y, 7)
end

function ui.draw_weapons()
    local x, y = 10, 50
    
    print("Weapons:", x, y, 7)
    
    for i, weapon_name in ipairs(player.current_weapons) do
        local weapon_y = y + 10 + (i-1) * 10
        print("• " .. weapon_name, x, weapon_y, 6)
    end
    
    -- player stats (if upgraded)
    local stats_y = y + 10 + #player.current_weapons * 10 + 10
    
    if player.damage_mult > 1 then
        print("Damage: +" .. flr((player.damage_mult - 1) * 100) .. "%", x, stats_y, 11)
        stats_y += 8
    end
    
    if player.range_mult > 1 then
        print("Range: +" .. flr((player.range_mult - 1) * 100) .. "%", x, stats_y, 11)
        stats_y += 8
    end
    
    if player.speed_mult > 1 then
        print("Speed: +" .. flr((player.speed_mult - 1) * 100) .. "%", x, stats_y, 11)
        stats_y += 8
    end
    
    if player.health_regen > 0 then
        print("Regen: " .. player.health_regen .. "/sec", x, stats_y, 11)
        stats_y += 8
    end
    
    if player.armor > 0 then
        print("Armor: " .. player.armor, x, stats_y, 11)
        stats_y += 8
    end
    
    if player.crit_chance > 0 then
        print("Crit: " .. flr(player.crit_chance * 100) .. "%", x, stats_y, 11)
        stats_y += 8
    end
end