-- LANDER'S REVENGE - Upgrade System

-- Upgrade definitions
upgrades = {
    {name = "Better Thrusters", desc = "Increase thrust power", type = "thrust"},
    {name = "Extra Fuel Tank", desc = "Increase max fuel", type = "fuel"},
    {name = "Armor Plating", desc = "Reduce damage taken", type = "armor"},
    {name = "Weapon Damage", desc = "Increase weapon damage", type = "damage"},
    {name = "Rate of Fire", desc = "Shoot faster", type = "rate"},
    {name = "Extended Range", desc = "Bullets travel further", type = "range"}
}

-- Service options (always available)
services = {
    {name = "Partial Repair", desc = "Restore some health", type = "partial_repair"}
}

-- Weapon options (show one random unowned weapon)
function get_available_weapons()
    local all_unowned_weapons = {}
    
    -- Collect all unowned primary weapons
    for i, weapon in ipairs(weapon_config.primary_weapons) do
        if not player.owned_weapons.primary[i] then
            all_unowned_weapons[#all_unowned_weapons + 1] = {
                name = weapon.name .. " (Primary)",
                desc = get_weapon_description(weapon, "primary"),
                type = "weapon_primary",
                weapon_index = i,
                cost = weapon.cost
            }
        end
    end
    
    -- Collect all unowned secondary weapons
    for i, weapon in ipairs(weapon_config.secondary_weapons) do
        if not player.owned_weapons.secondary[i] then
            all_unowned_weapons[#all_unowned_weapons + 1] = {
                name = weapon.name .. " (Secondary)",
                desc = get_weapon_description(weapon, "secondary"),
                type = "weapon_secondary", 
                weapon_index = i,
                cost = weapon.cost
            }
        end
    end
    
    -- Return only one random weapon if any are available
    if #all_unowned_weapons > 0 then
        local random_index = flr(rnd(#all_unowned_weapons)) + 1
        return {all_unowned_weapons[random_index]}
    else
        return {}
    end
end

function get_weapon_description(weapon, weapon_type)
    local desc = "DMG:" .. weapon.damage .. " Rate:" .. weapon.rate
    if weapon.bullets and weapon.bullets > 1 then
        desc = desc .. " Bullets:" .. weapon.bullets
    end
    desc = desc .. " - $" .. weapon.cost
    return desc
end

-- Current upgrade selection and available choices
upgrade_selection = 1
available_upgrades = {}

function generate_upgrade_choices()
    available_upgrades = {}
    local choices = {}
    
    -- Add available weapons first (priority items)
    local weapon_options = get_available_weapons()
    for weapon in all(weapon_options) do
        choices[#choices + 1] = weapon
    end
    
    -- Add partial repair service (only if player is damaged)
    if player.health < player.max_health then
        choices[#choices + 1] = services[1]  -- Partial Repair
    end
    
    -- Add random upgrades to fill remaining slots (max 4 total items since only 1 weapon now)
    while #choices < 4 do
        local choice = upgrades[flr(rnd(#upgrades)) + 1]
        local found = false
        for j = 1, #choices do
            local existing = choices[j]
            if existing.type == choice.type then
                found = true
                break
            end
        end
        if not found then
            choices[#choices + 1] = choice
        end
    end
    
    available_upgrades = choices
    upgrade_selection = 1  -- Reset selection
end

function count_services(choices)
    local count = 0
    for i = 1, #choices do
        if choices[i].type == "partial_repair" then
            count += 1
        end
    end
    return count
end

function apply_upgrade(upgrade_type, upgrade_item)
    local config = upgrade_config
    local money_config = money_config
    
    if upgrade_type == "weapon_primary" then
        local cost = upgrade_item.cost or 0
        if player.money >= cost then
            player.money -= cost
            player.owned_weapons.primary[upgrade_item.weapon_index] = true
            player.current_primary = upgrade_item.weapon_index  -- Auto-equip
            if debug_mode then print("Purchased primary weapon: " .. upgrade_item.name) end
        else
            if debug_mode then print("Not enough money for weapon") end
            return false
        end
    elseif upgrade_type == "weapon_secondary" then
        local cost = upgrade_item.cost or 0
        if player.money >= cost then
            player.money -= cost
            player.owned_weapons.secondary[upgrade_item.weapon_index] = true
            player.current_secondary = upgrade_item.weapon_index  -- Auto-equip
            if debug_mode then print("Purchased secondary weapon: " .. upgrade_item.name) end
        else
            if debug_mode then print("Not enough money for weapon") end
            return false
        end
    elseif upgrade_type == "partial_repair" then
        local repair_amount = 25  -- Fixed amount of health restored
        local cost = repair_amount * money_config.repair_cost_per_unit
        if player.money >= cost then
            player.money -= cost
            player.health = min(player.max_health, player.health + repair_amount)
            if debug_mode then print("Partial repair for $" .. cost .. ", +" .. repair_amount .. " health") end
        else
            if debug_mode then print("Not enough money for partial repair") end
            return false
        end
    elseif upgrade_type == "thrust" then
        player.thrust_power += config.thrust_increase
    elseif upgrade_type == "fuel" then
        player.max_fuel += config.fuel_increase
        player.fuel += config.fuel_increase  -- Also restore some fuel
    elseif upgrade_type == "armor" then
        player.armor += config.armor_increase
        player.max_health += config.health_increase
        player.health += config.health_increase  -- Also heal
    elseif upgrade_type == "damage" then
        player.weapons.damage += config.damage_increase
    elseif upgrade_type == "rate" then
        player.weapons.rate = max(0.05, player.weapons.rate - config.rate_improvement)
    elseif upgrade_type == "range" then
        player.weapons.range += config.range_increase
    end
    return true
end

function update_upgrade_screen()
    -- Navigation (using WASD keys or arrow keys)
    if btnp(input_config.key_w) or btnp(input_config.arrow_up) then  -- W key or Up arrow - up
        upgrade_selection = max(1, upgrade_selection - 1)
    elseif btnp(input_config.key_s) or btnp(input_config.arrow_down) then  -- S key or Down arrow - down
        upgrade_selection = min(#available_upgrades, upgrade_selection + 1)
    end
    
    -- Selection
    if btnp(input_config.menu_select) then  -- Z key
        if #available_upgrades > 0 then
            local selected_item = available_upgrades[upgrade_selection]
            local success = apply_upgrade(selected_item.type, selected_item)
            if success then
                -- Only return to playing if purchase was successful
                game_state = "playing"
            else
                -- Stay in shop if not enough money
                -- Could add visual feedback here
            end
        end
    end
    
    -- Exit shop (ESC key or X key as backup)
    if btnp(input_config.primary_weapon) then  -- X key - exit shop
        game_state = "playing"
    end
end

function advance_to_next_level()
    -- Continue to next level
    level += 1
    player.fuel = player.max_fuel
    player.health = player.max_health
    target_pad = 1
    generate_terrain()
    place_landing_pads()
    -- Position player on first landing pad for new level
    if #landing_pads > 0 then
        local first_pad = landing_pads[1]
        player.x = first_pad.x
        player.y = first_pad.y - 16
        player.vx = 0
        player.vy = 0
        player.last_safe_x = first_pad.x
        player.last_safe_y = first_pad.y - 16
    end
    clear_enemies()  -- Clear enemies when starting new level
    
    -- Show dialog every few levels
    if should_show_story_dialog() then
        advance_story()
        start_dialog(dialog.current_story)
        game_state = "dialog"
    else
        game_state = "playing"
    end
end

-- Note: draw_upgrade_screen() is defined in ui.lua

-- Utility functions for upgrade descriptions
function get_upgrade_description(upgrade_type)
    local config = upgrade_config
    local descriptions = {
        partial_repair = "Restore 25 health - $" .. get_service_cost("partial_repair"),
        thrust = "+" .. (config.thrust_increase * 100) .. "% thrust power",
        fuel = "+" .. config.fuel_increase .. " max fuel",
        armor = "+" .. (config.armor_increase * 100) .. "% damage reduction, +" .. config.health_increase .. " max health",
        damage = "+" .. config.damage_increase .. " weapon damage",
        rate = "-" .. (config.rate_improvement * 100) .. "% shot cooldown",
        range = "+" .. config.range_increase .. " bullet range"
    }
    return descriptions[upgrade_type] or "Unknown upgrade"
end

function get_service_cost(service_type)
    if service_type == "partial_repair" then
        local repair_amount = 25  -- Fixed amount
        return repair_amount * money_config.repair_cost_per_unit
    end
    return 0
end

function get_upgrade_icon(upgrade_type)
    -- Could return sprite numbers for upgrade icons when available
    local icons = {
        thrust = nil,  -- Thruster sprite
        fuel = nil,    -- Fuel tank sprite  
        armor = nil,   -- Armor sprite
        damage = nil,  -- Weapon sprite
        rate = nil,    -- Rate of fire sprite
        range = nil    -- Range sprite
    }
    return icons[upgrade_type]
end

-- Reset upgrades (for new game)
function reset_upgrades()
    upgrade_selection = 1
    available_upgrades = {}
end