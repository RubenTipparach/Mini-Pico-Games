-- asteroids.lua - asteroid system with random movement

asteroids = {
    list = {}
}

function asteroids.init()
    asteroids.list = {}
    
    -- spawn initial asteroids
    for i = 1, 8 do
        asteroids.spawn()
    end
end

function asteroids.spawn()
    -- spawn off-screen around the camera/player
    local spawn_distance = 200 + rnd(100) -- 200-300 pixels from camera center
    local angle = rnd(1) -- random angle around player
    
    local asteroid = {
        x = camera.x + cos(angle) * spawn_distance,
        y = camera.y + sin(angle) * spawn_distance,
        dx = (rnd(2) - 1) * 0.5,
        dy = (rnd(2) - 1) * 0.5,
        size = 3 + rnd(5),
        rotation = 0,
        rotation_speed = (rnd(2) - 1) * 0.02,
        color = 6,
        health = 20
    }
    
    add(asteroids.list, asteroid)
end

function asteroids.update()
    for i = #asteroids.list, 1, -1 do
        local asteroid = asteroids.list[i]
        
        -- movement
        asteroid.x += asteroid.dx
        asteroid.y += asteroid.dy
        asteroid.rotation += asteroid.rotation_speed
        
        -- remove asteroids that drift too far from camera
        local dist_from_camera = sqrt((asteroid.x - camera.x)^2 + (asteroid.y - camera.y)^2)
        if dist_from_camera > 400 then
            del(asteroids.list, asteroid)
        end
        
        -- remove destroyed asteroids
        if asteroid.health <= 0 then
            -- split into smaller pieces if large enough
            if asteroid.size > 4 then
                asteroids.split_asteroid(asteroid)
            end
            
            -- spawn xp
            xp.spawn_orb(asteroid.x, asteroid.y, 2)
            del(asteroids.list, asteroid)
        end
    end
    
    -- spawn new asteroids occasionally
    if #asteroids.list < 12 and rnd(300) < 1 then
        asteroids.spawn()
    end
end

function asteroids.split_asteroid(asteroid)
    local pieces = 2 + flr(rnd(2)) -- 2-3 pieces
    
    for i = 1, pieces do
        local piece = {
            x = asteroid.x + (rnd(10) - 5),
            y = asteroid.y + (rnd(10) - 5),
            dx = (rnd(2) - 1) * 1,
            dy = (rnd(2) - 1) * 1,
            size = asteroid.size * 0.6,
            rotation = rnd(1),
            rotation_speed = (rnd(2) - 1) * 0.03,
            color = asteroid.color,
            health = asteroid.health * 0.4
        }
        add(asteroids.list, piece)
    end
end

function asteroids.draw()
    for asteroid in all(asteroids.list) do
        local screen_x = asteroid.x - camera.x + sw/2
        local screen_y = asteroid.y - camera.y + sh/2
        
        -- only draw if on screen
        if screen_x >= -asteroid.size and screen_x < sw + asteroid.size and 
           screen_y >= -asteroid.size and screen_y < sh + asteroid.size then
            
            local size = asteroid.size
            local rot = asteroid.rotation
            
            -- create octagon points
            local points = {}
            for i = 0, 7 do
                local angle = (i / 8) + rot
                local px = screen_x + cos(angle) * size
                local py = screen_y + sin(angle) * size
                add(points, {x = px, y = py})
            end
            
            -- draw octagon
            for i = 1, #points do
                local p1 = points[i]
                local p2 = points[i == #points and 1 or i + 1]
                line(p1.x, p1.y, p2.x, p2.y, asteroid.color)
            end
            
            -- draw some internal lines for detail
            if size > 5 then
                line(screen_x - size/2, screen_y, screen_x + size/2, screen_y, asteroid.color)
                line(screen_x, screen_y - size/2, screen_x, screen_y + size/2, asteroid.color)
            end
        end
    end
end

function asteroids.damage_asteroid(asteroid, damage)
    asteroid.health -= damage
    game.score += damage
    
    -- visual feedback - briefly change color
    asteroid.color = 7
    -- would need timer system to reset color
end

function asteroids.get_list()
    return asteroids.list
end