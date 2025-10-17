-- Weapon and bullet system

local bullets_module = {}

function bullets_module.init_bullets()
    bullets = {}
    enemy_bullets = {}
    weapon_pickups = {}
end

function bullets_module.fire_weapon(weapon, target)
    local player = get_player()
    local cx = player.x + player.w/2
    local cy = player.y + player.h/2
    
    weapon.cooldown = weapon.fire_rate
    
    if weapon.type == "front_turret" then
        -- Fire in ship's forward direction
        local angle_rad = player.angle / 360
        add(bullets, {
            x = cx,
            y = cy,
            vx = cos(angle_rad) * 6,
            vy = sin(angle_rad) * 6,
            damage = weapon.damage,
            color = 10,
            type = "normal"
        })
        
    elseif weapon.type == "multi_turret" then
        -- Fire in 4 directions
        for i = 0, 3 do
            local angle = (i * 90 + player.angle) / 360
            add(bullets, {
                x = cx,
                y = cy,
                vx = cos(angle) * 5,
                vy = sin(angle) * 5,
                damage = weapon.damage,
                color = 9,
                type = "normal"
            })
        end
        
    elseif weapon.type == "shotgun_turret" then
        -- Fire multiple bullets towards closest enemy
        if target then
            local dx = target.x - cx
            local dy = target.y - cy
            local dist = sqrt(dx*dx + dy*dy)
            
            if dist < weapon.range then
                -- Fire 5 bullets in a spread
                for i = -2, 2 do
                    local spread_angle = atan2(dx, dy) + (i * 0.1)
                    add(bullets, {
                        x = cx,
                        y = cy,
                        vx = cos(spread_angle) * 7,
                        vy = sin(spread_angle) * 7,
                        damage = weapon.damage / 3,
                        color = 14,
                        type = "shotgun"
                    })
                end
            end
        end
    end
end

function bullets_module.fire_enemy_bullet(enemy, target_x, target_y)
    local dx = target_x - enemy.x
    local dy = target_y - enemy.y
    local dist = sqrt(dx*dx + dy*dy)
    
    if dist > 0 then
        add(enemy_bullets, {
            x = enemy.x,
            y = enemy.y,
            vx = (dx / dist) * 4,
            vy = (dy / dist) * 4,
            damage = 15,
            color = 8
        })
    end
end

function bullets_module.update_bullets()
    -- Update player bullets
    for bullet in all(bullets) do
        bullet.x += bullet.vx
        bullet.y += bullet.vy
        
        -- Remove if off screen
        if bullet.x < 0 or bullet.x > 480 or bullet.y < 0 or bullet.y > 270 then
            del(bullets, bullet)
        end
    end
    
    -- Update enemy bullets
    for bullet in all(enemy_bullets) do
        bullet.x += bullet.vx
        bullet.y += bullet.vy
        
        -- Remove if off screen
        if bullet.x < 0 or bullet.x > 480 or bullet.y < 0 or bullet.y > 270 then
            del(enemy_bullets, bullet)
        end
    end
    
    -- Update weapon pickups
    for pickup in all(weapon_pickups) do
        pickup.bob_timer += 1
        pickup.y += sin(pickup.bob_timer / 30) * 0.5
        
        -- Remove after timeout
        pickup.life -= 1
        if pickup.life <= 0 then
            del(weapon_pickups, pickup)
        end
    end
end

function bullets_module.draw_bullets()
    -- Draw player bullets
    for bullet in all(bullets) do
        if bullet.type == "shotgun" then
            circfill(bullet.x, bullet.y, 1, bullet.color)
        else
            circfill(bullet.x, bullet.y, 1, bullet.color)
            pset(bullet.x, bullet.y, 7)
        end
    end
    
    -- Draw enemy bullets
    for bullet in all(enemy_bullets) do
        circfill(bullet.x, bullet.y, 1, bullet.color)
    end
    
    -- Draw weapon pickups
    for pickup in all(weapon_pickups) do
        local alpha = pickup.life / pickup.max_life
        
        if pickup.weapon_type == "front_turret" then
            rect(pickup.x - 4, pickup.y - 4, pickup.x + 4, pickup.y + 4, 10)
            print("F", pickup.x - 2, pickup.y - 2, 7)
        elseif pickup.weapon_type == "multi_turret" then
            rect(pickup.x - 4, pickup.y - 4, pickup.x + 4, pickup.y + 4, 9)
            print("M", pickup.x - 2, pickup.y - 2, 7)
        elseif pickup.weapon_type == "shotgun_turret" then
            rect(pickup.x - 4, pickup.y - 4, pickup.x + 4, pickup.y + 4, 14)
            print("S", pickup.x - 2, pickup.y - 2, 7)
        elseif pickup.weapon_type == "drone" then
            rect(pickup.x - 4, pickup.y - 4, pickup.x + 4, pickup.y + 4, 11)
            print("D", pickup.x - 2, pickup.y - 2, 7)
        end
    end
end

function bullets_module.spawn_weapon_pickup(x, y, weapon_type)
    add(weapon_pickups, {
        x = x,
        y = y,
        weapon_type = weapon_type,
        bob_timer = 0,
        life = 600,  -- 10 seconds at 60fps
        max_life = 600
    })
end

function bullets_module.find_closest_enemy()
    local player = get_player()
    local closest = nil
    local closest_dist = 999999
    
    -- Check enemies
    local enemies = get_enemies()
    if enemies then
        for enemy in all(enemies) do
            local dx = enemy.x - player.x
            local dy = enemy.y - player.y
            local dist = sqrt(dx*dx + dy*dy)
            
            if dist < closest_dist then
                closest = enemy
                closest_dist = dist
            end
        end
    end
    
    -- Check asteroids
    local asteroids = get_asteroids()
    if asteroids then
        for asteroid in all(asteroids) do
            local dx = asteroid.x - player.x
            local dy = asteroid.y - player.y
            local dist = sqrt(dx*dx + dy*dy)
            
            if dist < closest_dist then
                closest = asteroid
                closest_dist = dist
            end
        end
    end
    
    return closest
end

function bullets_module.get_bullets()
    return bullets
end

function bullets_module.get_enemy_bullets()
    return enemy_bullets
end

function bullets_module.get_weapon_pickups()
    return weapon_pickups
end

function bullets_module.remove_bullet(bullet)
    del(bullets, bullet)
end

function bullets_module.remove_enemy_bullet(bullet)
    del(enemy_bullets, bullet)
end

function bullets_module.remove_weapon_pickup(pickup)
    del(weapon_pickups, pickup)
end

return bullets_module