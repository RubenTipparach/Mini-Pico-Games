-- Orbital Pioneer - Main Game File
-- A 2D physics sandbox for building and launching rockets

-- Game state management
local game_state = "space_center" -- space_center, vab, flight, tracking
local dt = 1/30
local time_scale = 1

-- Core modules
local physics = require("physics")
local parts = require("parts")
local ui = require("ui")
local vessel = require("vessel")
local celestial = require("celestial")

-- Game data
local current_vessel = nil
local active_flights = {}
local funds = 25000
local science = 0

function _init()
    -- Initialize game systems
    physics.init()
    parts.init()
    ui.init()
    celestial.init()
    
    print("orbital pioneer initialized")
end

function _update()
    if game_state == "space_center" then
        update_space_center()
    elseif game_state == "vab" then
        update_vab()
    elseif game_state == "flight" then
        update_flight()
    elseif game_state == "tracking" then
        update_tracking()
    end
end

function _draw()
    cls(0) -- Clear screen with black
    
    if game_state == "space_center" then
        draw_space_center()
    elseif game_state == "vab" then
        draw_vab()
    elseif game_state == "flight" then
        draw_flight()
    elseif game_state == "tracking" then
        draw_tracking()
    end
    
    -- Always draw top UI bar
    draw_top_ui()
end

function update_space_center()
    -- Handle space center navigation
    if btnp(4) then -- z key - enter VAB
        game_state = "vab"
        current_vessel = vessel.new()
    elseif btnp(5) then -- x key - launch pad
        if current_vessel and #current_vessel.parts > 0 then
            game_state = "flight"
            physics.start_flight(current_vessel)
        end
    end
end

function update_vab()
    -- Handle vehicle assembly building
    vessel.update_assembly(current_vessel)
    
    if btnp(5) then -- x key - return to space center
        game_state = "space_center"
    end
end

function update_flight()
    -- Handle active flight
    physics.update(dt * time_scale)
    
    -- Flight controls
    if btn(0) then physics.pitch_left() end
    if btn(1) then physics.pitch_right() end
    if btn(2) then physics.throttle_up() end
    if btn(3) then physics.throttle_down() end
    if btnp(4) then physics.stage() end
    
    if btnp(5) then -- x key - return to tracking
        game_state = "tracking"
    end
end

function update_tracking()
    -- Handle tracking station
    if btnp(5) then -- x key - return to space center
        game_state = "space_center"
    end
end

function draw_space_center()
    -- Draw space center buildings
    ui.draw_space_center()
    
    -- Status text
    print("funds: $" .. funds, 10, 10, 7)
    print("science: " .. science, 10, 20, 7)
    print("z: vab  x: launch", 10, 250, 6)
end

function draw_vab()
    -- Split screen: parts list (left) + assembly area (right)
    ui.draw_vab(current_vessel)
    
    print("vehicle assembly building", 10, 10, 7)
    print("x: back to space center", 10, 250, 6)
end

function draw_flight()
    -- Split screen: stage view (left) + map view (right)
    
    -- Left side - stage view (240x270)
    clip(0, 0, 240, 270)
    ui.draw_stage_view()
    
    -- Right side - map view (240x270)
    clip(240, 0, 240, 270)
    ui.draw_map_view()
    
    -- Reset clip
    clip()
    
    -- Flight UI overlay
    ui.draw_flight_ui()
end

function draw_tracking()
    ui.draw_tracking_station()
    print("tracking station", 10, 10, 7)
    print("x: back to space center", 10, 250, 6)
end

function draw_top_ui()
    -- Top status bar
    rectfill(0, 0, 480, 20, 1)
    print("orbital pioneer", 10, 7, 7)
    print("state: " .. game_state, 200, 7, 7)
    print("time: " .. time_scale .. "x", 350, 7, 7)
end

-- Utility functions
function change_state(new_state)
    game_state = new_state
end

function get_funds()
    return funds
end

function spend_funds(amount)
    if funds >= amount then
        funds = funds - amount
        return true
    end
    return false
end

function add_funds(amount)
    funds = funds + amount
end