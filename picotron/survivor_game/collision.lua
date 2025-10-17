-- Collision detection system for all game objects

local collision_module = {}

function collision_module.collision_check(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function collision_module.collision_module.distance_check(x1, y1, x2, y2, radius)
    local dx = x2 - x1
    local dy = y2 - y1
    return sqrt(dx*dx + dy*dy) < radius
end

function collision_module.check_all_collisions()
    collision_module.check_player_bullet_collisions()
    collision_module.check_enemy_bullet_collisions()
    collision_module.check_player_enemy_collisions()
    collision_module.check_player_asteroid_collisions()
    collision_module.check_weapon_pickup_collisions()
    collision_module.check_drone_collisions_main()
end

function collision_module.check_player_bullet_collisions()
    local bullets = get_bullets()
    local enemies = get_enemies()
    local asteroids = get_asteroids()
    
    -- Player bullets vs enemies
    for bullet in all(bullets) do
        local hit = false
        
        -- Check against enemies
        for enemy in all(enemies) do
            if collision_module.collision_module.distance_check(bullet.x, bullet.y, enemy.x + enemy.size/2, enemy.y + enemy.size/2, enemy.size/2 + 2) then
                damage_enemy(enemy, bullet.damage)
                remove_bullet(bullet)
                hit = true
                break
            end
        end
        
        if not hit then
            -- Check against asteroids
            for asteroid in all(asteroids) do
                local size = asteroid.size * 4
                if collision_module.distance_check(bullet.x, bullet.y, asteroid.x + size/2, asteroid.y + size/2, size/2 + 2) then
                    damage_asteroid(asteroid, bullet.damage)
                    remove_bullet(bullet)
                    break
                end
            end
        end
    end
end

function collision_module.check_enemy_bullet_collisions()
    local enemy_bullets = get_enemy_bullets()
    local player = get_player()
    
    -- Enemy bullets vs player
    for bullet in all(enemy_bullets) do
        if collision_module.distance_check(bullet.x, bullet.y, player.x + player.w/2, player.y + player.h/2, player.w/2 + 2) then
            damage_player(bullet.damage)
            remove_enemy_bullet(bullet)
        end
    end
end

function collision_module.check_player_enemy_collisions()
    local player = get_player()
    local enemies = get_enemies()
    
    -- Player vs enemies (ramming damage)
    for enemy in all(enemies) do
        if collision_module.distance_check(player.x + player.w/2, player.y + player.h/2, 
                         enemy.x + enemy.size/2, enemy.y + enemy.size/2, 
                         player.w/2 + enemy.size/2) then
            damage_player(20)
            damage_enemy(enemy, 30)  -- Player ship is tough!
        end
    end
end

function collision_module.check_player_asteroid_collisions()
    local player = get_player()
    local asteroids = get_asteroids()
    
    -- Player vs asteroids
    for asteroid in all(asteroids) do
        local size = asteroid.size * 4
        if collision_module.distance_check(player.x + player.w/2, player.y + player.h/2,
                         asteroid.x + size/2, asteroid.y + size/2,
                         player.w/2 + size/2) then
            damage_player(10 + asteroid.size * 5)
            damage_asteroid(asteroid, 50)  -- Player ship damages asteroid too
        end
    end
end

function collision_module.check_weapon_pickup_collisions()
    local player = get_player()
    local pickups = get_weapon_pickups()
    
    -- Player vs weapon pickups
    for pickup in all(pickups) do
        if collision_module.distance_check(player.x + player.w/2, player.y + player.h/2,
                         pickup.x, pickup.y, player.w/2 + 8) then
            add_weapon_to_player(pickup.weapon_type)
            remove_weapon_pickup(pickup)
        end
    end
end

function collision_module.check_drone_collisions_main()
    local drones = player.drones
    local enemies = get_enemies()
    local asteroids = get_asteroids()
    
    -- Drones vs enemies and asteroids
    for drone in all(drones) do
        local target = collision_module.check_drone_collisions(drone)
        -- This is handled in the player update function
    end
end

function collision_module.check_drone_collisions(drone)
    local enemies = get_enemies()
    local asteroids = get_asteroids()
    
    -- Check enemies first (priority target)
    for enemy in all(enemies) do
        if collision_module.distance_check(drone.x, drone.y, enemy.x + enemy.size/2, enemy.y + enemy.size/2, enemy.size/2 + 3) then
            return enemy
        end
    end
    
    -- Check asteroids
    for asteroid in all(asteroids) do
        local size = asteroid.size * 4
        if collision_module.distance_check(drone.x, drone.y, asteroid.x + size/2, asteroid.y + size/2, size/2 + 3) then
            return asteroid
        end
    end
    
    return nil
end

function collision_module.damage_target(target, amount)
    if target.type == "asteroid" then
        damage_asteroid(target, amount)
    else
        damage_enemy(target, amount)
    end
end

return collision_module