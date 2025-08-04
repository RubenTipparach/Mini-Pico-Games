-- Parts System - Rocket Components and Management

local parts = {}

-- Sprite indices for game assets
local sprites = {
    -- Rocket parts (1-6)
    command_pod = 1,
    engine = 2, 
    fuel_tank = 3,
    decoupler = 4,
    landing_leg = 5,
    parachute = 6,
    
    -- Buildings (7-13)
    vab_building = 7,
    launch_pad = 8,
    mission_control = 9,
    research_lab = 10,
    tracking_station = 11,
    admin_office = 12,
    hangar = 13,
    
    -- Effects (14-17)
    thrust_flame = 14,
    explosion = 15,
    parachute_deployed = 16,
    landing_dust = 17,
    
    -- Celestial (18-20)
    earth = 18,
    moon = 19,
    stars = 20,
    
    -- UI elements (21-25)
    cursor = 21,
    grid_dot = 22,
    throttle_bar = 23,
    stage_icon = 24,
    warning_icon = 25
}

-- Part definitions based on design document
local part_definitions = {
    -- Command pods
    command_pod_mk1 = {
        id = "command_pod_mk1",
        name = "Command Pod Mk-I",
        type = "command",
        mass = 0.8, -- tonnes
        cost = 1000,
        tech_level = 1,
        width = 16,
        height = 16,
        sprite = sprites.command_pod,
        crew_capacity = 1,
        element = "Al"
    },
    
    -- Engines
    engine_mk1 = {
        id = "engine_mk1",
        name = "Liquid Engine Mk-I",
        type = "engine",
        mass = 1.2,
        thrust = 120, -- kN
        isp = 300, -- specific impulse in seconds
        cost = 1200,
        tech_level = 1,
        width = 16,
        height = 16,
        sprite = sprites.engine,
        fuel_consumption = 0.4, -- kg/s at full throttle
        element = "Fe"
    },
    
    -- Fuel tanks
    fuel_tank_s = {
        id = "fuel_tank_s",
        name = "Fuel Tank S",
        type = "fuel",
        mass = 0.3, -- dry mass
        fuel_capacity = 1.5, -- tonnes of fuel
        cost = 800,
        tech_level = 1,
        width = 16,
        height = 16,
        sprite = sprites.fuel_tank,
        element = "Al"
    },
    
    -- Decouplers
    decoupler = {
        id = "decoupler",
        name = "Decoupler",
        type = "decoupler",
        mass = 0.1,
        cost = 400,
        tech_level = 1,
        width = 16,
        height = 16,
        sprite = sprites.decoupler,
        element = "Fe"
    },
    
    -- Landing systems
    landing_leg = {
        id = "landing_leg",
        name = "Landing Leg",
        type = "landing",
        mass = 0.05,
        cost = 200,
        tech_level = 1,
        width = 16,
        height = 16,
        sprite = sprites.landing_leg,
        element = "Al"
    },
    
    parachute = {
        id = "parachute",
        name = "Parachute",
        type = "parachute",
        mass = 0.1,
        cost = 300,
        tech_level = 1,
        width = 16,
        height = 16,
        sprite = sprites.parachute,
        element = "Al"
    }
}

-- Available parts (unlocked through tech tree)
local available_parts = {"command_pod_mk1", "engine_mk1", "fuel_tank_s", "decoupler"}
local inventory = {} -- Parts owned by player

function parts.init()
    -- Initialize parts inventory with some starting parts
    for part_id in all(available_parts) do
        inventory[part_id] = 3 -- Start with 3 of each basic part
    end
end

function parts.get_definition(part_id)
    return part_definitions[part_id]
end

function parts.get_available_parts()
    return available_parts
end

function parts.get_inventory()
    return inventory
end

function parts.create_part(part_id, x, y, stage)
    local def = part_definitions[part_id]
    if not def then
        print("unknown part: " .. part_id)
        return nil
    end
    
    local part = {
        id = part_id,
        type = def.type,
        mass = def.mass,
        x = x or 0,
        y = y or 0,
        stage = stage or 1,
        rotation = 0,
        
        -- Engine specific
        thrust = def.thrust or 0,
        isp = def.isp or 0,
        fuel_consumption = def.fuel_consumption or 0,
        
        -- Fuel tank specific
        fuel_capacity = def.fuel_capacity or 0,
        fuel = def.fuel_capacity or 0, -- Start full
        
        -- Display properties
        width = def.width,
        height = def.height,
        sprite = def.sprite,
        name = def.name
    }
    
    return part
end

function parts.buy_part(part_id, quantity)
    quantity = quantity or 1
    local def = part_definitions[part_id]
    
    if not def then
        return false, "part not found"
    end
    
    local total_cost = def.cost * quantity
    
    -- Check if we can afford it (assuming main.lua provides spend_funds function)
    if get_funds and get_funds() >= total_cost then
        spend_funds(total_cost)
        inventory[part_id] = (inventory[part_id] or 0) + quantity
        return true, "purchased " .. quantity .. " " .. def.name
    else
        return false, "insufficient funds"
    end
end

function parts.use_part(part_id)
    if inventory[part_id] and inventory[part_id] > 0 then
        inventory[part_id] = inventory[part_id] - 1
        return true
    end
    return false
end

function parts.return_part(part_id)
    inventory[part_id] = (inventory[part_id] or 0) + 1
end

function parts.unlock_part(part_id)
    if part_definitions[part_id] then
        -- Add to available parts if not already there
        local already_available = false
        for id in all(available_parts) do
            if id == part_id then
                already_available = true
                break
            end
        end
        
        if not already_available then
            add(available_parts, part_id)
        end
        
        return true
    end
    return false
end

-- Calculate total delta-v for a vessel configuration
function parts.calculate_delta_v(vessel_parts)
    local stages = {}
    
    -- Group parts by stage
    for part in all(vessel_parts) do
        if not stages[part.stage] then
            stages[part.stage] = {engines = {}, fuel_tanks = {}, other = {}}
        end
        
        if part.type == "engine" then
            add(stages[part.stage].engines, part)
        elseif part.type == "fuel" then
            add(stages[part.stage].fuel_tanks, part)
        else
            add(stages[part.stage].other, part)
        end
    end
    
    local total_dv = 0
    local remaining_mass = 0
    
    -- Calculate mass of all parts
    for part in all(vessel_parts) do
        remaining_mass = remaining_mass + part.mass
        if part.fuel then
            remaining_mass = remaining_mass + part.fuel
        end
    end
    
    -- Calculate delta-v for each stage (reverse order)
    local stage_keys = {}
    for k, v in pairs(stages) do
        add(stage_keys, k)
    end
    
    -- Sort stages in descending order
    for i = 1, #stage_keys - 1 do
        for j = i + 1, #stage_keys do
            if stage_keys[i] < stage_keys[j] then
                local temp = stage_keys[i]
                stage_keys[i] = stage_keys[j]
                stage_keys[j] = temp
            end
        end
    end
    
    for stage_num in all(stage_keys) do
        local stage = stages[stage_num]
        
        -- Calculate stage properties
        local stage_thrust = 0
        local stage_fuel = 0
        local stage_dry_mass = 0
        local avg_isp = 0
        
        for engine in all(stage.engines) do
            stage_thrust = stage_thrust + engine.thrust
            avg_isp = avg_isp + engine.isp * engine.thrust
        end
        
        if stage_thrust > 0 then
            avg_isp = avg_isp / stage_thrust
        end
        
        for tank in all(stage.fuel_tanks) do
            stage_fuel = stage_fuel + tank.fuel
            stage_dry_mass = stage_dry_mass + tank.mass
        end
        
        for part in all(stage.other) do
            stage_dry_mass = stage_dry_mass + part.mass
        end
        
        for engine in all(stage.engines) do
            stage_dry_mass = stage_dry_mass + engine.mass
        end
        
        -- Tsiolkovsky rocket equation: dv = isp * g * ln(m_wet / m_dry)
        if stage_fuel > 0 and avg_isp > 0 then
            local wet_mass = remaining_mass
            local dry_mass = remaining_mass - stage_fuel
            local stage_dv = avg_isp * 9.81 * math.log(wet_mass / dry_mass)
            total_dv = total_dv + stage_dv
        end
        
        -- Remove staged mass for next calculation
        remaining_mass = remaining_mass - stage_dry_mass - stage_fuel
    end
    
    return total_dv
end

-- Get TWR (Thrust to Weight Ratio) for current stage
function parts.calculate_twr(vessel_parts, stage)
    local total_thrust = 0
    local total_mass = 0
    
    for part in all(vessel_parts) do
        total_mass = total_mass + part.mass
        if part.fuel then
            total_mass = total_mass + part.fuel
        end
        
        if part.type == "engine" and part.stage <= stage then
            total_thrust = total_thrust + part.thrust
        end
    end
    
    local weight = total_mass * 9.81 -- Convert to Newtons
    return total_thrust * 1000 / weight -- Convert kN to N
end

-- Export sprite constants for other modules
function parts.get_sprites()
    return sprites
end

return parts