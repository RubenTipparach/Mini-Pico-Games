-- upgrades.lua - roguelike upgrade system

upgrades = {
    choices = {},
    selected = 1
}

-- available upgrade types
local upgrade_types = {
    -- weapon upgrades
    {
        id = "new_weapon_laser",
        name = "Laser Cannon",
        description = "Add laser weapon",
        type = "weapon",
        weapon = "laser",
        available = function() return not player.has_weapon("laser") end
    },
    {
        id = "new_weapon_missile",
        name = "Missile Launcher", 
        description = "Add homing missiles",
        type = "weapon",
        weapon = "missile",
        available = function() return not player.has_weapon("missile") end
    },
    {
        id = "new_weapon_drones",
        name = "Drone Swarm",
        description = "Deploy protective drones",
        type = "weapon", 
        weapon = "drone_swarm",
        available = function() return not player.has_weapon("drone_swarm") end
    },
    
    -- stat upgrades
    {
        id = "damage",
        name = "Damage Boost",
        description = "+25% weapon damage",
        type = "stat",
        apply = function() player.damage_mult *= 1.25 end
    },
    {
        id = "range",
        name = "Extended Range",
        description = "+30% weapon range",
        type = "stat",
        apply = function() player.range_mult *= 1.3 end
    },
    {
        id = "speed",
        name = "Engine Upgrade",
        description = "+20% movement speed",
        type = "stat",
        apply = function() player.speed_mult *= 1.2 end
    },
    {
        id = "health_regen",
        name = "Regeneration",
        description = "+2 health per second",
        type = "stat",
        apply = function() player.health_regen += 2 end
    },
    {
        id = "armor",
        name = "Armor Plating",
        description = "+5 damage reduction",
        type = "stat",
        apply = function() player.armor += 5 end
    },
    {
        id = "criticals",
        name = "Targeting Computer",
        description = "+10% critical hit chance",
        type = "stat",
        apply = function() player.crit_chance += 0.1 end
    },
    {
        id = "max_health",
        name = "Hull Reinforcement",
        description = "+25 max health",
        type = "stat",
        apply = function() 
            player.max_health += 25
            player.health = player.max_health -- full heal
        end
    }
}

function upgrades.init()
    upgrades.choices = {}
    upgrades.selected = 1
end

function upgrades.generate_choices()
    upgrades.choices = {}
    upgrades.selected = 1
    
    -- get available upgrades
    local available = {}
    for upgrade in all(upgrade_types) do
        if not upgrade.available or upgrade.available() then
            add(available, upgrade)
        end
    end
    
    -- pick 3 random upgrades
    for i = 1, 3 do
        if #available > 0 then
            local idx = flr(rnd(#available)) + 1
            local choice = available[idx]
            add(upgrades.choices, choice)
            del(available, choice)
        end
    end
end

function upgrades.update()
    -- navigation
    if btnp(2) then -- up
        upgrades.selected = max(1, upgrades.selected - 1)
    elseif btnp(3) then -- down
        upgrades.selected = min(#upgrades.choices, upgrades.selected + 1)
    elseif btnp(4) then -- x to select
        upgrades.apply_upgrade(upgrades.choices[upgrades.selected])
        xp.level_up_consumed()
        game.state = "playing"
    end
end

function upgrades.apply_upgrade(upgrade)
    if upgrade.type == "weapon" then
        player.add_weapon(upgrade.weapon)
    elseif upgrade.type == "stat" then
        upgrade.apply()
    end
end

function upgrades.draw()
    -- semi-transparent background
    rectfill(0, 0, sw, sh, 0)
    
    -- upgrade panel
    local panel_x = 80
    local panel_y = 40
    local panel_w = 320
    local panel_h = 190
    
    rectfill(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, 1)
    rect(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, 7)
    
    -- title
    print("LEVEL UP!", panel_x + 120, panel_y + 10, 10)
    print("Level " .. xp.level, panel_x + 130, panel_y + 25, 7)
    
    -- upgrade choices
    for i = 1, #upgrades.choices do
        local upgrade = upgrades.choices[i]
        local choice_y = panel_y + 50 + (i-1) * 40
        local col = i == upgrades.selected and 7 or 5
        
        -- selection indicator
        if i == upgrades.selected then
            print("❯", panel_x + 10, choice_y, 10)
        end
        
        -- upgrade name and description
        print(upgrade.name, panel_x + 25, choice_y, col)
        print(upgrade.description, panel_x + 25, choice_y + 10, 6)
    end
    
    -- instructions
    print("Use arrows to select, X to confirm", panel_x + 40, panel_y + panel_h - 20, 5)
end