-- xp.lua - experience and leveling system

xp = {
    orbs = {},
    current_xp = 0,
    level = 1,
    xp_to_next = 100
}

function xp.init()
    xp.orbs = {}
    xp.current_xp = 0
    xp.level = 1
    xp.xp_to_next = 100
end

function xp.reset()
    xp.orbs = {}
    xp.current_xp = 0
    xp.level = 1
    xp.xp_to_next = 100
end

function xp.spawn_orb(x, y, value)
    local orb = {
        x = x,
        y = y,
        value = value,
        life = 600, -- 10 seconds at 60fps
        attract_range = 40,
        collect_range = 8,
        dx = 0,
        dy = 0,
        color = 10
    }
    
    add(xp.orbs, orb)
end

function xp.update()
    for i = #xp.orbs, 1, -1 do
        local orb = xp.orbs[i]
        
        -- check distance to player
        local dx = player.x - orb.x
        local dy = player.y - orb.y
        local dist = sqrt(dx*dx + dy*dy)
        
        -- collect orb if close enough
        if dist <= orb.collect_range then
            xp.gain_xp(orb.value)
            del(xp.orbs, orb)
        -- attract orb if within range
        elseif dist <= orb.attract_range then
            local speed = 2
            orb.dx = (dx / dist) * speed
            orb.dy = (dy / dist) * speed
            orb.x += orb.dx
            orb.y += orb.dy
        end
        
        -- reduce life
        orb.life -= 1
        if orb.life <= 0 then
            del(xp.orbs, orb)
        end
        
        -- fade color as life decreases
        if orb.life < 120 then
            orb.color = 5
        end
    end
end

function xp.gain_xp(amount)
    xp.current_xp += amount
    
    -- check for level up
    while xp.current_xp >= xp.xp_to_next do
        xp.current_xp -= xp.xp_to_next
        xp.level += 1
        xp.xp_to_next = flr(xp.xp_to_next * 1.2) -- increase xp required for next level
        
        -- trigger level up
        game.pending_level_up = true
    end
end

function xp.can_level_up()
    return game.pending_level_up
end

function xp.level_up_consumed()
    game.pending_level_up = false
end

function xp.draw()
    -- draw xp orbs
    for orb in all(xp.orbs) do
        local screen_x = orb.x - camera.x + sw/2
        local screen_y = orb.y - camera.y + sh/2
        
        -- only draw if on screen
        if screen_x >= -5 and screen_x < sw + 5 and screen_y >= -5 and screen_y < sh + 5 then
            circfill(screen_x, screen_y, 2, orb.color)
            
            -- draw glow effect
            circ(screen_x, screen_y, 3, orb.color)
        end
    end
end

function xp.get_xp_percent()
    return xp.current_xp / xp.xp_to_next
end