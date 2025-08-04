-- Vessel Management System
-- Handles rocket assembly, staging, and vessel operations

local vessel = {}
local parts = require("parts")
local sprites = parts.get_sprites()

function vessel.new()
    return {
        parts = {},
        root_part = nil,
        total_mass = 0,
        total_dv = 0,
        stages = 1,
        name = "untitled vessel"
    }
end

function vessel.add_part(v, part_id, x, y, stage)
    local part = parts.create_part(part_id, x, y, stage or 1)
    if part and parts.use_part(part_id) then
        add(v.parts, part)
        
        -- Set as root part if it's the first command pod
        if part.type == "command" and not v.root_part then
            v.root_part = part
        end
        
        vessel.update_vessel_stats(v)
        return part
    end
    return nil
end

function vessel.remove_part(v, part)
    -- Return part to inventory
    parts.return_part(part.id)
    
    -- Remove from vessel
    for i = 1, #v.parts do
        if v.parts[i] == part then
            table.remove(v.parts, i)
            break
        end
    end
    
    vessel.update_vessel_stats(v)
end

function vessel.update_vessel_stats(v)
    v.total_mass = 0
    v.stages = 1
    
    for part in all(v.parts) do
        v.total_mass = v.total_mass + part.mass
        if part.fuel then
            v.total_mass = v.total_mass + part.fuel
        end
        v.stages = math.max(v.stages, part.stage)
    end
    
    v.total_dv = parts.calculate_delta_v(v.parts)
end

-- VAB Assembly Interface
local vab_state = {
    selected_part = nil,
    selected_part_id = "command_pod_mk1",
    cursor_x = 240,
    cursor_y = 135,
    current_stage = 1,
    grid_size = 16
}

function vessel.update_assembly(v)
    -- Handle mouse input for part placement
    if btnp(4) then -- Z key - place part
        vessel.place_part_at_cursor(v)
    end
    
    if btnp(5) then -- X key - remove part
        vessel.remove_part_at_cursor(v)
    end
    
    -- Handle cursor movement
    if btn(0) then vab_state.cursor_x = vab_state.cursor_x - 2 end
    if btn(1) then vab_state.cursor_x = vab_state.cursor_x + 2 end
    if btn(2) then vab_state.cursor_y = vab_state.cursor_y - 2 end
    if btn(3) then vab_state.cursor_y = vab_state.cursor_y + 2 end
    
    -- Constrain cursor to assembly area (16-pixel grid aligned)
    vab_state.cursor_x = math.max(128, math.min(352, vab_state.cursor_x))
    vab_state.cursor_y = math.max(32, math.min(224, vab_state.cursor_y))
end

function vessel.place_part_at_cursor(v)
    local grid_x = math.floor(vab_state.cursor_x / vab_state.grid_size)
    local grid_y = math.floor(vab_state.cursor_y / vab_state.grid_size)
    
    -- Check if position is valid (not overlapping)
    if vessel.is_position_valid(v, grid_x, grid_y) then
        local part = vessel.add_part(v, vab_state.selected_part_id, 
                                   grid_x * vab_state.grid_size, 
                                   grid_y * vab_state.grid_size, 
                                   vab_state.current_stage)
        if part then
            print("placed " .. part.name)
        else
            print("no parts in inventory")
        end
    else
        print("position blocked")
    end
end

function vessel.remove_part_at_cursor(v)
    local part = vessel.get_part_at_position(v, vab_state.cursor_x, vab_state.cursor_y)
    if part then
        vessel.remove_part(v, part)
        print("removed " .. part.name)
    end
end

function vessel.is_position_valid(v, grid_x, grid_y)
    local x = grid_x * vab_state.grid_size
    local y = grid_y * vab_state.grid_size
    
    for part in all(v.parts) do
        if math.abs(part.x - x) < 16 and 
           math.abs(part.y - y) < 16 then
            return false
        end
    end
    return true
end

function vessel.get_part_at_position(v, x, y)
    for part in all(v.parts) do
        if math.abs(part.x - x) < 16 and 
           math.abs(part.y - y) < 16 then
            return part
        end
    end
    return nil
end

function vessel.draw_assembly_view(v)
    -- Draw grid with grid_dot sprites
    for x = 120, 360, vab_state.grid_size do
        for y = 30, 240, vab_state.grid_size do
            -- Draw grid dots using sprite concept
            pset(x, y, 1) -- Dark blue dots
        end
    end
    
    -- Draw grid lines (faint) - every 16 pixels
    for x = 120, 360, 16 do
        line(x, 30, x, 240, 1)
    end
    for y = 30, 240, 16 do
        line(120, y, 360, y, 1)
    end
    
    -- Draw parts using sprites
    for part in all(v.parts) do
        vessel.draw_part(part)
    end
    
    -- Draw cursor using cursor sprite concept
    rect(vab_state.cursor_x - 8, vab_state.cursor_y - 8, 16, 16, 8)
    line(vab_state.cursor_x - 12, vab_state.cursor_y, vab_state.cursor_x + 12, vab_state.cursor_y, 8)
    line(vab_state.cursor_x, vab_state.cursor_y - 12, vab_state.cursor_x, vab_state.cursor_y + 12, 8)
    
    -- Draw part preview
    vessel.draw_part_preview(vab_state.selected_part_id, vab_state.cursor_x, vab_state.cursor_y)
end

function vessel.draw_part(part)
    -- Draw part using its sprite
    if part.sprite then
        -- For now, simulate sprite drawing with colored rectangles
        -- In actual Picotron, this would be: spr(part.sprite, part.x - 8, part.y - 8)
        
        -- Get part dimensions from definition
        local def = parts.get_definition(part.id)
        local w = def.width or 16
        local h = def.height or 16
        
        -- Color code by type for sprite simulation
        local color = 7
        if part.type == "command" then color = 12 -- Light blue
        elseif part.type == "engine" then color = 8 -- Red
        elseif part.type == "fuel" then color = 3 -- Dark green
        elseif part.type == "decoupler" then color = 9 -- Orange
        elseif part.type == "landing" then color = 6 -- Gray
        elseif part.type == "parachute" then color = 14 -- Pink
        end
        
        rectfill(part.x - w/2, part.y - h/2, w, h, color)
        rect(part.x - w/2, part.y - h/2, w, h, 0) -- Black outline
        
        -- Draw stage number using stage_icon concept
        local stage_x = part.x + w/2 - 8
        local stage_y = part.y - h/2 + 2
        rectfill(stage_x, stage_y, 16, 16, 1) -- Dark blue background
        print(part.stage, stage_x + 6, stage_y + 6, 7) -- White text
    end
end

function vessel.draw_part_preview(part_id, x, y)
    local def = parts.get_definition(part_id)
    if def then
        local w = def.width or 16
        local h = def.height or 16
        
        -- Draw semi-transparent preview
        rect(x - w/2, y - h/2, w, h, 6) -- Gray outline
        
        -- Draw dotted fill for preview
        for px = x - w/2 + 2, x + w/2 - 2, 4 do
            for py = y - h/2 + 2, y + h/2 - 2, 4 do
                pset(px, py, 5) -- Gray dots
            end
        end
    end
end

function vessel.get_vab_state()
    return vab_state
end

function vessel.set_selected_part(part_id)
    vab_state.selected_part_id = part_id
end

function vessel.set_current_stage(stage)
    vab_state.current_stage = stage
end

-- Validation functions
function vessel.validate_design(v)
    local issues = {}
    
    -- Must have a command pod
    local has_command = false
    for part in all(v.parts) do
        if part.type == "command" then
            has_command = true
            break
        end
    end
    if not has_command then
        add(issues, "no command pod")
    end
    
    -- Must have at least one engine in stage 1
    local has_engine = false
    for part in all(v.parts) do
        if part.type == "engine" and part.stage == 1 then
            has_engine = true
            break
        end
    end
    if not has_engine then
        add(issues, "no engines in first stage")
    end
    
    -- Check TWR > 1 for first stage
    local twr = parts.calculate_twr(v.parts, 1)
    if twr < 1.0 then
        add(issues, "twr too low: " .. math.floor(twr * 100) / 100)
    end
    
    return issues
end

-- Save/Load functions
function vessel.save(v, filename)
    -- Save vessel design to file
    local data = {
        name = v.name,
        parts = {}
    }
    
    for part in all(v.parts) do
        add(data.parts, {
            id = part.id,
            x = part.x,
            y = part.y,
            stage = part.stage,
            rotation = part.rotation
        })
    end
    
    -- In Picotron, this would use the file system
    -- For now, just print the data
    print("saving vessel: " .. v.name)
    return true
end

function vessel.load(filename)
    -- Load vessel design from file
    -- This would read from Picotron's file system
    print("loading vessel: " .. filename)
    return vessel.new()
end

return vessel