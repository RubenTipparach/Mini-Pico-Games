pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- fishing game
-- by claude

function _init()
    -- game state
    gamestate = "playing"
    time = 0
    
    -- boat
    boat = {
        x = 64,
        y = 20,
        bobspeed = 0.5,
        boboffset = 0
    }
    
    -- fishing line
    hook = {
        x = boat.x,
        y = boat.y + 8,
        depth = 0,
        maxdepth = 80,
        casting = false,
        reeling = false
    }
    
    -- fish array
    fish = {}
    for i=1,8 do
        add(fish, {
            x = 20 + rnd(80),
            y = 50 + rnd(60),
            dir = rnd(1) > 0.5 and 1 or -1,
            speed = 0.2 + rnd(0.3),
            type = flr(rnd(3)),
            caught = false
        })
    end
    
    -- weather
    weather = {
        type = 0, -- 0=sunny, 1=cloudy, 2=rainy
        timer = 0,
        changetime = 300 + rnd(600)
    }
    
    -- rain drops
    raindrops = {}
    
    -- caught fish
    caughtfish = nil
    reelpower = 0
    reeltimer = 0
end

function _update()
    time += 1
    
    -- update boat bobbing (sync with blue wave line)
    local wave_y = 32 + sin((boat.x + time * 0.5) * 0.02) * 2
    boat.y = wave_y - 8  -- position boat on top of blue wave
    
    -- update weather
    update_weather()
    
    -- controls
    if gamestate == "playing" then
        update_boat()
        update_fishing()
        update_fish()
    elseif gamestate == "reeling" then
        update_reeling()
    end
end

function update_boat()
    -- boat movement
    if btn(⬅️) and boat.x > 10 then
        boat.x -= 1
    end
    if btn(➡️) and boat.x < 118 then
        boat.x += 1
    end
    
    -- update hook position when not cast
    if hook.depth == 0 then
        hook.x = boat.x
    end
end

function update_weather()
    weather.timer += 1
    
    if weather.timer > weather.changetime then
        weather.type = (weather.type + 1) % 3
        weather.timer = 0
        weather.changetime = 300 + rnd(600)
        
        -- clear rain if changing from rainy
        if weather.type != 2 then
            raindrops = {}
        end
    end
    
    -- add rain drops
    if weather.type == 2 and rnd(1) < 0.3 then
        add(raindrops, {
            x = rnd(128),
            y = -5,
            speed = 2 + rnd(2)
        })
    end
    
    -- update rain drops
    for drop in all(raindrops) do
        drop.y += drop.speed
        if drop.y > 128 then
            del(raindrops, drop)
        end
    end
end

function update_fishing()
    -- cast line
    if btnp(❎) and not hook.casting and hook.depth == 0 then
        hook.casting = true
    end
    
    -- extend line
    if hook.casting then
        hook.depth += 2
        hook.y = boat.y + 8 + hook.depth
        if hook.depth >= hook.maxdepth then
            hook.casting = false
        end
    end
    
    -- reel in line
    if btn(🅾️) and hook.depth > 0 and not hook.casting then
        hook.depth -= 1.5
        hook.y = boat.y + 8 + hook.depth
        if hook.depth <= 0 then
            hook.depth = 0
            hook.y = boat.y + 8
        end
    end
    
    -- check fish collision
    for f in all(fish) do
        if not f.caught and 
           abs(f.x - hook.x) < 6 and 
           abs(f.y - hook.y) < 6 and 
           hook.depth > 30 then
            f.caught = true
            caughtfish = f
            gamestate = "reeling"
            reelpower = 0
            reeltimer = 0
            sfx(0) -- fish caught sound
        end
    end
end

function update_fish()
    for f in all(fish) do
        if not f.caught then
            f.x += f.dir * f.speed
            
            -- bounce off edges
            if f.x < 8 or f.x > 120 then
                f.dir *= -1
            end
            
            -- subtle vertical movement
            f.y += sin(time * 0.3 + f.x * 0.1) * 0.1
        end
    end
end

function update_reeling()
    reeltimer += 1
    
    -- player must tap ❎ to build reel power
    if btnp(❎) then
        reelpower += 1
        sfx(1) -- reel sound
    end
    
    -- fish struggles (reduces reel power)
    if rnd(1) < 0.1 then
        reelpower = max(0, reelpower - 1)
    end
    
    -- success condition
    if reelpower >= 15 then
        del(fish, caughtfish)
        caughtfish = nil
        gamestate = "playing"
        hook.depth = 0
        hook.y = boat.y + 8
        sfx(2) -- success sound
    end
    
    -- failure condition
    if reeltimer > 300 then
        caughtfish.caught = false
        caughtfish = nil
        gamestate = "playing"
        hook.depth = 0
        hook.y = boat.y + 8
    end
end

function _draw()
    cls()
    
    -- draw background based on weather
    if weather.type == 0 then
        -- sunny
        fillp(0b0101010110101010)
        rectfill(0, 0, 127, 30, 12)
        fillp()
        circfill(100, 8, 6, 10)
    elseif weather.type == 1 then
        -- cloudy
        rectfill(0, 0, 127, 30, 13)
        circfill(20, 10, 8, 6)
        circfill(50, 8, 10, 6)
        circfill(90, 12, 7, 6)
    else
        -- rainy
        rectfill(0, 0, 127, 30, 5)
        circfill(30, 8, 12, 13)
        circfill(70, 6, 15, 13)
        circfill(110, 10, 8, 13)
    end
    
    -- draw waves
    draw_waves()
    
    -- draw boat
    spr(1, boat.x - 4, boat.y)
    
    -- draw fishing line
    if hook.depth > 0 then
        line(boat.x, boat.y + 8, hook.x, hook.y, 6)
        circfill(hook.x, hook.y, 1, 8)
    end
    
    -- draw fish as circles
    for f in all(fish) do
        if not f.caught then
            local colors = {8, 9, 10} -- red, orange, yellow
            circfill(f.x, f.y, 3, colors[f.type + 1])
            circfill(f.x, f.y, 2, 7) -- white center
        end
    end
    
    -- draw rain
    if weather.type == 2 then
        for drop in all(raindrops) do
            line(drop.x, drop.y, drop.x, drop.y + 3, 6)
        end
    end
    
    -- draw ui
    if gamestate == "reeling" then
        rectfill(10, 110, 118, 125, 0)
        rect(10, 110, 118, 125, 7)
        print("reel! press ❎", 15, 115, 7)
        
        -- power bar
        rectfill(15, 120, 15 + reelpower * 6, 123, 8)
        rect(14, 119, 105, 124, 7)
    else
        print("❎ to cast", 5, 5, 7)
        print("🅾️ to reel", 5, 12, 7)
        print("⬅️➡️ to move", 5, 19, 7)
    end
end

function draw_waves()
    -- water
    rectfill(0, 32, 127, 127, 1)
    
    -- wave animation (slower)
    for x=0,127,4 do
        local wave1 = 32 + sin((x + time * 0.5) * 0.02) * 2
        local wave2 = 34 + sin((x + time * 0.3) * 0.015) * 1.5
        line(x, wave1, x + 4, wave1, 12)
        line(x, wave2, x + 4, wave2, 6)
    end
end

__gfx__
00000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066600000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00677660000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06777776006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66777766948888490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660944444490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600099999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000008880000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800885588008300380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888888851158883033038000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000880000888800008888000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800888888008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000880000088000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080000008000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001000000c0500e050100501305016050190502205029050310500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000c0500c0500c0400c0300c0200c0200c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c010
000800002405028050300503605030050280502405020050180501605014050120501005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
