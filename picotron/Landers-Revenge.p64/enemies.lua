-- LANDER'S REVENGE - Enemy System

-- Enemies array
enemies = {}

function spawn_enemies()
    -- Don't spawn enemies when player has landed
    if player_landed then
        return
    end
    
    if #enemies < enemy_config.max_enemies then
        local spawn_chance = enemy_config.spawn_chance + (level * enemy_config.spawn_chance_per_level)
        if rnd(100) < spawn_chance then
            create_enemy()
        end
    end
end

function create_enemy()
    -- Spawn enemy off-screen only
    local screen_left = camera.x
    local screen_right = camera.x + 480
    local spawn_margin = 50  -- Extra distance beyond screen edge
    
    local enemy_x
    local world_width = (#terrain or 500) * (world_config.terrain_spacing or 4)
    
    -- Choose to spawn on left or right side of screen
    if rnd(1) > 0.5 then
        -- Spawn on right side (off-screen right)
        enemy_x = screen_right + spawn_margin + rnd(100)
    else
        -- Spawn on left side (off-screen left)
        enemy_x = screen_left - spawn_margin - rnd(100)
    end
    
    -- Clamp to world bounds
    enemy_x = max(50, min(enemy_x, world_width - 50))
    
    -- If clamping put us back on screen, don't spawn
    if enemy_x >= screen_left - spawn_margin and enemy_x <= screen_right + spawn_margin then
        return  -- Don't create enemy if can't spawn off-screen
    end
    
    -- Place above terrain
    local enemy_y = (get_terrain_height and get_terrain_height(enemy_x) or 200) - 30
    
    enemies[#enemies + 1] = {
        x = enemy_x,
        y = enemy_y,
        vx = 0,
        vy = 0,
        health = enemy_config.base_health + (level * enemy_config.health_per_level),
        max_health = enemy_config.base_health + (level * enemy_config.health_per_level),
        shoot_timer = 0,
        type = "guard",
        facing_direction = 1  -- 1 = right, -1 = left
    }
end

function update_enemies()
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        
        update_enemy_ai(enemy)
        update_enemy_physics(enemy)
        update_enemy_combat(enemy)
        check_enemy_player_collision(enemy, i)
        
        -- Remove enemies marked for removal
        if enemy.remove_me then
            deli(enemies, i)
            -- Update target if it was pointing to a removed enemy
            if current_target == i then
                current_target = 0
            elseif current_target > i then
                current_target -= 1
            end
        end
    end
end

function update_enemy_ai(enemy)
    if enemy.fleeing then
        -- Fleeing behavior - move away from player
        local dx = enemy.x - player.x
        local dy = enemy.y - player.y
        local dist = sqrt(dx^2 + dy^2)
        
        if dist > 0 then
            -- Continue moving away
            enemy.vx += (dx / dist) * enemy_config.move_speed * 3  -- Faster when fleeing
            enemy.vy += (dy / dist) * enemy_config.move_speed * 3
        end
        
        -- Remove enemies that have fled far enough
        if dist > 400 then
            -- Mark for removal
            enemy.remove_me = true
        end
    else
        -- Normal AI: approach to optimal distance
        local dx = player.x - enemy.x
        local dy = player.y - enemy.y
        local dist = sqrt(dx^2 + dy^2)
        local approach_distance = enemy_config.approach_distance
        
        if dist > 0 then
            if dist > approach_distance + 20 then
                -- Too far - move toward player
                enemy.vx += (dx / dist) * enemy_config.move_speed
                enemy.vy += (dy / dist) * enemy_config.move_speed
            elseif dist < approach_distance - 20 then
                -- Too close - move away from player
                enemy.vx -= (dx / dist) * enemy_config.move_speed * 0.5
                enemy.vy -= (dy / dist) * enemy_config.move_speed * 0.5
            else
                -- At good distance - orbit around player slightly
                local orbit_speed = enemy_config.move_speed * 0.3
                enemy.vx += -dy / dist * orbit_speed  -- Perpendicular movement
                enemy.vy += dx / dist * orbit_speed
            end
        end
    end
end

function update_enemy_physics(enemy)
    -- Update facing direction based on horizontal velocity
    if abs(enemy.vx) > 0.01 then  -- Only update if moving significantly
        enemy.facing_direction = enemy.vx > 0 and 1 or -1
    end
    
    -- Apply movement
    enemy.x += enemy.vx
    enemy.y += enemy.vy
    
    -- Apply drag
    enemy.vx *= enemy_config.drag
    enemy.vy *= enemy_config.drag
    
    -- Terrain collision
    if get_terrain_height then
        local terrain_height = get_terrain_height(enemy.x)
        if enemy.y + enemy_config.size > terrain_height then
            enemy.y = terrain_height - enemy_config.size
            enemy.vy = 0
        end
    end
    
    -- Add thruster particles when moving
    add_enemy_thruster_particles(enemy)
end

function add_enemy_thruster_particles(enemy)
    -- Only add particles if enemy is moving (either direction)
    local is_thrusting = abs(enemy.vx) > 0.005 or abs(enemy.vy) > 0.005
    
    if is_thrusting and rnd(1) > 0.7 then  -- 30% chance per frame to add particle
        -- Thruster position - opposite to movement direction
        local thruster_offset = 8  -- Distance behind enemy center
        local thrust_x = enemy.x - (enemy.facing_direction * thruster_offset)
        local thrust_y = enemy.y + 4  -- Slightly below center
        
        -- Particle velocity - mainly opposite to enemy movement, with some spread
        local particle_speed = 1 + rnd(2)  -- 1-3 pixels per frame
        local spread = 0.3
        local base_vx = -enemy.vx * 0.5 + (rnd(spread * 2) - spread)
        local base_vy = -enemy.vy * 0.5 + (rnd(spread * 2) - spread) + 0.5  -- Slight downward bias
        
        -- Create thruster particle
        particles[#particles + 1] = {
            x = thrust_x + rnd(4) - 2,  -- Small random offset
            y = thrust_y + rnd(4) - 2,
            vx = base_vx,
            vy = base_vy,
            life = 8 + rnd(4),  -- 8-12 frames lifetime
            age = 0,  -- Track age for color progression
            color = 7,  -- Start white, will progress to yellow then orange
            size = 2  -- Bigger particle size like player thrusters
        }
    end
end

function update_enemy_combat(enemy)
    -- Don't shoot when fleeing or when player has landed
    if enemy.fleeing or player_landed then
        return
    end

    -- Check if enemy is on screen before allowing it to shoot
    local enemy_screen_x = enemy.x - camera.x
    local enemy_screen_y = enemy.y - camera.y
    local is_on_screen = enemy_screen_x >= -50 and enemy_screen_x <= 530 and enemy_screen_y >= -50 and enemy_screen_y <= 320

    -- Only shoot if enemy is on screen
    if not is_on_screen then
        return
    end

    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local dist = sqrt(dx^2 + dy^2)

    -- Shooting
    enemy.shoot_timer += 1
    if enemy.shoot_timer > enemy_config.shoot_cooldown and dist < enemy_config.shoot_range then
        enemy_shoot(enemy, dx, dy, dist)
        enemy.shoot_timer = 0
    end
end

function check_enemy_player_collision(enemy, enemy_index)
    local dx = enemy.x - player.x
    local dy = enemy.y - player.y
    local dist = sqrt(dx^2 + dy^2)
    
    if dist < (enemy_config.size + player.size) then
        -- Damage both player and enemy
        player.health -= max(1, enemy_config.collision_damage / player.armor)
        enemy.health -= 20  -- Enemy takes damage from collision too
        
        -- Add hit explosion particles for both player and enemy
        add_player_hit_particles(player.x, player.y)
        add_explosion_particles(enemy.x, enemy.y)
        
        if enemy.health <= 0 then
            deli(enemies, enemy_index)
            add_explosion_particles(enemy.x, enemy.y)
        end
        
        if player.health <= 0 then
            -- Play ship explosion sound effect
            if audio_config.explosion_sound then
                sfx(audio_config.explosion_sound)
            end

            game_state = "destroyed"
            destruction_timer = 0
            rescue_timer = 0
            crash_reason = "enemy_collision"  -- Store crash reason
            crash_x = player.x
            crash_y = player.y
        end
    end
end

function enemy_shoot(enemy, dx, dy, dist)
    -- Play enemy weapon firing sound effect
    if audio_config.enemy_shoot_sound then
        sfx(audio_config.enemy_shoot_sound)
    end

    bullets[#bullets + 1] = {
        x = enemy.x,
        y = enemy.y,
        vx = (dx / dist) * enemy_config.bullet_speed,
        vy = (dy / dist) * enemy_config.bullet_speed,
        life = enemy_config.bullet_lifetime,
        enemy_bullet = true,
        color = weapon_config.enemy_bullet_color,
        animation_timer = 0,  -- For sprite animation
        sprite_frame = 0      -- Current animation frame (0 or 1)
    }
end

function clear_enemies()
    enemies = {}
end

function draw_enemies()
    for i = 1, #enemies do
        local enemy = enemies[i]
        local ex = enemy.x - camera.x
        local ey = enemy.y - camera.y
        
        if sprites.use_sprites and sprites.enemy_guard then
            draw_enemy_sprite(ex, ey, enemy)
        else
            draw_enemy_vector(ex, ey, enemy)
        end
        
        -- Draw health bar if damaged
        if enemy.health < enemy.max_health then
            draw_enemy_health_bar(ex, ey, enemy)
        end
    end
end

function draw_enemy_sprite(ex, ey, enemy)
    -- Draw sprite version with horizontal flipping based on facing direction (inverted)
    local flip_x = enemy.facing_direction == 1  -- Flip horizontally when facing right
    spr(sprites.enemy_guard, ex - enemy_config.size, ey - enemy_config.size, flip_x, false)  -- flipy=false
end

function draw_enemy_vector(ex, ey, enemy)
    -- Enemy body (simple rectangle)
    rectfill(ex - enemy_config.size, ey - enemy_config.size, 
             ex + enemy_config.size, ey + enemy_config.size, 
             enemy_config.body_color)
    rect(ex - enemy_config.size, ey - enemy_config.size, 
         ex + enemy_config.size, ey + enemy_config.size, 
         enemy_config.outline_color)
end

function draw_enemy_health_bar(ex, ey, enemy)
    local health_width = (enemy_config.size * 2) * (enemy.health / enemy.max_health)
    local bar_y = ey - enemy_config.size - 5
    
    -- Background
    rectfill(ex - enemy_config.size, bar_y, 
             ex + enemy_config.size, bar_y + 2, 
             ui_config.health_bar_bg_color)
    
    -- Health fill
    rectfill(ex - enemy_config.size, bar_y, 
             ex - enemy_config.size + health_width, bar_y + 2, 
             ui_config.health_critical_color)
end