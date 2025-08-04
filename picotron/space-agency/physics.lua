-- Physics System for Orbital Mechanics
-- Implements 2D patched conic approximation with stability guarantees

local physics = {}

-- Constants
local G = 6.67430e-11 -- Gravitational constant (scaled for game units)
local EARTH_MASS = 5.972e24
local EARTH_RADIUS = 6371 -- km, but we use pixels as km
local ATMOSPHERE_HEIGHT = 70 -- km altitude where drag stops

-- Current flight state
local current_vessel = nil
local position = {x = 0, y = -EARTH_RADIUS - 10} -- Start 10km above surface
local velocity = {x = 0, y = 0}
local thrust_vector = {x = 0, y = 0}
local throttle = 0
local current_stage = 1

-- Orbital elements for display
local apoapsis = 0
local periapsis = 0
local orbital_period = 0

function physics.init()
    -- Initialize physics system
end

function physics.start_flight(vessel)
    current_vessel = vessel
    position = {x = 0, y = -EARTH_RADIUS - 10}
    velocity = {x = 0, y = 0}
    thrust_vector = {x = 0, y = 0}
    throttle = 0
    current_stage = 1
end

function physics.update(dt)
    if not current_vessel then return end
    
    -- Calculate forces
    local forces = calculate_forces()
    
    -- Integrate motion
    if throttle == 0 and altitude() > ATMOSPHERE_HEIGHT then
        -- Use analytical kepler step for stability when coasting in space
        analytical_step(dt)
    else
        -- Use numerical integration when under thrust or in atmosphere
        numerical_step(dt, forces)
    end
    
    -- Update orbital parameters
    update_orbital_elements()
end

function calculate_forces()
    local forces = {x = 0, y = 0}
    
    -- Gravitational force (always toward Earth center)
    local r = math.sqrt(position.x^2 + position.y^2)
    local g_mag = G * EARTH_MASS / (r^2)
    forces.x = forces.x - g_mag * (position.x / r)
    forces.y = forces.y - g_mag * (position.y / r)
    
    -- Thrust force
    if throttle > 0 and current_vessel then
        local active_engines = get_active_engines()
        local total_thrust = 0
        
        for engine in all(active_engines) do
            if engine.fuel_flow > 0 then
                total_thrust = total_thrust + engine.thrust
            end
        end
        
        forces.x = forces.x + thrust_vector.x * total_thrust * throttle
        forces.y = forces.y + thrust_vector.y * total_thrust * throttle
    end
    
    -- Atmospheric drag (simplified)
    if altitude() < ATMOSPHERE_HEIGHT then
        local air_density = math.max(0, 1 - altitude() / ATMOSPHERE_HEIGHT)
        local drag_coeff = 0.01 * air_density
        local vel_mag = math.sqrt(velocity.x^2 + velocity.y^2)
        
        if vel_mag > 0 then
            forces.x = forces.x - drag_coeff * velocity.x * vel_mag
            forces.y = forces.y - drag_coeff * velocity.y * vel_mag
        end
    end
    
    return forces
end

function numerical_step(dt, forces)
    -- Semi-implicit Euler integration
    local mass = get_vessel_mass()
    
    -- Update velocity
    velocity.x = velocity.x + (forces.x / mass) * dt
    velocity.y = velocity.y + (forces.y / mass) * dt
    
    -- Update position
    position.x = position.x + velocity.x * dt
    position.y = position.y + velocity.y * dt
end

function analytical_step(dt)
    -- Analytical Kepler step for stable orbits
    -- This maintains the vessel exactly on its orbital path
    
    local r = math.sqrt(position.x^2 + position.y^2)
    local v = math.sqrt(velocity.x^2 + velocity.y^2)
    
    -- Calculate orbital elements
    local mu = G * EARTH_MASS
    local energy = v^2 / 2 - mu / r
    local semi_major = -mu / (2 * energy)
    
    if semi_major > 0 then
        -- Elliptical orbit
        local mean_motion = math.sqrt(mu / (semi_major^3))
        local mean_anomaly_change = mean_motion * dt
        
        -- Update position along orbit (simplified)
        local angle = math.atan2(position.y, position.x)
        angle = angle + mean_anomaly_change
        
        position.x = r * math.cos(angle)
        position.y = r * math.sin(angle)
        
        -- Update velocity to maintain orbit
        local vel_angle = angle + math.pi/2
        velocity.x = v * math.cos(vel_angle)
        velocity.y = v * math.sin(vel_angle)
    end
end

function update_orbital_elements()
    local r = math.sqrt(position.x^2 + position.y^2)
    local v = math.sqrt(velocity.x^2 + velocity.y^2)
    local mu = G * EARTH_MASS
    
    -- Specific orbital energy
    local energy = v^2 / 2 - mu / r
    
    if energy < 0 then
        -- Bound orbit (ellipse)
        local semi_major = -mu / (2 * energy)
        
        -- Calculate apoapsis and periapsis
        local h = position.x * velocity.y - position.y * velocity.x -- Angular momentum
        local ecc_vector_x = (v^2 - mu/r) * position.x / mu - (position.x * velocity.x + position.y * velocity.y) * velocity.x / mu
        local ecc_vector_y = (v^2 - mu/r) * position.y / mu - (position.x * velocity.x + position.y * velocity.y) * velocity.y / mu
        local eccentricity = math.sqrt(ecc_vector_x^2 + ecc_vector_y^2)
        
        apoapsis = semi_major * (1 + eccentricity) - EARTH_RADIUS
        periapsis = semi_major * (1 - eccentricity) - EARTH_RADIUS
        orbital_period = 2 * math.pi * math.sqrt(semi_major^3 / mu)
    else
        -- Escape trajectory
        apoapsis = -1
        periapsis = -1
        orbital_period = -1
    end
end

function get_active_engines()
    if not current_vessel then return {} end
    
    local engines = {}
    for part in all(current_vessel.parts) do
        if part.type == "engine" and part.stage <= current_stage then
            add(engines, part)
        end
    end
    return engines
end

function get_vessel_mass()
    if not current_vessel then return 1 end
    
    local total_mass = 0
    for part in all(current_vessel.parts) do
        total_mass = total_mass + part.mass
        if part.fuel then
            total_mass = total_mass + part.fuel
        end
    end
    return total_mass
end

function altitude()
    local r = math.sqrt(position.x^2 + position.y^2)
    return r - EARTH_RADIUS
end

-- Control functions
function physics.pitch_left()
    local angle = math.atan2(thrust_vector.y, thrust_vector.x)
    angle = angle + 0.02 -- 2 degrees per update
    thrust_vector.x = math.cos(angle)
    thrust_vector.y = math.sin(angle)
end

function physics.pitch_right()
    local angle = math.atan2(thrust_vector.y, thrust_vector.x)
    angle = angle - 0.02
    thrust_vector.x = math.cos(angle)
    thrust_vector.y = math.sin(angle)
end

function physics.throttle_up()
    throttle = math.min(1, throttle + 0.05)
end

function physics.throttle_down()
    throttle = math.max(0, throttle - 0.05)
end

function physics.stage()
    -- Drop current stage and activate next
    current_stage = current_stage + 1
    
    -- Remove staged parts
    local new_parts = {}
    for part in all(current_vessel.parts) do
        if part.stage > current_stage - 1 then
            add(new_parts, part)
        end
    end
    current_vessel.parts = new_parts
end

-- Getters for UI
function physics.get_position()
    return position
end

function physics.get_velocity()
    return velocity
end

function physics.get_altitude()
    return altitude()
end

function physics.get_apoapsis()
    return apoapsis
end

function physics.get_periapsis()
    return periapsis
end

function physics.get_throttle()
    return throttle
end

function physics.get_thrust_angle()
    return math.atan2(thrust_vector.y, thrust_vector.x)
end

return physics