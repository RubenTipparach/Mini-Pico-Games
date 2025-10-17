--[[pod_format="raw",created="2025-08-16 22:26:22",modified="2025-08-19 02:14:12",revision=9]]
-- gamestate.lua - manages menu, ship selection, and game over states

gamestate = {}

local ships = {
    {name = "Fighter", health = 100, speed = .1, color = 7, starting_weapon = "cannon"},
    {name = "Cruiser", health = 150, speed = 0.05, color = 11, starting_weapon = "laser"},
    {name = "Scout", health = 75, speed = 0.12, color = 6, starting_weapon = "missile"}
}

local selected_ship = 1

function gamestate.init()
    game.state = "menu"
    game.score = 0
    game.high_score = 0
end

function gamestate.update_menu()
    if btnp(2) then -- up
        selected_ship = max(1, selected_ship - 1)
    elseif btnp(3) then -- down
        selected_ship = min(#ships, selected_ship + 1)
    elseif btnp(4) then -- x to start
        gamestate.start_game()
    end
end

function gamestate.start_game()
    game.state = "playing"
    game.score = 0
    
    -- initialize player with selected ship
    local ship = ships[selected_ship]
    player.setup(ship)
    waves.reset()
    xp.reset()
end

function gamestate.update_game_over()
    if btnp(4) then -- x to restart
        game.state = "menu"
    end
end

function gamestate.draw_menu()
    print("SPACE SURVIVOR", sw/2 - 50, 40, 7)
    print("Select your ship:", 50, 80, 6)
    
    for i = 1, #ships do
        local ship = ships[i]
        local y = 100 + (i-1) * 30
        local col = i == selected_ship and 7 or 5
        
        print("❯ " .. ship.name, 60, y, col)
        print("Health: " .. ship.health, 70, y + 8, col)
        print("Speed: " .. ship.speed, 70, y + 16, col)
        print("Weapon: " .. ship.starting_weapon, 160, y + 8, col)
        
        -- draw ship preview
        local x = 300
        circfill(x, y + 10, 3, ship.color)
    end
    
    print("Press Z to start", sw/2 - 40, 220, 6)
     print("WASD move ship, mouse rotate, Z shoot.", sw/2 - 90, 240, 5)
    print("Use arrows to select", sw/2 - 50, 260, 5)
end

function gamestate.draw_game_over()
    print("GAME OVER", sw/2 - 30, 100, 8)
    print("Score: " .. game.score, sw/2 - 25, 120, 7)
    
    if game.score > game.high_score then
        game.high_score = game.score
        print("New High Score!", sw/2 - 45, 140, 10)
    else
        print("High Score: " .. game.high_score, sw/2 - 40, 140, 6)
    end
    
    print("Press Z to return to menu", sw/2 - 60, 180, 5)
   
end

function gamestate.game_over()
    game.state = "game_over"
end