-- Enemy ships with AI

local enemies_module = {}

function enemies_module.init_enemies()
    enemies = {}
    enemy_spawn_timer = 0
    enemy_spawn_rate = 180  -- 3 seconds at 60fps
end

function enemies_module.update_enemies()
    -- Update existing enemies
    for enemy in all(enemies) do
        enemies_module.update_enemy_ai(enemy)
        
        -- Remove if health <= 0
        if enemy.health <= 0 then
            -- Drop weapon pickup sometimes
            if rnd() < 0.3 then
                local weapon_types = {"front_turret", "multi_turret", "shotgun_turret", "drone"}
                spawn_weapon_pickup(enemy.x, enemy.y, weapon_types[flr(rnd(#weapon_types)) + 1])
            end
            
            -- Give XP to player
            add_xp(25)
            get_player().kills += 1
            
            del(enemies, enemy)
        end
        
        -- Remove if too far off screen
        if enemy.x < -50 or enemy.x > 530 or enemy.y < -50 or enemy.y > 320 then
            del(enemies, enemy)
        end
    end
    
    -- Spawn new enemies
    enemy_spawn_timer += 1
    if enemy_spawn_timer >= enemy_spawn_rate then
        enemy_spawn_timer = 0
        enemies_module.spawn_enemy()
        
        -- Increase difficulty over time
        if enemy_spawn_rate > 60 then
            enemy_spawn_rate -= 2
        end
    end
end

function enemies_module.spawn_enemy()
    local player = get_player()
    local spawn_side = flr(rnd(4))  -- 0=top, 1=right, 2=bottom, 3=left
    local x, y
    
    if spawn_side == 0 then      -- top
        x = rnd(480)
        y = -20
    elseif spawn_side == 1 then  -- right
        x = 500
        y = rnd(270)
    elseif spawn_side == 2 then  -- bottom
        x = rnd(480)
        y = 290
    else                         -- left
        x = -20
        y = rnd(270)
    end
    
    local enemy_type = (rnd() < 0.7) and "fighter" or "bomber"
    
    local enemy = {
        x = x,
        y = y,
        type = enemy_type,
        health = enemy_type == "fighter" and 30 or 60,
        max_health = enemy_type == "fighter" and 30 or 60,
        speed = enemy_type == "fighter" and 1.5 or 1,
        angle = 0,
        vx = 0,
        vy = 0,
        state = "approach",  -- approach, attack, retreat
        state_timer = 0,
        shoot_cooldown = 0,
        color = enemy_type == "fighter" and 8 or 2,
        size = enemy_type == "fighter" and 6 or 8
    }
    
    add(enemies, enemy)
end

function enemies_module.update_enemy_ai(enemy)
    local player = get_player()
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local dist = sqrt(dx*dx + dy*dy)
    
    enemy.state_timer += 1
    
    if enemy.state == "approach" then
        -- Move towards player
        if dist > 0 then
            enemy.vx += (dx / dist) * enemy.speed * 0.5
            enemy.vy += (dy / dist) * enemy.speed * 0.5
        end
        
        -- Switch to attack when close enough
        if dist < 80 or enemy.state_timer > 180 then
            enemy.state = "attack"
            enemy.state_timer = 0
        end
        
    elseif enemy.state == "attack" then
        -- Circle around player and shoot
        local circle_angle = atan2(dx, dy) + 0.02
        local target_x = player.x + cos(circle_angle) * 60
        local target_y = player.y + sin(circle_angle) * 60
        
        local tdx = target_x - enemy.x
        local tdy = target_y - enemy.y
        enemy.vx += tdx * 0.03
        enemy.vy += tdy * 0.03
        
        -- Shoot at player
        enemy.shoot_cooldown -= 1
        if enemy.shoot_cooldown <= 0 then
            if enemy.type == "fighter" then
                enemy.shoot_cooldown = 40
            else  -- bomber
                enemy.shoot_cooldown = 60
            end
            
            fire_enemy_bullet(enemy, player.x + player.w/2, player.y + player.h/2)
        end
        
        -- Switch to retreat after some time or if low health
        if enemy.state_timer > 240 or enemy.health < enemy.max_health * 0.3 then
            enemy.state = "retreat"
            enemy.state_timer = 0
        end
        
    elseif enemy.state == "retreat" then
        -- Move away from player
        if dist > 0 then
            enemy.vx -= (dx / dist) * enemy.speed * 0.8
            enemy.vy -= (dy / dist) * enemy.speed * 0.8
        end
        
        -- Switch back to approach after retreating
        if enemy.state_timer > 120 then
            enemy.state = "approach"
            enemy.state_timer = 0
        end
    end
    
    -- Apply velocity limits
    local vel = sqrt(enemy.vx * enemy.vx + enemy.vy * enemy.vy)
    if vel > enemy.speed * 2 then
        enemy.vx = (enemy.vx / vel) * enemy.speed * 2
        enemy.vy = (enemy.vy / vel) * enemy.speed * 2
    end
    
    -- Apply movement
    enemy.x += enemy.vx
    enemy.y += enemy.vy
    
    -- Apply friction
    enemy.vx *= 0.9
    enemy.vy *= 0.9
    
    -- Update facing direction
    if enemy.vx != 0 or enemy.vy != 0 then
        enemy.angle = atan2(enemy.vx, enemy.vy) * 360
    end
end

function enemies_module.draw_enemies()
    for enemy in all(enemies) do
        enemies_module.draw_enemy(enemy)
    end
end

function enemies_module.draw_enemy(enemy)
    local cx = enemy.x + enemy.size/2
    local cy = enemy.y + enemy.size/2
    
    -- Draw ship based on type
    if enemy.type == "fighter" then
        -- Draw as diamond
        local points = {
            {cx, cy - enemy.size/2},      -- top
            {cx + enemy.size/2, cy},      -- right
            {cx, cy + enemy.size/2},      -- bottom
            {cx - enemy.size/2, cy}       -- left
        }
        
        for i = 1, #points do
            local next_i = (i % #points) + 1
            line(points[i][1], points[i][2], points[next_i][1], points[next_i][2], enemy.color)
        end
        
    else  -- bomber
        -- Draw as rectangle with engines
        rect(cx - enemy.size/2, cy - enemy.size/2, cx + enemy.size/2, cy + enemy.size/2, enemy.color)
        -- Engine glow
        pset(cx - enemy.size/2 - 1, cy - 1, 9)
        pset(cx - enemy.size/2 - 1, cy + 1, 9)
    end
    
    -- Draw health bar if damaged
    if enemy.health < enemy.max_health then
        local bar_width = enemy.size
        local health_ratio = enemy.health / enemy.max_health
        
        -- Background
        line(cx - bar_width/2, cy - enemy.size/2 - 3, 
             cx + bar_width/2, cy - enemy.size/2 - 3, 8)
        
        -- Health
        line(cx - bar_width/2, cy - enemy.size/2 - 3, 
             cx - bar_width/2 + bar_width * health_ratio, cy - enemy.size/2 - 3, 
             health_ratio > 0.3 and 11 or 8)
    end
    
    -- Show state indicator (debug)
    -- local state_colors = {approach=10, attack=8, retreat=12}
    -- pset(cx, cy + enemy.size/2 + 2, state_colors[enemy.state])
end

function enemies_module.damage_enemy(enemy, amount)
    enemy.health -= amount
    
    -- Force into retreat state if heavily damaged
    if enemy.health < enemy.max_health * 0.2 and enemy.state != "retreat" then
        enemy.state = "retreat"
        enemy.state_timer = 0
    end
end

function enemies_module.get_enemies()
    return enemies
end

return enemies_module