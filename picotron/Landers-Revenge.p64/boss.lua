-- LANDER'S REVENGE - Boss Fight System

-- Boss state
boss = nil
boss_active = false
boss_spawn_timer = 0
boss_stage_transition_timer = 0
boss_exploding = false

-- Boss configuration
boss_config = {
    -- Boss appearance
    width = 80,
    height = 60,
    sprite_id = 9,  -- Boss sprite (if available)
    
    -- Boss stats per stage
    stages = {
        {
            health = 100,
            weak_points = 4,
            attack_pattern = "spread",
            bullet_speed = 0.8,  -- Slower for big projectiles
            bullet_rate = 60,    -- Faster firing (reduced from 90)
            movement_speed = 0.5,
            bullet_size = 8      -- Big projectiles
        },
        {
            health = 150,
            weak_points = 5,
            attack_pattern = "spiral",
            bullet_speed = 1.0,  -- Slower for big projectiles
            bullet_rate = 45,    -- Faster firing (reduced from 70)
            movement_speed = 0.8,
            bullet_size = 10     -- Bigger projectiles
        },
        {
            health = 200,
            weak_points = 8,
            attack_pattern = "barrage",
            bullet_speed = 1.2,  -- Slower for big projectiles  
            bullet_rate = 35,    -- Faster firing (reduced from 50)
            movement_speed = 1.2,
            bullet_size = 12     -- Biggest projectiles
        },
        {
            health = 300,
            weak_points = 0,     -- No weak points - boss can be damaged directly
            attack_pattern = "chaos",
            bullet_speed = 1.5,  -- Fastest bullets
            bullet_rate = 25,    -- Very fast firing
            movement_speed = 1.5,
            bullet_size = 14     -- Massive projectiles
        }
    },
    
    -- Visual
    body_color = 2,      -- Red
    weak_point_color = 8, -- Red
    destroyed_weak_point_color = 0, -- Black
    health_bar_color = 8, -- Red
}

-- Add global variable to track if we should spawn boss at end of level
should_spawn_boss_flag = false

function should_spawn_boss()
    -- Only spawn boss when the flag is set (at end of level)
    return should_spawn_boss_flag
end

function spawn_boss()
    if boss_active then return end
    
    -- Clear existing enemies
    enemies = {}
    
    -- Calculate stage index based on level (1-4 stages cycling)
    local stage_index = ((level - 1) % 4) + 1  -- Cycle through stages 1, 2, 3, 4
    local stage = boss_config.stages[stage_index]
    
    -- Debug check to ensure stage exists
    if not stage then
        stage_index = 1  -- Fallback to stage 1
        stage = boss_config.stages[stage_index]
    end
    
    -- Position boss at the end of the level (right side)
    local world_width = (#terrain or 500) * (world_config.terrain_spacing or 4)
    local boss_x = world_width - 100  -- Near the right edge of the world
    local boss_y = 100   -- Fixed height above terrain
    
    boss = {
        x = boss_x,
        y = boss_y,
        vx = 0,
        vy = 0,
        width = boss_config.width,
        height = boss_config.height,
        
        -- Stage and health
        current_stage = stage_index,
        max_health = stage.health,
        health = stage.health,
        
        -- Weak points
        weak_points = {},
        weak_points_destroyed = 0,
        total_weak_points = stage.weak_points,
        
        -- Combat
        shoot_timer = 0,
        attack_pattern = stage.attack_pattern,
        bullet_speed = stage.bullet_speed,
        bullet_rate = stage.bullet_rate,
        
        -- Movement
        movement_speed = stage.movement_speed,
        movement_timer = 0,
        movement_direction = 1,
        
        -- State
        invulnerable = false,
        stage_complete = false
    }
    
    -- Generate weak points around the boss
    generate_boss_weak_points()
    
    boss_active = true
    boss_exploding = false
    boss_stage_transition_timer = 0
    
    print("Boss spawned! Stage " .. stage_index, 10, 200, 8)
end

function generate_boss_weak_points()
    boss.weak_points = {}
    local stage = boss_config.stages[boss.current_stage]

    -- Safety check for stage
    if not stage then
        stage = boss_config.stages[1]  -- Fallback to stage 1
    end

    -- Distribute weak points around the boss perimeter, avoiding cross barriers
    for i = 1, stage.weak_points do
        local angle = (i / stage.weak_points) * 2 * 3.14159
        local radius = min(boss.width, boss.height) / 2 - 8
        
        local wp_x = cos(angle) * radius
        local wp_y = sin(angle) * radius
        
        -- Check if weak point overlaps with cross barriers and adjust position
        local barrier_width = 4
        local barrier_clearance = 10  -- Extra space to ensure no overlap
        
        -- If weak point is too close to vertical barrier (center vertical line)
        if abs(wp_x) < (barrier_width / 2 + barrier_clearance) then
            -- Move it further out horizontally
            if wp_x >= 0 then
                wp_x = barrier_width / 2 + barrier_clearance
            else
                wp_x = -(barrier_width / 2 + barrier_clearance)
            end
            -- Recalculate radius to maintain circular-ish distribution
            radius = sqrt(wp_x * wp_x + wp_y * wp_y)
            if radius > 0 then
                wp_y = wp_y * (radius / sqrt(wp_x * wp_x + wp_y * wp_y))
            end
        end
        
        -- If weak point is too close to horizontal barrier (center horizontal line)
        if abs(wp_y) < (barrier_width / 2 + barrier_clearance) then
            -- Move it further out vertically
            if wp_y >= 0 then
                wp_y = barrier_width / 2 + barrier_clearance
            else
                wp_y = -(barrier_width / 2 + barrier_clearance)
            end
            -- Recalculate to maintain distribution
            radius = sqrt(wp_x * wp_x + wp_y * wp_y)
            if radius > 0 then
                wp_x = wp_x * (radius / sqrt(wp_x * wp_x + wp_y * wp_y))
            end
        end

        boss.weak_points[i] = {
            x = wp_x,
            y = wp_y,
            destroyed = false,
            health = 25,  -- Reduced health since no armor system
            size = 8,     -- Size
        }
    end
end

function update_boss()
    if not boss_active or not boss then return end

    -- Handle stage transitions
    if boss_exploding then
        boss_stage_transition_timer += 1

        -- Create explosion effects during transition
        if boss_stage_transition_timer % 10 == 0 then
            add_boss_explosion_particle()
        end

        -- End transition after 3 seconds
        if boss_stage_transition_timer > 180 then
            if boss.current_stage >= 3 then
                -- Boss defeated
                defeat_boss()
            else
                -- Advance to next stage
                advance_boss_stage()
            end
        end
        return
    end

    update_boss_movement()
    update_boss_combat()
    check_boss_weak_point_collisions()

    -- Check if all weak points destroyed
    if boss.weak_points_destroyed >= boss.total_weak_points then
        start_stage_transition()
    end
end

function update_weak_point_vulnerability()
    -- Update vulnerability of each weak point based on player position
    for i, wp in ipairs(boss.weak_points) do
        if not wp.destroyed then
            local wp_world_x = boss.x + wp.x
            local wp_world_y = boss.y + wp.y

            -- Calculate angle from weak point to player
            local dx = player.x - wp_world_x
            local dy = player.y - wp_world_y
            local angle_to_player = atan2(dy, dx)

            -- Determine if player is in the vulnerable zone for this armor direction
            wp.vulnerable = is_player_in_vulnerable_zone(wp.armor_direction, angle_to_player, wp_world_x, wp_world_y)
        end
    end
end

function is_player_in_vulnerable_zone(armor_direction, angle_to_player, wp_x, wp_y)
    -- Convert angle to degrees for easier calculation
    local angle_deg = (angle_to_player * 180 / 3.14159 + 360) % 360

    -- Define vulnerable zones (90-degree arcs opposite to armor direction)
    if armor_direction == "top" then
        -- Armor faces up, vulnerable from below (180° ± 45°)
        return angle_deg >= 135 and angle_deg <= 225
    elseif armor_direction == "bottom" then
        -- Armor faces down, vulnerable from above (0° ± 45°)
        return angle_deg >= 315 or angle_deg <= 45
    elseif armor_direction == "left" then
        -- Armor faces left, vulnerable from right (270° ± 45°)
        return angle_deg >= 225 and angle_deg <= 315
    elseif armor_direction == "right" then
        -- Armor faces right, vulnerable from left (90° ± 45°)
        return angle_deg >= 45 and angle_deg <= 135
    end

    return false
end

function update_boss_movement()
    boss.movement_timer += 1
    
    -- Horizontal movement pattern
    if boss.movement_timer % 120 == 0 then  -- Change direction every 2 seconds
        boss.movement_direction *= -1
    end
    
    boss.vx = boss.movement_direction * boss.movement_speed
    
    -- Vertical bobbing motion
    boss.vy = sin(boss.movement_timer * 0.05) * 0.3
    
    -- Apply movement
    boss.x += boss.vx
    boss.y += boss.vy
    
    -- Keep boss on screen
    local screen_left = camera.x + boss.width/2
    local screen_right = camera.x + 480 - boss.width/2
    
    if boss.x < screen_left then
        boss.x = screen_left
        boss.movement_direction = 1
    elseif boss.x > screen_right then
        boss.x = screen_right
        boss.movement_direction = -1
    end
end

function update_boss_combat()
    boss.shoot_timer += 1
    
    if boss.shoot_timer >= boss.bullet_rate then
        boss.shoot_timer = 0
        fire_boss_bullets()
    end
end

function fire_boss_bullets()
    local pattern = boss.attack_pattern
    
    if pattern == "spread" then
        fire_spread_pattern()
    elseif pattern == "spiral" then
        fire_spiral_pattern()
    elseif pattern == "barrage" then
        fire_barrage_pattern()
    elseif pattern == "chaos" then
        fire_chaos_pattern()
    end
end

function fire_spread_pattern()
    -- Check if boss is on screen before firing
    local boss_screen_x = boss.x - camera.x
    local boss_screen_y = boss.y - camera.y
    if boss_screen_x < -50 or boss_screen_x > 530 or boss_screen_y < -50 or boss_screen_y > 320 then
        return  -- Boss is off-screen, don't fire
    end

    -- Play enemy weapon firing sound effect
    if audio_config.enemy_shoot_sound then
        sfx(audio_config.enemy_shoot_sound)
    end

    -- Fan of bullets toward player
    local bullets_count = 9  -- Increased from 5
    local spread_angle = 0.4  -- Increased spread

    local dx = player.x - boss.x
    local dy = player.y - boss.y
    local base_angle = atan2(dy, dx)

    for i = 1, bullets_count do
        local angle = base_angle + ((i - 5) * spread_angle / bullets_count)  -- Adjusted center for 9 bullets

        bullets[#bullets + 1] = {
            x = boss.x,
            y = boss.y + boss.height/2,
            vx = cos(angle) * boss.bullet_speed,
            vy = sin(angle) * boss.bullet_speed,
            life = 400,  -- Longer lifetime for slow bullets
            enemy_bullet = true,
            boss_bullet = true,  -- Mark as boss bullet
            color = weapon_config.enemy_bullet_color,
            damage = 25,
            size = boss.bullet_size or 8,  -- Big projectile
            animation_timer = 0,  -- For sprite animation
            sprite_frame = 0      -- Current animation frame (0 or 1)
        }
    end
end

function fire_spiral_pattern()
    -- Check if boss is on screen before firing
    local boss_screen_x = boss.x - camera.x
    local boss_screen_y = boss.y - camera.y
    if boss_screen_x < -50 or boss_screen_x > 530 or boss_screen_y < -50 or boss_screen_y > 320 then
        return  -- Boss is off-screen, don't fire
    end

    -- Play enemy weapon firing sound effect
    if audio_config.enemy_shoot_sound then
        sfx(audio_config.enemy_shoot_sound)
    end

    -- Rotating spiral pattern
    local angle = (boss.movement_timer * 0.1) % (2 * 3.14159)

    for i = 0, 7 do  -- 8 bullets in spiral (increased from 4)
        local spiral_angle = angle + (i * 3.14159 / 4)  -- Adjusted spacing for 8 bullets

        bullets[#bullets + 1] = {
            x = boss.x,
            y = boss.y + boss.height/2,
            vx = cos(spiral_angle) * boss.bullet_speed,
            vy = sin(spiral_angle) * boss.bullet_speed,
            life = 400,
            enemy_bullet = true,
            boss_bullet = true,  -- Mark as boss bullet
            color = weapon_config.enemy_bullet_color,
            damage = 25,
            size = boss.bullet_size or 8,  -- Big projectile
            animation_timer = 0,  -- For sprite animation
            sprite_frame = 0      -- Current animation frame (0 or 1)
        }
    end
end

function fire_barrage_pattern()
    -- Check if boss is on screen before firing
    local boss_screen_x = boss.x - camera.x
    local boss_screen_y = boss.y - camera.y
    if boss_screen_x < -50 or boss_screen_x > 530 or boss_screen_y < -50 or boss_screen_y > 320 then
        return  -- Boss is off-screen, don't fire
    end

    -- Play enemy weapon firing sound effect
    if audio_config.enemy_shoot_sound then
        sfx(audio_config.enemy_shoot_sound)
    end

    -- Multiple bullets toward player with slight spread
    local bullets_count = 15  -- Increased from 8
    local spread = 0.3  -- Increased spread

    local dx = player.x - boss.x
    local dy = player.y - boss.y
    local base_angle = atan2(dy, dx)

    for i = 1, bullets_count do
        local angle = base_angle + (rnd(spread * 2) - spread)

        bullets[#bullets + 1] = {
            x = boss.x + rnd(boss.width) - boss.width/2,
            y = boss.y + boss.height/2,
            vx = cos(angle) * boss.bullet_speed,
            vy = sin(angle) * boss.bullet_speed,
            life = 400,
            enemy_bullet = true,
            boss_bullet = true,  -- Mark as boss bullet
            color = weapon_config.enemy_bullet_color,
            damage = 25,
            size = boss.bullet_size or 8,  -- Big projectile
            animation_timer = 0,  -- For sprite animation
            sprite_frame = 0      -- Current animation frame (0 or 1)
        }
    end
end

function fire_chaos_pattern()
    -- Check if boss is on screen before firing
    local boss_screen_x = boss.x - camera.x
    local boss_screen_y = boss.y - camera.y
    if boss_screen_x < -50 or boss_screen_x > 530 or boss_screen_y < -50 or boss_screen_y > 320 then
        return  -- Boss is off-screen, don't fire
    end

    -- Play weapon firing sound effect
    if audio_config.enemy_shoot_sound then
        sfx(audio_config.enemy_shoot_sound)
    end

    -- Chaos pattern: Combines all patterns for maximum mayhem
    
    -- Part 1: Spread pattern toward player (12 bullets)
    local dx = player.x - boss.x
    local dy = player.y - boss.y
    local base_angle = atan2(dy, dx)
    
    for i = 1, 12 do
        local spread_angle = 0.6  -- Very wide spread
        local angle = base_angle + ((i - 6.5) * spread_angle / 12)

        bullets[#bullets + 1] = {
            x = boss.x,
            y = boss.y + boss.height/2,
            vx = cos(angle) * boss.bullet_speed,
            vy = sin(angle) * boss.bullet_speed,
            life = 400,
            enemy_bullet = true,
            boss_bullet = true,
            damage = 25,
            size = boss.bullet_size,
            color = 8,  -- Red bullets
            animation_timer = 0,
            sprite_frame = 0
        }
    end
    
    -- Part 2: 360-degree spiral (8 bullets)
    local spiral_time = boss.movement_timer * 0.15
    for i = 0, 7 do
        local spiral_angle = spiral_time + (i * 3.14159 / 4)

        bullets[#bullets + 1] = {
            x = boss.x,
            y = boss.y,
            vx = cos(spiral_angle) * boss.bullet_speed * 0.8,
            vy = sin(spiral_angle) * boss.bullet_speed * 0.8,
            life = 400,
            enemy_bullet = true,
            boss_bullet = true,
            damage = 25,
            size = boss.bullet_size,
            color = 9,  -- Orange bullets
            animation_timer = 0,
            sprite_frame = 0
        }
    end
    
    -- Part 3: Random scatter barrage (10 bullets)
    for i = 1, 10 do
        local random_angle = rnd(6.28)  -- Full 360 degrees

        bullets[#bullets + 1] = {
            x = boss.x + rnd(boss.width) - boss.width/2,
            y = boss.y + rnd(boss.height) - boss.height/2,
            vx = cos(random_angle) * boss.bullet_speed * 1.2,
            vy = sin(random_angle) * boss.bullet_speed * 1.2,
            life = 400,
            enemy_bullet = true,
            boss_bullet = true,
            damage = 25,
            size = boss.bullet_size,
            color = 10,  -- Yellow bullets
            animation_timer = 0,
            sprite_frame = 0
        }
    end
end

function check_boss_weak_point_collisions()
    -- Check player bullets vs weak points (or direct boss damage if no weak points)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if not bullet.enemy_bullet then
            
            -- If boss has no weak points (stage 4), damage boss directly
            if boss.total_weak_points == 0 then
                local dx = bullet.x - boss.x
                local dy = bullet.y - boss.y
                local dist = sqrt(dx*dx + dy*dy)
                
                -- Check if bullet hits boss body
                if dist < (boss.width / 2) then
                    boss.health -= bullet.damage
                    deli(bullets, i)
                    
                    -- Add hit effect on boss body
                    add_weak_point_hit_effect(bullet.x, bullet.y)
                    
                    if debug_mode then 
                        print("Direct boss hit! Health: " .. flr(boss.health))
                    end
                    
                    -- Check if boss is defeated
                    if boss.health <= 0 then
                        defeat_boss()
                    end
                    break
                end
            else
                -- Normal weak point targeting for stages 1-3
                for j, wp in ipairs(boss.weak_points) do
                if not wp.destroyed then
                    local wp_world_x = boss.x + wp.x
                    local wp_world_y = boss.y + wp.y

                    local dist = sqrt((bullet.x - wp_world_x)^2 + (bullet.y - wp_world_y)^2)

                    if dist < wp.size then
                        -- Check if bullet is blocked by boss barriers first
                        local blocked = is_bullet_blocked_by_barriers(bullet.x, bullet.y, wp_world_x, wp_world_y)
                        if not blocked then
                            -- Hit weak point (all weak points are now always vulnerable)
                            wp.health -= bullet.damage
                            deli(bullets, i)

                            -- Add hit effect
                            add_weak_point_hit_effect(wp_world_x, wp_world_y)

                            if wp.health <= 0 then
                                wp.destroyed = true
                                boss.weak_points_destroyed += 1

                                -- Reduce boss health when weak point is destroyed
                                local health_reduction = boss.max_health / boss.total_weak_points
                                boss.health -= health_reduction

                                -- Add destruction effect
                                add_weak_point_explosion(wp_world_x, wp_world_y)
                                
                                if debug_mode then 
                                    print("Weak point destroyed! Boss health: " .. flr(boss.health))
                                end
                            end
                            break
                        else
                            -- Bullet blocked by barrier
                            deli(bullets, i)
                            add_barrier_deflect_effect(bullet.x, bullet.y)
                            break
                        end
                    end
                end
            end
            end  -- Close the else block for weak point targeting
        end
    end
end

function add_weak_point_hit_effect(x, y)
    -- Add hit particles for successful hits
    for i = 1, 4 do
        particles[#particles + 1] = {
            x = x,
            y = y,
            vx = (rnd(4) - 2),
            vy = (rnd(4) - 2),
            life = 20,
            color = 10,  -- Yellow hit effect
            size = 2
        }
    end
end

function add_barrier_deflect_effect(x, y)
    -- Add deflection particles for barrier hits
    for i = 1, 4 do
        particles[#particles + 1] = {
            x = x,
            y = y,
            vx = (rnd(6) - 3),
            vy = (rnd(6) - 3),
            life = 20,
            color = 7,  -- White deflection effect
            size = 2
        }
    end
end

function is_bullet_blocked_by_barriers(bullet_x, bullet_y, target_x, target_y)
    -- Check if the bullet path from bullet to target crosses the boss barriers
    local boss_center_x = boss.x
    local boss_center_y = boss.y
    local barrier_width = 4  -- Width of barrier beams (reduced from 6)
    local barrier_length = boss.width * 0.8  -- Length of each barrier arm
    
    -- Check vertical barrier (blocks horizontal shots across middle)
    local vertical_left = boss_center_x - barrier_width / 2
    local vertical_right = boss_center_x + barrier_width / 2
    local vertical_top = boss_center_y - barrier_length / 2
    local vertical_bottom = boss_center_y + barrier_length / 2
    
    -- Check horizontal barrier (blocks vertical shots across middle)
    local horizontal_left = boss_center_x - barrier_length / 2
    local horizontal_right = boss_center_x + barrier_length / 2
    local horizontal_top = boss_center_y - barrier_width / 2
    local horizontal_bottom = boss_center_y + barrier_width / 2
    
    -- Check if bullet path crosses the vertical barrier
    if line_intersects_rect(bullet_x, bullet_y, target_x, target_y, 
                           vertical_left, vertical_top, vertical_right, vertical_bottom) then
        return true
    end
    
    -- Check if bullet path crosses the horizontal barrier
    if line_intersects_rect(bullet_x, bullet_y, target_x, target_y,
                           horizontal_left, horizontal_top, horizontal_right, horizontal_bottom) then
        return true
    end
    
    return false
end

function line_intersects_rect(x1, y1, x2, y2, rect_left, rect_top, rect_right, rect_bottom)
    -- Simple line-rectangle intersection check
    -- Check if line endpoints are on opposite sides of any rectangle edge
    
    -- If either point is inside the rectangle, there's an intersection
    if (x1 >= rect_left and x1 <= rect_right and y1 >= rect_top and y1 <= rect_bottom) or
       (x2 >= rect_left and x2 <= rect_right and y2 >= rect_top and y2 <= rect_bottom) then
        return true
    end
    
    -- Check if line crosses any edge of the rectangle
    -- This is a simplified check - could be more precise but works for our use case
    local dx = x2 - x1
    local dy = y2 - y1
    
    if dx == 0 and dy == 0 then return false end
    
    -- Check intersection with vertical edges
    if dx ~= 0 then
        local t_left = (rect_left - x1) / dx
        local t_right = (rect_right - x1) / dx
        
        for _, t in ipairs({t_left, t_right}) do
            if t >= 0 and t <= 1 then
                local y_intersect = y1 + t * dy
                if y_intersect >= rect_top and y_intersect <= rect_bottom then
                    return true
                end
            end
        end
    end
    
    -- Check intersection with horizontal edges
    if dy ~= 0 then
        local t_top = (rect_top - y1) / dy
        local t_bottom = (rect_bottom - y1) / dy
        
        for _, t in ipairs({t_top, t_bottom}) do
            if t >= 0 and t <= 1 then
                local x_intersect = x1 + t * dx
                if x_intersect >= rect_left and x_intersect <= rect_right then
                    return true
                end
            end
        end
    end
    
    return false
end

function add_weak_point_explosion(x, y)
    -- Add multiple explosion particles
    for i = 1, 8 do
        particles[#particles + 1] = {
            x = x,
            y = y,
            vx = (rnd(4) - 2),
            vy = (rnd(4) - 2),
            life = 15 + rnd(10),
            color = 9 + flr(rnd(2)),  -- Orange/yellow
            size = 2
        }
    end
end

function add_boss_explosion_particle()
    -- Random explosion on boss body
    local exp_x = boss.x + rnd(boss.width) - boss.width/2
    local exp_y = boss.y + rnd(boss.height) - boss.height/2
    
    for i = 1, 5 do
        particles[#particles + 1] = {
            x = exp_x,
            y = exp_y,
            vx = (rnd(6) - 3),
            vy = (rnd(6) - 3),
            life = 20 + rnd(15),
            color = 8 + flr(rnd(3)),  -- Red/orange/yellow
            size = 3
        }
    end
end

function start_stage_transition()
    boss_exploding = true
    boss_stage_transition_timer = 0
    boss.invulnerable = true
    
    -- Stop boss movement during transition
    boss.vx = 0
    boss.vy = 0
    
    print("Stage " .. boss.current_stage .. " complete!", 10, 220, 11)
end

function advance_boss_stage()
    boss.current_stage += 1
    
    if boss.current_stage <= 3 then
        local new_stage = boss_config.stages[boss.current_stage]
        
        -- Safety check for stage
        if not new_stage then
            new_stage = boss_config.stages[1]  -- Fallback to stage 1
            boss.current_stage = 1
        end
        
        -- Reset boss for next stage
        boss.health = new_stage.health
        boss.max_health = new_stage.health
        boss.attack_pattern = new_stage.attack_pattern
        boss.bullet_speed = new_stage.bullet_speed
        boss.bullet_rate = new_stage.bullet_rate
        boss.movement_speed = new_stage.movement_speed
        boss.total_weak_points = new_stage.weak_points
        boss.weak_points_destroyed = 0
        boss.invulnerable = false
        
        -- Generate new weak points
        generate_boss_weak_points()
        
        boss_exploding = false
        print("Boss Stage " .. boss.current_stage .. " begins!", 10, 220, 8)
    end
end

-- Global variables for level progression
level_progression_timer = 0
show_level_complete_text = false

function defeat_boss()
    boss_active = false
    boss = nil
    boss_exploding = false
    should_spawn_boss_flag = false  -- Reset flag

    -- Check if this is the end of level 3 - trigger ending cutscene
    if level == 3 then
        game_state = "ending"
        ending_timer = 0
        ending_text_phase = 1
        print("THE END! Starting ending cutscene...", 10, 220, 11)
        return
    end

    -- Start normal level completion sequence
    show_level_complete_text = true
    level_progression_timer = 0

    -- Give rewards
    player.money += 500  -- Big reward for beating boss

    -- Reset player health and fuel to maximum
    player.health = player.max_health
    player.fuel = player.max_fuel

    print("Boss defeated! Level " .. level .. " complete!", 10, 220, 11)
end

function reset_boss_for_new_level()
    -- Reset boss state for new level
    boss_active = false
    boss = nil
    boss_exploding = false
    should_spawn_boss_flag = false
    boss_spawn_timer = 0
    boss_stage_transition_timer = 0
    show_level_complete_text = false
    level_progression_timer = 0
end

function update_level_progression()
    if show_level_complete_text then
        level_progression_timer += 1
        
        -- Show level complete text for 3 seconds
        if level_progression_timer > 180 then
            -- Advance to next level
            level += 1

            -- Change background color for new level
            change_background_for_level()

            -- Generate new terrain for next level
            generate_terrain()
            place_landing_pads()
            
            -- Position player on first landing pad for new level
            if #landing_pads > 0 then
                local first_pad = landing_pads[1]
                player.x = first_pad.x
                player.y = first_pad.y - 16
                player.vx = 0
                player.vy = 0
                player.last_safe_x = first_pad.x
                player.last_safe_y = first_pad.y - 16
            end

            -- Reset boss state for new level
            reset_boss_for_new_level()

            -- Hide level complete text
            show_level_complete_text = false
            level_progression_timer = 0
        end
    end
end

function change_background_for_level()
    -- Change terrain color based on level
    local level_colors = {1, 2, 3, 4, 5, 6}  -- Different dark colors
    local color_index = ((level - 1) % #level_colors) + 1
    world_config.terrain_color = level_colors[color_index]
    world_config.terrain_fill_color = level_colors[color_index]
    
    -- Also change horizon color slightly
    world_config.horizon_color = level_colors[color_index] + 10
end

function draw_boss()
    if not boss_active or not boss then return end
    
    local bx = boss.x - camera.x
    local by = boss.y - camera.y
    
    -- Only draw if on screen
    if bx > -boss.width and bx < 480 + boss.width and by > -boss.height and by < 270 + boss.height then
        
        -- Draw boss body
        if sprites.use_sprites and sprites[boss_config.sprite_id] then
            spr(boss_config.sprite_id, bx - boss.width/2, by - boss.height/2, 
                boss.width/8, boss.height/8, false, false)
        else
            -- Fallback vector boss
            rectfill(bx - boss.width/2, by - boss.height/2, 
                     bx + boss.width/2, by + boss.height/2, boss_config.body_color)
            rect(bx - boss.width/2, by - boss.height/2, 
                 bx + boss.width/2, by + boss.height/2, 7)
        end
        
        -- Draw giant cross barriers (only if boss has weak points)
        if boss.total_weak_points > 0 then
            draw_boss_barriers(bx, by)
        end
        
        -- Draw weak points (simplified - no armor) - only if boss has weak points
        if boss.total_weak_points > 0 then
            for wp in all(boss.weak_points) do
            local wpx = bx + wp.x
            local wpy = by + wp.y

            if wp.destroyed then
                -- Destroyed weak point
                circfill(wpx, wpy, wp.size/2, boss_config.destroyed_weak_point_color)
                circ(wpx, wpy, wp.size/2, 1)  -- Dark outline
            else
                -- Draw weak point core (always vulnerable now)
                circfill(wpx, wpy, wp.size/2, 8)  -- Red core
                circ(wpx, wpy, wp.size/2, 7)  -- White outline
                
                -- Draw targeting indicator (always visible since always vulnerable)
                draw_weak_point_targeting_indicator(wpx, wpy, wp.size)
            end
        end
        end  -- Close the if block for weak points
        
        -- Draw boss health bar
        draw_boss_health_bar()
    end
end

function draw_boss_barriers(bx, by)
    local barrier_width = 4  -- Match collision detection width
    local barrier_length = boss.width * 0.8
    local barrier_color = 6  -- Grey color for barriers
    local barrier_outline = 0  -- Black outline
    
    -- Draw vertical barrier (blocks horizontal shots)
    local v_left = bx - barrier_width / 2
    local v_right = bx + barrier_width / 2
    local v_top = by - barrier_length / 2
    local v_bottom = by + barrier_length / 2
    
    rectfill(v_left, v_top, v_right, v_bottom, barrier_color)
    rect(v_left, v_top, v_right, v_bottom, barrier_outline)
    
    -- Draw horizontal barrier (blocks vertical shots)
    local h_left = bx - barrier_length / 2
    local h_right = bx + barrier_length / 2
    local h_top = by - barrier_width / 2
    local h_bottom = by + barrier_width / 2
    
    rectfill(h_left, h_top, h_right, h_bottom, barrier_color)
    rect(h_left, h_top, h_right, h_bottom, barrier_outline)
    
    -- Draw center intersection (slightly thicker)
    local center_size = barrier_width + 2
    rectfill(bx - center_size/2, by - center_size/2, bx + center_size/2, by + center_size/2, barrier_color)
    rect(bx - center_size/2, by - center_size/2, bx + center_size/2, by + center_size/2, barrier_outline)
end

function draw_weak_point_targeting_indicator(x, y, size)
    -- Animated targeting brackets around vulnerable weak points
    local time = time() * 10  -- Animation speed
    local pulse = sin(time) * 2 + 3  -- Pulsing size
    local bracket_size = size/2 + pulse
    local color = 10  -- Yellow targeting color

    -- Corner brackets
    local offset = bracket_size + 2

    -- Top-left
    line(x - offset, y - offset, x - offset + 4, y - offset, color)
    line(x - offset, y - offset, x - offset, y - offset + 4, color)

    -- Top-right
    line(x + offset, y - offset, x + offset - 4, y - offset, color)
    line(x + offset, y - offset, x + offset, y - offset + 4, color)

    -- Bottom-left
    line(x - offset, y + offset, x - offset + 4, y + offset, color)
    line(x - offset, y + offset, x - offset, y + offset - 4, color)

    -- Bottom-right
    line(x + offset, y + offset, x + offset - 4, y + offset, color)
    line(x + offset, y + offset, x + offset, y + offset - 4, color)
end

function draw_boss_health_bar()
    local bar_width = 200
    local bar_height = 8
    local bar_x = 480/2 - bar_width/2
    local bar_y = 20
    
    -- Background
    rectfill(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, 1)
    rect(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, 7)
    
    -- Health fill
    local health_ratio = boss.health / boss.max_health
    local fill_width = health_ratio * bar_width
    rectfill(bar_x, bar_y, bar_x + fill_width, bar_y + bar_height, boss_config.health_bar_color)
    
    -- Boss info
    print("BOSS STAGE " .. boss.current_stage, bar_x, bar_y - 10, 7)
    print("WEAK POINTS: " .. (boss.total_weak_points - boss.weak_points_destroyed), bar_x, bar_y + bar_height + 5, 7)
end

function draw_level_complete_text()
    if show_level_complete_text then
        local text = "LEVEL " .. level .. " OF 3 COMPLETE!"
        local text_x = (480 - #text * 4) / 2
        local text_y = 120
        
        -- Draw text with outline for visibility
        print(text, text_x - 1, text_y, 0); print(text, text_x + 1, text_y, 0)
        print(text, text_x, text_y - 1, 0); print(text, text_x, text_y + 1, 0)
        print(text, text_x, text_y, 11)  -- Light green
        
        -- Progress indicator
        local dots = ""
        local dot_count = flr(level_progression_timer / 20) % 4
        for i = 1, dot_count do
            dots = dots .. "."
        end
        local next_text = "Proceeding to next level" .. dots
        local next_x = (480 - #next_text * 4) / 2
        print(next_text, next_x - 1, text_y + 15, 0); print(next_text, next_x + 1, text_y + 15, 0)
        print(next_text, next_x, text_y + 14, 0); print(next_text, next_x, text_y + 16, 0)
        print(next_text, next_x, text_y + 15, 7)  -- White
    end
end