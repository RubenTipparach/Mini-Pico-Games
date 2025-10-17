-- LANDER'S REVENGE - UI System

function draw_game_ui()
    draw_fuel_bar()
    draw_health_bar()
    draw_level_info()
    draw_money_display()
    draw_landing_safety_indicator()
    draw_controls_help()
    draw_fuel_warning()
    draw_emergency_landing_warning()
end

function draw_fuel_bar()
    local config = ui_config
    local x, y = config.fuel_bar_x, config.fuel_bar_y
    local w, h = config.fuel_bar_width, config.fuel_bar_height
    
    -- Background
    if sprites.use_sprites and sprites.fuel_bar_bg then
        spr(sprites.fuel_bar_bg, x, y, 1, 1, false, true)  -- flipy=true
    else
        rectfill(x, y, x + w, y + h, config.fuel_bar_bg_color)
        rect(x, y, x + w, y + h, config.fuel_bar_border_color)
    end
    
    -- Fuel fill
    local fuel_fill = (player.fuel / player.max_fuel) * w
    local fuel_color = get_fuel_color()
    
    if sprites.use_sprites and sprites.fuel_bar_fill then
        -- TODO: Handle sprite-based fuel bar with clipping
        rectfill(x, y, x + fuel_fill, y + h, fuel_color)
    else
        rectfill(x, y, x + fuel_fill, y + h, fuel_color)
    end
    
    -- Label
    print("FUEL", x, y - 8, config.text_primary)
end

function get_fuel_color()
    local config = ui_config
    if player.fuel <= 0 then
        return 8  -- Red when empty (crash danger)
    elseif player.fuel < config.fuel_critical_threshold then
        return config.fuel_critical_color
    elseif player.fuel < config.fuel_warning_threshold then
        return config.fuel_warning_color
    else
        return config.fuel_good_color
    end
end

function draw_health_bar()
    local config = ui_config
    local x, y = config.health_bar_x, config.health_bar_y
    local w, h = config.health_bar_width, config.health_bar_height
    
    -- Background
    rectfill(x, y, x + w, y + h, config.health_bar_bg_color)
    rect(x, y, x + w, y + h, config.health_bar_border_color)
    
    -- Health fill
    local health_fill = (player.health / player.max_health) * w
    local health_color = get_health_color()
    
    rectfill(x, y, x + health_fill, y + h, health_color)
    
    -- Label
    print("HEALTH", x, y - 8, config.text_primary)
end

function get_health_color()
    local config = ui_config
    if player.health < config.health_critical_threshold then
        return config.health_critical_color
    elseif player.health < config.health_warning_threshold then
        return config.health_warning_color
    else
        return config.health_good_color
    end
end

function draw_level_info()
    local config = ui_config
    print("LEVEL " .. level, 400, 10, config.text_primary)
    print("TARGET PAD " .. target_pad, 350, 25, config.text_secondary)
end

function draw_weapon_info()
    local config = ui_config
    if weapon_config and player then
        local primary = weapon_config.primary_weapons[player.current_primary]
        local secondary = weapon_config.secondary_weapons[player.current_secondary]
        
        -- Current weapons
        print("Primary: " .. primary.name, 200, 10, primary.color)
        print("Secondary: " .. secondary.name, 200, 25, secondary.color)
        
        -- Owned weapons count
        local owned_primary_count = 0
        local owned_secondary_count = 0
        for i = 1, #weapon_config.primary_weapons do
            if player.owned_weapons.primary[i] then owned_primary_count += 1 end
        end
        for i = 1, #weapon_config.secondary_weapons do
            if player.owned_weapons.secondary[i] then owned_secondary_count += 1 end
        end
        print("Owned: " .. owned_primary_count .. "/" .. #weapon_config.primary_weapons .. " P, " .. owned_secondary_count .. "/" .. #weapon_config.secondary_weapons .. " S", 200, 40, config.text_secondary)
        
        -- Target info
        if current_target > 0 and current_target <= #enemies then
            print("Target: Enemy " .. current_target, 200, 55, config.text_error)
        else
            print("Target: None", 200, 55, config.text_secondary)
        end
    end
end


function draw_money_display()
    local config = ui_config
    if player then
        print("Money: $" .. player.money, 10, 50, config.text_success)
    end
end

function draw_velocity_display()
    local config = ui_config
    if player then
        local vx_display = flr(abs(player.vx) * 100) / 100  -- Round to 2 decimal places
        local vy_display = flr(abs(player.vy) * 100) / 100
        local total_speed = flr(sqrt(player.vx^2 + player.vy^2) * 100) / 100
        
        print("Velocity:", 10, 70, config.text_primary)
        print("H: " .. vx_display .. "  V: " .. vy_display, 10, 80, config.text_secondary)
        print("Speed: " .. total_speed, 10, 90, config.text_secondary)
        
        -- Landing status debug
        local landing_status = player_landed and "LANDED" or "FLYING"
        local status_color = player_landed and config.text_success or config.text_secondary
        --print("Status: " .. landing_status, 10, 100, status_color)
    end
end

function draw_landing_safety_indicator()
    local config = ui_config
    if player then
        local safe_h_vel = world_config.velocity_tolerance or 0.5
        local safe_v_vel = world_config.velocity_tolerance or 0.5
        
        local h_safe = abs(player.vx) <= safe_h_vel
        local v_safe = abs(player.vy) <= safe_v_vel
        local landing_safe = h_safe and v_safe
        
        local status_color = landing_safe and config.text_success or config.text_error
        local status_text = landing_safe and "SAFE TO LAND" or "TOO FAST"
        
        print("Landing Status:", 10, 110, config.text_primary)
        print(status_text, 10, 120, status_color)
        
        -- Show individual velocity safety
        local h_color = h_safe and config.text_success or config.text_error
        local v_color = v_safe and config.text_success or config.text_error
        --print("H:" .. (h_safe and "OK" or "FAST") .. " V:" .. (v_safe and "OK" or "FAST"), 10, 130, config.text_secondary)
    end
end

function draw_controls_help()
    local config = ui_config
    print("WASD/Arrows: Thrust  Z: Cycle Targets  X: Cycle Weapons  Auto-Fire: ON", 10, 460, config.text_secondary)
end

function draw_fuel_warning()
    local config = ui_config
    
    if player.fuel <= 0 then
        -- Critical fuel warning (blinking)
        if (time() * 8) % 2 < 1 then  -- Blink every 1/8 second
            print("WARNING: OUT OF FUEL!", 200, 400, 8)  -- Red
            print("CRASH DANGER - LAND IMMEDIATELY!", 160, 415, 8)
        end
    elseif player.fuel < config.fuel_critical_threshold then
        -- Low fuel warning
        print("LOW FUEL WARNING", 200, 400, config.fuel_critical_color)
    end
end

function draw_emergency_landing_warning()
    local config = ui_config
    
    -- Check if health is critically low (less than 25% of max health)
    if player and player.health < (player.max_health * 0.25) then
        -- Flashing red bold text warning
        if (time() * 10) % 2 < 1 then  -- Blink every 1/10 second (faster than fuel warning)
            local warning_text = "EMERGENCY LANDING REQUIRED!"
            local text_x = (480 - #warning_text * 8) / 2  -- Center the text
            
            -- Draw bold text effect by drawing the same text multiple times with slight offsets
            print(warning_text, text_x - 1, 350, 8)  -- Left shadow
            print(warning_text, text_x + 1, 350, 8)  -- Right shadow
            print(warning_text, text_x, 349, 8)      -- Top shadow
            print(warning_text, text_x, 351, 8)      -- Bottom shadow
            print(warning_text, text_x, 350, 8)      -- Main text (red)
            
            -- Additional warning line
            local subtext = "CRITICAL DAMAGE DETECTED"
            local sub_x = (480 - #subtext * 4) / 2
            print(subtext, sub_x, 365, 8)
        end
    end
end

function draw_shop_prompt()
    local config = ui_config
    local box_w = 200
    local box_h = 70
    local box_x = 480 - box_w - 10  -- Right side with margin
    local box_y = 60  -- Upper right area
    
    -- Prompt box
    rectfill(box_x, box_y, box_x + box_w, box_y + box_h, 1)  -- Dark blue background
    rect(box_x, box_y, box_x + box_w, box_y + box_h, 7)      -- White border
    
    -- Refuel message
    print("REFUELED!", box_x + 70, box_y + 10, config.text_success)
    
    -- Shop prompt
    print("Shop Available", box_x + 55, box_y + 25, config.text_primary)
    print("Z: Enter Shop", box_x + 60, box_y + 45, config.text_highlight)
end

-- Menu UI
function draw_menu()
    local config = ui_config

    -- Draw scrolling background first
    draw_menu_background()

    -- Add some atmospheric particles/dust over the landscape
    draw_menu_atmosphere()

    -- Title with outline for better visibility against terrain
    local title = "LANDER'S REVENGE"
    local title_x = (480 - #title * 8) / 2
    -- Title outline (black outline for contrast)
    print(title, title_x - 1, 100, 0)
    print(title, title_x + 1, 100, 0)
    print(title, title_x, 99, 0)
    print(title, title_x, 101, 0)
    print(title, title_x, 100, config.text_primary)

    -- Subtitle with outline
    local subtitle = "The Bastard Prince's Quest"
    local sub_x = (480 - #subtitle * 4) / 2
    print(subtitle, sub_x - 1, 130, 0)
    print(subtitle, sub_x + 1, 130, 0)
    print(subtitle, sub_x, 129, 0)
    print(subtitle, sub_x, 131, 0)
    print(subtitle, sub_x, 130, config.text_secondary)

    -- Instructions with outline and highlight
    local instructions = "Press Z to Start"
    local inst_x = (480 - #instructions * 4) / 2
    print(instructions, inst_x - 1, 200, 0)
    print(instructions, inst_x + 1, 200, 0)
    print(instructions, inst_x, 199, 0)
    print(instructions, inst_x, 201, 0)
    print(instructions, inst_x, 200, config.text_highlight)

    -- Story setup with outlines
    local story1 = "Tom Lander must reclaim his throne"
    local story1_x = (480 - #story1 * 4) / 2
    print(story1, story1_x - 1, 250, 0)
    print(story1, story1_x + 1, 250, 0)
    print(story1, story1_x, 249, 0)
    print(story1, story1_x, 251, 0)
    print(story1, story1_x, 250, config.text_secondary)

    local story2 = "Navigate from Darkside to Armstrong City"
    local story2_x = (480 - #story2 * 4) / 2
    print(story2, story2_x - 1, 270, 0)
    print(story2, story2_x + 1, 270, 0)
    print(story2, story2_x, 269, 0)
    print(story2, story2_x, 271, 0)
    print(story2, story2_x, 270, config.text_secondary)
end

function draw_menu_atmosphere()
    -- Add some floating particles/dust for atmosphere
    for i = 1, 15 do
        local x = (rnd(480) + menu_scroll_x * 0.3) % 480  -- Slow parallax movement
        local y = 60 + rnd(200)  -- Particles in middle area
        local particle_color = (rnd(1) > 0.7) and 6 or 5  -- Light or dark grey
        pset(x, y, particle_color)
    end

    -- Add some distant atmospheric haze
    for i = 1, 8 do
        local x = (rnd(480) + menu_scroll_x * 0.1) % 480  -- Very slow movement
        local y = 40 + rnd(60)  -- Upper area
        pset(x, y, 20)  -- Same as horizon color
    end
end

-- Game Over UI
function draw_game_over()
    local config = ui_config
    
    print("GAME OVER", 200, 150, config.text_error)
    print("Tom Lander's quest has ended...", 140, 180, config.text_secondary)
    print("You reached level " .. level, 170, 210, config.text_primary)
    print("Press Z to try again", 170, 250, config.text_highlight)
    
    -- Show flavor text based on performance
    local flavor_text = get_game_over_flavor_text()
    local flavor_x = (480 - #flavor_text * 4) / 2
    print(flavor_text, flavor_x, 290, config.text_secondary)
end

function get_game_over_flavor_text()
    if level < 5 then
        return "The darkside proved too treacherous"
    elseif level < 10 then
        return "The royal guards were too strong"
    else
        return "A valiant effort, but the throne remains distant"
    end
end

-- Upgrade screen UI as overlay
function draw_upgrade_overlay()
    -- Draw the game world in background (faded)
    draw_playing()
    
    -- Dark semi-transparent overlay
    rectfill(0, 0, 480, 270, 1)  -- Dark blue overlay
    
    -- Draw shop window
    draw_shop_window()
end

function draw_shop_window()
    local config = ui_config
    local window_x = 60
    local window_y = 30
    local window_w = 360
    local window_h = 210
    
    -- Window background
    rectfill(window_x, window_y, window_x + window_w, window_y + window_h, 0)  -- Black background
    rect(window_x, window_y, window_x + window_w, window_y + window_h, 7)      -- White border
    
    -- Title
    print("LANDING PAD SHOP", window_x + 110, window_y + 10, config.text_success)
    print("Level " .. level .. " - Pad " .. target_pad, window_x + 130, window_y + 25, config.text_secondary)
    
    -- Draw available upgrades (moved up and adjusted spacing)
    for i = 1, #available_upgrades do
        local upgrade = available_upgrades[i]
        local y = window_y + 50 + i * 25  -- Tighter spacing and moved up
        local is_weapon = upgrade.type == "weapon_primary" or upgrade.type == "weapon_secondary"
        local is_selected = (i == upgrade_selection)
        
        -- Choose colors based on item type
        local name_color = upgrade_config.unselected_color
        local desc_color = upgrade_config.description_color
        
        if is_selected then
            name_color = upgrade_config.selection_color
            if is_weapon then
                desc_color = 11  -- Light green highlight for selected weapons
            end
        elseif is_weapon then
            name_color = 10  -- Yellow for weapon names
            desc_color = 9   -- Orange for weapon descriptions
        end
        
        -- Selection cursor
        if is_selected then
            local cursor_color = is_weapon and 8 or upgrade_config.cursor_color  -- Red cursor for weapons
            print(">", window_x + 10, y, cursor_color)
        end
        
        print(upgrade.name, window_x + 25, y, name_color)
        
        -- Show description (use custom desc for weapons, fallback for others)
        local desc = upgrade.desc or get_upgrade_description(upgrade.type)
        print(desc, window_x + 25, y + 8, desc_color)
    end
    
    -- Instructions
    print("W/S or ↑/↓: Select  Z: Purchase  X: Leave", window_x + 65, window_y + window_h - 25, config.text_highlight)
    
    -- Show current resources in corner
    print("Money: $" .. player.money, window_x + window_w - 100, window_y + 10, config.text_success)
    print("Fuel: " .. flr(player.fuel) .. "/" .. player.max_fuel, window_x + window_w - 100, window_y + 25, config.text_secondary)
    print("Health: " .. flr(player.health) .. "/" .. player.max_health, window_x + window_w - 100, window_y + 40, config.text_secondary)
end

-- Legacy function (kept for compatibility)
function draw_upgrade_screen()
    draw_upgrade_overlay()
end

function draw_player_stats()
    local config = ui_config
    print("Current Stats:", 300, 130, config.text_primary)
    print("Money: $" .. player.money, 300, 150, config.text_success)
    print("Fuel: " .. flr(player.fuel) .. "/" .. player.max_fuel, 300, 170, config.text_secondary)
    print("Health: " .. flr(player.health) .. "/" .. player.max_health, 300, 190, config.text_secondary)
    print("Thrust: " .. flr(player.thrust_power * 100), 300, 210, config.text_secondary)
    print("Armor: " .. flr(player.armor * 100) .. "%", 300, 230, config.text_secondary)
    print("Weapon Damage: " .. player.weapons.damage, 300, 250, config.text_secondary)
end

-- Dialog UI
function draw_dialog_box()
    local config = dialog_config
    
    -- Background box
    rectfill(config.box_x, config.box_y, 
             config.box_x + config.box_width, config.box_y + config.box_height, 
             config.box_bg_color)
    rect(config.box_x, config.box_y, 
         config.box_x + config.box_width, config.box_y + config.box_height, 
         config.box_border_color)
    
    -- Speaker name
    local speaker_x = config.box_x + config.text_x_offset
    local speaker_y = config.box_y + config.text_y_offset
    print(dialog.speaker .. ":", speaker_x, speaker_y, config.speaker_color)
    
    -- Dialog text
    local text_y = speaker_y + 20
    print(dialog.text, speaker_x, text_y, config.text_color)
    
    -- Continue prompt
    local continue_y = config.box_y + config.box_height - 20
    print("Press Z to continue", speaker_x, continue_y, config.continue_color)
end