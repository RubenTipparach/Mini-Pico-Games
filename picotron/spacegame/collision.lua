-- collision.lua - collision detection and damage systems

collision = {}

function collision.update()
    -- check projectile vs enemy collisions
    collision.check_projectile_enemy()
    
    -- check projectile vs asteroid collisions  
    collision.check_projectile_asteroid()
    
    -- check enemy vs player collisions
    collision.check_enemy_player()
    
    -- check projectile vs player collisions (enemy shots)
    collision.check_projectile_player()
    
    -- check asteroid vs player collisions
    collision.check_asteroid_player()
end

function collision.check_projectile_enemy()
    local projectiles = weapons.get_projectiles()
    local enemy_list = enemies.get_list()
    
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        
        -- skip enemy projectiles
        if proj.is_enemy then
            goto continue
        end
        
        for enemy in all(enemy_list) do
            if collision.circle_collision(proj.x, proj.y, 3, enemy.x, enemy.y, enemy.size) then
                -- hit explosion
                explosions.spawn(proj.x, proj.y, 5, 15, 9)
                
                local enemy_health_before = enemy.health
                enemies.damage_enemy(enemy, proj.damage)
                
                -- death explosion
                if enemy.health <= 0 and enemy_health_before > 0 then
                    explosions.spawn(enemy.x, enemy.y, enemy.size * 2, 30, 8)
                end
                
                del(projectiles, proj)
                break
            end
        end
        
        ::continue::
    end
end

function collision.check_projectile_asteroid()
    local projectiles = weapons.get_projectiles()
    local asteroid_list = asteroids.get_list()
    
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        
        -- skip enemy projectiles
        if proj.is_enemy then
            goto continue
        end
        
        for asteroid in all(asteroid_list) do
            if collision.circle_collision(proj.x, proj.y, 3, asteroid.x, asteroid.y, asteroid.size) then
                -- hit explosion
                explosions.spawn(proj.x, proj.y, 4, 12, 6)
                
                local asteroid_health_before = asteroid.health
                asteroids.damage_asteroid(asteroid, proj.damage)
                
                -- destruction explosion
                if asteroid.health <= 0 and asteroid_health_before > 0 then
                    explosions.spawn(asteroid.x, asteroid.y, asteroid.size * 1.5, 25, 6)
                end
                
                del(projectiles, proj)
                break
            end
        end
        
        ::continue::
    end
end

function collision.check_enemy_player()
    local enemy_list = enemies.get_list()
    
    for enemy in all(enemy_list) do
        if collision.circle_collision(player.x, player.y, player.size, enemy.x, enemy.y, enemy.size) then
            -- big explosion effect at collision point
            local explosion_x = (player.x + enemy.x) / 2
            local explosion_y = (player.y + enemy.y) / 2
            explosions.spawn(explosion_x, explosion_y, 20, 40, 8) -- large explosion
            
            -- damage player and kill enemy (no XP reward for collision)
            player.take_damage(enemy.damage)
            enemy.health = 0 -- kill enemy 
            enemy.killed_by_collision = true -- mark as collision kill (no XP)
        end
    end
end

function collision.check_projectile_player()
    local projectiles = weapons.get_projectiles()
    
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        
        -- only check enemy projectiles
        if proj.is_enemy then
            if collision.circle_collision(player.x, player.y, player.size, proj.x, proj.y, 3) then
                -- hit explosion
                explosions.spawn(proj.x, proj.y, 6, 18, 8)
                player.take_damage(proj.damage)
                del(projectiles, proj)
            end
        end
    end
end

function collision.check_asteroid_player()
    local asteroid_list = asteroids.get_list()
    
    for asteroid in all(asteroid_list) do
        if collision.circle_collision(player.x, player.y, player.size, asteroid.x, asteroid.y, asteroid.size) then
            -- damage player and push away from asteroid
            player.take_damage(5)
            
            -- push player away
            local dx = player.x - asteroid.x
            local dy = player.y - asteroid.y
            local dist = sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                local push_force = 3
                player.dx += (dx/dist) * push_force
                player.dy += (dy/dist) * push_force
            end
        end
    end
end

function collision.circle_collision(x1, y1, r1, x2, y2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist_sq = dx*dx + dy*dy
    local radii_sum = r1 + r2
    
    return dist_sq <= radii_sum * radii_sum
end