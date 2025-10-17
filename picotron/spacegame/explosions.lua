-- explosions.lua - explosion effects system

explosions = {
    list = {}
}

function explosions.init()
    explosions.list = {}
end

function explosions.spawn(x, y, size, duration, color)
    local explosion = {
        x = x,
        y = y,
        size = size or 10,
        max_size = size or 10,
        duration = duration or 30,
        max_duration = duration or 30,
        color = color or 9,
        particles = {}
    }
    
    -- create particles for explosion
    local particle_count = size or 8
    for i = 1, particle_count do
        local particle = {
            x = x,
            y = y,
            dx = (rnd(2) - 1) * 3,
            dy = (rnd(2) - 1) * 3,
            life = duration or 30,
            color = color or 9
        }
        add(explosion.particles, particle)
    end
    
    add(explosions.list, explosion)
end

function explosions.update()
    for i = #explosions.list, 1, -1 do
        local explosion = explosions.list[i]
        
        explosion.duration -= 1
        
        -- update particles
        for j = #explosion.particles, 1, -1 do
            local particle = explosion.particles[j]
            particle.x += particle.dx
            particle.y += particle.dy
            particle.dx *= 0.95
            particle.dy *= 0.95
            particle.life -= 1
            
            if particle.life <= 0 then
                del(explosion.particles, particle)
            end
        end
        
        -- remove explosion when done
        if explosion.duration <= 0 then
            del(explosions.list, explosion)
        end
    end
end

function explosions.draw()
    for explosion in all(explosions.list) do
        -- draw particles
        for particle in all(explosion.particles) do
            local screen_x = particle.x - camera.x + sw/2
            local screen_y = particle.y - camera.y + sh/2
            
            -- fade color based on life
            local alpha = particle.life / 30
            local color = alpha > 0.5 and particle.color or (alpha > 0.25 and 5 or 0)
            
            if screen_x >= 0 and screen_x < sw and screen_y >= 0 and screen_y < sh then
                pset(screen_x, screen_y, color)
            end
        end
        
        -- draw main explosion flash
        if explosion.duration > explosion.max_duration * 0.7 then
            local screen_x = explosion.x - camera.x + sw/2
            local screen_y = explosion.y - camera.y + sh/2
            local flash_size = explosion.size * (explosion.duration / explosion.max_duration)
            
            if screen_x >= -flash_size and screen_x < sw + flash_size and 
               screen_y >= -flash_size and screen_y < sh + flash_size then
                circfill(screen_x, screen_y, flash_size, 7) -- white flash
                circ(screen_x, screen_y, flash_size + 1, explosion.color)
            end
        end
    end
end