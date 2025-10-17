-- Level up and upgrade system

local levelup_module = {}

function levelup_module.init_levelup()
    upgrade_options = {}
    selected_upgrade = 1
end

function levelup_module.generate_upgrade_options()
    upgrade_options = {}
    
    -- Pool of possible upgrades
    local possible_upgrades = {
        {
            name = "Shield Boost",
            description = "Increase max shields by 25",
            type = "shields",
            value = 25
        },
        {
            name = "Speed Boost", 
            description = "Increase movement speed by 20%",
            type = "speed",
            value = 0.2
        },
        {
            name = "Damage Boost",
            description = "Increase weapon damage by 30%",
            type = "damage",
            value = 0.3
        },
        {
            name = "Fire Rate Boost",
            description = "Reduce weapon cooldowns by 25%",
            type = "fire_rate",
            value = 0.25
        },
        {
            name = "Shield Regen",
            description = "Faster shield regeneration",
            type = "shield_regen",
            value = 2
        },
        {
            name = "Extra Weapon",
            description = "Add a front turret",
            type = "weapon",
            value = "front_turret"
        },
        {
            name = "Multi Turret",
            description = "Add a multi-directional turret",
            type = "weapon",
            value = "multi_turret"
        },
        {
            name = "Shotgun Turret",
            description = "Add a shotgun turret",
            type = "weapon",
            value = "shotgun_turret"
        },
        {
            name = "Defense Drone",
            description = "Add an orbiting drone",
            type = "weapon",
            value = "drone"
        }
    }
    
    -- Randomly select 3 upgrades
    for i = 1, 3 do
        local idx = flr(rnd(#possible_upgrades)) + 1
        add(upgrade_options, possible_upgrades[idx])
        del(possible_upgrades, possible_upgrades[idx])
    end
    
    selected_upgrade = 1
end

function levelup_module.update_levelup()
    -- Navigation
    if btnp(2) then  -- up
        selected_upgrade = max(1, selected_upgrade - 1)
    elseif btnp(3) then  -- down
        selected_upgrade = min(#upgrade_options, selected_upgrade + 1)
    end
    
    -- Selection
    if btnp(4) or btnp(5) then  -- z or x
        levelup_module.apply_upgrade(upgrade_options[selected_upgrade])
        game_state = "playing"
    end
end

function levelup_module.apply_upgrade(upgrade)
    local player = get_player()
    
    if upgrade.type == "shields" then
        player.max_shields += upgrade.value
        player.shields = player.max_shields  -- Full heal on shield upgrade
        
    elseif upgrade.type == "speed" then
        player.speed *= (1 + upgrade.value)
        player.max_speed *= (1 + upgrade.value)
        
    elseif upgrade.type == "damage" then
        -- Boost all existing weapons
        for weapon in all(player.weapons) do
            weapon.damage = flr(weapon.damage * (1 + upgrade.value))
        end
        
    elseif upgrade.type == "fire_rate" then
        -- Reduce cooldowns for all weapons
        for weapon in all(player.weapons) do
            weapon.fire_rate = flr(weapon.fire_rate * (1 - upgrade.value))
        end
        
    elseif upgrade.type == "shield_regen" then
        -- This will be handled in player update
        player.shield_regen_rate = (player.shield_regen_rate or 0.1) * upgrade.value
        
    elseif upgrade.type == "weapon" then
        add_weapon_to_player(upgrade.value)
    end
end

function levelup_module.draw_levelup()
    cls(0)
    
    -- Title
    local title = "LEVEL UP!"
    local title_w = #title * 8
    print(title, (480 - title_w) / 2, 40, 10)
    
    -- Level info
    local player = get_player()
    local level_text = "Level " .. player.level
    local level_w = #level_text * 4
    print(level_text, (480 - level_w) / 2, 60, 7)
    
    -- Instructions
    local instr = "Choose an upgrade:"
    local instr_w = #instr * 4
    print(instr, (480 - instr_w) / 2, 80, 6)
    
    -- Upgrade options
    for i, upgrade in ipairs(upgrade_options) do
        local y = 110 + (i - 1) * 40
        local color = (i == selected_upgrade) and 11 or 7
        local bg_color = (i == selected_upgrade) and 1 or 0
        
        -- Background for selected option
        if i == selected_upgrade then
            rectfill(40, y - 5, 440, y + 25, bg_color)
            rect(40, y - 5, 440, y + 25, color)
        end
        
        -- Upgrade name
        print(upgrade.name, 50, y, color)
        
        -- Upgrade description
        print(upgrade.description, 50, y + 10, 6)
    end
    
    -- Controls
    print("Use arrow keys to select, Z to confirm", 120, 240, 5)
end

return levelup_module