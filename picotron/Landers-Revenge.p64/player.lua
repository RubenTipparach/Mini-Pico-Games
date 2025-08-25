--[[pod_format="raw",created="2025-08-22 05:03:27",modified="2025-08-22 05:03:56",revision=3]]
-- LANDER'S REVENGE - Player Ship System

-- Player object
player = {
    x = player_config.start_x,
    y = player_config.start_y,
    vx = 0,
    vy = 0,
    angle = 0,
    fuel = player_config.starting_fuel,
    max_fuel = player_config.starting_fuel,
    health = player_config.starting_health,
    max_health = player_config.starting_health,
    thrust_power = player_config.thrust_power,
    turn_speed = player_config.turn_speed,
    thrusting = false,
    weapons = {
        damage = player_config.weapon_damage,
        rate = player_config.weapon_rate,
        range = player_config.weapon_range,
        last_shot = 0
    },
    armor = player_config.starting_armor,
    size = player_config.size,
    last_safe_x = player_config.start_x,
    last_safe_y = player_config.start_y,
    money = money_config.starting_money,
    current_primary = 1,  -- Always start with basic weapon
    current_secondary = 1,  -- Always start with no secondary
    owned_weapons = {primary = {[1] = true}, secondary = {[1] = true}}  -- Track owned weapons
}

-- Bullets array
bullets = {}

-- Particles array  
particles = {}

-- Coins array
coins = {}

-- Bullet trails array
bullet_trails = {}

-- Targeting system
current_target = 0  -- Index of currently targeted enemy (0 = no target)
current_boss_target = 0  -- Index of currently targeted boss weak point (0 = no target)
auto_fire_enabled = true
weapon_fire_timer = 0

-- Crash tracking
crash_reason = "unknown"

function player_reset()
    -- Position player on first landing pad if it exists
    if #landing_pads > 0 then
        local first_pad = landing_pads[1]
        player.x = first_pad.x  -- Center on landing pad
        player.y = first_pad.y - 16  -- Position exactly on pad surface (accounting for 32x32 sprite)
    else
        -- Fallback to config values if no landing pads
        player.x = player_config.start_x
        player.y = player_config.start_y
    end
    player.vx = 0
    player.vy = 0
    player.angle = 0
    player.fuel = player_config.starting_fuel
    player.max_fuel = player_config.starting_fuel
    player.health = player_config.starting_health
    player.max_health = player_config.starting_health
    player.thrust_power = player_config.thrust_power
    player.thrusting = false
    player.weapons = {
        damage = player_config.weapon_damage,
        rate = player_config.weapon_rate,
        range = player_config.weapon_range,
        last_shot = 0
    }
    player.armor = player_config.starting_armor
    -- Set safe position to match actual starting position
    if #landing_pads > 0 then
        local first_pad = landing_pads[1]
        player.last_safe_x = first_pad.x
        player.last_safe_y = first_pad.y - 16
    else
        player.last_safe_x = player_config.start_x
        player.last_safe_y = player_config.start_y
    end
    player.current_primary = 1  -- Reset to basic weapon
    player.current_secondary = 1  -- Reset to no secondary
    player.owned_weapons = {primary = {[1] = true}, secondary = {[1] = true}}  -- Reset owned weapons
    bullets = {}
    particles = {}
    
    -- Stop all sounds
    stop_thruster_sound()
    stop_low_fuel_warning()
end

function respawn_at_last_safe_position()
    -- Respawn at the last safe landing pad
    player.x = player.last_safe_x
    player.y = player.last_safe_y - 20  -- Spawn slightly above the pad
    player.vx = 0
    player.vy = 0
    player.health = player.max_health  -- Full health on respawn
    player.fuel = player.max_fuel      -- Full fuel on respawn
    
    -- Clear any ongoing effects
    bullets = {}
    particles = {}
    
    if debug_mode then print("Respawned at last safe position") end
end

function handle_player_input()
    -- WASD Lunar lander controls
    player.thrusting = false
    local any_thruster_active = false

    -- W or Up Arrow = Thrust upward (main thruster) - gradual acceleration
    if (btn(input_config.key_w) or btn(input_config.arrow_up)) and player.fuel > 0 then
        player.thrusting = true
        any_thruster_active = true
        -- Gradual thrust buildup for heavier feel
        local thrust_force = player.thrust_power * 0.8  -- Reduced immediate thrust
        player.vy -= thrust_force
        player.fuel -= player_config.fuel_consumption
        add_thrust_particle()
    end

    -- A or Left Arrow = Left side thruster - weaker and more gradual
    if (btn(input_config.key_a) or btn(input_config.arrow_left)) and player.fuel > 0 then
        any_thruster_active = true
        local side_thrust = player.thrust_power * 0.5  -- Even weaker side thrusters
        player.vx -= side_thrust
        player.fuel -= player_config.fuel_consumption * 0.3
        add_side_thrust_particle("right")
    end

    -- D or Right Arrow = Right side thruster - weaker and more gradual
    if (btn(input_config.key_d) or btn(input_config.arrow_right)) and player.fuel > 0 then
        any_thruster_active = true
        local side_thrust = player.thrust_power * 0.5  -- Even weaker side thrusters
        player.vx += side_thrust
        player.fuel -= player_config.fuel_consumption * 0.3
        add_side_thrust_particle("left")
    end

    -- Handle thruster sound
    handle_thruster_sound(any_thruster_active)
    
    -- Handle low fuel warning
    handle_low_fuel_warning()

    -- S or Down Arrow = Downward thruster (for more precise control)
    if (btn(input_config.key_s) or btn(input_config.arrow_down)) and player.fuel > 0 then
        any_thruster_active = true
        local down_thrust = player.thrust_power * 0.3  -- Weak downward thrust
        player.vy += down_thrust
        player.fuel -= player_config.fuel_consumption * 0.2
        add_downward_thrust_particle()
    end

    -- Target cycling (but not when shop prompt is active)
    if btnp(4) and not show_shop_prompt then -- Z key - cycle targets
        cycle_target()
    end

    -- C key - target closest enemy or cycle if closest is already targeted
    if btnp(input_config.secondary_weapon) and not show_shop_prompt then -- C key
        target_closest_or_cycle()
    end

    -- X key now does nothing since all weapons fire together
    -- (Keeping this comment for clarity)

    -- Auto-targeting and firing
    handle_auto_weapons()
end

-- Sound and visual state tracking
local thruster_sound_playing = false
local low_fuel_warning_playing = false
local low_fuel_flash_timer = 0

function handle_thruster_sound(any_thruster_active)
    if any_thruster_active and not thruster_sound_playing then
        -- Start thruster sound loop
        if audio_config.thrust_sound then
            sfx(audio_config.thrust_sound, -1, 0, -1)  -- Loop indefinitely
            thruster_sound_playing = true
        end
    elseif not any_thruster_active and thruster_sound_playing then
        -- Stop thruster sound
        stop_thruster_sound()
    end
end

function stop_thruster_sound()
    if thruster_sound_playing and audio_config.thrust_sound then
        sfx(-1, audio_config.thrust_sound)  -- Stop the sound on this channel
        thruster_sound_playing = false
    end
end

function handle_low_fuel_warning()
    local fuel_percentage = player.fuel / player.max_fuel
    local is_low_fuel = fuel_percentage < 0.25  -- Below 25%
    
    if is_low_fuel then
        -- Update flash timer for visual warning
        low_fuel_flash_timer += 1
        
        if not low_fuel_warning_playing then
            -- Start low fuel warning sound loop
            sfx(5, -1, 0, -1)  -- Loop sfx 5 indefinitely
            low_fuel_warning_playing = true
        end
    else
        -- Reset flash timer and stop warning
        low_fuel_flash_timer = 0
        if low_fuel_warning_playing then
            stop_low_fuel_warning()
        end
    end
end

function stop_low_fuel_warning()
    if low_fuel_warning_playing then
        sfx(-1, 5)  -- Stop sfx 5
        low_fuel_warning_playing = false
    end
end

function cycle_target()
    if #enemies == 0 then
        current_target = 0
        if debug_mode then print("No enemies to target") end
        return
    end

    -- Find next visible enemy
    local start_target = current_target
    local attempts = 0

    repeat
        current_target = (current_target % #enemies) + 1
        attempts += 1

        -- Check if this enemy is visible on screen
        if current_target <= #enemies and is_enemy_visible_on_screen(enemies[current_target]) then
            if debug_mode then print("Targeting visible enemy " .. current_target) end
            return
        end

    until current_target == start_target or attempts > #enemies

    -- No visible enemies found
    current_target = 0
    if debug_mode then print("No visible enemies to target") end
end

function target_closest_or_cycle()
    -- During boss fights, allow targeting both boss weak points and regular enemies
    if boss_active and boss then
        -- If currently targeting an enemy, switch to boss weak points
        if current_target > 0 then
            current_target = 0  -- Clear enemy target
            cycle_boss_weak_points()
        -- If currently targeting boss weak points, switch to regular enemies
        elseif current_boss_target > 0 then
            current_boss_target = 0  -- Clear boss target
            if #enemies > 0 then
                local nearest_index = get_nearest_enemy()
                if nearest_index > 0 then
                    current_target = nearest_index
                    if debug_mode then print("Targeting enemy " .. current_target) end
                else
                    cycle_target()
                end
            end
        -- If no current target, prioritize boss weak points but allow enemy targeting
        else
            if boss.total_weak_points > 0 then
                cycle_boss_weak_points()
            elseif #enemies > 0 then
                local nearest_index = get_nearest_enemy()
                if nearest_index > 0 then
                    current_target = nearest_index
                    if debug_mode then print("Targeting enemy " .. current_target) end
                end
            end
        end
    elseif #enemies == 0 then
        current_target = 0
        if debug_mode then print("No enemies to target") end
        return
    else
        local nearest_index = get_nearest_enemy()
        
        -- If no nearest enemy found or we're already targeting the closest enemy, cycle to next
        if nearest_index == 0 or current_target == nearest_index then
            cycle_target()
        else
            -- Target the closest enemy
            current_target = nearest_index
            if debug_mode then print("Targeting closest enemy " .. current_target) end
        end
    end
end

function get_nearest_enemy()
    if #enemies == 0 then return 0 end

    local nearest_index = 0
    local nearest_dist = math.huge
    local max_range = player_config.max_shooting_range

    for i = 1, #enemies do
        local enemy = enemies[i]

        -- Check if enemy is visible on screen
        if is_enemy_visible_on_screen(enemy) then
            local dist = sqrt((enemy.x - player.x)^2 + (enemy.y - player.y)^2)

            -- Only target enemies within shooting range and visible on screen
            if dist <= max_range and dist < nearest_dist then
                nearest_dist = dist
                nearest_index = i
            end
        end
    end

    return nearest_index
end

function cycle_boss_weak_points()
    if not boss_active or not boss or not boss.weak_points then
        current_boss_target = 0
        if debug_mode then print("No boss weak points to target") end
        return
    end

    -- Find next non-destroyed weak point
    local start_target = current_boss_target
    local attempts = 0

    repeat
        current_boss_target = (current_boss_target % #boss.weak_points) + 1
        attempts += 1

        -- Check if this weak point is not destroyed
        if current_boss_target <= #boss.weak_points and not boss.weak_points[current_boss_target].destroyed then
            if debug_mode then print("Targeting boss weak point " .. current_boss_target) end
            return
        end

    until current_boss_target == start_target or attempts > #boss.weak_points

    -- No available weak points found
    current_boss_target = 0
    if debug_mode then print("No available boss weak points to target") end
end

function get_nearest_boss_weak_point()
    if not boss_active or not boss or not boss.weak_points then return 0 end

    local nearest_index = 0
    local nearest_dist = math.huge
    local max_range = player_config.max_shooting_range

    for i = 1, #boss.weak_points do
        local wp = boss.weak_points[i]

        -- Only consider non-destroyed weak points
        if not wp.destroyed then
            local wp_world_x = boss.x + wp.x
            local wp_world_y = boss.y + wp.y
            local dist = sqrt((wp_world_x - player.x)^2 + (wp_world_y - player.y)^2)

            -- Only target weak points within shooting range
            if dist <= max_range and dist < nearest_dist then
                nearest_dist = dist
                nearest_index = i
            end
        end
    end

    return nearest_index
end

function is_enemy_visible_on_screen(enemy)
    -- Calculate enemy position relative to screen
    local screen_x = enemy.x - camera.x
    local screen_y = enemy.y - camera.y

    -- Screen bounds with small buffer for enemies partially visible
    local buffer = 50
    local screen_left = -buffer
    local screen_right = 480 + buffer
    local screen_top = -buffer
    local screen_bottom = 270 + buffer

    -- Check if enemy is within visible screen bounds
    return screen_x >= screen_left and screen_x <= screen_right and
           screen_y >= screen_top and screen_y <= screen_bottom
end

function handle_auto_weapons()
    -- Don't fire weapons when player has landed
    if player_landed then
        return
    end

    weapon_fire_timer += 1

    -- Check if we're in boss fight mode
    if boss_active and boss then
        -- Allow targeting both boss weak points and regular enemies
        local fired_at_target = false
        
        -- If player has manually targeted a boss weak point, prioritize that
        if current_boss_target > 0 then
            fired_at_target = handle_boss_targeting()
        -- If player has manually targeted an enemy, prioritize that
        elseif current_target > 0 and current_target <= #enemies then
            handle_normal_targeting()
            fired_at_target = true
        -- Auto-target: try boss first, then enemies
        else
            fired_at_target = handle_boss_targeting()
            if not fired_at_target and #enemies > 0 then
                handle_normal_targeting()
            end
        end
    else
        -- Normal enemy targeting
        handle_normal_targeting()
    end
end

function handle_normal_targeting()
    -- Auto-target nearest enemy if no target selected or current target is invalid
    if current_target == 0 or current_target > #enemies then
        current_target = get_nearest_enemy()
    end

    -- Validate current target is still visible and in range
    if current_target > 0 and current_target <= #enemies then
        local target_enemy = enemies[current_target]

        -- Check if current target is still visible on screen
        if not is_enemy_visible_on_screen(target_enemy) then
            -- Current target is off-screen, find a new one
            current_target = get_nearest_enemy()
            if current_target == 0 then
                return  -- No visible enemies to target
            end
            target_enemy = enemies[current_target]
        end

        local dist = sqrt((target_enemy.x - player.x)^2 + (target_enemy.y - player.y)^2)

        -- Only fire if enemy is within shooting range and visible
        if dist <= player_config.max_shooting_range then
            local fastest_rate = get_fastest_weapon_rate()

            -- Check if we can fire (rate limiting)
            if weapon_fire_timer > (fastest_rate * 60) then  -- Convert rate to frames
                auto_fire_at_enemy(target_enemy)
                weapon_fire_timer = 0
            end
        end
    end
end

function handle_boss_targeting()
    local target_wp = nil
    local target_dist = math.huge

    -- Check if we have a manually selected boss target
    if current_boss_target > 0 and current_boss_target <= #boss.weak_points then
        local wp = boss.weak_points[current_boss_target]
        if not wp.destroyed then
            local wp_world_x = boss.x + wp.x
            local wp_world_y = boss.y + wp.y
            local dist = sqrt((wp_world_x - player.x)^2 + (wp_world_y - player.y)^2)
            
            if dist <= player_config.max_shooting_range then
                target_wp = {x = wp_world_x, y = wp_world_y, index = current_boss_target}
                target_dist = dist
            end
        else
            -- Current target is destroyed, clear it
            current_boss_target = 0
        end
    end

    -- If no manual target or manual target is out of range, find nearest weak point
    if not target_wp then
        -- Auto-target nearest boss weak point if no manual target selected
        if current_boss_target == 0 then
            current_boss_target = get_nearest_boss_weak_point()
        end
        
        -- Try to target the selected weak point
        if current_boss_target > 0 and current_boss_target <= #boss.weak_points then
            local wp = boss.weak_points[current_boss_target]
            if not wp.destroyed then
                local wp_world_x = boss.x + wp.x
                local wp_world_y = boss.y + wp.y
                local dist = sqrt((wp_world_x - player.x)^2 + (wp_world_y - player.y)^2)
                
                if dist <= player_config.max_shooting_range then
                    target_wp = {x = wp_world_x, y = wp_world_y, index = current_boss_target}
                    target_dist = dist
                end
            end
        end
    end

    -- Fire at target weak point
    if target_wp then
        local fastest_rate = get_fastest_weapon_rate()

        -- Check if we can fire (rate limiting)
        if weapon_fire_timer > (fastest_rate * 60) then
            auto_fire_at_boss_weak_point(target_wp)
            weapon_fire_timer = 0
            return true  -- Successfully fired at boss
        end
    end
    
    return false  -- Didn't fire at boss
end

function auto_fire_at_boss_weak_point(target_wp)
    -- Fire all owned weapons at the boss weak point
    fire_all_owned_weapons(target_wp.x, target_wp.y)
end

function update_player_physics()
    -- Apply gravity (constant downward force)
    player.vy += player_config.gravity
    
    -- Terminal velocity limits for realism (heavy ship can't go infinitely fast)
    local max_horizontal_speed = 3.0
    local max_vertical_speed = 4.0
    
    -- Clamp horizontal velocity
    if abs(player.vx) > max_horizontal_speed then
        player.vx = player.vx > 0 and max_horizontal_speed or -max_horizontal_speed
    end
    
    -- Clamp vertical velocity
    if abs(player.vy) > max_vertical_speed then
        player.vy = player.vy > 0 and max_vertical_speed or -max_vertical_speed
    end
    
    -- Apply velocity with momentum conservation
    player.x += player.vx
    player.y += player.vy
    
    -- Apply drag (atmospheric resistance)
    player.vx *= player_config.drag
    player.vy *= player_config.drag
    
    -- Add minimal velocity decay for ultra-low speeds (friction)
    if abs(player.vx) < 0.01 then player.vx *= 0.9 end
    if abs(player.vy) < 0.01 then player.vy *= 0.9 end
    
    -- World bounds with momentum loss and boss spawning
    local world_width = (#terrain or 500) * (world_config.terrain_spacing or 4)
    local boss_trigger_distance = 200  -- Distance from right edge to trigger boss

    -- Left boundary
    if player.x < 0 then
        player.x = 0
        player.vx = 0
    end

    -- Right boundary - prevent going past and trigger boss
    if player.x > world_width - boss_trigger_distance then
        -- Trigger boss spawn when approaching the end
        if not boss_active and not should_spawn_boss_flag then
            should_spawn_boss_flag = true
            if debug_mode then print("Boss spawn triggered at end of level!") end
        end

        -- Hard boundary - don't let player go past the end
        if player.x > world_width then
            player.x = world_width
            player.vx = 0
        end
    end

    -- Clamp fuel to not go below zero
    player.fuel = max(0, player.fuel)

    -- Add smoke particles when heavily damaged
    add_damage_smoke_particles()
end

function get_current_primary_weapon()
    return weapon_config.primary_weapons[player.current_primary]
end

function get_current_secondary_weapon()
    return weapon_config.secondary_weapons[player.current_secondary]
end

function get_all_owned_primary_weapons()
    local owned_weapons = {}
    for i = 1, #weapon_config.primary_weapons do
        if player.owned_weapons.primary[i] then
            owned_weapons[#owned_weapons + 1] = weapon_config.primary_weapons[i]
        end
    end
    return owned_weapons
end

function get_fastest_weapon_rate()
    local owned_weapons = get_all_owned_primary_weapons()
    if #owned_weapons == 0 then
        return weapon_config.primary_weapons[1].rate  -- Fallback to basic weapon
    end
    
    local fastest_rate = math.huge
    for _, weapon in ipairs(owned_weapons) do
        if weapon.rate < fastest_rate then
            fastest_rate = weapon.rate
        end
    end
    
    return fastest_rate
end

function fire_all_owned_weapons(target_x, target_y)
    local all_weapons = get_all_owned_primary_weapons()
    if #all_weapons == 0 then return end
    
    -- Play weapon firing sound effect once
    if audio_config.shoot_sound then
        sfx(audio_config.shoot_sound)
    end

    local dx = target_x - player.x
    local dy = target_y - player.y
    local dist = sqrt(dx*dx + dy*dy)

    if dist > 0 then
        -- Calculate base angle
        local base_angle = -atan2(dy, dx) - math.rad(90)/(2*math.pi)
        
        -- Fire each owned weapon with slight offset for visual variety
        for i, weapon in ipairs(all_weapons) do
            local weapon_offset = (i - (#all_weapons + 1) / 2) * 0.01  -- Small angular offset
            
            for j = 1, weapon.bullets do
                local spread_angle = (weapon.spread * (j - (weapon.bullets + 1) / 2)) / (2 * 3.14159)
                local final_angle = base_angle + spread_angle + weapon_offset

                bullets[#bullets + 1] = {
                    x = player.x,
                    y = player.y,
                    vx = cos(final_angle) * player_config.bullet_speed,
                    vy = sin(final_angle) * player_config.bullet_speed,
                    life = player.weapons.range,
                    enemy_bullet = false,
                    weapon_type = weapon.name,
                    damage = weapon.damage,
                    color = weapon.color or 7
                }
            end
        end
    end
end

function auto_fire_at_enemy(enemy)
    -- Check if enemy is on screen before firing
    local enemy_screen_x = enemy.x - camera.x
    local enemy_screen_y = enemy.y - camera.y

    -- Only fire if enemy is visible on screen (with small buffer)
    if enemy_screen_x < -50 or enemy_screen_x > 530 or enemy_screen_y < -50 or enemy_screen_y > 320 then
        return  -- Enemy is off-screen, don't fire
    end

    -- Fire all owned weapons at the enemy
    fire_all_owned_weapons(enemy.x, enemy.y)
end

function shoot_primary_weapon(target_x, target_y)
    -- Legacy function - redirect to auto fire system
    if current_target > 0 and current_target <= #enemies then
        auto_fire_at_enemy(enemies[current_target])
    end
end

function shoot_secondary_weapon(target_x, target_y)
    local weapon = get_current_secondary_weapon()
    if weapon.name == "None" then return end

    -- Play weapon firing sound effect
    if audio_config.shoot_sound then
        sfx(audio_config.shoot_sound)
    end

    local world_x = target_x + (camera and camera.x or 0)
    local world_y = target_y + (camera and camera.y or 0)
    local dx = world_x - player.x
    local dy = world_y - player.y
    local dist = sqrt(dx*dx + dy*dy)

    if dist > 0 then
        local angle = -atan2(dy, dx) - math.rad(90)/(2*math.pi)

        bullets[#bullets + 1] = {
            x = player.x,
            y = player.y,
            vx = cos(angle) * player_config.bullet_speed * 0.8,  -- Slower secondary weapons
            vy = sin(angle) * player_config.bullet_speed * 0.8,
            life = player.weapons.range * 1.5,  -- Longer range
            enemy_bullet = false,
            weapon_type = weapon.name,
            damage = weapon.damage,
            secondary = true,
            color = weapon.color or 7  -- Use weapon color or default to white
        }
    end
end

function shoot_bullet(target_x, target_y)
    -- Legacy function - redirect to primary weapon
    shoot_primary_weapon(target_x, target_y)
end

function add_thrust_particle()
    local config = effects_config
    -- Main thruster particles go downward from single point (positioned for 32x32 sprite)
    particles[#particles + 1] = {
        x = player.x,  -- Single point origin (no random spread)
        y = player.y + 16,  -- Below the 32x32 ship
        vx = (rnd(4) - 2),  -- More horizontal spread in velocity
        vy = rnd(4) + 3,  -- Stronger downward velocity
        life = config.thrust_life,
        color = config.particle_colors[flr(rnd(#config.particle_colors)) + 1],
        size = 2  -- Bigger particle size
    }
end

function add_side_thrust_particle(direction)
    local config = effects_config
    local side_x = direction == "left" and -16 or 16  -- Positioned for 32x32 sprite
    local vel_x = direction == "left" and -3 or 3  -- Stronger sideways velocity
    
    particles[#particles + 1] = {
        x = player.x + side_x,
        y = player.y,  -- Single point origin (no vertical spread)
        vx = vel_x + (rnd(2) - 1),
        vy = rnd(3) - 1.5,  -- More vertical velocity spread
        life = config.thrust_life * 0.7,  -- Shorter life for side thrusters
        color = config.particle_colors[flr(rnd(#config.particle_colors)) + 1],
        size = 2  -- Bigger particle size
    }
end

function add_downward_thrust_particle()
    local config = effects_config
    -- Downward thruster particles go upward from top of ship (positioned for 32x32 sprite)
    particles[#particles + 1] = {
        x = player.x,  -- Single point origin (no random spread)
        y = player.y - 16,  -- Above the 32x32 ship
        vx = (rnd(4) - 2),  -- More horizontal spread in velocity
        vy = -(rnd(4) + 2),  -- Upward velocity (negative)
        life = config.thrust_life * 0.5,  -- Shorter life for weaker thruster
        color = config.particle_colors[flr(rnd(#config.particle_colors)) + 1],
        size = 1  -- Smaller particle size for weaker thrust
    }
end

function add_damage_smoke_particles()
    -- Only add smoke when heavily damaged (less than 50% health)
    if player.health < (player.max_health * 0.5) and rnd(1) > 0.6 then  -- 40% chance per frame
        -- More smoke the more damage taken
        local damage_ratio = 1 - (player.health / player.max_health)
        local smoke_intensity = damage_ratio * 2  -- Scale with damage
        
        -- Spawn smoke from random positions on the ship
        local smoke_x = player.x + (rnd(20) - 10)  -- Random position within ship bounds
        local smoke_y = player.y + (rnd(20) - 10)
        
        -- Create smoke particle
        particles[#particles + 1] = {
            x = smoke_x,
            y = smoke_y,
            vx = (rnd(1) - 0.5) * 0.5,  -- Slight horizontal drift
            vy = -(0.5 + rnd(1)),       -- Upward movement
            life = 20 + rnd(15),        -- 20-35 frames (longer than thrust particles)
            color = 5 + flr(rnd(2)),    -- Grey colors (5 or 6)
            size = 2 + flr(smoke_intensity)  -- Bigger particles when more damaged
        }
    end
end

function update_bullets()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        
        -- Add trail for enemy bullets
        add_bullet_trail(bullet)
        
        bullet.x += bullet.vx
        bullet.y += bullet.vy
        bullet.life -= 1
        
        -- Update animation for bullets with animation_timer
        if bullet.animation_timer ~= nil then
            bullet.animation_timer += 1
            if bullet.animation_timer >= 15 then  -- Change frame every 15 frames (quarter second)
                bullet.sprite_frame = 1 - bullet.sprite_frame  -- Toggle between 0 and 1
                bullet.animation_timer = 0
            end
        end
        
        -- Check enemy collisions (player bullets only)
        if not bullet.enemy_bullet then
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                local dist = sqrt((bullet.x - enemy.x)^2 + (bullet.y - enemy.y)^2)
                if dist < enemy_config.size then
                    local damage = bullet.damage or player.weapons.damage
                    enemy.health -= damage
                    deli(bullets, i)
                    if enemy.health <= 0 then
                        -- Spawn coin when enemy dies
                        spawn_coin(enemy.x, enemy.y)
                        deli(enemies, j)
                        add_explosion_particles(enemy.x, enemy.y)
                    end
                    break
                end
            end
        else
            -- Enemy bullet hits player
            local bullet_size = bullet.size or 2  -- Default size for normal bullets
            local collision_radius = bullet.boss_bullet and bullet_size / 2 or 1
            local dist = sqrt((bullet.x - player.x)^2 + (bullet.y - player.y)^2)
            
            if dist < (player.size + collision_radius) then
                local damage = bullet.damage or enemy_config.bullet_damage
                player.health -= max(1, damage / player.armor)
                deli(bullets, i)

                -- Add hit explosion particles
                add_player_hit_particles(player.x, player.y)

                -- Check if player died from bullet damage
                if player.health <= 0 then
                    trigger_destruction("bullet_damage")
                end
            end
        end
        
        -- Remove bullets that are out of bounds or out of life
        local world_width = (#terrain or 500) * (world_config.terrain_spacing or 4)
        if bullet.life <= 0 or bullet.x < 0 or bullet.x > world_width or bullet.y < 0 or bullet.y > 270 then
            deli(bullets, i)
        end
    end
end

function add_explosion_particles(x, y)
    local config = effects_config
    for i = 1, config.explosion_particles do
        particles[#particles + 1] = {
            x = x,
            y = y,
            vx = (rnd(config.explosion_speed_max - config.explosion_speed_min) + config.explosion_speed_min) * (rnd(2) > 1 and 1 or -1),
            vy = (rnd(config.explosion_speed_max - config.explosion_speed_min) + config.explosion_speed_min) * (rnd(2) > 1 and 1 or -1),
            life = config.explosion_life,
            color = config.particle_colors[flr(rnd(#config.particle_colors)) + 1]
        }
    end
end

function add_player_hit_particles(x, y)
    -- Create hit particles when player is damaged
    for i = 1, 6 do
        particles[#particles + 1] = {
            x = x + rnd(16) - 8,  -- Spread around ship (32x32 sprite)
            y = y + rnd(16) - 8,
            vx = (rnd(4) - 2),    -- Random horizontal velocity
            vy = (rnd(4) - 2),    -- Random vertical velocity
            life = 15 + rnd(10),  -- 15-25 frames
            color = 8 + flr(rnd(2)),  -- Red or orange (8 or 9)
            size = 2 + flr(rnd(2))    -- Size 2 or 3
        }
    end
    
    -- Add some sparks for impact effect
    for i = 1, 4 do
        particles[#particles + 1] = {
            x = x + rnd(8) - 4,
            y = y + rnd(8) - 4,
            vx = (rnd(6) - 3),
            vy = (rnd(6) - 3),
            life = 8 + rnd(6),    -- 8-14 frames
            color = 10,           -- Yellow sparks
            size = 1
        }
    end
end

function spawn_coin(x, y)
    coins[#coins + 1] = {
        x = x,
        y = y,
        vx = 0,  -- Velocity for attraction movement
        vy = 0,
        life = money_config.coin_lifetime,
        color = money_config.coin_colors[flr(rnd(#money_config.coin_colors)) + 1],
        bob = 0,  -- For bobbing animation
        attracted = false  -- Whether coin is being attracted to player
    }
end

function update_coins()
    for i = #coins, 1, -1 do
        local coin = coins[i]
        coin.life -= 1
        coin.bob += 0.1

        -- Calculate distance to player
        local dx = player.x - coin.x
        local dy = player.y - coin.y
        local dist = sqrt(dx^2 + dy^2)

        -- Check if coin should be attracted to player
        if dist < money_config.coin_attraction_distance and not coin.attracted then
            coin.attracted = true
        end

        -- Move coin towards player if attracted
        if coin.attracted and dist > money_config.coin_collect_distance then
            local move_speed = money_config.coin_attraction_speed
            -- Normalize direction and apply speed
            if dist > 0 then
                coin.vx = (dx / dist) * move_speed
                coin.vy = (dy / dist) * move_speed

                -- Move coin
                coin.x += coin.vx
                coin.y += coin.vy
            end
        end

        -- Check collection (recalculate distance after movement)
        local final_dist = sqrt((coin.x - player.x)^2 + (coin.y - player.y)^2)
        if final_dist < money_config.coin_collect_distance then
            -- Play coin pickup sound effect
            if audio_config.coin_pickup_sound then
                sfx(audio_config.coin_pickup_sound)
            end

            player.money += money_config.enemy_kill_reward
            deli(coins, i)
            if debug_mode then print("Collected coin! Money: " .. player.money) end
        elseif coin.life <= 0 then
            deli(coins, i)
        end
    end
end

function update_bullet_trails()
    for i = #bullet_trails, 1, -1 do
        local trail = bullet_trails[i]
        trail.life -= 1
        if trail.life <= 0 then
            deli(bullet_trails, i)
        end
    end
end

function add_bullet_trail(bullet)
    if bullet.enemy_bullet and weapon_config.enemy_bullet_trail then
        bullet_trails[#bullet_trails + 1] = {
            x = bullet.x,
            y = bullet.y,
            life = weapon_config.trail_length,
            color = weapon_config.enemy_bullet_color
        }
    end
end

function update_particles()
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x += p.vx
        p.y += p.vy
        p.life -= 1
        
        -- Update age for color progression (if particle has age tracking)
        if p.age ~= nil then
            p.age += 1
            -- Update color based on age progression: white -> yellow -> orange
            local age_ratio = p.age / (p.age + p.life)  -- 0 to 1 progression
            if age_ratio < 0.3 then
                p.color = 7  -- White
            elseif age_ratio < 0.7 then
                p.color = 10  -- Yellow
            else
                p.color = 9  -- Orange
            end
        end
        
        if p.life <= 0 then
            deli(particles, i)
        end
    end
end

function check_player_terrain_collision()
    if not terrain or not get_terrain_height then return end
    
    -- Check for approaching terrain too quickly (proximity check)
    local terrain_height = get_terrain_height(player.x)
    local distance_to_terrain = (terrain_height - (player.y + 16))
    
    -- If close to terrain and moving downward quickly
    if distance_to_terrain > 0 and distance_to_terrain < 30 and player.vy > 0 then
        local total_velocity = sqrt(player.vx^2 + player.vy^2)
        local velocity_threshold = player.fuel <= 0 and balance_config.fuel_crash_velocity_threshold or balance_config.crash_velocity_threshold
        
        -- Predict if we'll crash at current velocity
        local time_to_impact = distance_to_terrain / player.vy
        if time_to_impact < 1 and total_velocity > velocity_threshold then
            -- Going to crash in less than 1 frame - trigger early crash
            trigger_destruction("velocity_crash")
            return
        end
    end
    
    -- Check actual terrain collision
    if player.y + 16 > terrain_height then
        -- Check velocity to determine crash severity
        local total_velocity = sqrt(player.vx^2 + player.vy^2)
        local velocity_threshold = player.fuel <= 0 and balance_config.fuel_crash_velocity_threshold or balance_config.crash_velocity_threshold
        
        if total_velocity > velocity_threshold then
            -- High-speed impact - instant destruction
            trigger_destruction("velocity_crash")
        else
            -- Lower speed impact - still crashes but different reason
            trigger_destruction("terrain_crash")
        end
        return
    end
    
    -- Check landing pad collisions and proximity
    for i, pad in ipairs(landing_pads) do
        local pad_left = pad.x - pad.width
        local pad_right = pad.x + pad.width
        local pad_top = pad.y
        local pad_bottom = pad.y + pad.height
        
        -- Check if approaching pad too quickly
        local distance_to_pad = (pad_top - (player.y + 16))
        if distance_to_pad > 0 and distance_to_pad < 30 and player.vy > 0 then
            -- Check if horizontally aligned with pad
            if player.x > pad_left and player.x < pad_right then
                local total_velocity = sqrt(player.vx^2 + player.vy^2)
                local velocity_threshold = player.fuel <= 0 and balance_config.fuel_crash_velocity_threshold or balance_config.crash_velocity_threshold
                
                -- Predict if we'll crash at current velocity
                local time_to_impact = distance_to_pad / player.vy
                if time_to_impact < 1 and total_velocity > velocity_threshold then
                    -- Going to crash into landing pad too fast
                    trigger_destruction("velocity_crash")
                    return
                end
            end
        end
        
        -- Check if player ship (32x32 sprite) overlaps with landing pad
        local ship_left = player.x - 16
        local ship_right = player.x + 16
        local ship_top = player.y - 16
        local ship_bottom = player.y + 16
        
        -- AABB collision detection with landing pad platform
        if ship_right > pad_left and ship_left < pad_right and
           ship_bottom > pad_top and ship_top < pad_bottom then
            
            -- Check approach velocity - crash if too fast
            local total_velocity = sqrt(player.vx^2 + player.vy^2)
            local velocity_threshold = player.fuel <= 0 and balance_config.fuel_crash_velocity_threshold or balance_config.crash_velocity_threshold
            
            if total_velocity > velocity_threshold then
                -- Approaching too fast - crash!
                trigger_destruction("velocity_crash")
                return
            end
            
            -- Safe landing - stop the ship on the landing pad
            player.y = pad_top - 16  -- Position bottom of sprite on pad surface
            player.vy = 0
            player.vx *= 0.3  -- Reduce horizontal momentum significantly
            return
        end
        
        -- Also check support columns
        local support_left_x = pad.x - pad.width * 0.7
        local support_right_x = pad.x + pad.width * 0.7
        local support_top = pad.y + pad.height
        local support_bottom = pad.terrain_y
        
        -- Left support collision
        if ship_right > support_left_x - 2 and ship_left < support_left_x + 2 and
           ship_bottom > support_top and ship_top < support_bottom then
            trigger_destruction("support_crash")
            return
        end
        
        -- Right support collision
        if ship_right > support_right_x - 2 and ship_left < support_right_x + 2 and
           ship_bottom > support_top and ship_top < support_bottom then
            trigger_destruction("support_crash")
            return
        end
    end
end

function trigger_destruction(crash_type)
    -- Stop all sounds immediately
    stop_thruster_sound()
    stop_low_fuel_warning()

    -- Play ship explosion sound effect
    if audio_config.explosion_sound then
        sfx(audio_config.explosion_sound)
    end

    game_state = "destroyed"
    destruction_timer = 0
    rescue_timer = 0
    crash_reason = crash_type  -- Store why we crashed

    -- Store crash location for visual effects
    crash_x = player.x
    crash_y = player.y

    if debug_mode then print("Ship destroyed: " .. crash_type) end
end

function draw_player()
    local px = player.x - camera.x
    local py = player.y - camera.y
    
    if sprites.use_sprites and sprites.player_ship then
        -- Draw 32x32 sprite centered on player position, flipped vertically
        spr(sprites.player_ship, px - 16, py - 16, 4,  false, true)  -- flipy = true
    else
        -- Draw vector art version
        draw_player_vector(px, py)
    end
    
    -- Draw thrust effect
    if player.thrusting then
        if sprites.use_sprites and sprites.player_thrust then
            -- TODO: Draw thrust sprite
        else
            draw_thrust_vector(px, py)
        end
    end
    
    -- Draw low fuel warning text
    draw_low_fuel_warning(px, py)
end

function draw_player_vector(px, py)
    -- Lunar lander body (no rotation - always upright)
    local ship_color = player_config.ship_color
    
    -- Main body (rectangle)
    rectfill(px - 6, py - 4, px + 6, py + 4, ship_color)
    
    -- Landing legs
    line(px - 6, py + 4, px - 10, py + 8, ship_color)  -- Left leg
    line(px + 6, py + 4, px + 10, py + 8, ship_color)  -- Right leg
    
    -- Landing pads
    line(px - 12, py + 8, px - 8, py + 8, ship_color)   -- Left pad
    line(px + 8, py + 8, px + 12, py + 8, ship_color)   -- Right pad
    
    -- Command module (top)
    rectfill(px - 4, py - 6, px + 4, py - 4, ship_color)
end

function draw_thrust_vector(px, py)
    -- Main thruster effect (below ship) - positioned for 32x32 sprite
    for i = 1, 8 do
        local thrust_x = px + (rnd(12) - 6)
        local thrust_y = py + 16 + rnd(12)  -- Below the 32x32 sprite
        local color = (rnd(2) > 1) and player_config.thrust_color_1 or player_config.thrust_color_2
        pset(thrust_x, thrust_y, color)
    end
end

function draw_low_fuel_warning(px, py)
    local fuel_percentage = player.fuel / player.max_fuel
    
    if fuel_percentage < 0.25 then  -- Below 25%
        -- Flash warning text every 30 frames (half second)
        local flash_on = (low_fuel_flash_timer % 30) < 15
        
        if flash_on then
            local warning_text = "LOW FUEL"
            local text_width = #warning_text * 4  -- Approximate text width
            local text_x = px - text_width / 2
            local text_y = py - 30  -- Above the ship
            
            -- Draw text with outline for visibility
            print(warning_text, text_x - 1, text_y, 0)  -- Black outline
            print(warning_text, text_x + 1, text_y, 0)
            print(warning_text, text_x, text_y - 1, 0)
            print(warning_text, text_x, text_y + 1, 0)
            print(warning_text, text_x, text_y, 8)  -- Red text
        end
    end
end

function draw_bullets()
    for i = 1, #bullets do
        local bullet = bullets[i]
        local bx = bullet.x - camera.x
        local by = bullet.y - camera.y
        
        if sprites.use_sprites then
            local sprite = nil
            
            if bullet.boss_bullet then
                -- Boss bullets use sprites 9 and 10 animated
                sprite = (bullet.sprite_frame == 0) and 9 or 10
            elseif bullet.enemy_bullet then
                -- Regular enemy bullets use sprites 11 and 12 animated
                sprite = (bullet.sprite_frame == 0) and 11 or 12
            else
                -- Player bullets use original sprite
                sprite = sprites.bullet_player
            end
            
            if sprite then
                spr(sprite, bx, by, 1, 1, false, true)  -- flipy=true
            else
                draw_bullet_vector(bx, by, bullet)
            end
        else
            draw_bullet_vector(bx, by, bullet)
        end
    end
end

function draw_bullet_vector(bx, by, bullet)
    local color = bullet.color or (bullet.enemy_bullet and weapon_config.enemy_bullet_color or ui_config.text_primary)
    local size = bullet.size or 2  -- Default size for normal bullets
    
    if bullet.boss_bullet then
        -- Draw big boss bullets as circles
        local radius = size / 2
        circfill(bx, by, radius, color)
        circ(bx, by, radius, 0)  -- Dark outline
    else
        -- Normal bullets (2x2 pixels)
        rectfill(bx, by, bx + 1, by + 1, color)
    end
end

function draw_particles()
    for i = 1, #particles do
        local particle = particles[i]
        local px = particle.x - camera.x
        local py = particle.y - camera.y
        
        -- Draw bigger particles if size is specified
        if particle.size and particle.size > 1 then
            local size = particle.size
            rectfill(px - size/2, py - size/2, px + size/2, py + size/2, particle.color)
        else
            pset(px, py, particle.color)
        end
    end
end

function draw_coins()
    for coin in ipairs(coins) do
        local coin_data = coins[coin]
        local cx = coin_data.x - camera.x
        local cy = coin_data.y - camera.y + sin(coin_data.bob) * 2  -- Bobbing effect
        
        -- Draw coin as a small circle
        circfill(cx, cy, 3, coin_data.color)
        circ(cx, cy, 3, 7)  -- White outline
    end
end

function draw_bullet_trails()
    for trail in ipairs(bullet_trails) do
        local trail_data = bullet_trails[trail]
        local tx = trail_data.x - camera.x
        local ty = trail_data.y - camera.y
        local alpha = trail_data.life / weapon_config.trail_length
        
        -- Draw fading trail point
        if alpha > 0.5 then
            pset(tx, ty, trail_data.color)
        else
            -- Faded trail
            pset(tx, ty, 1)  -- Dark color
        end
    end
end

function draw_target_indicator()
    -- Draw boss weak point targeting if in boss fight
    if boss_active and boss and current_boss_target > 0 and current_boss_target <= #boss.weak_points then
        draw_boss_target_indicator()
    -- Draw enemy targeting if not in boss fight or no boss target
    elseif current_target > 0 and current_target <= #enemies then
        draw_enemy_target_indicator()
    end
end

function draw_boss_target_indicator()
    local wp = boss.weak_points[current_boss_target]
    if wp.destroyed then return end
    
    local bx = boss.x - camera.x
    local by = boss.y - camera.y
    local wpx = bx + wp.x
    local wpy = by + wp.y
    
    -- Draw target brackets around boss weak point
    local size = wp.size + 4
    local color = 11  -- Light blue for all weak points (always vulnerable now)
    
    -- Animated pulsing brackets
    local pulse = sin(time() * 15) * 2 + 4
    size = size + pulse
    
    -- Corner brackets
    line(wpx - size, wpy - size, wpx - size + 4, wpy - size, color)      -- Top-left horizontal
    line(wpx - size, wpy - size, wpx - size, wpy - size + 4, color)      -- Top-left vertical
    
    line(wpx + size, wpy - size, wpx + size - 4, wpy - size, color)      -- Top-right horizontal
    line(wpx + size, wpy - size, wpx + size, wpy - size + 4, color)      -- Top-right vertical
    
    line(wpx - size, wpy + size, wpx - size + 4, wpy + size, color)      -- Bottom-left horizontal
    line(wpx - size, wpy + size, wpx - size, wpy + size - 4, color)      -- Bottom-left vertical
    
    line(wpx + size, wpy + size, wpx + size - 4, wpy + size, color)      -- Bottom-right horizontal
    line(wpx + size, wpy + size, wpx + size, wpy + size - 4, color)      -- Bottom-right vertical
    
    -- Draw targeting line from player to weak point
    local px = player.x - camera.x
    local py = player.y - camera.y
    
    -- Dotted line to target
    local dx = wpx - px
    local dy = wpy - py
    local dist = sqrt(dx*dx + dy*dy)
    
    if dist > 0 then
        dx = dx / dist
        dy = dy / dist
        
        local dot_spacing = 6
        local steps = flr(dist / dot_spacing)
        
        for i = 1, steps do
            local dot_x = px + (dx * i * dot_spacing)
            local dot_y = py + (dy * i * dot_spacing)
            
            -- Only draw every other dot
            if i % 2 == 1 then
                pset(dot_x, dot_y, color)
            end
        end
    end
end

function draw_enemy_target_indicator()
    local target_enemy = enemies[current_target]
    local ex = target_enemy.x - camera.x
    local ey = target_enemy.y - camera.y
    
    -- Draw target brackets around enemy
    local size = enemy_config.size + 3
    local color = 8  -- Red targeting color
    
    -- Corner brackets
    line(ex - size, ey - size, ex - size + 3, ey - size, color)      -- Top-left horizontal
    line(ex - size, ey - size, ex - size, ey - size + 3, color)      -- Top-left vertical
    
    line(ex + size, ey - size, ex + size - 3, ey - size, color)      -- Top-right horizontal
    line(ex + size, ey - size, ex + size, ey - size + 3, color)      -- Top-right vertical
    
    line(ex - size, ey + size, ex - size + 3, ey + size, color)      -- Bottom-left horizontal
    line(ex - size, ey + size, ex - size, ey + size - 3, color)      -- Bottom-left vertical
    
    line(ex + size, ey + size, ex + size - 3, ey + size, color)      -- Bottom-right horizontal
    line(ex + size, ey + size, ex + size, ey + size - 3, color)      -- Bottom-right vertical
    
    -- Draw targeting line from player to enemy
    local px = player.x - camera.x
    local py = player.y - camera.y
    
    -- Dotted line to target
    local dx = ex - px
    local dy = ey - py
    local dist = sqrt(dx*dx + dy*dy)
    
    if dist > 0 then
        dx = dx / dist
        dy = dy / dist
        
        local dot_spacing = 8
        local steps = flr(dist / dot_spacing)
        
        for i = 1, steps do
            local dot_x = px + (dx * i * dot_spacing)
            local dot_y = py + (dy * i * dot_spacing)
            
            -- Only draw every other dot
            if i % 2 == 1 then
                pset(dot_x, dot_y, color)
            end
        end
    end
end