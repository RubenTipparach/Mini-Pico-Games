-- Celestial Bodies System
-- Manages planets, moons, and orbital mechanics

local celestial = {}
local parts = require("parts")
local sprites = parts.get_sprites()

-- Celestial body definitions
local bodies = {
    earth = {
        name = "Earth",
        mass = 5.972e24,  -- kg
        radius = 6371,    -- km (but we use pixels as km)
        position = {x = 0, y = 0},
        velocity = {x = 0, y = 0},
        color = 3,        -- Green
        atmosphere_height = 70,
        soi = 100000,     -- Sphere of influence in km
        parent = nil
    },
    
    moon = {
        name = "Moon",
        mass = 7.342e22,  -- kg
        radius = 1737,    -- km
        position = {x = 38440, y = 0}, -- ~384,400 km from Earth (scaled down)
        velocity = {x = 0, y = 1022},  -- Orbital velocity
        color = 6,        -- Light gray
        atmosphere_height = 0,
        soi = 6000,       -- km
        parent = "earth"
    }
}

-- Current sphere of influence
local current_soi = "earth"

function celestial.init()
    -- Initialize celestial system
end

function celestial.update(dt)
    -- Update celestial body positions (simplified)
    -- In a full implementation, this would calculate n-body dynamics
    
    -- For now, just update the Moon's orbit around Earth
    if bodies.moon then
        local moon = bodies.moon
        local earth = bodies.earth
        
        -- Simple circular orbit
        local distance = math.sqrt((moon.position.x - earth.position.x)^2 + 
                                 (moon.position.y - earth.position.y)^2)
        local orbital_speed = math.sqrt(6.67430e-11 * earth.mass / (distance * 1000)) -- m/s
        orbital_speed = orbital_speed / 1000 -- Convert to km/s
        
        -- Update position
        local angle = math.atan2(moon.position.y - earth.position.y, 
                                moon.position.x - earth.position.x)
        angle = angle + (orbital_speed / distance) * dt
        
        moon.position.x = earth.position.x + distance * math.cos(angle)
        moon.position.y = earth.position.y + distance * math.sin(angle)
        
        moon.velocity.x = -orbital_speed * math.sin(angle)
        moon.velocity.y = orbital_speed * math.cos(angle)
    end
end

function celestial.get_primary_body(position)
    -- Determine which celestial body has gravitational influence
    local min_distance = math.huge
    local primary = "earth"
    
    for name, body in pairs(bodies) do
        local distance = math.sqrt((position.x - body.position.x)^2 + 
                                 (position.y - body.position.y)^2)
        
        if distance < body.soi and distance < min_distance then
            min_distance = distance
            primary = name
        end
    end
    
    return primary
end

function celestial.get_body(name)
    return bodies[name]
end

function celestial.get_gravitational_force(position, mass)
    -- Calculate gravitational force from primary body
    local primary_name = celestial.get_primary_body(position)
    local primary = bodies[primary_name]
    
    if not primary then return {x = 0, y = 0} end
    
    local dx = primary.position.x - position.x
    local dy = primary.position.y - position.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    if distance == 0 then return {x = 0, y = 0} end
    
    local G = 6.67430e-11
    local force_magnitude = G * primary.mass * mass / (distance^2 * 1000000) -- Convert to proper units
    
    local force_x = force_magnitude * (dx / distance) / 1000 -- Convert to kN
    local force_y = force_magnitude * (dy / distance) / 1000
    
    return {x = force_x, y = force_y}
end

function celestial.get_altitude(position, body_name)
    body_name = body_name or celestial.get_primary_body(position)
    local body = bodies[body_name]
    
    if not body then return 0 end
    
    local distance = math.sqrt((position.x - body.position.x)^2 + 
                              (position.y - body.position.y)^2)
    return distance - body.radius
end

function celestial.is_in_atmosphere(position, body_name)
    body_name = body_name or celestial.get_primary_body(position)
    local body = bodies[body_name]
    
    if not body or body.atmosphere_height == 0 then return false end
    
    local altitude = celestial.get_altitude(position, body_name)
    return altitude < body.atmosphere_height
end

function celestial.get_escape_velocity(position, body_name)
    body_name = body_name or celestial.get_primary_body(position)
    local body = bodies[body_name]
    
    if not body then return 0 end
    
    local distance = math.sqrt((position.x - body.position.x)^2 + 
                              (position.y - body.position.y)^2)
    local G = 6.67430e-11
    return math.sqrt(2 * G * body.mass / (distance * 1000)) / 1000 -- km/s
end

function celestial.get_orbital_velocity(position, body_name)
    body_name = body_name or celestial.get_primary_body(position)
    local body = bodies[body_name]
    
    if not body then return 0 end
    
    local distance = math.sqrt((position.x - body.position.x)^2 + 
                              (position.y - body.position.y)^2)
    local G = 6.67430e-11
    return math.sqrt(G * body.mass / (distance * 1000)) / 1000 -- km/s
end

function celestial.draw_body(body_name, camera_x, camera_y, scale)
    local body = bodies[body_name]
    if not body then return end
    
    local screen_x = (body.position.x - camera_x) * scale + 360 -- Center of right panel
    local screen_y = (body.position.y - camera_y) * scale + 135
    
    -- Only draw if on screen
    if screen_x > 240 and screen_x < 480 and screen_y > 20 and screen_y < 270 then
        local radius = math.max(4, body.radius * scale * 0.001) -- Scale down for display
        
        -- Always draw as circles for physics consistency
        -- Use sprites only when zoomed out (radius < 8) or for UI icons
        if radius < 8 then
            -- Very zoomed out - use 16x16 sprite icons
            if body_name == "earth" then
                -- Draw Earth icon sprite (would be spr(sprites.earth, screen_x-8, screen_y-8))
                -- For now, draw simplified representation
                rectfill(screen_x - 8, screen_y - 8, 16, 16, 1) -- Blue background
                rectfill(screen_x - 4, screen_y - 4, 8, 8, 3) -- Green continents
                pset(screen_x - 2, screen_y - 2, 7) -- White clouds
                pset(screen_x + 2, screen_y + 1, 7) -- White clouds
            elseif body_name == "moon" then
                -- Draw Moon icon sprite (would be spr(sprites.moon, screen_x-8, screen_y-8))
                rectfill(screen_x - 8, screen_y - 8, 16, 16, 6) -- Light gray background
                pset(screen_x - 3, screen_y - 3, 5) -- Dark crater
                pset(screen_x + 2, screen_y + 1, 5) -- Small crater
            else
                -- Generic small body
                rectfill(screen_x - 8, screen_y - 8, 16, 16, body.color)
            end
        else
            -- Normal view - draw as detailed circles for physics
            if body_name == "earth" then
                circfill(screen_x, screen_y, radius, 3) -- Green base
                circfill(screen_x - radius/3, screen_y - radius/4, radius/3, 1) -- Blue ocean
                circfill(screen_x + radius/4, screen_y + radius/3, radius/4, 11) -- Green continents
                -- Draw some cloud wisps
                for i = 1, 3 do
                    local cloud_x = screen_x + (i - 2) * radius/3
                    local cloud_y = screen_y + math.sin(i) * radius/2
                    circfill(cloud_x, cloud_y, 2, 7) -- White clouds
                end
            elseif body_name == "moon" then
                circfill(screen_x, screen_y, radius, 6) -- Light gray base
                -- Draw craters
                circfill(screen_x - radius/3, screen_y - radius/4, radius/5, 5) -- Dark crater
                circfill(screen_x + radius/4, screen_y + radius/3, radius/6, 5) -- Small crater
                circfill(screen_x, screen_y - radius/2, radius/8, 5) -- Tiny crater
            else
                -- Generic celestial body
                circfill(screen_x, screen_y, radius, body.color)
            end
        end
        
        -- Draw atmosphere if present (only for larger bodies)
        if body.atmosphere_height > 0 and radius > 6 then
            local atmo_radius = radius + math.max(1, body.atmosphere_height * scale * 0.001)
            circ(screen_x, screen_y, atmo_radius, 12) -- Light blue atmosphere
        end
        
        -- Draw name if large enough
        if radius > 8 then
            local name_x = screen_x - (#body.name * 2)
            local name_y = screen_y + radius + 3
            print(body.name, name_x, name_y, 7)
        end
    end
end

function celestial.draw_all_bodies(camera_x, camera_y, scale)
    -- Draw all celestial bodies
    for name, body in pairs(bodies) do
        celestial.draw_body(name, camera_x, camera_y, scale)
    end
end

-- Mission target calculations
function celestial.get_transfer_window(from_body, to_body)
    -- Calculate optimal transfer window (simplified)
    local from = bodies[from_body]
    local to = bodies[to_body]
    
    if not from or not to then return nil end
    
    -- For Earth-Moon transfers, calculate phase angle
    if from_body == "earth" and to_body == "moon" then
        local moon_angle = math.atan2(to.position.y, to.position.x)
        local transfer_time = estimate_transfer_time(from.position, to.position)
        local moon_angular_velocity = 2 * math.pi / (27.3 * 24 * 3600) -- Moon orbital period
        
        local required_phase_angle = moon_angular_velocity * transfer_time
        local current_phase_angle = moon_angle
        
        return {
            phase_angle = required_phase_angle,
            transfer_time = transfer_time,
            dv_required = estimate_transfer_dv(from_body, to_body)
        }
    end
    
    return nil
end

function estimate_transfer_time(pos1, pos2)
    -- Rough estimate of transfer time using distance
    local distance = math.sqrt((pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2)
    return distance / 1000 -- Very rough estimate in seconds
end

function estimate_transfer_dv(from_body, to_body)
    -- Rough estimate of delta-v required for transfer
    if from_body == "earth" and to_body == "moon" then
        return 3200 -- Approximate m/s for Earth-Moon transfer
    end
    return 1000 -- Default estimate
end

function celestial.get_surface_gravity(body_name)
    local body = bodies[body_name]
    if not body then return 9.81 end -- Default to Earth gravity
    
    local G = 6.67430e-11
    return G * body.mass / ((body.radius * 1000)^2) -- m/s^2
end

-- Collision detection for landing (always use circular collision)
function celestial.check_surface_collision(position, body_name)
    body_name = body_name or celestial.get_primary_body(position)
    local body = bodies[body_name]
    
    if not body then return false end
    
    local distance = math.sqrt((position.x - body.position.x)^2 + 
                              (position.y - body.position.y)^2)
    
    -- Return true if vessel is at or below surface
    return distance <= body.radius
end

function celestial.get_surface_normal(position, body_name)
    -- Get surface normal vector for landing orientation
    body_name = body_name or celestial.get_primary_body(position)
    local body = bodies[body_name]
    
    if not body then return {x = 0, y = 1} end
    
    local dx = position.x - body.position.x
    local dy = position.y - body.position.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    if distance == 0 then return {x = 0, y = 1} end
    
    -- Normal points away from planet center
    return {x = dx / distance, y = dy / distance}
end

return celestial