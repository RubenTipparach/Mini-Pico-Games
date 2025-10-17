-- Player ship mechanics with mouse orientation and WASD strafing

local player_module = {}

function player_module.init_player()
    player = {
        x = 240,
        y = 135,
        vx = 0,
        vy = 0,
        angle = 0,  -- ship orientation in degrees
        speed = 2,
        max_speed = 4,
        friction = 0.85,
        w = 12,
        h = 12,
        color = 7,
        shields = 100,
        max_shields = 100,
        xp = 0,
        level = 1,
        kills = 0,
        weapons = {},
        drones = {}
    }
    
    -- Add initial weapon (will be chosen by player later)
    player_module.add_weapon_to_player("front_turret")
end

function player_module.update_player()
    -- Mouse-controlled orientation
    local mx, my = mouse()
    local dx = mx - (player.x + player.w/2)
    local dy = my - (player.y + player.h/2)
    
    if dx != 0 or dy != 0 then
        player.angle = atan2(dx, dy) * 360
    end
    
    -- WASD strafing relative to ship rotation
    local strafe_x = 0
    local strafe_y = 0
    
    if btn(0) then strafe_x -= 1 end  -- A - left strafe
    if btn(1) then strafe_x += 1 end  -- D - right strafe
    if btn(2) then strafe_y -= 1 end  -- W - forward
    if btn(3) then strafe_y += 1 end  -- S - backward
    
    -- Convert strafe to world coordinates based on ship angle
    local angle_rad = player.angle / 360
    local cos_a = cos(angle_rad)
    local sin_a = sin(angle_rad)
    
    local world_x = strafe_x * cos_a - strafe_y * sin_a
    local world_y = strafe_x * sin_a + strafe_y * cos_a
    
    -- Apply movement
    player.vx += world_x * player.speed
    player.vy += world_y * player.speed
    
    -- Limit max speed
    local speed = sqrt(player.vx * player.vx + player.vy * player.vy)
    if speed > player.max_speed then
        player.vx = (player.vx / speed) * player.max_speed
        player.vy = (player.vy / speed) * player.max_speed
    end
    
    -- Apply movement and friction
    player.x += player.vx
    player.y += player.vy
    player.vx *= player.friction
    player.vy *= player.friction
    
    -- Keep player on screen
    player.x = mid(6, player.x, 480 - player.w - 6)
    player.y = mid(6, player.y, 270 - player.h - 6)
    
    -- Update weapons (auto-shooting)
    update_player_weapons()
    
    -- Update drones
    update_player_drones()
    
    -- Shield regeneration
    if player.shields < player.max_shields then
        player.shields += 0.1
    end
end

function player_module.update_player_weapons()
    for weapon in all(player.weapons) do
        weapon.cooldown -= 1
        
        if weapon.cooldown <= 0 then
            local target = find_closest_enemy()
            if target then
                fire_weapon(weapon, target)
            end
        end
    end
end

function player_module.update_player_drones()
    for i, drone in ipairs(player.drones) do
        -- Orbit around player
        local orbit_angle = (time() * 60 + i * 60) % 360
        local orbit_radius = 20 + i * 5
        local angle_rad = orbit_angle / 360
        
        drone.x = player.x + player.w/2 + cos(angle_rad) * orbit_radius
        drone.y = player.y + player.h/2 + sin(angle_rad) * orbit_radius
        
        -- Check for collisions with enemies/asteroids
        local hit_target = check_drone_collisions(drone)
        if hit_target then
            -- Drone explodes and damages target
            damage_target(hit_target, drone.damage)
            del(player.drones, drone)
        end
    end
end

function player_module.draw_player()
    local cx = player.x + player.w/2
    local cy = player.y + player.h/2
    
    -- Draw ship as rotated triangle
    local angle_rad = player.angle / 360
    local cos_a = cos(angle_rad)
    local sin_a = sin(angle_rad)
    
    -- Ship vertices (pointing forward)
    local points = {
        {0, -6},   -- nose
        {-4, 4},   -- left wing
        {4, 4}     -- right wing
    }
    
    -- Rotate and translate points
    local world_points = {}
    for point in all(points) do
        local rx = point[1] * cos_a - point[2] * sin_a
        local ry = point[1] * sin_a + point[2] * cos_a
        add(world_points, {cx + rx, cy + ry})
    end
    
    -- Draw ship hull
    for i = 1, #world_points do
        local next_i = (i % #world_points) + 1
        line(world_points[i][1], world_points[i][2], 
             world_points[next_i][1], world_points[next_i][2], player.color)
    end
    
    -- Draw weapons
    draw_player_weapons()
    
    -- Draw drones
    for drone in all(player.drones) do
        circfill(drone.x, drone.y, 2, 11)
        circ(drone.x, drone.y, 3, 3)
    end
    
    -- Draw shields if damaged
    if player.shields < player.max_shields then
        local shield_alpha = (player.max_shields - player.shields) / player.max_shields
        circ(cx, cy, 10, 12)
    end
end

function player_module.draw_player_weapons()
    local cx = player.x + player.w/2
    local cy = player.y + player.h/2
    
    for weapon in all(player.weapons) do
        if weapon.type == "front_turret" then
            -- Draw front-facing turret
            local angle_rad = player.angle / 360
            local tx = cx + cos(angle_rad) * 8
            local ty = cy + sin(angle_rad) * 8
            circfill(tx, ty, 1, 8)
        elseif weapon.type == "multi_turret" then
            -- Draw multi-directional turret
            circfill(cx, cy, 2, 9)
            for i = 0, 3 do
                local a = (i * 90 + player.angle) / 360
                local tx = cx + cos(a) * 4
                local ty = cy + sin(a) * 4
                pset(tx, ty, 10)
            end
        elseif weapon.type == "shotgun_turret" then
            -- Draw shotgun turret
            rect(cx - 3, cy - 3, cx + 3, cy + 3, 14)
        end
    end
end

function player_module.add_weapon_to_player(weapon_type)
    local weapon = {
        type = weapon_type,
        cooldown = 0,
        damage = 10,
        range = 100
    }
    
    if weapon_type == "front_turret" then
        weapon.fire_rate = 20
    elseif weapon_type == "multi_turret" then
        weapon.fire_rate = 30
        weapon.damage = 8
    elseif weapon_type == "shotgun_turret" then
        weapon.fire_rate = 60
        weapon.damage = 25
    elseif weapon_type == "drone" then
        add(player.drones, {
            x = player.x,
            y = player.y,
            damage = 20
        })
        return  -- Don't add as weapon
    end
    
    add(player.weapons, weapon)
end

function player_module.damage_player(amount)
    player.shields -= amount
    if player.shields <= 0 then
        -- Player dies
        game_state = "game_over"
    end
end

function player_module.add_xp(amount)
    player.xp += amount
    local xp_needed = player.level * 100
    if player.xp >= xp_needed then
        player.xp -= xp_needed
        player.level += 1
        game_state = "level_up"
    end
end

function player_module.get_player()
    return player
end

return player_module