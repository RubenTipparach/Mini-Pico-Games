pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

function _init()
    -- load highscore
    cartdata("ufo_abduction_v1")
    highscore = dget(0)
    if highscore == 0 then
        highscore = 100 -- default highscore
    end
    
    -- game state
    game_state = "play"
    score = 0
    time_left = 60 * 30 -- 30 seconds at 60fps
    ufo_death_timer = 0
    victory_timer = 0
    victory_ufo_y = 0
    new_highscore = false
    
    -- ufo
    ufo = {
        x = 64,
        y = 20,
        w = 16,
        h = 16,
        dx = 0,
        dy = 0,
        vx = 0,
        vy = 0,
        beam_on = false,
        beam_timer = 0,
        tilt = 0,
        bob_timer = 0,
        light_timer = 0,
        particles = {},
        health = 12,
        laser_cooldown = 0
    }
    
    -- farmer
    farmer = {
        x = 20,
        y = 110,
        w = 8,
        h = 8,
        target_x = 20,
        shoot_timer = 0,
        shoot_cooldown = 0,
        health = 2,
        alive = true,
        respawn_timer = 0,
        death_particles = {},
        death_timer = 0,
        lives = 3
    }
    
    -- projectiles
    bullets = {}
    lasers = {}
    
    -- cows
    cows = {}
    for i = 1, 8 do
        add(cows, {
            x = rnd(120),
            y = 100 + rnd(20),
            w = 8,
            h = 8,
            dx = (rnd(2) - 1) * 0.5,
            abducted = false,
            beam_y = 0
        })
    end
end

function _update()
    if game_state == "play" then
        update_game()
    elseif game_state == "ufo_death" then
        update_ufo_death()
    elseif game_state == "victory" then
        update_victory()
    end
end

function _draw()
    cls(1) -- dark blue background
    
    -- draw ground
    rectfill(0, 120, 127, 127, 3)
    
    if game_state == "play" then
        draw_game()
    elseif game_state == "gameover" then
        draw_gameover()
    elseif game_state == "ufo_death" then
        draw_ufo_death()
    elseif game_state == "victory" then
        draw_victory()
    end
end

function update_game()
    -- countdown timer
    time_left -= 1
    if time_left <= 0 then
        -- check if UFO won (farmer eliminated or no farmers left)
        if farmer.lives <= 0 then
            game_state = "victory"
            victory_timer = 0
            victory_ufo_y = ufo.y
            
            -- check for new highscore
            if score > highscore then
                highscore = score
                new_highscore = true
                dset(0, highscore) -- save highscore
            end
        else
            game_state = "gameover"
        end
        return
    end
    
    -- ufo movement with acceleration
    local accel = 0.3
    local max_speed = 2
    local friction = 0.85
    
    if btn(0) then 
        ufo.vx -= accel
        ufo.tilt = max(ufo.tilt - 0.1, -0.3)
    elseif btn(1) then 
        ufo.vx += accel
        ufo.tilt = min(ufo.tilt + 0.1, 0.3)
    else
        ufo.tilt *= 0.9
    end
    
    if btn(2) then ufo.vy -= accel end
    if btn(3) then ufo.vy += accel end
    
    -- apply speed limits
    ufo.vx = mid(-max_speed, ufo.vx, max_speed)
    ufo.vy = mid(-max_speed, ufo.vy, max_speed)
    
    -- apply movement and friction
    ufo.x += ufo.vx
    ufo.y += ufo.vy
    ufo.vx *= friction
    ufo.vy *= friction
    
    -- floating animation
    ufo.bob_timer += 0.1
    local bob = sin(ufo.bob_timer) * 1
    
    -- keep ufo on screen
    ufo.x = mid(0, ufo.x, 127 - ufo.w)
    ufo.y = mid(10, ufo.y + bob, 80) - bob
    
    -- update light animation
    ufo.light_timer += 0.2
    
    -- ufo weapons
    ufo.laser_cooldown = max(0, ufo.laser_cooldown - 1)
    
    -- abduction beam (X button)
    if btn(4) then
        ufo.beam_on = true
        ufo.beam_timer = 10
        
        -- add beam particles
        if #ufo.particles < 20 and rnd(1) < 0.6 then
            add(ufo.particles, {
                x = ufo.x + 4 + rnd(8),
                y = ufo.y + 16 + rnd(40),
                dy = -0.5 - rnd(1),
                life = 20 + rnd(20),
                col = 9 + rnd(2)
            })
        end
    else
        ufo.beam_timer -= 1
        if ufo.beam_timer <= 0 then
            ufo.beam_on = false
        end
    end
    
    -- laser weapon (Z button)
    if btn(5) and ufo.laser_cooldown == 0 and farmer.alive then
        add(lasers, {
            x = ufo.x + 8,
            y = ufo.y + 16,
            dx = 0,
            dy = 3,
            life = 40
        })
        ufo.laser_cooldown = 30
        sfx(1)
    end
    
    -- update particles
    for particle in all(ufo.particles) do
        particle.y += particle.dy
        particle.life -= 1
        if particle.life <= 0 or particle.y < ufo.y then
            del(ufo.particles, particle)
        end
    end
    
    -- update farmer ai
    if farmer.alive then
        farmer.shoot_cooldown = max(0, farmer.shoot_cooldown - 1)
        
        -- farmer follows ufo (slower movement)
        local dist_to_ufo = abs(farmer.x - (ufo.x + 8))
        if dist_to_ufo > 10 then
            if farmer.x < ufo.x + 8 then
                farmer.x += 0.3
            else
                farmer.x -= 0.3
            end
        end
        
        -- keep farmer on screen
        farmer.x = mid(5, farmer.x, 115)
        
        -- farmer shoots at ufo
        farmer.shoot_timer += 1
        if farmer.shoot_timer > 45 + rnd(30) and farmer.shoot_cooldown == 0 then
            add(bullets, {
                x = farmer.x + 4,
                y = farmer.y,
                dx = (ufo.x + 8 - farmer.x - 4) / 20,
                dy = (ufo.y + 8 - farmer.y) / 20,
                life = 60
            })
            farmer.shoot_timer = 0
            farmer.shoot_cooldown = 20
            sfx(2)
        end
    end
    
    -- update projectiles
    for bullet in all(bullets) do
        bullet.x += bullet.dx
        bullet.y += bullet.dy
        bullet.life -= 1
        if bullet.life <= 0 or bullet.y < 0 then
            del(bullets, bullet)
        end
    end
    
    for laser in all(lasers) do
        laser.x += laser.dx
        laser.y += laser.dy
        laser.life -= 1
        if laser.life <= 0 or laser.y > 128 then
            del(lasers, laser)
        end
    end
    
    -- update cows
    for cow in all(cows) do
        if not cow.abducted then
            -- move cow
            cow.x += cow.dx
            
            -- bounce off edges
            if cow.x < 0 or cow.x > 120 then
                cow.dx = -cow.dx
            end
            
            -- check for abduction
            if ufo.beam_on and 
               cow.x + cow.w > ufo.x and 
               cow.x < ufo.x + ufo.w and
               cow.y < ufo.y + 60 then
                cow.abducted = true
                cow.beam_y = cow.y
                score += 10
                sfx(0)
            end
        else
            -- move abducted cow up
            cow.beam_y -= 2
            if cow.beam_y < ufo.y then
                del(cows, cow)
            end
        end
    end
    
    -- collision detection
    -- bullets hitting ufo
    for bullet in all(bullets) do
        if bullet.x + 2 > ufo.x and bullet.x < ufo.x + ufo.w and
           bullet.y + 2 > ufo.y and bullet.y < ufo.y + ufo.h then
            del(bullets, bullet)
            ufo.health -= 1
            sfx(3)
            if ufo.health <= 0 then
                game_state = "ufo_death"
                ufo_death_timer = 120 -- 2 seconds death screen
                
                -- create ufo death particles
                for i = 1, 20 do
                    add(ufo.particles, {
                        x = ufo.x + 8 + rnd(16) - 8,
                        y = ufo.y + 8 + rnd(16) - 8,
                        dx = (rnd(6) - 3) * 1.5,
                        dy = (rnd(6) - 3) * 1.5,
                        life = 40 + rnd(40),
                        col = 8 + rnd(3)
                    })
                end
            end
        end
    end
    
    -- lasers hitting farmer
    if farmer.alive then
        for laser in all(lasers) do
            if laser.x + 2 > farmer.x and laser.x < farmer.x + farmer.w and
               laser.y + 2 > farmer.y and laser.y < farmer.y + farmer.h then
                del(lasers, laser)
                farmer.health -= 1
                sfx(3)
                if farmer.health <= 0 then
                    farmer.lives -= 1
                    farmer.alive = false
                    farmer.respawn_timer = 180 -- 3 seconds at 60fps
                    farmer.death_timer = 90 -- longer death display
                    
                    if farmer.lives > 0 then
                        score += 25 -- points for killing farmer
                    else
                        score += 50 -- bonus points for final elimination
                    end
                    
                    -- create death particles
                    for i = 1, 15 do
                        add(farmer.death_particles, {
                            x = farmer.x + 4 + rnd(4) - 2,
                            y = farmer.y + 4 + rnd(4) - 2,
                            dx = (rnd(4) - 2) * 0.8,
                            dy = (rnd(3) - 1.5) * 0.8,
                            life = 20 + rnd(20),
                            col = 8 + rnd(3)
                        })
                    end
                    
                    -- create celebration particles around UFO
                    for i = 1, 10 do
                        add(ufo.particles, {
                            x = ufo.x + 8 + rnd(16) - 8,
                            y = ufo.y + 8 + rnd(16) - 8,
                            dy = -1 - rnd(2),
                            life = 30 + rnd(30),
                            col = 9 + rnd(3)
                        })
                    end
                    
                    sfx(4) -- death sound
                end
            end
        end
    end
    
    -- update farmer death effects
    if farmer.death_timer > 0 then
        farmer.death_timer -= 1
    end
    
    -- update farmer death particles
    for particle in all(farmer.death_particles) do
        particle.x += particle.dx
        particle.y += particle.dy
        particle.dy += 0.1 -- gravity
        particle.life -= 1
        if particle.life <= 0 then
            del(farmer.death_particles, particle)
        end
    end
    
    -- handle farmer respawn
    if not farmer.alive and farmer.respawn_timer > 0 and farmer.lives > 0 then
        farmer.respawn_timer -= 1
        if farmer.respawn_timer <= 0 then
            farmer.alive = true
            farmer.health = 2
            farmer.x = 20 + rnd(80) -- spawn at random x position
            farmer.shoot_timer = 0
            farmer.shoot_cooldown = 30 -- brief invulnerability period
            farmer.death_particles = {} -- clear any remaining particles
        end
    end
    
    -- spawn new cows occasionally
    if #cows < 3 and rnd(100) < 2 then
        add(cows, {
            x = rnd(120),
            y = 100 + rnd(20),
            w = 8,
            h = 8,
            dx = (rnd(2) - 1) * 0.5,
            abducted = false,
            beam_y = 0
        })
    end
end

function draw_game()
    -- draw abduction beam
    if ufo.beam_on then
        -- main beam
        for i = 0, 3 do
            local beam_x = ufo.x + 4 + i * 2
            local alpha = 0.7 - i * 0.1
            line(beam_x, ufo.y + 16, beam_x, 120, 9)
        end
        
        -- beam glow effect
        for i = 0, 2 do
            local beam_x = ufo.x + 6 + i * 2
            line(beam_x, ufo.y + 16, beam_x, 120, 10)
        end
    end
    
    -- draw beam particles
    for particle in all(ufo.particles) do
        local col = particle.col
        if particle.life < 5 then col = 6 end
        pset(particle.x, particle.y, col)
    end
    
    -- draw projectiles
    for bullet in all(bullets) do
        circfill(bullet.x, bullet.y, 1, 8)
        pset(bullet.x, bullet.y, 7)
    end
    
    for laser in all(lasers) do
        -- draw laser beam as bright line
        line(laser.x - 1, laser.y - 3, laser.x + 1, laser.y + 3, 10)
        line(laser.x, laser.y - 4, laser.x, laser.y + 4, 9)
        circfill(laser.x, laser.y, 1, 12)
    end
    
    -- draw farmer death particles
    for particle in all(farmer.death_particles) do
        local col = particle.col
        if particle.life < 5 then col = 5 end
        circfill(particle.x, particle.y, 1, col)
    end
    
    -- draw farmer
    if farmer.alive then
        draw_farmer(farmer.x, farmer.y)
    elseif farmer.death_timer > 0 then
        -- flash death effect
        if farmer.death_timer % 4 < 2 then
            draw_farmer_death(farmer.x, farmer.y)
        end
        
        -- victory celebration text
        if farmer.death_timer > 60 then
            local flash_col = 10
            if farmer.death_timer % 8 < 4 then flash_col = 9 end
            if farmer.lives > 0 then
                print("farmer down!", 35, 40, flash_col)
                print("+25 points!", 38, 48, 12)
                print("lives left: " .. farmer.lives, 32, 56, 6)
            else
                print("farmer eliminated!", 25, 40, flash_col)
                print("+50 points!", 38, 48, 12)
            end
        end
    end
    
    -- draw cows
    for cow in all(cows) do
        if not cow.abducted then
            draw_cow(cow.x, cow.y)
        else
            draw_cow(cow.x, cow.beam_y)
        end
    end
    
    -- draw ufo with bob effect
    local bob = sin(ufo.bob_timer) * 1
    draw_ufo(ufo.x, ufo.y + bob, ufo.tilt)
    
    -- draw ui
    print("score: " .. score, 2, 2, 7)
    print("time: " .. flr(time_left / 60), 80, 2, 7)
    print("ufo hp: " .. ufo.health, 2, 8, 8)
    print("best: " .. highscore, 2, 14, 6)
    if farmer.alive then
        print("farmer hp: " .. farmer.health, 80, 8, 11)
        print("lives: " .. farmer.lives, 80, 14, 11)
    elseif farmer.respawn_timer > 0 and farmer.lives > 0 then
        print("respawn: " .. flr(farmer.respawn_timer / 60), 80, 8, 6)
        print("lives: " .. farmer.lives, 80, 14, 6)
    else
        print("farmer: kia", 80, 8, 8)
        print("lives: 0", 80, 14, 8)
    end
end

function draw_ufo(x, y, tilt)
    tilt = tilt or 0
    
    -- ufo body
    ovalfill(x, y, x + 15, y + 7, 8)
    ovalfill(x + 2, y + 1, x + 13, y + 6, 12)
    
    -- ufo dome
    ovalfill(x + 5, y - 2, x + 10, y + 3, 6)
    
    -- animated lights
    local light_phase = flr(ufo.light_timer) % 6
    local light_colors = {10, 9, 8, 7, 8, 9}
    local light_col = light_colors[light_phase + 1]
    
    pset(x + 2, y + 3, light_col)
    pset(x + 13, y + 3, light_col)
    pset(x + 7, y + 6, light_col)
    pset(x + 8, y + 6, light_col)
end

function draw_farmer(x, y)
    -- farmer body
    rectfill(x + 2, y + 2, x + 5, y + 7, 4)
    
    -- farmer head
    circfill(x + 3, y + 1, 1, 12)
    
    -- hat
    rectfill(x + 2, y, x + 5, y + 1, 3)
    
    -- gun
    if farmer.shoot_cooldown > 15 then
        line(x + 6, y + 3, x + 8, y + 2, 6)
    else
        line(x + 6, y + 3, x + 7, y + 2, 6)
    end
    
    -- legs
    line(x + 3, y + 7, x + 3, y + 8, 4)
    line(x + 4, y + 7, x + 4, y + 8, 4)
end

function draw_farmer_death(x, y)
    -- draw farmer in red/dark colors to show death
    rectfill(x + 2, y + 2, x + 5, y + 7, 2)
    circfill(x + 3, y + 1, 1, 8)
    rectfill(x + 2, y, x + 5, y + 1, 2)
    
    -- x marks for eyes
    line(x + 2, y, x + 3, y + 1, 8)
    line(x + 3, y, x + 2, y + 1, 8)
    line(x + 4, y, x + 5, y + 1, 8)
    line(x + 5, y, x + 4, y + 1, 8)
    
    -- legs
    line(x + 3, y + 7, x + 3, y + 8, 2)
    line(x + 4, y + 7, x + 4, y + 8, 2)
end

function draw_cow(x, y)
    -- cow body
    rectfill(x, y + 2, x + 7, y + 6, 7)
    
    -- cow head
    rectfill(x + 1, y, x + 3, y + 3, 7)
    
    -- spots
    pset(x + 2, y + 3, 0)
    pset(x + 5, y + 4, 0)
    
    -- legs
    line(x + 1, y + 6, x + 1, y + 7, 0)
    line(x + 3, y + 6, x + 3, y + 7, 0)
    line(x + 4, y + 6, x + 4, y + 7, 0)
    line(x + 6, y + 6, x + 6, y + 7, 0)
end

function draw_gameover()
    print("game over!", 40, 50, 7)
    if ufo.health <= 0 then
        print("ufo destroyed!", 35, 55, 8)
        print("farmer wins!", 40, 60, 11)
    else
        print("time's up!", 42, 55, 6)
        print("ufo victory!", 38, 60, 10)
    end
    print("final score: " .. score, 30, 65, 7)
    print("press Z to restart", 30, 75, 6)
    
    if btnp(5) then -- Z button
        _init()
    end
end

function update_ufo_death()
    ufo_death_timer -= 1
    
    -- update particles
    for particle in all(ufo.particles) do
        particle.x += particle.dx
        particle.y += particle.dy
        particle.life -= 1
        if particle.life <= 0 then
            del(ufo.particles, particle)
        end
    end
    
    if ufo_death_timer <= 0 then
        game_state = "gameover"
    end
end

function update_victory()
    victory_timer += 1
    
    -- UFO flies upward
    if victory_timer > 60 then
        victory_ufo_y -= 1.5
    end
    
    -- update particles
    for particle in all(ufo.particles) do
        particle.y += particle.dy
        particle.life -= 1
        if particle.life <= 0 then
            del(ufo.particles, particle)
        end
    end
end

function draw_ufo_death()
    -- draw explosion particles
    for particle in all(ufo.particles) do
        local col = particle.col
        if particle.life < 10 then col = 5 end
        circfill(particle.x, particle.y, 2, col)
    end
    
    -- draw defeat message
    if ufo_death_timer > 60 then
        local flash_col = 8
        if ufo_death_timer % 8 < 4 then flash_col = 2 end
        print("ufo destroyed!", 33, 40, flash_col)
        print("humanity survives!", 28, 48, 11)
    end
    
    if ufo_death_timer < 30 then
        print("final score: " .. score, 30, 60, 7)
        print("press Z to restart", 30, 70, 6)
        
        if btnp(5) then -- Z button
            _init()
        end
    end
end

function draw_victory()
    -- draw stars background
    for i = 1, 20 do
        local star_x = (i * 13) % 128
        local star_y = (i * 7 + victory_timer * 0.3) % 120
        pset(star_x, star_y, 7)
    end
    
    -- draw planet in distance
    if victory_timer > 120 then
        local planet_size = min(victory_timer - 120, 20)
        circfill(100, 30, planet_size, 3)
        circfill(98, 28, planet_size - 2, 11)
        -- planet rings
        if planet_size > 10 then
            oval(100 - planet_size - 5, 30 - 3, 100 + planet_size + 5, 30 + 3, 6)
        end
    end
    
    -- draw UFO flying away
    if victory_timer > 60 and victory_ufo_y > -20 then
        draw_ufo(ufo.x, victory_ufo_y)
        
        -- trail particles
        if victory_timer % 3 == 0 then
            add(ufo.particles, {
                x = ufo.x + 8,
                y = victory_ufo_y + 16,
                dy = 1,
                life = 20,
                col = 9
            })
        end
    end
    
    -- victory text
    if victory_timer < 180 then
        local flash_col = 10
        if victory_timer % 10 < 5 then flash_col = 9 end
        print("mission complete!", 30, 50, flash_col)
        print("ufo escapes to space!", 22, 58, 12)
        print("final score: " .. score, 30, 70, 7)
        
        -- show highscore info
        if new_highscore then
            local hs_col = 12
            if victory_timer % 6 < 3 then hs_col = 10 end
            print("new highscore!", 32, 78, hs_col)
        else
            print("highscore: " .. highscore, 32, 78, 6)
        end
    end
    
    if victory_timer > 3600 then -- 60 seconds at 60fps
        print("press Z to restart", 30, 90, 6)
        if btnp(5) then -- Z button
            _init()
        end
    end
end

__gfx__
00cccccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccc99cc99cccc000077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc9999999999cc007777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc99aa9999aa99cc77777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc99aa9999aa99cc77777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc999999999999cc77777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc99cc99cc99ccc77777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc07777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888888888888800000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888888888888888800066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888888888888000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888888888888000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888888888888000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888888888888000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888888888888888800d66d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088888888888880000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00100000105001c5002850035500455005650077500885009850078500675005750047500375002750027500175001750017500175001750017500175001750017500175001750017500175001750017500175
001000001c55024550285502a5502c5502e55030550315503155030550305502e5502c5502a55028550245501c5501855015550125500f5500c55009550065500355001550005500055000550005500055000550
00100000185501c5502055024550285502c5502e55030550325503455036550375503755036550345503255030550285502455020550185501455010550085500455001550005500055000550005500055000550
001000000c1500e1501015012150141501615018150191501a1501b1501c1501d1501e1501f1502015021150221502215022150215502155021550215502155021550215502155021550215502155021550
00100000301502c1502815024150201501c15018150141501115010150101500f1500e1500d1500c1500b1500a15009150081500715006150051500415003150021500115001150011500115001150011500115