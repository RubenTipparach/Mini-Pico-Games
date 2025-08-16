-- vampire survivor inspired space combat game
-- main game file

-- require modules
include "player.lua"
include "weapons.lua"
include "enemies.lua"
include "asteroids.lua"
include "xp.lua"
include "upgrades.lua"
include "waves.lua"
include "collision.lua"
include "explosions.lua"
include "ui.lua"
include "gamestate.lua"

-- screen resolution
sw = 480
sh = 270

-- global game state
game = {}

-- camera system
camera = {
    x = 0,
    y = 0,
    target_x = 0,
    target_y = 0,
    smoothing = 0.1
}

function _init()
    gamestate.init()
    player.init()
    weapons.init()
    enemies.init()
    asteroids.init()
    xp.init()
    upgrades.init()
    waves.init()
    explosions.init()
    ui.init()
end

function _update()
    if game.state == "menu" then
        gamestate.update_menu()
    elseif game.state == "playing" then
        player.update()
        weapons.update()
        enemies.update()
        asteroids.update()
        xp.update()
        waves.update()
        explosions.update()
        collision.update()
        
        -- update camera to follow player (do this after player update)
        camera.target_x = player.x
        camera.target_y = player.y
        camera.x += (camera.target_x - camera.x) * camera.smoothing
        camera.y += (camera.target_y - camera.y) * camera.smoothing
        
        -- check for level up
        if xp.can_level_up() then
            game.state = "upgrade"
            upgrades.generate_choices()
        end
    elseif game.state == "upgrade" then
        upgrades.update()
    elseif game.state == "game_over" then
        gamestate.update_game_over()
    end
end

function _draw()
    cls()
    
    if game.state == "menu" then
        gamestate.draw_menu()
    elseif game.state == "playing" or game.state == "upgrade" then
        -- draw game world
        asteroids.draw()
        enemies.draw()
        player.draw()
        weapons.draw()
        explosions.draw()
        xp.draw()
        ui.draw()
        
        -- draw upgrade screen on top if needed
        if game.state == "upgrade" then
            upgrades.draw()
        end
    elseif game.state == "game_over" then
        gamestate.draw_game_over()
    end
end