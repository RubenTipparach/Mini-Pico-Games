pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- lander state
lander = {
    x = 64,        -- middle of screen
    y = 20,        -- starting high up
    vx = 0,        -- horizontal speed
    vy = 0,        -- vertical speed
    fuel = 100,    -- simple fuel system
    fuel_max = 100,

    angle = 0,     -- not used in this version
    w = 8,
    h = 8
}

gravity = 0.1
thrust = -0.2
max_safe_speed = 1.0
terrain = {}
landed = false
crashed = false
sfx_playing = false
landing_pads = {
    start = { x = 20, width = 16, y = 0 },
    goal  = { x = 90, width = 16, y = 0 }
}
local sprite_bottom_y = lander.y
local sprite_top_y = lander.y - 8
speed = 0

rocks = {}

function is_near_pad(x)
    for _, pad in pairs(landing_pads) do
        if x >= pad.x - 4 and x <= pad.x + pad.width + 4 then
            return true
        end
    end
    return false
end

function generate_rocks()
    rocks = {}
    for i = 1, 30 do
        local x
        repeat
            x = flr(rnd(128))
        until not is_near_pad(x)
        local y = terrain[x] - 1
        add(rocks, {x = x, y = y + 10, sprite = rnd(2) + 2})
    end
end

function generate_terrain()
    landing_pads.start.x = flr(rnd(30)) + 10
    landing_pads.goal.x  = flr(rnd(30)) + 80
    landing_pads.start.width = 16
    landing_pads.goal.width = 16
    local x1 = rnd(300)
    local x2= rnd(200)
    local x3 = rnd(300)
    for x = 0, 127 do

        local big = cos((x + x1)/200 ) * 30
        --local med = sin((x+ rnd(x1))/150 ) * 6
        --local small = sin((x+ rnd(x1))/100 ) * 2

        local med = sin((x + x2) / 50 ) * 4 + rnd(3)
        local small = sin((x + x3)/ 300 + rnd(3)) * 2

        terrain[x] = min(95 + big, 110) + med --+ small
    end

    -- flatten pads
    for _, pad in pairs(landing_pads) do
        local pad_y = terrain[pad.x]
        pad.y = pad_y
        for i = pad.x, pad.x + pad.width - 1 do
            terrain[i] = pad_y
        end
    end

    -- generate rocks
    generate_rocks()
end

function draw_flame()
    for i=1,5 do
        local fx = lander.x + rnd(2) - 1  -- center under feet
        local fy = lander.y + rnd(3)  -4   -- just below bottom
        pset(fx, fy, rnd({8, 9, 10}))     -- fire colors
    end
end

function draw_side_thrusters()
    local fy = lander.y - 8 + rnd(2)  -- mid-body vertical offset


    if btn(0) then
        -- moving left ヌ●★ gas right
        local fx = lander.x + 3
        pset(fx + rnd(4), fy, 7)  -- white
        pset(fx + rnd(4), fy, 7)  -- white

    end

    if btn(1) then
        -- moving right ヌ●★ gas left
        local fx = lander.x - 4
        pset(fx - rnd(4), fy, 7)  -- white
        pset(fx - rnd(4), fy, 7)  -- white

    end
end
function _init()
    generate_terrain()
end


function _init()
        -- clear all state
    terrain = {}
    lander = {}
    landed = false
    crashed = false
    has_taken_off = false
    sfx_playing = false

    generate_terrain()

    local s = landing_pads.start

    lander = {
        x = s.x + s.width / 2,
        y = s.y,
        vx = 0,
        vy = 0,
        fuel = 100,
        fuel_max = 100,
        w = 8,
        h = 8
    }

    palt(0, true)  -- make black (color 0) transparent

end

function _update()
        -- reset game if player presses ❎
    if btnp(5) then
        _init() 
    end
    
    if landed or crashed then return end

    lander.vy += gravity

    if (btn(4) and lander.fuel > 0) then
        lander.vy += thrust
        lander.fuel -= 1
        if not sfx_playing then sfx(1) sfx_playing = true end
        -- mark as taken off if lander has moved vertically or horizontally
        if not has_taken_off and (lander.vy < -0.01 or abs(lander.vx) > 0.01) then
            has_taken_off = true
        end
    else
        sfx_playing = false
    end

    if (btn(0)) lander.vx -= 0.05
    if (btn(1)) lander.vx += 0.05

    lander.x += lander.vx
    lander.y += lander.vy

    if lander.x < 0 then lander.x = 0 lander.vx = 0 end
    if lander.x > 120 then lander.x = 120 lander.vx = 0 end

    -- collision with terrain
    local tx = flr(lander.x)
    local terrain_y = terrain[tx] or 127
    local g = landing_pads.goal

    -- if lander.y + lander.h >= terrain_y then
    --     lander.y = terrain_y - lander.h
    speed = sqrt(lander.vx^2 + lander.vy^2)

    if lander.y >= terrain_y then
        lander.y = terrain_y

        local on_goal =
            lander.x >= landing_pads.goal.x and
            lander.x + lander.w <= landing_pads.goal.x + landing_pads.goal.width

        if abs(speed) <= max_safe_speed and on_goal then
            landed = true
        elseif has_taken_off  and abs(speed) > max_safe_speed then
            crashed = true
        end

        lander.vx = 0
        lander.vy = 0
    end


end

function _draw()
    cls()

    -- line(lander.x + 4, lander.y+3, lander.x + 4, lander.y - 10, 11) 
    -- line(lander.x -5, lander.y+3, lander.x -5, lander.y - 10, 9) 

    if not landed and not crashed then
        if btn(4) then draw_flame() end
        if btn(0) or btn(1) then draw_side_thrusters() end
    end
    -- draw lander
    spr(1, lander.x - 4, lander.y -10)


    -- draw red terrain
    for x=0,127 do
        line(x, terrain[x], x, 127, 8) -- red terrain
    end
    
    -- draw rocks
    for rock in all(rocks) do
        local c = rnd({6, 13, 5}) -- grays and browns
        spr(rock.sprite, rock.x, rock.y)
        --if rnd() < 0.5 then pset(rock.x+1, rock.y, c) end
        --if rnd() < 0.3 then pset(rock.x, rock.y+1, c) end
    end
    
    -- draw pads
    local start = landing_pads.start
    rectfill(start.x, start.y - 2, start.x + start.width, start.y, 5) -- gray pad

    local goal = landing_pads.goal
    rectfill(goal.x, goal.y - 2, goal.x + goal.width, goal.y, 10) -- gold pad

    -- UI
    --print("fuel: "..flr(lander.fuel), 1, 1, 7)
    print("fuel", 1, 1, 7)
    --print("lander " .. lander.y, 1, 16, 7)
    --print("pad " .. landing_pads.goal.y, 1, 32, 7)
    local safe = speed <= max_safe_speed
    local col = safe and 11 or 8
    print("spd: "..flr(speed * 100)/100, 1, 32, col)
    
    -- draw fuel bar background
    rect(1, 8, 33, 13, 5)
    local fuel_w = flr(lander.fuel / lander.fuel_max * 32)
    rectfill(2, 9, 1 + fuel_w, 12, 11)

    if landed then
        print("landed!", 50, 60, 11)
    elseif crashed then
        print("crashed!", 50, 60, 8)
    end

    print("❎ to reset", 90, 1, 6)

end



__gfx__
00000000000000000000000067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000dddd000670000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000dc7d006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000dccd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000d0000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000f650166501365010650126501765017650176501b6500f6500f6500f65015650106500e6501065014650156500d650146500d65014650106500e650106500e6500e6500e6500e6500f6501065014650
__music__
00 01424344

