-- weapons.lua - weapon system

weapons = {
    projectiles = {},
    weapon_timers = {},
    drones = {}
}

-- weapon definitions
local weapon_data = {
    cannon = {
        name = "Cannon",
        damage = 20,
        fire_rate = 15, -- frames between shots (faster)
        range = 150,
        spread = 0,
        projectile_speed = 5,
        color = 10 -- bright yellow
    },
    laser = {
        name = "Laser",
        damage = 15,
        fire_rate = 10, -- faster fire rate
        range = 200,
        spread = 0,
        projectile_speed = 8,
        color = 10 -- bright yellow
    },
    missile = {
        name = "Missile",
        damage = 40,
        fire_rate = 40, -- faster fire rate
        range = 180,
        spread = 0.1,
        projectile_speed = 3,
        color = 9, -- orange for missiles
        homing = true
    },
    drone_swarm = {
        name = "Drone Swarm",
        damage = 10,
        max_drones = 3,
        drone_speed = 2,
        orbit_radius = 30,
        color = 6
    }
}

function weapons.init()
    weapons.projectiles = {}
    weapons.weapon_timers = {}
    weapons.drones = {}
    
    -- initialize timers for all weapon types
    for weapon_name, _ in pairs(weapon_data) do
        weapons.weapon_timers[weapon_name] = 0
    end
end

function weapons.update()
    -- update weapon timers
    for weapon_name, timer in pairs(weapons.weapon_timers) do
        if timer > 0 then
            weapons.weapon_timers[weapon_name] = timer - 1
        end
    end
    
    -- auto-fire all player weapons
    for weapon_name in all(player.current_weapons) do
        weapons.fire_weapon(weapon_name)
    end
    
    -- update projectiles
    for i = #weapons.projectiles, 1, -1 do
        local p = weapons.projectiles[i]
        
        -- move projectile
        if p.homing and p.target then
            -- simple homing behavior
            local dx = p.target.x - p.x
            local dy = p.target.y - p.y
            local dist = sqrt(dx*dx + dy*dy)
            if dist > 0 then
                p.dx = p.dx * 0.9 + (dx/dist) * p.speed * 0.1
                p.dy = p.dy * 0.9 + (dy/dist) * p.speed * 0.1
            end
        end
        
        p.x += p.dx
        p.y += p.dy
        p.life -= 1
        
        -- remove if expired or too far from camera
        local screen_x = p.x - camera.x + sw/2
        local screen_y = p.y - camera.y + sh/2
        if p.life <= 0 or screen_x < -50 or screen_x > sw+50 or screen_y < -50 or screen_y > sh+50 then
            del(weapons.projectiles, p)
        end
    end
    
    -- update drones
    for i = #weapons.drones, 1, -1 do
        local d = weapons.drones[i]
        
        -- orbit around player
        d.angle += d.orbit_speed
        d.target_x = player.x + cos(d.angle) * d.orbit_radius
        d.target_y = player.y + sin(d.angle) * d.orbit_radius
        
        -- move towards target position
        local dx = d.target_x - d.x
        local dy = d.target_y - d.y
        d.x += dx * 0.1
        d.y += dy * 0.1
        
        -- drone auto-attack
        d.attack_timer -= 1
        if d.attack_timer <= 0 then
            local target = enemies.find_nearest(d.x, d.y, 50)
            if target then
                -- fire from drone toward target
                local fire_angle = atan2(target.y - d.y, target.x - d.x)
                local projectile = {
                    x = d.x,
                    y = d.y,
                    dx = cos(fire_angle) * 4,
                    dy = sin(fire_angle) * 4,
                    damage = d.damage,
                    color = d.color,
                    life = 60
                }
                add(weapons.projectiles, projectile)
                d.attack_timer = 30
            end
        end
    end
end

function weapons.fire_weapon(weapon_name)
    local weapon = weapon_data[weapon_name]
    if not weapon or weapons.weapon_timers[weapon_name] > 0 then
        return
    end
    
    if weapon_name == "drone_swarm" then
        weapons.spawn_drone()
    else
        weapons.fire_projectile_weapon(weapon_name, weapon)
    end
    
    weapons.weapon_timers[weapon_name] = weapon.fire_rate
end

function weapons.fire_projectile_weapon(weapon_name, weapon)
    -- calculate spawn position at ship's nose
    local nose_distance = player.size + 2
    local spawn_x = player.x + cos(player.angle) * nose_distance
    local spawn_y = player.y + sin(player.angle) * nose_distance
    
    -- fire in the direction the ship is facing
    local fire_angle = player.angle
    
    -- find nearest enemy for slight auto-aim adjustment
    local target = enemies.find_nearest(player.x, player.y, weapon.range * player.range_mult)
    if target then
        local target_angle = atan2(target.y - player.y, target.x - player.x)
        local angle_diff = target_angle - player.angle
        
        -- normalize angle difference to -0.5 to 0.5 (Picotron uses 0-1 for full rotation)
        while angle_diff > 0.5 do angle_diff -= 1 end
        while angle_diff < -0.5 do angle_diff += 1 end
        
        -- only adjust if target is roughly in front of us (smaller cone)
        if abs(angle_diff) < 0.15 then
            fire_angle = player.angle + angle_diff * 0.2 -- smaller adjustment
        end
    end
    
    -- add weapon spread
    local spread = weapon.spread * (rnd(2) - 1)
    fire_angle += spread
    
    -- create projectile with velocity instead of target position
    local projectile = {
        x = spawn_x,
        y = spawn_y,
        dx = cos(fire_angle) * weapon.projectile_speed,
        dy = sin(fire_angle) * weapon.projectile_speed,
        damage = weapon.damage * player.damage_mult,
        color = weapon.color,
        life = weapon.range * player.range_mult / weapon.projectile_speed,
        homing = weapon.homing,
        target = weapon.homing and target or nil
    }
    add(weapons.projectiles, projectile)
end

function weapons.create_projectile(x, y, target_x, target_y, props)
    local dx = target_x - x
    local dy = target_y - y
    local dist = sqrt(dx*dx + dy*dy)
    
    if dist > 0 then
        local projectile = {
            x = x,
            y = y,
            dx = (dx/dist) * props.speed,
            dy = (dy/dist) * props.speed,
            damage = props.damage,
            color = props.color,
            life = props.life,
            homing = props.homing,
            target = props.target
        }
        add(weapons.projectiles, projectile)
    end
end

function weapons.spawn_drone()
    local weapon = weapon_data.drone_swarm
    
    -- don't spawn if at max drones
    if #weapons.drones >= weapon.max_drones then return end
    
    local drone = {
        x = player.x,
        y = player.y,
        target_x = player.x,
        target_y = player.y,
        angle = rnd(1),
        orbit_speed = 0.02,
        orbit_radius = weapon.orbit_radius,
        damage = weapon.damage * player.damage_mult,
        color = weapon.color,
        attack_timer = 0
    }
    add(weapons.drones, drone)
end

function weapons.draw()
    -- draw projectiles
    for p in all(weapons.projectiles) do
        local screen_x = p.x - camera.x + sw/2
        local screen_y = p.y - camera.y + sh/2
        
        if screen_x >= -5 and screen_x < sw + 5 and screen_y >= -5 and screen_y < sh + 5 then
            circfill(screen_x, screen_y, 3, p.color) -- even larger bullets
            circfill(screen_x, screen_y, 2, 7) -- bright white center
            pset(screen_x, screen_y, 7) -- bright center pixel
        end
    end
    
    -- draw drones
    for d in all(weapons.drones) do
        local screen_x = d.x - camera.x + sw/2
        local screen_y = d.y - camera.y + sh/2
        
        if screen_x >= -10 and screen_x < sw + 10 and screen_y >= -10 and screen_y < sh + 10 then
            circfill(screen_x, screen_y, 2, d.color)
            circ(screen_x, screen_y, 3, 7) -- glow effect
        end
    end
end

function weapons.get_projectiles()
    return weapons.projectiles
end