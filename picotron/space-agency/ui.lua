-- User Interface System
-- Handles all UI drawing and interaction

local ui = {}
local parts = require("parts")
local sprites = parts.get_sprites()

function ui.init()
    -- Initialize UI system
end

function ui.draw_space_center()
    -- Draw space center background with star field
    rectfill(0, 20, 480, 270, 0) -- Black space background
    
    -- Draw star field background
    for i = 1, 50 do
        local x = (i * 37) % 480
        local y = 20 + (i * 23) % 250
        pset(x, y, 7)
    end
    
    -- Draw buildings with sprites
    local buildings = {
        {name = "vab", sprite = sprites.vab_building, x = 80, y = 130, key = "z"},
        {name = "launch pad", sprite = sprites.launch_pad, x = 180, y = 100, key = "x"},
        {name = "mission control", sprite = sprites.mission_control, x = 280, y = 120, key = "m"},
        {name = "research lab", sprite = sprites.research_lab, x = 380, y = 140, key = "r"},
        {name = "tracking", sprite = sprites.tracking_station, x = 120, y = 200, key = "t"},
        {name = "admin", sprite = sprites.admin_office, x = 220, y = 180, key = "f"},
        {name = "hangar", sprite = sprites.hangar, x = 320, y = 200, key = "h"}
    }
    
    for building in all(buildings) do
        -- Draw building sprite (16x16)
        -- Simulate sprite drawing with colored rectangles for now
        rectfill(building.x, building.y, 16, 16, 6)
        rect(building.x, building.y, 16, 16, 7)
        
        -- Draw building name and hotkey
        print(building.name, building.x, building.y + 20, 7)
        print("[" .. building.key .. "]", building.x, building.y + 30, 11)
    end
    
    -- Instructions
    print("space center - select building with hotkeys", 10, 250, 7)
end

function ui.draw_vab(vessel)
    -- Draw VAB interface with split layout
    
    -- Left side - Parts list (120px wide)
    clip(0, 20, 120, 250)
    ui.draw_parts_list()
    clip()
    
    -- Right side - Assembly area
    clip(120, 20, 360, 250)
    vessel.draw_assembly_view(vessel)
    clip()
    
    -- Bottom info panel
    ui.draw_vessel_info(vessel)
end

function ui.draw_parts_list()
    rectfill(0, 20, 120, 250, 1) -- Dark blue background
    print("parts", 10, 30, 7)
    
    local available = parts.get_available_parts()
    local inventory = parts.get_inventory()
    local y = 50
    
    for i, part_id in ipairs(available) do
        local def = parts.get_definition(part_id)
        local count = inventory[part_id] or 0
        local color = count > 0 and 7 or 5
        
        -- Draw part sprite icon (16x16)
        if def.sprite then
            -- Simulate sprite drawing with colored rectangle
            local sprite_color = 7
            if def.type == "command" then sprite_color = 12
            elseif def.type == "engine" then sprite_color = 8
            elseif def.type == "fuel" then sprite_color = 3
            elseif def.type == "decoupler" then sprite_color = 9
            end
            
            rectfill(5, y, 16, 16, sprite_color)
            rect(5, y, 16, 16, 0)
        end
        
        print(def.name, 18, y, color)
        print("x" .. count, 18, y + 8, color)
        print("$" .. def.cost, 18, y + 16, 6)
        
        y = y + 30
    end
    
    print("z: place  x: remove", 5, 240, 6)
end

function ui.draw_vessel_info(vessel)
    -- Bottom info panel
    rectfill(0, 250, 480, 20, 2)
    
    local mass = math.floor(vessel.total_mass * 10) / 10
    local dv = math.floor(vessel.total_dv)
    local twr = math.floor(parts.calculate_twr(vessel.parts, 1) * 100) / 100
    
    print("mass: " .. mass .. "t", 10, 255, 7)
    print("dv: " .. dv .. "m/s", 100, 255, 7)
    print("twr: " .. twr, 200, 255, 7)
    print("parts: " .. #vessel.parts, 300, 255, 7)
end

function ui.draw_stage_view()
    -- Left side of flight screen - shows the rocket
    local physics = require("physics")
    local alt = physics.get_altitude()
    
    -- Background color based on altitude
    local bg_color = 9 -- Sky blue for low altitude
    if alt > 50 then bg_color = 1 end -- Dark blue for high altitude
    if alt > 100 then bg_color = 0 end -- Black for space
    
    rectfill(0, 20, 240, 250, bg_color)
    
    -- Draw horizon line if in atmosphere
    if alt < 100 then
        line(0, 200, 240, 200, 3)
    end
    
    -- Draw rocket (simplified representation)
    local rocket_x = 120
    local rocket_y = 180
    
    -- Draw rocket body using engine sprite representation
    rectfill(rocket_x - 8, rocket_y - 20, 16, 40, 7)
    rect(rocket_x - 8, rocket_y - 20, 16, 40, 0)
    
    -- Draw thrust flame if throttle > 0
    local throttle = physics.get_throttle()
    if throttle > 0 then
        local flame_height = throttle * 20
        -- Animated flame effect using thrust_flame sprite concept
        local flame_frame = math.floor(time() * 10) % 3
        local flame_colors = {8, 9, 10} -- Red, orange, yellow
        
        for i = 1, 3 do
            local flame_y = rocket_y + 20 + (i - 1) * 4
            local flame_w = 12 - i * 2
            if flame_y < rocket_y + 20 + flame_height then
                rectfill(rocket_x - flame_w/2, flame_y, flame_w, 4, flame_colors[(i + flame_frame) % 3 + 1])
            end
        end
    end
    
    -- Display flight info
    local vel = physics.get_velocity()
    local speed = math.floor(math.sqrt(vel.x^2 + vel.y^2))
    
    print("alt: " .. math.floor(alt) .. "km", 10, 30, 7)
    print("spd: " .. speed .. "m/s", 10, 40, 7)
    print("thr: " .. math.floor(throttle * 100) .. "%", 10, 50, 7)
    
    -- Draw staging info
    print("stage: 1", 10, 200, 7) -- TODO: get actual stage from vessel
end

function ui.draw_map_view()
    -- Right side of flight screen - shows orbital map
    rectfill(240, 20, 240, 250, 0) -- Black space background
    
    local center_x = 360 -- Center of right panel
    local center_y = 135
    local scale = 0.01 -- Scale factor for display
    
    -- Draw Earth
    circfill(center_x, center_y, 30, 3) -- Green Earth
    circ(center_x, center_y, 30, 7) -- White outline
    
    -- Draw atmosphere
    circ(center_x, center_y, 32, 1) -- Thin blue atmosphere line
    
    -- Draw vessel position
    local physics = require("physics")
    local pos = physics.get_position()
    local vessel_x = center_x + pos.x * scale
    local vessel_y = center_y + pos.y * scale
    
    pset(vessel_x, vessel_y, 8) -- Red dot for vessel
    
    -- Draw orbital info
    local ap = physics.get_apoapsis()
    local pe = physics.get_periapsis()
    
    if ap > 0 then
        print("ap: " .. math.floor(ap) .. "km", 250, 30, 7)
        print("pe: " .. math.floor(pe) .. "km", 250, 40, 7)
        
        if pe > 70 then
            print("stable orbit", 250, 50, 11) -- Green
        else
            print("suborbital", 250, 50, 8) -- Red
        end
    else
        print("escape trajectory", 250, 30, 9) -- Orange
    end
end

function ui.draw_flight_ui()
    -- Flight controls overlay
    local throttle = require("physics").get_throttle()
    
    -- Throttle indicator using throttle_bar sprite concept
    rect(10, 200, 20, 50, 7)
    local throttle_height = throttle * 48
    
    -- Draw throttle bar with gradient effect
    for i = 0, throttle_height do
        local color = 8 -- Red at bottom
        if i > throttle_height * 0.3 then color = 9 end -- Orange in middle
        if i > throttle_height * 0.7 then color = 11 end -- Green at top
        
        line(12, 250 - i, 28, 250 - i, color)
    end
    
    -- Throttle percentage text
    print("thr:" .. math.floor(throttle * 100) .. "%", 35, 205, 7)
    
    -- Control instructions
    print("arrows: pitch", 35, 220, 6)
    print("space: stage", 35, 230, 6)
    print("x: return", 35, 240, 6)
    
    -- Stage indicators using stage_icon sprite concept
    for stage = 1, 3 do
        local x = 200 + stage * 25
        local y = 240
        local active = stage == 1 -- TODO: get actual current stage
        
        local stage_color = active and 11 or 5
        rectfill(x, y, 20, 15, stage_color)
        rect(x, y, 20, 15, 7)
        print(stage, x + 8, y + 5, active and 1 or 7)
    end
end

function ui.draw_tracking_station()
    -- Tracking station interface
    rectfill(0, 20, 480, 250, 0) -- Black background
    print("tracking station", 200, 100, 7)
    print("(not implemented yet)", 180, 120, 6)
end

-- Generic UI elements
function ui.draw_button(x, y, w, h, text, pressed)
    local color = pressed and 6 or 7
    local bg_color = pressed and 5 or 1
    
    rectfill(x, y, w, h, bg_color)
    rect(x, y, w, h, color)
    
    -- Center text
    local text_x = x + w/2 - #text * 2
    local text_y = y + h/2 - 3
    print(text, text_x, text_y, color)
end

function ui.draw_progress_bar(x, y, w, h, progress, color)
    rect(x, y, w, h, 6)
    if progress > 0 then
        local fill_w = (w - 2) * progress
        rectfill(x + 1, y + 1, fill_w, h - 2, color)
    end
end

function ui.draw_window(x, y, w, h, title)
    -- Window background
    rectfill(x, y, w, h, 6)
    rect(x, y, w, h, 0)
    
    -- Title bar
    rectfill(x, y, w, 12, 1)
    print(title, x + 5, y + 3, 7)
end

-- Color constants for consistency
ui.colors = {
    background = 0,     -- Black
    panel = 1,          -- Dark blue
    text = 7,           -- White
    accent = 8,         -- Red
    success = 11,       -- Green
    warning = 9,        -- Orange
    error = 8,          -- Red
    disabled = 5        -- Gray
}

return ui