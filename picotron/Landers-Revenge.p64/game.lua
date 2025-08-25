-- LANDER'S REVENGE - Core Game Logic

-- Game state management
game_state = "menu"
states = {menu=1, playing=2, upgrade=3, dialog=4, game_over=5, destroyed=6, boss_fight=7, ending=8}

-- Global game variables
level = 1
target_pad = 1
destruction_timer = 0
rescue_timer = 0
crash_x = 0
crash_y = 0

-- Menu background scrolling
menu_scroll_x = 0
menu_terrain = {}
menu_buildings = {}

-- Ending cutscene variables
ending_timer = 0
ending_text_phase = 1

function game_init()
    generate_terrain()
    place_landing_pads()
    player_reset()  -- Reset player after landing pads are generated
    generate_menu_background()
    if game_options.skip_intro then
        game_state = "playing"
    else
        start_simple_dialog()
    end
end

function game_update()
    if game_state == "menu" then
        update_menu()
    elseif game_state == "playing" then
        update_playing()
    elseif game_state == "upgrade" then
        update_upgrade_screen()
    elseif game_state == "dialog" then
        update_dialog()
    elseif game_state == "game_over" then
        update_game_over()
    elseif game_state == "destroyed" then
        update_destroyed()
    elseif game_state == "boss_fight" then
        update_boss_fight()
    elseif game_state == "ending" then
        update_ending()
    end
end

function game_draw()
    cls(0)
    
    if game_state == "menu" then
        draw_menu()
    elseif game_state == "playing" then
        draw_playing()
    elseif game_state == "upgrade" then
        draw_upgrade_overlay()
    elseif game_state == "dialog" then
        draw_dialog()
    elseif game_state == "game_over" then
        draw_game_over()
    elseif game_state == "destroyed" then
        draw_destroyed()
    elseif game_state == "boss_fight" then
        draw_boss_fight()
    elseif game_state == "ending" then
        draw_ending()
    end
    
    -- Debug information (only if enabled)
    if debug_mode then
        draw_debug_info()
    end
end

-- Menu state
function update_menu()
    -- Update scrolling background
    menu_scroll_x += 0.5  -- Slow scroll speed
    
    -- Wrap scroll position for infinite scrolling
    local terrain_width = world_config.terrain_width * world_config.terrain_spacing * 2
    if menu_scroll_x > terrain_width then
        menu_scroll_x -= terrain_width
    end
    
    if btnp(4) then  -- Z key (button 4) - hardcoded for now
        if debug_mode then print("Menu: Transitioning to dialog") end
        game_state = "dialog"
        start_simple_dialog()
    end
end

-- Playing state
function update_playing()
    -- Handle shop prompt if active (but don't pause game)
    if show_shop_prompt then
        shop_prompt_timer += 1
        
        -- Hide shop prompt if player starts moving
        local velocity_threshold = 0.1
        local is_moving = abs(player.vx) > velocity_threshold or abs(player.vy) > velocity_threshold
        if is_moving then
            show_shop_prompt = false
        end
        
        if btnp(4) then  -- Z key - enter shop
            generate_upgrade_choices()
            game_state = "upgrade"
            show_shop_prompt = false
        elseif shop_prompt_timer > 300 then  -- Timeout only - removed X key skip
            show_shop_prompt = false
        end
        
        -- Continue with normal game logic - game stays active
    end
    
    handle_player_input()
    update_player_physics()
    update_bullets()
    update_enemies()
    update_particles()
    update_coins()
    update_bullet_trails()
    update_camera()
    check_player_terrain_collision()
    check_landing()
    
    -- Check if we should spawn boss
    if not boss_active and should_spawn_boss() then
        spawn_boss()
        game_state = "boss_fight"  -- Switch to boss fight state
    else
        spawn_enemies()
    end
    
    -- Update boss if active
    if boss_active then
        update_boss()
    end
    
    -- Update level progression
    update_level_progression()
    
    -- Check for destruction
    if player.health <= 0 then
        game_state = "destroyed"
        destruction_timer = 0
        rescue_timer = 0
    end
end

function draw_playing()
    -- Draw horizon first (farthest background layer)
    draw_horizon()
    
    -- Draw starfield background
    draw_starfield()
    
    -- Draw background objects with parallax
    draw_background_objects()
    
    -- Draw world
    draw_terrain()
    draw_landing_pads()
    
    -- Draw effects first
    draw_bullet_trails()
    
    -- Draw entities
    draw_enemies()
    draw_player()
    draw_bullets()
    draw_particles()
    draw_coins()
    
    -- Draw boss if active
    if boss_active then
        draw_boss()
    end
    
    -- Draw targeting system on top (only in playing state)
    draw_target_indicator()
    
    -- Draw UI last
    draw_game_ui()
    
    -- Draw landing debug info
    draw_landing_debug()
    
    -- Draw shop prompt if active
    if show_shop_prompt then
        draw_shop_prompt()
    end
    
    -- Draw level complete text
    draw_level_complete_text()
end

-- Boss fight state
function update_boss_fight()
    handle_player_input()
    update_player_physics()
    update_bullets()
    update_enemies()  -- Still need enemy updates for collision checking
    update_particles()
    update_coins()
    update_bullet_trails()
    update_camera()
    check_player_terrain_collision()
    check_landing()  -- Allow landing for refueling during boss fights

    -- Update boss
    if boss_active then
        update_boss()
    else
        -- Boss defeated, go back to playing state for level progression
        game_state = "playing"
    end

    -- Update level progression
    update_level_progression()

    -- Check for destruction
    if player.health <= 0 then
        game_state = "destroyed"
        destruction_timer = 0
        rescue_timer = 0
    end
end

function draw_boss_fight()
    -- Draw horizon first (farthest background layer)
    draw_horizon()
    
    -- Draw starfield background
    draw_starfield()
    
    -- Draw background objects with parallax
    draw_background_objects()
    
    -- Draw world (terrain doesn't scroll during boss fight)
    draw_terrain()
    draw_landing_pads()
    
    -- Draw effects first
    draw_bullet_trails()
    
    -- Draw entities
    draw_enemies()
    draw_player()
    draw_bullets()
    draw_particles()
    draw_coins()
    
    -- Draw boss
    if boss_active then
        draw_boss()
    end
    
    -- Draw targeting system on top
    draw_target_indicator()
    
    -- Draw UI last
    draw_game_ui()
    
    -- Draw boss fight indicator
    print("BOSS FIGHT!", 200, 250, 8)
    
    -- Draw level complete text
    draw_level_complete_text()
end

-- Game over state
function update_game_over()
    if btnp(input_config.menu_select) then
        restart_game()
    end
end

function restart_game()
    game_state = "menu"
    level = balance_config.starting_level
    target_pad = 1
    clear_enemies()
    reset_dialog()
    reset_upgrades()
    reset_boss_for_new_level()  -- Reset boss state
    generate_terrain()
    place_landing_pads()
    player_reset()  -- Reset player after landing pads are generated
end

-- Utility functions
function get_current_state_name()
    for name, id in pairs(states) do
        if game_state == name then
            return name
        end
    end
    return "unknown"
end

function change_state(new_state)
    if states[new_state] then
        game_state = new_state
        return true
    end
    return false
end

function draw_debug_info()
    -- Debug info in top-left corner
    print("DEBUG:", 5, 5, 8)
    print("State: " .. tostr(game_state), 5, 15, 7)
    print("Level: " .. tostr(level), 5, 25, 7)
    print("Target: " .. tostr(target_pad), 5, 35, 7)
    
    -- Button state debug
    print("Buttons:", 5, 50, 8)
    local btn_str = ""
    for i = 0, 5 do
        if btn(i) then btn_str = btn_str .. i end
    end
    print("Held: " .. btn_str, 5, 60, 6)
    
    local btnp_str = ""
    for i = 0, 5 do
        if btnp(i) then btnp_str = btnp_str .. i end
    end
    print("Pressed: " .. btnp_str, 5, 70, 6)
    
    -- Dialog debug
    print("Dialog active: " .. tostr(dialog_active), 5, 85, 7)
    print("Story: " .. tostr(current_story), 5, 95, 7)
    
    -- Player debug
    if player then
        print("Player health: " .. tostr(flr(player.health)), 5, 110, 7)
        print("Player fuel: " .. tostr(flr(player.fuel)), 5, 120, 7)
    end
    
    -- Arrays debug
    print("Enemies: " .. tostr(#enemies), 5, 135, 7)
    print("Bullets: " .. tostr(#bullets), 5, 145, 7)
    print("Terrain pts: " .. tostr(#terrain), 5, 155, 7)
end

-- Destroyed state
function update_destroyed()
    destruction_timer += 1
    
    if destruction_timer > 60 then -- 3 seconds of destruction
        rescue_timer += 1
        if rescue_timer > 120 then -- 4 seconds of rescue message
            -- Return to playing
            respawn_at_last_safe_position()
            destruction_timer = 0
            rescue_timer = 0
            game_state = "playing"
        end
    end
end

function draw_destroyed()
    -- Draw the game world normally (no dark overlay)
    draw_playing()
    
    -- Draw crash site explosion and effects
    draw_crash_site_effects()
    
    if destruction_timer <= 60 then
        -- Destruction phase - overlay text without background box
        local shake_x = (rnd(6) - 3)
        local shake_y = (rnd(6) - 3)
        
        -- Centered explosion text based on crash type
        local text = "SHIP DESTROYED!"
        if crash_reason == "fuel_crash" then
            text = "OUT OF FUEL CRASH!"
        elseif crash_reason == "health_crash" then
            text = "SHIP DESTROYED!"
        elseif crash_reason == "velocity_crash" then
            text = "TOO FAST CRASH!"
        elseif crash_reason == "terrain_crash" then
            text = "TERRAIN COLLISION!"
        end
        
        local text_x = (480 - #text * 8) / 2  -- Center text on screen (larger font)
        local text_y = 50  -- Top area
        
        -- Large, shaking text with outline for visibility
        print(text, text_x + shake_x - 1, text_y + shake_y, 0)  -- Black outline
        print(text, text_x + shake_x + 1, text_y + shake_y, 0)
        print(text, text_x + shake_x, text_y + shake_y - 1, 0)
        print(text, text_x + shake_x, text_y + shake_y + 1, 0)
        print(text, text_x + shake_x, text_y + shake_y, 8)      -- Red main text
        
    else
        -- Rescue phase - centered text with background box
        local line1 = "The local moon dwellers find your wreckage..."
        local line2 = "They drag your ship back to the last landing pad."
        local line3 = "Your ship has been repaired!"
        
        -- Progress indicator
        local dots = ""
        local dot_count = flr(rescue_timer / 20) % 4
        for i = 1, dot_count do
            dots = dots .. "."
        end
        local launch_text = "Preparing for launch" .. dots
        
        -- Calculate box dimensions based on longest line
        local longest_line = line2  -- This is typically the longest
        local box_width = (#longest_line * 4) + 200  -- Text width + padding
        local box_height = 80  -- Height for 4 lines + padding
        local box_x = (480 - box_width) / 2
        local box_y = (270 - box_height) / 2  -- Center vertically on screen
        
        -- Draw background box with border
        rectfill(box_x, box_y, box_x + box_width, box_y + box_height, 1)  -- Dark blue background
        rect(box_x, box_y, box_x + box_width, box_y + box_height, 7)      -- White border
        
        -- Calculate centered text positions
        local line1_x = (480 - #line1 * 4) / 2
        local line2_x = (480 - #line2 * 4) / 2
        local line3_x = (480 - #line3 * 4) / 2
        local launch_x = (480 - #launch_text * 4) / 2
        
        -- Adjust Y positions to be centered in the box
        local text_start_y = box_y + 10
        
        -- Draw text without outlines since we have background box
        print(line1, line1_x, text_start_y, 7)      -- White text
        print(line2, line2_x, text_start_y + 15, 6) -- Light grey text
        print(line3, line3_x, text_start_y + 30, 11) -- Light green text
        print(launch_text, launch_x, text_start_y + 50, 12) -- Light blue text
    end
end

function draw_crash_site_effects()
    local crash_screen_x = crash_x - camera.x
    local crash_screen_y = crash_y - camera.y
    
    -- Only draw if crash site is visible on screen
    if crash_screen_x > -50 and crash_screen_x < 530 and crash_screen_y > -50 and crash_screen_y < 320 then
        
        -- Draw explosion at crash site
        local explosion_size = 20 + (destruction_timer * 0.5)  -- Growing explosion
        local explosion_intensity = max(0, 1 - (destruction_timer / 60))  -- Fade over time
        
        -- Multiple explosion circles for effect
        for i = 1, 5 do
            local radius = explosion_size * (0.5 + i * 0.2)
            local color = 8 + (i % 3)  -- Red/orange colors (8, 9, 10)
            if explosion_intensity > 0.3 then
                circ(crash_screen_x, crash_screen_y, radius * explosion_intensity, color)
            end
        end
        
        -- Fire and smoke particles
        for i = 1, 8 do
            local particle_x = crash_screen_x + (rnd(30) - 15)
            local particle_y = crash_screen_y + (rnd(20) - 10) - (destruction_timer * 0.3)  -- Rise over time
            
            -- Fire particles (red/orange/yellow)
            if destruction_timer < 40 and rnd(1) > 0.3 then
                local fire_color = 8 + flr(rnd(3))  -- Colors 8, 9, 10
                pset(particle_x, particle_y, fire_color)
            end
            
            -- Smoke particles (grey/dark grey)
            if destruction_timer > 20 and rnd(1) > 0.5 then
                local smoke_color = 5 + flr(rnd(2))  -- Colors 5, 6 (grey tones)
                pset(particle_x, particle_y - 10, smoke_color)
            end
        end
        
        -- Debris particles
        for i = 1, 6 do
            local debris_x = crash_screen_x + (rnd(40) - 20)
            local debris_y = crash_screen_y + (rnd(30) - 15)
            pset(debris_x, debris_y, 0)  -- Black debris
        end
    end
end

-- Ending cutscene functions
function update_ending()
    ending_timer += 1
    
    -- Progress through text phases
    if ending_timer > 180 and ending_text_phase == 1 then  -- 6 seconds
        ending_text_phase = 2
    elseif ending_timer > 360 and ending_text_phase == 2 then  -- 12 seconds total
        ending_text_phase = 3
    elseif ending_timer > 540 and ending_text_phase == 3 then  -- 18 seconds total
        ending_text_phase = 4
    elseif ending_timer > 720 then  -- 24 seconds total - return to menu
        game_state = "menu"
        restart_game()
    end
end

function draw_ending()
    cls(0)  -- Black background
    
    -- Draw ending art - sprite 17 at 128x128 size in center of screen
    local sprite_x = (480 - 128) / 2  -- Center horizontally
    local sprite_y = (270 - 128) / 2  -- Center vertically
    
    -- Draw sprite 17 at 128x128 size (scaled up from original sprite size)
    spr(17, sprite_x, sprite_y, true, false, 4, 4)  -- 4x scale to make it 128x128
    
    -- Display text based on current phase
    if ending_text_phase >= 1 then
        local text1 = "The Evil Barons have been slained!"
        local text1_x = (480 - #text1 * 4) / 2
        print(text1, text1_x, 50, 11)  -- White text at top
    end
    
    if ending_text_phase >= 2 then
        local text2 = "The mighty Prince has reclaimed his throne"
        local text2_x = (480 - #text2 * 4) / 2
        print(text2, text2_x, 200, 12)  -- Blue text below sprite
    end
    
    if ending_text_phase >= 3 then
        local text3 = "as King Tom Lander the First!"
        local text3_x = (480 - #text3 * 4) / 2
        print(text3, text3_x, 215, 12)  -- Blue text continued
    end
    
    if ending_text_phase >= 4 then
        local text4 = "He has achieved..... REVENGE!!!"
        local text4_x = (480 - #text4 * 4) / 2
        print(text4, text4_x, 240, 8)  -- Red text at bottom
    end
end

-- Menu background functions
function generate_menu_background()
    -- Generate wider terrain for menu scrolling (double width)
    local terrain_width = world_config.terrain_width * 2
    menu_terrain = {}

    local current_height = 200  -- Start at a reasonable height
    for i = 1, terrain_width do
        local x = i * world_config.terrain_spacing

        -- More dramatic terrain variation for visual interest
        local height_change = (rnd(world_config.terrain_variation * 3) - world_config.terrain_variation * 1.5)
        current_height += height_change

        -- Keep height within bounds but allow more variation
        current_height = max(world_config.terrain_min_height - 20, min(world_config.terrain_max_height + 20, current_height))

        add(menu_terrain, {x = x, y = current_height})
    end

    -- Generate buildings along the terrain with parallax values
    menu_buildings = {}
    for i = 1, 20 do  -- More buildings for scrolling
        local x = rnd(terrain_width * world_config.terrain_spacing - 100)
        local terrain_y = get_menu_terrain_height_at(x)
        local building_type = (i % 3 == 0) and "building_1" or "building_2"

        -- Vary building sizes for more interest
        local building_width = 24 + rnd(16)  -- 24-40 width
        local building_height = 48 + rnd(32)  -- 48-80 height

        -- Assign parallax values for depth sorting (0.1 = far, 0.9 = near)
        local parallax = 0.2 + rnd(0.6)  -- Random parallax between 0.2 and 0.8

        add(menu_buildings, {
            x = x,
            y = terrain_y,
            type = building_type,
            width = building_width,
            height = building_height,
            color = (i % 4 == 0) and 12 or 6,  -- Mix of blue and grey buildings
            parallax = parallax
        })
    end
end

function get_menu_terrain_height_at(x)
    -- Find closest terrain point
    local terrain_index = flr(x / world_config.terrain_spacing) + 1
    terrain_index = max(1, min(#menu_terrain, terrain_index))
    
    if menu_terrain[terrain_index] then
        return menu_terrain[terrain_index].y
    end
    return world_config.terrain_min_height
end

function draw_terrain_segment(x1, y1, x2, y2, terrain_width)
    -- Only draw if visible on screen
    if x2 > 0 and x1 < 480 then
        line(x1, y1, x2, y2, world_config.terrain_color)
        -- Fill terrain to bottom of screen
        if x1 < x2 then
            rectfill(x1, y1, x2, 270, world_config.terrain_fill_color)
        end
    end
end

function draw_menu_terrain_segment(x1, y1, x2, y2, terrain_width)
    -- Only draw if visible on screen
    if x2 > 0 and x1 < 480 then
        -- Fill ground from bottom of screen up to terrain line (grey ground)
        -- No terrain line drawn - just the ground fill
        if x1 < x2 then
            -- Find the minimum y value for this segment to fill from bottom
            local min_y = min(y1, y2)
            local max_y = max(y1, y2)

            -- Fill grey ground from bottom of screen (270) up to terrain
            rectfill(x1, min_y, x2, 270, 5)  -- Dark grey ground

            -- Add some rocky texture with random pixels
            for i = 0, x2 - x1, 2 do
                local x = x1 + i
                if x >= 0 and x < 480 and rnd(1) > 0.7 then
                    local rock_y = min_y + rnd(20)  -- Rocks near surface
                    if rock_y < 270 then
                        pset(x, rock_y, 1)  -- Dark blue rocks
                    end
                end
            end

            -- Add some lighter highlights on terrain surface
            if rnd(1) > 0.5 then
                local highlight_x = x1 + rnd(x2 - x1)
                if highlight_x >= 0 and highlight_x < 480 then
                    -- Interpolate y position along the terrain line
                    local t = (highlight_x - x1) / (x2 - x1)
                    local highlight_y = y1 + t * (y2 - y1)
                    pset(highlight_x, highlight_y, 6)  -- Light grey highlights
                end
            end
        end
    end
end

function draw_building_at(x, y, building)
    -- Only draw if visible on screen
    if x > -64 and x < 480 then
        if sprites.use_sprites and sprites[building.type] then
            -- Draw sprite version
            local sprite_index = (building.type == "building_1") and sprites.building_1 or sprites.building_2
            spr(sprite_index, x, y - 64, false, false)  -- flipy=true
        else
            -- Fallback vector art
            rectfill(x, y - building.height, x + building.width, y, building.color)
            rect(x, y - building.height, x + building.width, y, 1)  -- Dark blue outline
            -- Simple antenna
            line(x + building.width/2, y - building.height, x + building.width/2, y - building.height - 8, building.color)
            pset(x + building.width/2, y - building.height - 8, 8)  -- Red light
        end
    end
end

function draw_building_at_parallax(x, y, building, terrain_width)
    -- Only draw if visible on screen
    if x > -64 and x < 480 then
        -- Adjust building appearance based on parallax distance
        local depth_factor = building.parallax
        local alpha_effect = depth_factor  -- Closer buildings are more opaque

        if sprites.use_sprites and sprites[building.type] then
            -- Draw sprite version
            local sprite_index = (building.type == "building_1") and sprites.building_1 or sprites.building_2
            spr(sprite_index, x, y - 64, false, false)
        else
            -- Fallback vector art with depth-based color adjustment
            local building_color = building.color

            -- Make distant buildings darker/more faded
            if depth_factor < 0.4 then
                building_color = 5  -- Dark grey for distant buildings
            elseif depth_factor < 0.6 then
                building_color = 6  -- Medium grey for mid-distance buildings
            end

            rectfill(x, y - building.height, x + building.width, y, building_color)
            rect(x, y - building.height, x + building.width, y, 1)  -- Dark blue outline

            -- Only draw antenna on closer buildings
            if depth_factor > 0.5 then
                line(x + building.width/2, y - building.height, x + building.width/2, y - building.height - 8, building_color)
                pset(x + building.width/2, y - building.height - 8, 8)  -- Red light
            end
        end
    end
end

function draw_menu_horizon()
    local config = world_config

    -- Draw horizon rectangle similar to in-game, but adapted for menu
    -- Use average terrain height for menu horizon positioning
    local avg_terrain_height = (config.terrain_min_height + config.terrain_max_height) / 2
    local horizon_y = avg_terrain_height - 40  -- Similar offset as in-game
    local horizon_bottom = horizon_y + 400

    -- Ensure horizon is visible and covers the right area
    if horizon_y < 270 and horizon_bottom > 0 then
        rectfill(0, max(0, horizon_y), 480, min(270, horizon_bottom), config.horizon_color)
    end
end

function draw_menu_buildings_sorted()
    -- Create a sorted copy of buildings by parallax distance (furthest first)
    local sorted_buildings = {}
    for building in all(menu_buildings) do
        add(sorted_buildings, building)
    end

    -- Sort by parallax (lower parallax = further away = draw first)
    for i = 1, #sorted_buildings - 1 do
        for j = i + 1, #sorted_buildings do
            if sorted_buildings[i].parallax > sorted_buildings[j].parallax then
                local temp = sorted_buildings[i]
                sorted_buildings[i] = sorted_buildings[j]
                sorted_buildings[j] = temp
            end
        end
    end

    -- Draw sorted buildings with parallax scrolling
    local terrain_width = world_config.terrain_width * world_config.terrain_spacing * 2

    for building in all(sorted_buildings) do
        -- Apply parallax scrolling based on building's parallax value
        local x = building.x - (menu_scroll_x * building.parallax)
        local y = building.y

        -- Draw building (with wrapping)
        draw_building_at_parallax(x, y, building, terrain_width)

        -- Also draw wrapped version if needed
        if x < 100 then  -- Near left edge, draw wrapped version on right
            draw_building_at_parallax(x + terrain_width, y, building, terrain_width)
        elseif x > terrain_width - 100 then  -- Near right edge, draw wrapped version on left
            draw_building_at_parallax(x - terrain_width, y, building, terrain_width)
        end
    end
end

function draw_menu_background()
    -- Draw horizon similar to in-game horizon
    draw_menu_horizon()

    -- Draw scrolling buildings first (behind terrain) with simplified wrapping
    -- Sort buildings by parallax distance (furthest first)
    draw_menu_buildings_sorted()

    -- Draw scrolling terrain in front of all objects
    local terrain_width = world_config.terrain_width * world_config.terrain_spacing * 2

    for i = 1, #menu_terrain - 1 do
        local p1 = menu_terrain[i]
        local p2 = menu_terrain[i + 1]

        -- Apply scroll offset
        local x1 = p1.x - menu_scroll_x
        local x2 = p2.x - menu_scroll_x

        -- Draw terrain segment (with wrapping)
        draw_menu_terrain_segment(x1, p1.y, x2, p2.y, terrain_width)

        -- Also draw wrapped version if needed
        if x1 < 100 then  -- Near left edge, draw wrapped version on right
            draw_menu_terrain_segment(x1 + terrain_width, p1.y, x2 + terrain_width, p2.y, terrain_width)
        elseif x1 > terrain_width - 100 then  -- Near right edge, draw wrapped version on left
            draw_menu_terrain_segment(x1 - terrain_width, p1.y, x2 - terrain_width, p2.y, terrain_width)
        end
    end
end