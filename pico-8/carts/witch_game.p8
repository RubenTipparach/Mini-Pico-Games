pico-8 cartridge
version 42
__lua__

-- witch pumpkin dodge game
-- by claude

function _init()
    -- witch player
    witch = {
        x = 20,
        y = 64,
        w = 6,
        h = 6,
        dy = 0,
        flying = true
    }
    
    -- obstacles arrays
    pumpkins = {}
    ghosts = {}
    potions = {}
    spells = {}
    
    -- game state
    score = 0
    game_over = false
    game_won = false
    scroll_x = 0
    spawn_timer = 0
    game_speed = 3
    spawn_rate = 45
    potion_timer = 0
    
    -- castle goal
    castle_distance = 3000
    distance_traveled = 0
    
    -- life system
    lives = 3
    hit_invincible = false
    hit_timer = 0
    
    -- spell system
    spell_cooldown = 0
    mana = 100
    max_mana = 100
    
    -- power-up states
    invincible = false
    invincible_timer = 0
    slow_time = false
    slow_timer = 0
    speed_boost = false
    speed_timer = 0
    
    -- ground level
    ground_y = 100
end

function _update60()
    if game_over or game_won then
        if btnp(4) then
            _init()
        end
        return
    end
    
    -- scroll background (increases with score, affected by slow time)
    local base_speed = 1.5 + flr(score/500)
    if speed_boost then
        game_speed = base_speed * 1.2
    elseif slow_time then
        game_speed = base_speed * 0.3
    else
        game_speed = base_speed
    end
    spawn_rate = max(20, 45 - flr(score/200))
    scroll_x += game_speed
    
    -- witch controls and spells
    update_witch()
    update_spells()
    
    -- spell casting
    if btnp(5) and spell_cooldown <= 0 and mana >= 20 then
        cast_spell()
    end
    
    -- update spell cooldown and mana
    if spell_cooldown > 0 then
        spell_cooldown -= 1
    end
    
    -- regenerate mana
    if mana < max_mana then
        mana += 0.5
    end
    
    -- spawn obstacles (pumpkins and ghosts)
    spawn_timer += 1
    if spawn_timer > spawn_rate then
        if rnd(1) < 0.6 then
            spawn_pumpkin()
        else
            spawn_ghost()
        end
        -- chance for extra obstacles
        if rnd(1) < 0.3 + score/1000 then
            if rnd(1) < 0.5 then
                spawn_pumpkin_delayed()
            else
                spawn_ghost_delayed()
            end
        end
        spawn_timer = 0
    end
    
    -- spawn potions occasionally
    potion_timer += 1
    if potion_timer > 300 + rnd(200) then
        spawn_potion()
        potion_timer = 0
    end
    
    -- update obstacles and potions
    update_pumpkins()
    update_ghosts()
    update_potions()
    
    -- check collisions
    if not invincible and not hit_invincible then
        check_pumpkin_collisions()
        check_ghost_collisions()
    end
    check_potion_collisions()
    check_spell_collisions()
    
    -- update power-up timers and hit invincibility
    update_powerups()
    update_hit_system()
    
    -- increase score and track distance
    score += 1
    distance_traveled += game_speed
    
    -- check if reached castle
    if distance_traveled >= castle_distance then
        game_won = true
    end
end

function update_witch()
    -- slower flying controls
    if btn(2) then -- up arrow
        witch.dy -= 0.25
    elseif btn(3) then -- down arrow
        witch.dy += 0.25
    end
    
    -- reduced gravity
    witch.dy += 0.1
    
    -- more friction for better control
    witch.dy *= 0.92
    
    -- limit speed (reduced max speed)
    witch.dy = mid(-2, witch.dy, 2)
    
    witch.y += witch.dy
    
    -- tighter screen bounds
    if witch.y < 4 then
        witch.y = 4
        witch.dy = 0
    elseif witch.y > ground_y - witch.h - 4 then
        witch.y = ground_y - witch.h - 4
        witch.dy = 0
    end
end

function spawn_pumpkin()
    local pumpkin_y = rnd(5) -- more height variations
    if pumpkin_y < 1 then
        pumpkin_y = ground_y - 8 -- ground level
    elseif pumpkin_y < 2 then
        pumpkin_y = ground_y - 20 -- low air
    elseif pumpkin_y < 3 then
        pumpkin_y = ground_y - 35 -- mid air
    elseif pumpkin_y < 4 then
        pumpkin_y = ground_y - 50 -- high air
    else
        pumpkin_y = ground_y - 65 -- very high
    end
    
    local pumpkin = {
        x = 128 + rnd(20),
        y = pumpkin_y,
        w = 6 + rnd(4),
        h = 6 + rnd(4),
        speed = game_speed * 0.6 + rnd(0.5)
    }
    add(pumpkins, pumpkin)
end

function spawn_pumpkin_delayed()
    local pumpkin = {
        x = 150 + rnd(30),
        y = 15 + rnd(70),
        w = 8,
        h = 8,
        speed = game_speed * 0.7
    }
    add(pumpkins, pumpkin)
end

function spawn_ghost()
    local ghost = {
        x = 128 + rnd(20),
        y = 20 + rnd(60),
        w = 8,
        h = 10,
        speed = game_speed * 0.4,
        float_timer = rnd(60),
        dy = 0
    }
    add(ghosts, ghost)
end

function spawn_ghost_delayed()
    local ghost = {
        x = 160 + rnd(40),
        y = 25 + rnd(50),
        w = 8,
        h = 10,
        speed = game_speed * 0.5,
        float_timer = rnd(60),
        dy = 0
    }
    add(ghosts, ghost)
end

function update_pumpkins()
    for p in all(pumpkins) do
        p.x -= p.speed or game_speed
        if p.x < -12 then
            del(pumpkins, p)
        end
    end
end

function update_ghosts()
    for g in all(ghosts) do
        g.x -= g.speed
        
        -- floating movement
        g.float_timer += 1
        g.dy = sin(g.float_timer / 20) * 0.5
        g.y += g.dy
        
        if g.x < -12 then
            del(ghosts, g)
        end
    end
end

function check_pumpkin_collisions()
    for p in all(pumpkins) do
        if witch.x < p.x + p.w and
           witch.x + witch.w > p.x and
           witch.y < p.y + p.h and
           witch.y + witch.h > p.y then
            take_damage()
            return
        end
    end
end

function check_ghost_collisions()
    for g in all(ghosts) do
        if witch.x < g.x + g.w and
           witch.x + witch.w > g.x and
           witch.y < g.y + g.h and
           witch.y + witch.h > g.y then
            take_damage()
            return
        end
    end
end

function spawn_potion()
    local potion_type = flr(rnd(3)) -- 0=invincible, 1=slow, 2=speed
    local potion = {
        x = 128 + rnd(40),
        y = 25 + rnd(50),
        w = 6,
        h = 8,
        type = potion_type,
        bob_timer = rnd(60)
    }
    add(potions, potion)
end

function update_potions()
    for p in all(potions) do
        p.x -= game_speed * 0.3
        p.bob_timer += 1
        p.y += sin(p.bob_timer / 15) * 0.3
        
        if p.x < -8 then
            del(potions, p)
        end
    end
end

function check_potion_collisions()
    for p in all(potions) do
        if witch.x < p.x + p.w and
           witch.x + witch.w > p.x and
           witch.y < p.y + p.h and
           witch.y + witch.h > p.y then
            
            -- activate power-up based on type
            if p.type == 0 then -- invincible
                invincible = true
                invincible_timer = 240 -- 4 seconds
            elseif p.type == 1 then -- slow time
                slow_time = true
                slow_timer = 300 -- 5 seconds
            elseif p.type == 2 then -- speed boost
                speed_boost = true
                speed_timer = 180 -- 3 seconds
            end
            
            del(potions, p)
            score += 300 -- bonus points
        end
    end
end

function take_damage()
    lives -= 1
    hit_invincible = true
    hit_timer = 120 -- 2 seconds of invincibility
    
    if lives <= 0 then
        game_over = true
    end
end

function update_hit_system()
    if hit_invincible then
        hit_timer -= 1
        if hit_timer <= 0 then
            hit_invincible = false
        end
    end
end

function cast_spell()
    local spell = {
        x = witch.x + witch.w,
        y = witch.y + witch.h / 2,
        w = 4,
        h = 2,
        speed = 4,
        life = 60
    }
    add(spells, spell)
    
    mana -= 20
    spell_cooldown = 20
end

function update_spells()
    for s in all(spells) do
        s.x += s.speed
        s.life -= 1
        
        if s.x > 128 or s.life <= 0 then
            del(spells, s)
        end
    end
end

function check_spell_collisions()
    for s in all(spells) do
        -- check spell vs pumpkins
        for p in all(pumpkins) do
            if s.x < p.x + p.w and
               s.x + s.w > p.x and
               s.y < p.y + p.h and
               s.y + s.h > p.y then
                del(spells, s)
                del(pumpkins, p)
                score += 50
                return
            end
        end
        
        -- check spell vs ghosts
        for g in all(ghosts) do
            if s.x < g.x + g.w and
               s.x + s.w > g.x and
               s.y < g.y + g.h and
               s.y + s.h > g.y then
                del(spells, s)
                del(ghosts, g)
                score += 75
                return
            end
        end
    end
end

function update_powerups()
    -- invincibility timer
    if invincible then
        invincible_timer -= 1
        if invincible_timer <= 0 then
            invincible = false
        end
    end
    
    -- slow time timer
    if slow_time then
        slow_timer -= 1
        if slow_timer <= 0 then
            slow_time = false
        end
    end
    
    -- speed boost timer
    if speed_boost then
        speed_timer -= 1
        if speed_timer <= 0 then
            speed_boost = false
        end
    end
end

function _draw()
    cls(1) -- dark blue sky
    
    -- draw scrolling ground
    for i = 0, 16 do
        local x = (i * 8 - scroll_x % 8)
        rectfill(x, ground_y, x + 8, 128, 3) -- green ground
    end
    
    -- draw witch
    draw_witch()
    
    -- draw obstacles
    for p in all(pumpkins) do
        draw_pumpkin(p.x, p.y)
    end
    
    for g in all(ghosts) do
        draw_ghost(g.x, g.y, g.float_timer)
    end
    
    for p in all(potions) do
        draw_potion(p.x, p.y, p.type, p.bob_timer)
    end
    
    for s in all(spells) do
        draw_spell(s.x, s.y, s.life)
    end
    
    -- draw ui (compact)
    print("sc:" .. flr(score/60), 1, 1, 7)
    print("sp:" .. game_speed, 1, 7, 7)
    
    -- distance to castle
    local remaining = castle_distance - distance_traveled
    local progress = distance_traveled / castle_distance
    print("to castle:" .. flr(remaining/100), 1, 37, 7)
    
    -- progress bar
    rect(90, 2, 126, 6, 7) -- border
    local bar_width = progress * 34
    rectfill(91, 3, 91 + bar_width, 5, 11) -- green progress
    
    -- lives display
    print("♥", 1, 13, 8) -- red hearts
    print("x" .. lives, 8, 13, 7)
    
    -- mana display
    print("mp:", 1, 19, 7)
    rect(15, 19, 50, 22, 7) -- mana bar border
    local mana_width = (mana / max_mana) * 33
    rectfill(16, 20, 16 + mana_width, 21, 12) -- blue mana bar
    
    -- spell instructions
    print("z:spell", 1, 25, 6)
    
    -- power-up indicators
    if invincible then
        print("invuln!", 1, 31, 10)
    elseif slow_time then
        print("slow!", 1, 31, 11)
    elseif speed_boost then
        print("fast!", 1, 31, 9)
    end
    
    -- draw castle when close
    if remaining < 500 then
        draw_castle()
    end
    
    if game_over then
        rectfill(20, 50, 108, 80, 0)
        rect(20, 50, 108, 80, 7)
        print("game over!", 40, 55, 7)
        print("final score: " .. flr(score/60), 35, 65, 7)
        print("press x to restart", 25, 75, 7)
    elseif game_won then
        rectfill(15, 45, 113, 85, 0)
        rect(15, 45, 113, 85, 7)
        print("you reached the", 30, 50, 7)
        print("witch's castle!", 32, 58, 11)
        print("final score: " .. flr(score/60), 35, 66, 7)
        print("press x to restart", 25, 76, 7)
    end
end

function draw_witch()
    -- witch outline for clarity (flashing when invincible or hit)
    local outline_color = 0
    if invincible and (invincible_timer % 10 < 5) then
        outline_color = 10 -- flash white when invincible
    elseif hit_invincible and (hit_timer % 8 < 4) then
        outline_color = 8 -- flash red when hit
    end
    circfill(witch.x + 3, witch.y + 2, 3, outline_color) -- black outline
    
    -- witch hat (high contrast)
    circfill(witch.x + 3, witch.y - 1, 3, 0) -- black hat base
    line(witch.x + 2, witch.y + 1, witch.x + 7, witch.y - 4, 0) -- hat cone
    pset(witch.x + 8, witch.y - 5, 7) -- bright white hat tip
    rect(witch.x + 1, witch.y + 1, witch.x + 6, witch.y + 2, 0) -- hat brim
    
    -- witch face (high contrast)
    circfill(witch.x + 3, witch.y + 2, 2, 7) -- bright white face
    rect(witch.x + 2, witch.y + 1, witch.x + 2, witch.y + 2, 0) -- left eye
    rect(witch.x + 4, witch.y + 1, witch.x + 4, witch.y + 2, 0) -- right eye
    pset(witch.x + 3, witch.y + 3, 8) -- red nose
    line(witch.x + 2, witch.y + 4, witch.x + 4, witch.y + 4, 0) -- black mouth
    
    -- witch hair (more visible)
    pset(witch.x + 1, witch.y, 4) -- brown hair strand
    pset(witch.x + 5, witch.y, 4) -- brown hair strand
    pset(witch.x, witch.y + 1, 4) -- more hair
    
    -- witch robe (brighter color)
    circfill(witch.x + 3, witch.y + 5, 3, 2) -- purple robe
    rect(witch.x + 1, witch.y + 4, witch.x + 5, witch.y + 7, 2) -- robe body
    rect(witch.x + 1, witch.y + 4, witch.x + 5, witch.y + 5, 13) -- robe collar (pink)
    
    -- witch arms (more visible)
    circfill(witch.x, witch.y + 5, 1, 7) -- left arm
    circfill(witch.x + 6, witch.y + 5, 1, 7) -- right arm
    
    -- broom (high contrast)
    line(witch.x - 3, witch.y + 7, witch.x + 1, witch.y + 5, 4) -- brown handle
    rect(witch.x - 4, witch.y + 6, witch.x - 2, witch.y + 8, 9) -- orange bristles
    pset(witch.x - 5, witch.y + 7, 9) -- extra bristle
    pset(witch.x - 4, witch.y + 9, 9) -- extra bristle
    pset(witch.x - 3, witch.y + 9, 9) -- extra bristle
    pset(witch.x - 2, witch.y + 9, 9) -- extra bristle
    pset(witch.x - 1, witch.y + 8, 9) -- extra bristle
end

function draw_pumpkin(x, y)
    -- pumpkin body
    circfill(x + 4, y + 4, 4, 9) -- orange
    
    -- pumpkin lines
    line(x + 1, y + 2, x + 1, y + 6, 8) -- left line
    line(x + 4, y + 1, x + 4, y + 7, 8) -- middle line
    line(x + 7, y + 2, x + 7, y + 6, 8) -- right line
    
    -- pumpkin stem
    rect(x + 3, y, x + 5, y + 1, 3) -- green stem
    
    -- pumpkin face
    pset(x + 2, y + 3, 0) -- left eye
    pset(x + 6, y + 3, 0) -- right eye
    line(x + 2, y + 5, x + 6, y + 5, 0) -- mouth
end

function draw_ghost(x, y, timer)
    -- ghost body (wavy bottom)
    circfill(x + 4, y + 3, 4, 7) -- white body
    rect(x, y + 3, x + 8, y + 7, 7) -- body rectangle
    
    -- wavy bottom edge
    local wave = sin(timer / 10) * 0.5
    for i = 0, 7 do
        local wave_y = y + 7 + sin((timer + i * 8) / 15) * 1
        pset(x + i, wave_y, 7)
    end
    
    -- ghost face
    circfill(x + 2, y + 2, 1, 0) -- left eye
    circfill(x + 6, y + 2, 1, 0) -- right eye
    oval(x + 3, y + 4, x + 5, y + 5, 0) -- mouth
    
    -- ghost transparency effect
    if timer % 30 < 15 then
        -- semi-transparent by drawing fewer pixels
        for px = x, x + 8 do
            for py = y, y + 8 do
                if (px + py) % 3 == 0 and pget(px, py) == 7 then
                    pset(px, py, 6) -- lighter shade
                end
            end
        end
    end
end

function draw_potion(x, y, type, timer)
    -- potion bottle base
    rect(x + 2, y + 3, x + 4, y + 7, 5) -- grey bottle
    
    -- potion liquid (different colors by type)
    local liquid_color = 8 -- default red
    if type == 0 then -- invincible
        liquid_color = 10 -- yellow
    elseif type == 1 then -- slow time
        liquid_color = 12 -- blue
    elseif type == 2 then -- speed boost
        liquid_color = 11 -- green
    end
    
    rect(x + 2, y + 4, x + 4, y + 6, liquid_color)
    
    -- bottle neck
    rect(x + 2, y + 2, x + 4, y + 3, 5)
    
    -- cork
    pset(x + 3, y + 1, 4) -- brown cork
    
    -- sparkle effect
    if timer % 20 < 10 then
        pset(x + 1, y + 2, 7) -- left sparkle
        pset(x + 5, y + 4, 7) -- right sparkle
    end
    
    -- label based on type
    if type == 0 then
        pset(x + 3, y + 5, 7) -- invincible symbol
    elseif type == 1 then
        line(x + 2, y + 5, x + 4, y + 5, 7) -- slow symbol
    elseif type == 2 then
        pset(x + 2, y + 5, 7) -- speed symbol
        pset(x + 4, y + 5, 7)
    end
end

function draw_spell(x, y, life)
    -- spell projectile core
    circfill(x + 2, y + 1, 1, 10) -- bright yellow core
    
    -- magical sparkles around it
    local sparkle_offset = sin(life / 5) * 2
    pset(x + sparkle_offset, y, 9) -- orange sparkle
    pset(x + 4 - sparkle_offset, y + 2, 9) -- orange sparkle
    pset(x + 2, y - 1 + sparkle_offset, 7) -- white sparkle
    pset(x + 2, y + 3 - sparkle_offset, 7) -- white sparkle
    
    -- trailing effect
    if life % 3 == 0 then
        pset(x - 1, y + 1, 10) -- yellow trail
    end
    if life % 4 == 0 then
        pset(x - 2, y + 1, 9) -- orange trail
    end
end

function draw_castle()
    -- castle is stationary at x=110, appears when close
    local castle_x = 110
    
    -- castle base
    rectfill(castle_x, ground_y - 30, castle_x + 20, ground_y, 5) -- grey walls
    
    -- castle towers
    rectfill(castle_x - 2, ground_y - 40, castle_x + 4, ground_y - 30, 5) -- left tower
    rectfill(castle_x + 16, ground_y - 40, castle_x + 22, ground_y - 30, 5) -- right tower
    rectfill(castle_x + 7, ground_y - 45, castle_x + 13, ground_y - 30, 5) -- center tower
    
    -- castle details
    rect(castle_x + 8, ground_y - 20, castle_x + 12, ground_y - 10, 0) -- door
    rectfill(castle_x + 8, ground_y - 20, castle_x + 12, ground_y - 10, 4) -- brown door
    
    -- windows
    pset(castle_x + 2, ground_y - 35, 0) -- left tower window
    pset(castle_x + 18, ground_y - 35, 0) -- right tower window
    pset(castle_x + 10, ground_y - 40, 0) -- center tower window
    
    -- flags
    pset(castle_x + 1, ground_y - 42, 8) -- left flag
    pset(castle_x + 19, ground_y - 42, 8) -- right flag
    pset(castle_x + 10, ground_y - 47, 8) -- center flag
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000