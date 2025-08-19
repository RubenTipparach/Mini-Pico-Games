--[[pod_format="raw",created="2025-08-16 22:05:14",modified="2025-08-19 02:12:29",revision=83]]
-- player.lua - player ship system

player = {
    x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    angle = 0,
    health = 100,
    max_health = 100,
    speed = 1,
    color = 7,
    base_color = 7,
    size = 4,
    current_weapons = {},
    
    -- stats that can be upgraded
    damage_mult = 1,
    range_mult = 1,
    speed_mult = 1,
    health_regen = 0,
    armor = 0,
    crit_chance = 0,
    
    regen_timer = 0,
    hit_flash_timer = 0
}

function player.init()
    player.x = 0  -- world coordinates
    player.y = 0
end

function player.setup(ship_data)
    player.health = ship_data.health
    player.max_health = ship_data.health
    player.speed = ship_data.speed
    player.color = ship_data.color
    player.base_color = ship_data.color
    player.current_weapons = {ship_data.starting_weapon}
    
    -- reset upgrades
    player.damage_mult = 1
    player.range_mult = 1
    player.speed_mult = 1
    player.health_regen = 0
    player.armor = 0
    player.crit_chance = 0
    player.regen_timer = 0
    player.hit_flash_timer = 0
end

function player.update()
    -- mouse rotation - ship always points toward mouse cursor
    local mx, my = mouse()
    
    -- ship position on screen (actual screen coordinates)
    local ship_screen_x = player.x - camera.x + sw/2
    local ship_screen_y = player.y - camera.y + sh/2
    
    -- calculate direction vector from ship to mouse
    local dx = mx - ship_screen_x
    local dy = my - ship_screen_y
    
    -- calculate distance (magnitude of vector)
    local distance = sqrt(dx * dx + dy * dy)
    
    -- only update rotation if mouse is not at ship center
    if distance > 0 then
        -- normalize the direction vector
        local norm_x = dx / distance
        local norm_y = dy / distance
        
        -- convert normalized vector to angle
        player.angle = (-atan2(dy, dx)) -(math.rad(45) /math.pi)
    end
    
    -- WASD movement relative to ship rotation
    local move_speed = player.speed * player.speed_mult
    
    -- W/S - forward/backward relative to ship facing
    if key("w") then 
        player.dx += cos(player.angle) * move_speed
        player.dy += sin(player.angle) * move_speed
    end
    if key("s") then 
        player.dx -= cos(player.angle) * move_speed * 0.5
        player.dy -= sin(player.angle) * move_speed * 0.5
    end
    
    -- A/D - strafe left/right relative to ship facing
    if key("d") then 
        player.dx += cos(player.angle - 0.25) * move_speed * 0.7
        player.dy += sin(player.angle - 0.25) * move_speed * 0.7
    end
    if key("a") then 
        player.dx += cos(player.angle + 0.25) * move_speed * 0.7
        player.dy += sin(player.angle + 0.25) * move_speed * 0.7
    end
    
    -- apply friction
    player.dx *= 0.95
    player.dy *= 0.95
    
    -- update position
    player.x += player.dx
    player.y += player.dy
    
    -- health regeneration
    if player.health_regen > 0 then
        player.regen_timer += 1
        if player.regen_timer >= 60 then -- once per second
            player.health = min(player.max_health, player.health + player.health_regen)
            player.regen_timer = 0
        end
    end
    
    -- update hit flash timer and color
    if player.hit_flash_timer > 0 then
        player.hit_flash_timer -= 1
        -- flicker between red and base color
        player.color = (player.hit_flash_timer % 6 < 3) and 8 or player.base_color
    else
        player.color = player.base_color
    end
    
    -- check for death
    if player.health <= 0 then
        gamestate.game_over()
    end
end

function player.draw()
    -- convert world coordinates to screen coordinates
    local screen_x = player.x - camera.x + sw/2
    local screen_y = player.y - camera.y + sh/2
    
    -- draw ship as rotated triangle
    local size = player.size
    local angle = player.angle
    
    -- define triangle points relative to center
    local points = {
        {x = size, y = 0},      -- nose
        {x = -size, y = -size/2}, -- rear left
        {x = -size, y = size/2}   -- rear right
    }
    
    -- rotate and translate points
    local rotated_points = {}
    for i, point in ipairs(points) do
        local cos_a = cos(angle)
        local sin_a = sin(angle)
        local rx = point.x * cos_a - point.y * sin_a
        local ry = point.x * sin_a + point.y * cos_a
        rotated_points[i] = {x = screen_x + rx, y = screen_y + ry}
    end
    
    -- draw ship triangle
    for i = 1, #rotated_points do
        local p1 = rotated_points[i]
        local p2 = rotated_points[i == #rotated_points and 1 or i + 1]
        line(p1.x, p1.y, p2.x, p2.y, player.color)
    end
    
    -- draw health bar above ship
    local bar_w = 20
    local bar_h = 3
    local bar_x = screen_x - bar_w/2
    local bar_y = screen_y - size - 8
    
    rect(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, 5)
    local health_w = (player.health / player.max_health) * bar_w
    rectfill(bar_x, bar_y, bar_x + health_w, bar_y + bar_h, player.health > 30 and 11 or 8)
 
    -- mouse rotation - ship always points toward mouse cursor
    local mx, my = mouse()
    
   -- DEBUG stuff
	-- ship position on screen (since camera keeps it centered)
	

    -- ship position on screen (actual screen coordinates)
    local sx = player.x - camera.x + sw/2
    local sy = player.y - camera.y + sh/2
	
	--line(mx, my, sx, sy, 11)
	
	local angle = atan2(mx - sx, my - sy)

	offset = 10 -- offsetline
	
	len = 500 -- line length
	
	x2 = sx + cos(angle) * offset
	y2 = sy + sin(angle) * offset
	--line(sx, sy, x2, y2, 8)
	
	x3 = sx + cos(player.angle) * len
	y3 = sy + sin(player.angle) * len
	line(x2, y2, x3, y3, 11)
	--[[	
	local degreesAngle = math.deg(angle)	
	print(degreesAngle)]]--
end

function player.take_damage(damage)
    -- apply armor reduction
    local actual_damage = max(1, damage - player.armor)
    player.health -= actual_damage
    
    -- trigger hit flash effect
    player.hit_flash_timer = 30 -- 0.5 seconds at 60fps
end

function player.has_weapon(weapon_name)
    for w in all(player.current_weapons) do
        if w == weapon_name then
            return true
        end
    end
    return false
end

function player.add_weapon(weapon_name)
    if not player.has_weapon(weapon_name) then
        add(player.current_weapons, weapon_name)
    end
end