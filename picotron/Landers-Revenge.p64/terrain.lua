-- LANDER'S REVENGE - Terrain and World Generation

-- World data
terrain = {}
landing_pads = {}
camera = {x = 0, y = 0}
stars = {}
background_objects = {}
last_landed_pad = 0
show_shop_prompt = false
shop_prompt_timer = 0

function generate_terrain()
    terrain = {}
    local config = world_config
    local height = (config.terrain_min_height + config.terrain_max_height) / 2
    
    for i = 1, config.terrain_width do
        height += rnd(config.terrain_variation * 2) - config.terrain_variation
        height = max(config.terrain_min_height, min(height, config.terrain_max_height))
        terrain[#terrain + 1] = height
    end
    
    -- Generate starfield
    generate_starfield()
    
    -- Generate background objects
    generate_background_objects()
end

function generate_starfield()
    stars = {}
    local config = world_config
    local world_width = config.terrain_width * config.terrain_spacing
    
    for i = 1, config.star_count do
        stars[#stars + 1] = {
            x = rnd(world_width * 2),  -- Spread stars across larger area
            y = rnd(config.terrain_min_height - 50),  -- Stars only above terrain
            color = config.star_colors[flr(rnd(#config.star_colors)) + 1],
            brightness = rnd(1)  -- For twinkling effect
        }
    end
end

function generate_background_objects()
    background_objects = {}
    local config = world_config
    local world_width = config.terrain_width * config.terrain_spacing
    
    -- Generate distant mountains (furthest back) using sprites 5 and 6
    for i = 1, config.bg_mountain_count do
        background_objects[#background_objects + 1] = {
            type = "mountain",
            x = rnd(world_width * 3),  -- Spread across large area
            y = config.terrain_min_height + rnd(50),  -- Near horizon
            width = 64,  -- Sprite size
            height = 64, -- Sprite size
            color = 5,  -- Dark grey (fallback)
            parallax = 0.3,  -- Slow scrolling
            sprite_id = (i % 2 == 0) and 5 or 6  -- Alternate between sprites 5 and 6
        }
    end
    
    -- Generate outposts (middle layer)
    for i = 1, config.bg_outpost_count do
        local obj_width = sprites.use_sprites and 32 or (15 + rnd(25))
        local obj_height = sprites.use_sprites and 64 or (20 + rnd(30))
        
        background_objects[#background_objects + 1] = {
            type = "outpost",
            x = rnd(world_width * 2),
            y = config.terrain_min_height + rnd(30),
            width = obj_width,
            height = obj_height,
            color = 12,  -- Blue
            parallax = 0.5  -- Medium scrolling
        }
    end
    
    -- Generate rockets (closest layer)
    for i = 1, config.bg_rocket_count do
        local obj_width = sprites.use_sprites and 32 or (8 + rnd(12))
        local obj_height = sprites.use_sprites and 64 or (25 + rnd(35))
        
        background_objects[#background_objects + 1] = {
            type = "rocket",
            x = rnd(world_width * 1.5),
            y = config.terrain_min_height + rnd(20),
            width = obj_width,
            height = obj_height,
            color = 7,  -- White
            parallax = 0.7  -- Fast scrolling
        }
    end
end

function place_landing_pads()
    landing_pads = {}
    local config = world_config
    
    -- Calculate stage index based on level (matches boss stage calculation)
    local stage_index = ((level - 1) % 4) + 1  -- Cycle through stages 1, 2, 3, 4
    
    -- Determine number of pads based on stage
    local num_pads = config.landing_pads_per_level
    if stage_index == 2 then
        num_pads = num_pads - 1  -- Remove one pad for stage 2 (no 6th pad)
    end
    
    for i = 1, num_pads do
        local x = i * config.landing_pad_spacing + 50
        local terrain_height = get_terrain_height(x)
        local platform_y = terrain_height - config.landing_pad_support_height - config.landing_pad_height
        
        landing_pads[#landing_pads + 1] = {
            x = x, 
            y = platform_y,  -- Top of platform
            terrain_y = terrain_height,  -- Ground level for supports
            active = i == 1,
            width = config.landing_pad_width,
            height = config.landing_pad_height,
            support_height = config.landing_pad_support_height,
            last_landed_pos = {x = 0, y = 0}  -- Track where player was when they last landed here
        }
    end
    
    -- Reset landing pad tracking
    last_landed_pad = 0
end

function get_terrain_height(x)
    local config = world_config
    local index = flr(x / config.terrain_spacing) + 1
    if index >= 1 and index <= #terrain then
        return terrain[index]
    end
    return (config.terrain_min_height + config.terrain_max_height) / 2
end

-- Terrain scrolling state
terrain_scroll_offset = 0

function update_camera()
    local config = world_config
    camera.x = player.x - 240
    camera.y = player.y - 135
    
    -- Sync terrain scroll offset with camera position (no auto-scrolling)
    terrain_scroll_offset = camera.x
    
    -- Clamp camera to world bounds
    local world_width = #terrain * config.terrain_spacing
    camera.x = max(0, min(camera.x, world_width - 480))
    camera.y = max(0, min(camera.y, 270 - 270))
end

-- Track landing state
player_landed = false

function check_landing()
    local config = world_config
    local was_landed = player_landed
    player_landed = false
    
    for i, pad in ipairs(landing_pads) do
        local dist = abs(player.x - pad.x)
        local y_dist = abs(player.y - pad.y)
        
        -- Check if ship's center X is within pad bounds and ship is touching pad vertically
        local pad_left = pad.x - pad.width
        local pad_right = pad.x + pad.width
        local pad_top = pad.y
        local pad_bottom = pad.y + pad.height
        
        local ship_center_x = player.x  -- Ship's center X coordinate
        local ship_top = player.y - 16
        local ship_bottom = player.y + 16 + 4 -- 2 us for pad thickness
        
        -- Check if ship center X is within pad bounds
        if ship_center_x >= pad_left and ship_center_x <= pad_right then
            
            -- Y-distance landing criteria - ship bottom must be close to pad center
            local pad_center_y = pad.y + (pad.height / 2)  -- Center of the landing pad
            local y_distance_to_pad = abs(ship_bottom - pad_center_y)
            local max_y_distance = 0.5  -- Ship bottom must be within 0.5 pixels of pad center
            
            -- Only consider landed if velocity is (near) zero AND close to surface
            local velocity_threshold = 0.1  -- Very small threshold for "stopped"
            local is_stopped = abs(player.vx) < velocity_threshold and abs(player.vy) < velocity_threshold
            local is_close_to_pad = y_distance_to_pad <= max_y_distance
            
            if is_stopped and is_close_to_pad then
                player_landed = true
                
                -- Only complete landing if we just landed (wasn't landed before)
                if not was_landed then
                    complete_landing(i, pad)
                end
            else
                -- Not close enough to pad center or still moving
                player_landed = false
            end
            
            
            break  -- Exit loop after finding landing pad
        end
    end
    
    -- Make enemies flee when landing is completed
    if player_landed and not was_landed then
        make_enemies_flee()
    end
end

function draw_landing_debug()
    -- print("DEBUG: draw_landing_debug called, debug_mode=" .. tostr(debug_mode), 10, 200, 8)
    
    --if not debug_mode then return end
    
    -- print("DEBUG: Inside debug function", 10, 210, 8)
    
    -- Find closest landing pad
    local closest_pad = nil
    local closest_distance = math.huge
    local closest_index = 0
    
    -- print("DEBUG: Landing pads count=" .. #landing_pads, 10, 220, 8)
    
    for i, pad in ipairs(landing_pads) do
        local distance = sqrt((player.x - pad.x)^2 + (player.y - pad.y)^2)

        if distance < closest_distance then
            closest_distance = distance
            closest_pad = pad
            closest_index = i
        end
    end
    
    --print("DEBUG: Closest pad index=" .. closest_index .. " distance=" .. flr(closest_distance), 10, 230, 8)
    
    if false then
        -- Calculate debug info for closest pad
        local pad_left = closest_pad.x - closest_pad.width
        local pad_right = closest_pad.x + closest_pad.width
        local ship_center_x = player.x
        local ship_bottom = player.y + 16
        local pad_center_y = closest_pad.y + (closest_pad.height / 2)
        local y_distance_to_pad = abs(ship_bottom - pad_center_y)
        local max_y_distance = 0.5
        local velocity_threshold = 0.1
        
        local is_stopped = abs(player.vx) < velocity_threshold and abs(player.vy) < velocity_threshold
        local is_close_to_pad = y_distance_to_pad <= max_y_distance
        local x_in_bounds = ship_center_x >= pad_left and ship_center_x <= pad_right
        
        -- Draw debug info
        local debug_x = 100
        local debug_y = 50
        print("LANDING DEBUG (Closest Pad " .. closest_index .. "):", debug_x, debug_y, 7)
        print("Ship X: " .. flr(player.x) .. " | Pad X: " .. flr(closest_pad.x), debug_x, debug_y + 10, 6)
        print("Ship Bottom: " .. flr(ship_bottom) .. " | Pad Center: " .. flr(pad_center_y), debug_x, debug_y + 20, 6)
        print("X in bounds: " .. (x_in_bounds and "YES" or "NO"), debug_x, debug_y + 30, x_in_bounds and 11 or 8)
        print("Y distance: " .. flr(y_distance_to_pad * 100)/100 .. " (max: " .. max_y_distance .. ")", debug_x, debug_y + 40, is_close_to_pad and 11 or 8)
        print("Stopped: " .. (is_stopped and "YES" or "NO"), debug_x, debug_y + 50, is_stopped and 11 or 8)
        print("Close to pad: " .. (is_close_to_pad and "YES" or "NO"), debug_x, debug_y + 60, is_close_to_pad and 11 or 8)
        print("Distance: " .. flr(closest_distance), debug_x, debug_y + 70, 6)
    end
end

function complete_landing(i, pad)
    -- Stop thruster sound when landing
    if stop_thruster_sound then
        stop_thruster_sound()
    end

    -- Play landing sound effect
    if audio_config.landing_sound then
        sfx(audio_config.landing_sound)
    end

    -- Record this landing
    last_landed_pad = i
    pad.last_landed_pos.x = player.x
    pad.last_landed_pos.y = player.y

    -- Update safe respawn position for any successful landing (offset for 32x32 sprite)
    player.last_safe_x = pad.x
    player.last_safe_y = pad.y - 16

    -- Automatic refuel (free service)
    player.fuel = player.max_fuel
    if debug_mode then print("Landed on pad " .. i .. ", automatically refueled") end

    -- Make enemies flee (but not during boss fights)
    if not boss_active then
        make_enemies_flee()
    end

    -- Show shop prompt only if not in boss fight
    if not boss_active then
        show_shop_prompt = true
        shop_prompt_timer = 0
    else
        -- During boss fight, just show refuel message
        if debug_mode then print("Refueled during boss fight - no shop available") end
    end
    
    -- Advance target pad if this was the target
    if i == target_pad then
        if target_pad >= #landing_pads then
            -- Level complete - trigger boss fight instead of immediately advancing
            should_spawn_boss_flag = true
            target_pad += 1  -- Prevent retriggering
        else
            target_pad += 1
        end
    end
end

function make_enemies_flee()
    for i = 1, #enemies do
        local enemy = enemies[i]
        -- Make enemies move away from player quickly
        local dx = enemy.x - player.x
        local dy = enemy.y - player.y
        local dist = sqrt(dx*dx + dy*dy)
        
        if dist > 0 then
            enemy.vx = (dx / dist) * 2  -- Move away at double speed
            enemy.vy = (dy / dist) * 2
            enemy.fleeing = true
        end
    end
    
    if debug_mode then print("Enemies fleeing!") end
end

function draw_background_objects()
    local config = world_config
    
    for i = 1, #background_objects do
        local obj = background_objects[i]
        
        -- Apply parallax scrolling
        local ox = obj.x - (camera.x * obj.parallax)
        local oy = obj.y - (camera.y * obj.parallax)
        
        -- Wrap objects horizontally
        local world_width = config.terrain_width * config.terrain_spacing
        ox = ox % (world_width * 3)
        
        -- Only draw objects that are visible on screen
        if ox + obj.width >= -50 and ox <= 530 and oy + obj.height >= -50 and oy <= 320 then
            draw_background_object(obj, ox, oy)
        end
    end
end

function draw_background_object(obj, x, y)
    if obj.type == "mountain" then
        -- Draw mountain using sprites 5 or 6 (64x64)
        if sprites.use_sprites and obj.sprite_id then
            spr(obj.sprite_id, x, y - 64, false, false)  -- Draw 64x64 mountain sprite
        else
            -- Fallback to vector art
            rectfill(x, y, x + obj.width, y + obj.height, obj.color)
            -- Add peak
            local peak_x = x + obj.width / 2
            line(x, y, peak_x, y - obj.height * 0.3, obj.color)
            line(peak_x, y - obj.height * 0.3, x + obj.width, y, obj.color)
        end
        
    elseif obj.type == "outpost" then
        -- Draw outpost using sprite if available, otherwise use vector
        if sprites.use_sprites and sprites.building_1 then
            -- Draw 32x64 building sprite (4 sprites wide, 8 sprites tall)
            spr(sprites.building_1, x, y - 64, false, false)  -- flipy=true
        else
            -- Fallback to vector art
            rectfill(x, y, x + obj.width, y + obj.height, obj.color)
            rect(x, y, x + obj.width, y + obj.height, 1)  -- Dark blue outline
            -- Antenna
            line(x + obj.width/2, y, x + obj.width/2, y - 8, obj.color)
            pset(x + obj.width/2, y - 8, 8)  -- Red light
        end
        
    elseif obj.type == "rocket" then
        -- Draw rocket using second building sprite if available, otherwise use vector
        if sprites.use_sprites and sprites.building_2 then
            -- Draw 32x64 building sprite (4 sprites wide, 8 sprites tall)
            spr(sprites.building_2, x, y - 64, false, false)  -- flipy=true
        else
            -- Fallback to vector art
            rectfill(x, y, x + obj.width, y + obj.height, obj.color)
            rect(x, y, x + obj.width, y + obj.height, 6)  -- Grey outline
            -- Rocket tip
            local tip_x = x + obj.width / 2
            line(x, y, tip_x, y - 10, obj.color)
            line(tip_x, y - 10, x + obj.width, y, obj.color)
        end
        -- Thruster glow
        pset(x + obj.width/2, y + obj.height, 9)  -- Orange
    end
end

function draw_starfield()
    local config = world_config
    
    for i = 1, #stars do
        local star = stars[i]
        -- Parallax scrolling effect
        local sx = star.x - (camera.x * config.star_parallax)
        local sy = star.y - (camera.y * config.star_parallax)
        
        -- Wrap stars horizontally
        local world_width = config.terrain_width * config.terrain_spacing
        sx = sx % (world_width * 2)
        
        -- Only draw stars that are on screen
        if sx >= -10 and sx <= 490 and sy >= -10 and sy <= 280 then
            -- Twinkling effect
            if star.brightness > 0.3 then
                pset(sx, sy, star.color)
            end
        end
        
        -- Update twinkling
        star.brightness += (rnd(0.1) - 0.05)
        star.brightness = max(0, min(star.brightness, 1))
    end
end

function draw_terrain()
    local config = world_config
    
    if sprites.use_sprites and sprites.terrain_tile then
        draw_terrain_sprites()
    else
        draw_terrain_vector()
    end
end

function draw_terrain_sprites()
    -- TODO: Implement sprite-based terrain rendering
    -- For now, fall back to vector
    draw_terrain_vector()
end

function draw_horizon()
    local config = world_config
    
    -- Draw horizon rectangle (large grey background area behind everything)
    local horizon_y = config.terrain_min_height - camera.y - 40
    local horizon_bottom = horizon_y + 400
    if horizon_y < 270 and horizon_bottom > 0 then
        rectfill(0, max(0, horizon_y), 480, min(270, horizon_bottom), config.horizon_color)
    end
end

function draw_terrain_vector()
    local config = world_config
    local world_width = #terrain * config.terrain_spacing

    -- Draw terrain with proper wrapping
    for i = 1, #terrain - 1 do
        local x1 = (i - 1) * config.terrain_spacing - camera.x
        local y1 = terrain[i] - camera.y
        local x2 = i * config.terrain_spacing - camera.x
        local y2 = terrain[i + 1] - camera.y

        -- Draw terrain segment (main copy)
        draw_terrain_segment(x1, y1, x2, y2)

        -- Draw wrapped copies for seamless scrolling
        -- Left wrap (when camera is near right edge of world)
        draw_terrain_segment(x1 - world_width, y1, x2 - world_width, y2)

        -- Right wrap (when camera is near left edge of world)
        draw_terrain_segment(x1 + world_width, y1, x2 + world_width, y2)
    end
end

function draw_terrain_segment(x1, y1, x2, y2)
    local config = world_config

    -- Only draw if segment is visible on screen (with buffer)
    if x2 < -50 or x1 > 530 then
        return
    end

    -- Clamp coordinates to prevent drawing outside screen bounds
    local screen_x1 = max(-50, min(530, x1))
    local screen_x2 = max(-50, min(530, x2))
    local screen_y1 = max(-50, min(320, y1))
    local screen_y2 = max(-50, min(320, y2))

    -- Fill terrain from surface to bottom of screen
    local min_y = min(screen_y1, screen_y2)
    local max_y = max(screen_y1, screen_y2)

    -- Only fill if terrain is above bottom of screen
    if min_y < 270 then
        -- Fill the terrain area
        if screen_x1 < screen_x2 then
            rectfill(screen_x1, min_y, screen_x2, 270, config.terrain_fill_color)
        else
            rectfill(screen_x2, min_y, screen_x1, 270, config.terrain_fill_color)
        end
    end
end

function draw_landing_pads()
    local config = world_config
    
    for i, pad in ipairs(landing_pads) do
        local x = pad.x - camera.x
        local y = pad.y - camera.y
        
        if sprites.use_sprites and sprites.landing_pad then
            draw_landing_pad_sprite(x, y, pad, i)
        else
            draw_landing_pad_vector(x, y, pad, i)
        end
    end
end

function draw_landing_pad_sprite(x, y, pad, index)
    local config = world_config
    
    -- Draw support columns (still use vector)
    local terrain_y = pad.terrain_y - camera.y
    local support_left_x = x - pad.width * 0.7
    local support_right_x = x + pad.width * 0.7
    
    -- Left support column
    rectfill(support_left_x - 2, y + pad.height, support_left_x + 2, terrain_y, config.pad_support_color)
    
    -- Right support column  
    rectfill(support_right_x - 2, y + pad.height, support_right_x + 2, terrain_y, config.pad_support_color)
    
    -- Draw 32x8 landing pad sprite centered on pad position
    spr(sprites.landing_pad, x - 16, y, false, false)  -- 4 sprites wide, 1 sprite tall, flipy=true
    
    -- Optional: Add blinking effect for target pad by drawing colored overlay
    if index == target_pad then
        local blink_color = config.pad_active_color + (time() * 10) % 3
        -- Draw a subtle overlay for blinking effect
        rectfill(x - 16, y, x + 15, y + 7, blink_color)
    end
end

function draw_landing_pad_vector(x, y, pad, index)
    local config = world_config
    local color = config.pad_inactive_color
    
    -- Animate target pad
    if index == target_pad then
        color = config.pad_active_color + (time() * 10) % 3  -- Blinking effect
    end
    
    -- Draw support columns
    local terrain_y = pad.terrain_y - camera.y
    local support_left_x = x - pad.width * 0.7
    local support_right_x = x + pad.width * 0.7
    
    -- Left support column
    rectfill(support_left_x - 2, y + pad.height, support_left_x + 2, terrain_y, config.pad_support_color)
    
    -- Right support column  
    rectfill(support_right_x - 2, y + pad.height, support_right_x + 2, terrain_y, config.pad_support_color)
    
    -- Landing platform (raised above ground)
    rectfill(x - pad.width, y, x + pad.width, y + pad.height, color)
    
    -- Platform outline
    rect(x - pad.width, y, x + pad.width, y + pad.height, 7)  -- White outline
end

function get_world_width()
    return #terrain * world_config.terrain_spacing
end

function get_world_height()
    return 270  -- Screen height
end