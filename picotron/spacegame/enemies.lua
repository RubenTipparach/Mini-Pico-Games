-- enemies.lua - enemy system with AI behaviors

enemies = {
    list = {},
    spawn_timer = 0
}

-- enemy types
local enemy_types = {
    scout = {
        name = "Scout",
        health = 30,
        speed = 0.8,
        damage = 10,
        size = 3,
        color = 8,
        xp_value = 5,
        behavior = "chase",
        attack_range = 40,
        flee_health = 10
    },
    fighter = {
        name = "Fighter", 
        health = 50,
        speed = 0.6,
        damage = 15,
        size = 4,
        color = 2,
        xp_value = 10,
        behavior = "attack",
        attack_range = 60,
        fire_rate = 90
    },
    bomber = {
        name = "Bomber",
        health = 80,
        speed = 0.4,
        damage = 25,
        size = 5,
        color = 4,
        xp_value = 15,
        behavior = "approach",
        attack_range = 80,
        fire_rate = 120
    }
}

function enemies.init()
    enemies.list = {}
    enemies.spawn_timer = 0
end

function enemies.update()
    -- update all enemies
    for i = #enemies.list, 1, -1 do
        local enemy = enemies.list[i]
        enemies.update_enemy(enemy)
        
        -- remove dead enemies
        if enemy.health <= 0 then
            -- only spawn XP if enemy wasn't killed by collision
            if not enemy.killed_by_collision then
                xp.spawn_orb(enemy.x, enemy.y, enemy.xp_value)
            end
            del(enemies.list, enemy)
        end
    end
end

function enemies.update_enemy(enemy)
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local dist = sqrt(dx*dx + dy*dy)
    
    if dist > 0 then
        local nx = dx / dist
        local ny = dy / dist
        
        -- AI behavior based on type
        if enemy.behavior == "chase" then
            -- always move towards player
            enemy.x += nx * enemy.speed
            enemy.y += ny * enemy.speed
            
            -- flee if low health
            if enemy.health <= enemy.flee_health then
                enemy.x -= nx * enemy.speed * 2
                enemy.y -= ny * enemy.speed * 2
            end
            
        elseif enemy.behavior == "attack" then
            -- attack pattern: approach, shoot, retreat
            if dist > enemy.attack_range then
                -- approach
                enemy.x += nx * enemy.speed
                enemy.y += ny * enemy.speed
            elseif dist < enemy.attack_range * 0.7 then
                -- retreat
                enemy.x -= nx * enemy.speed * 0.5
                enemy.y -= ny * enemy.speed * 0.5
            end
            
            -- shoot at player
            enemy.attack_timer = enemy.attack_timer or 0
            enemy.attack_timer -= 1
            if enemy.attack_timer <= 0 and dist <= enemy.attack_range then
                enemies.enemy_shoot(enemy, nx, ny)
                enemy.attack_timer = enemy.fire_rate
            end
            
        elseif enemy.behavior == "approach" then
            -- slow approach with periodic shooting
            if dist > 30 then
                enemy.x += nx * enemy.speed
                enemy.y += ny * enemy.speed
            end
            
            enemy.attack_timer = enemy.attack_timer or 0
            enemy.attack_timer -= 1
            if enemy.attack_timer <= 0 then
                enemies.enemy_shoot(enemy, nx, ny)
                enemy.attack_timer = enemy.fire_rate
            end
        end
    end
    
    -- remove enemies that drift too far from player
    local dist_from_player = sqrt((enemy.x - player.x)^2 + (enemy.y - player.y)^2)
    if dist_from_player > 500 then
        del(enemies.list, enemy)
    end
end

function enemies.enemy_shoot(enemy, dx, dy)
    -- calculate proper firing direction
    local fire_angle = atan2(dy, dx)
    local speed = 2
    
    -- create enemy projectile
    local projectile = {
        x = enemy.x,
        y = enemy.y,
        dx = cos(fire_angle) * speed,
        dy = sin(fire_angle) * speed,
        damage = enemy.damage,
        color = 8,
        life = 60,
        is_enemy = true
    }
    add(weapons.projectiles, projectile)
end

function enemies.spawn(enemy_type, x, y)
    local template = enemy_types[enemy_type]
    if not template then return end
    
    local enemy = {}
    for k, v in pairs(template) do
        enemy[k] = v
    end
    
    enemy.x = x or enemies.get_spawn_position()
    enemy.y = y or enemies.get_spawn_position()
    enemy.max_health = enemy.health
    
    add(enemies.list, enemy)
end

function enemies.get_spawn_position()
    -- spawn off-screen around the player in world coordinates
    local spawn_distance = 250 + rnd(50) -- 250-300 pixels from player
    local angle = rnd(1) -- random angle around player
    
    local x = player.x + cos(angle) * spawn_distance
    local y = player.y + sin(angle) * spawn_distance
    
    return x, y
end

function enemies.draw()
    for enemy in all(enemies.list) do
        local screen_x = enemy.x - camera.x + sw/2
        local screen_y = enemy.y - camera.y + sh/2
        
        -- only draw if on screen
        if screen_x >= -enemy.size and screen_x < sw + enemy.size and 
           screen_y >= -enemy.size and screen_y < sh + enemy.size then
            
            -- draw enemy as circle
            circfill(screen_x, screen_y, enemy.size, enemy.color)
            
            -- draw health bar for damaged enemies
            if enemy.health < enemy.max_health then
                local bar_w = enemy.size * 3
                local bar_h = 2
                local bar_x = screen_x - bar_w/2
                local bar_y = screen_y - enemy.size - 6
                
                rect(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, 5)
                local health_w = (enemy.health / enemy.max_health) * bar_w
                rectfill(bar_x, bar_y, bar_x + health_w, bar_y + bar_h, 8)
            end
        end
    end
end

function enemies.find_nearest(x, y, max_range)
    local nearest = nil
    local nearest_dist = max_range or 1000
    
    for enemy in all(enemies.list) do
        local dx = enemy.x - x
        local dy = enemy.y - y
        local dist = sqrt(dx*dx + dy*dy)
        
        if dist < nearest_dist then
            nearest = enemy
            nearest_dist = dist
        end
    end
    
    return nearest
end

function enemies.damage_enemy(enemy, damage)
    -- apply critical hit chance
    local final_damage = damage
    if rnd(1) < player.crit_chance then
        final_damage *= 2
    end
    
    enemy.health -= final_damage
    game.score += final_damage
end

function enemies.get_list()
    return enemies.list
end