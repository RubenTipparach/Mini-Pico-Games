-- Asteroid system - freely drifting space rocks

local asteroids_module = {}

function asteroids_module.init_asteroids()
    asteroids = {}
    asteroid_spawn_timer = 0
    asteroid_spawn_rate = 120  -- Less frequent than before
end

function asteroids_module.update_asteroids()
    -- Update existing asteroids
    for asteroid in all(asteroids) do
        asteroid.x += asteroid.vx
        asteroid.y += asteroid.vy
        asteroid.rotation += asteroid.rot_speed
        
        -- Remove if far off screen
        if asteroid.x < -50 or asteroid.x > 530 or asteroid.y < -50 or asteroid.y > 320 then
            del(asteroids, asteroid)
        end
    end
    
    -- Spawn new asteroids
    asteroid_spawn_timer += 1
    if asteroid_spawn_timer >= asteroid_spawn_rate then
        asteroid_spawn_timer = 0
        asteroids_module.spawn_asteroid()
    end
end

function asteroids_module.spawn_asteroid()
    -- Spawn from random edge with random direction
    local spawn_side = flr(rnd(4))  -- 0=top, 1=right, 2=bottom, 3=left
    local x, y, vx, vy
    
    if spawn_side == 0 then      -- top
        x = rnd(480)
        y = -20
        vx = (rnd(2) - 1) * 2    -- random horizontal drift
        vy = rnd(1) + 0.5        -- downward
    elseif spawn_side == 1 then  -- right
        x = 500
        y = rnd(270)
        vx = -(rnd(1) + 0.5)     -- leftward
        vy = (rnd(2) - 1) * 2    -- random vertical drift
    elseif spawn_side == 2 then  -- bottom
        x = rnd(480)
        y = 290
        vx = (rnd(2) - 1) * 2    -- random horizontal drift
        vy = -(rnd(1) + 0.5)     -- upward
    else                         -- left
        x = -20
        y = rnd(270)
        vx = rnd(1) + 0.5        -- rightward
        vy = (rnd(2) - 1) * 2    -- random vertical drift
    end
    
    local asteroid = {
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        size = flr(rnd(3)) + 1,
        rotation = rnd(360),
        rot_speed = (rnd(2) - 1) * 3,
        color = 6,
        health = 20,
        type = "asteroid"
    }
    
    add(asteroids, asteroid)
end

function asteroids_module.draw_asteroids()
    for asteroid in all(asteroids) do
        asteroids_module.draw_asteroid(asteroid)
    end
end

function asteroids_module.draw_asteroid(asteroid)
    local size = asteroid.size * 4
    local cx = asteroid.x + size/2
    local cy = asteroid.y + size/2
    
    -- Draw rotating asteroid as irregular polygon
    local points = {}
    local num_points = 6 + asteroid.size
    
    for i = 0, num_points - 1 do
        local angle = (i / num_points) * 360 + asteroid.rotation
        local radius_var = 0.7 + (sin((angle + asteroid.rotation * 2) / 360) * 0.3)
        local radius = size * radius_var
        local x = cx + cos(angle / 360) * radius
        local y = cy + sin(angle / 360) * radius
        add(points, {x = x, y = y})
    end
    
    -- Draw the asteroid shape
    for i = 1, #points do
        local next_i = (i % #points) + 1
        line(points[i].x, points[i].y, points[next_i].x, points[next_i].y, asteroid.color)
    end
    
    -- Draw some surface details
    if asteroid.size > 1 then
        local detail_angle = asteroid.rotation * 1.5
        local dx = cos(detail_angle / 360) * size * 0.3
        local dy = sin(detail_angle / 360) * size * 0.3
        pset(cx + dx, cy + dy, 5)
        
        if asteroid.size > 2 then
            local dx2 = cos((detail_angle + 120) / 360) * size * 0.4
            local dy2 = sin((detail_angle + 120) / 360) * size * 0.4
            pset(cx + dx2, cy + dy2, 5)
        end
    end
end

function asteroids_module.damage_asteroid(asteroid, amount)
    asteroid.health -= amount
    
    if asteroid.health <= 0 then
        -- Break apart into smaller pieces
        if asteroid.size > 1 then
            for i = 1, 2 do
                local fragment = {
                    x = asteroid.x + rnd(10) - 5,
                    y = asteroid.y + rnd(10) - 5,
                    vx = asteroid.vx + (rnd(2) - 1) * 2,
                    vy = asteroid.vy + (rnd(2) - 1) * 2,
                    size = asteroid.size - 1,
                    rotation = rnd(360),
                    rot_speed = (rnd(2) - 1) * 5,
                    color = asteroid.color,
                    health = 10,
                    type = "asteroid"
                }
                add(asteroids, fragment)
            end
        end
        
        -- Small chance to drop pickup
        if rnd() < 0.1 then
            spawn_weapon_pickup(asteroid.x, asteroid.y, "front_turret")
        end
        
        -- Give small XP
        add_xp(5)
        
        del(asteroids, asteroid)
    end
end

function asteroids_module.get_asteroids()
    return asteroids
end

function asteroids_module.remove_asteroid(asteroid)
    del(asteroids, asteroid)
end

return asteroids_module