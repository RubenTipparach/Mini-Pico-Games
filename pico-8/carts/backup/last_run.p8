pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- Pixar Platformer Iteration 2
-- Enhanced Disney Pixar character with improved squash/stretch
-- More expressive 4-frame animations with personality

function _init()
    -- Player properties
    p = {
        x = 32, y = 88,
        w = 8, h = 8,
        dx = 0, dy = 0,
        max_dx = 2.2,
        acc = 0.45,
        friction = 0.85,
        jump_power = -4.8,
        gravity = 0.32,
        on_ground = false,
        
        -- Enhanced animation system
        anim_frame = 0,
        anim_timer = 0,
        state = "idle",
        facing = 1,
        
        -- Disney character personality
        bounce_offset = 0,
        squash_stretch = 1,
        blink_timer = 0,
        emotion_timer = 0,
        land_squash = 0
    }
    
    -- Camera with improved follow
    cam_x = 0
    
    -- Enhanced platformer level
    platforms = {
        {x=0, y=120, w=128, h=8},      -- ground
        {x=150, y=100, w=40, h=8},     -- platform 1  
        {x=230, y=75, w=35, h=8},      -- platform 2
        {x=320, y=55, w=40, h=8},      -- platform 3
        {x=420, y=85, w=50, h=8},      -- platform 4
        {x=520, y=105, w=60, h=8},     -- platform 5
        {x=620, y=95, w=45, h=8},      -- platform 6
    }
    
    -- Particle system for landing effects
    particles = {}
end

function _update()
    handle_input()
    update_physics()
    update_animation()
    update_camera()
    update_personality()
    update_particles()
end

function handle_input()
    local input_dx = 0
    
    if btn(0) then -- left arrow
        input_dx = -1
        p.facing = -1
    elseif btn(1) then -- right arrow
        input_dx = 1
        p.facing = 1
    end
    
    -- Enhanced movement with better feel
    p.dx = p.dx + input_dx * p.acc
    
    if input_dx == 0 then
        p.dx = p.dx * p.friction
    end
    
    p.dx = mid(-p.max_dx, p.dx, p.max_dx)
    
    -- Enhanced jump with anticipation
    if btnp(4) and p.on_ground then
        p.dy = p.jump_power
        p.on_ground = false
        p.squash_stretch = 1.3 -- Jump stretch
        p.emotion_timer = 10
    end
end

function update_physics()
    p.x = p.x + p.dx
    p.dy = p.dy + p.gravity
    p.y = p.y + p.dy
    
    local was_on_ground = p.on_ground
    p.on_ground = false
    
    for platform in all(platforms) do
        if p.x < platform.x + platform.w and
           p.x + p.w > platform.x and
           p.y < platform.y + platform.h and
           p.y + p.h > platform.y then
            
            if p.dy > 0 and p.y < platform.y then
                p.y = platform.y - p.h
                p.dy = 0
                p.on_ground = true
                
                -- Landing effect
                if not was_on_ground then
                    p.land_squash = 8
                    p.squash_stretch = 0.7 -- Landing squash
                    create_landing_particles()
                end
            end
        end
    end
    
    if p.x < 0 then p.x = 0 end
    if p.y > 128 then 
        p.y = 88
        p.x = 32
        p.dy = 0
    end
end

function update_animation()
    p.anim_timer = p.anim_timer + 1
    
    -- Enhanced state determination
    if not p.on_ground then
        if p.dy < -1 then
            p.state = "jump"
        else
            p.state = "fall"
        end
    elseif abs(p.dx) > 0.3 then
        p.state = "run"
    else
        p.state = "idle"
    end
    
    -- Improved animation timing for 4 frames
    if p.state == "run" then
        if p.anim_timer % 6 == 0 then -- Faster for energy
            p.anim_frame = (p.anim_frame + 1) % 4
        end
    elseif p.state == "idle" then
        if p.anim_timer % 12 == 0 then -- More lively idle
            p.anim_frame = (p.anim_frame + 1) % 4
        end
    else
        p.anim_frame = 0
    end
end

function update_personality()
    -- Enhanced idle bounce with breathing
    if p.state == "idle" then
        p.bounce_offset = sin(time() * 2.5) * 0.8 + sin(time() * 4) * 0.3
    else
        p.bounce_offset = 0
    end
    
    -- Squash and stretch decay
    p.squash_stretch = p.squash_stretch + (1 - p.squash_stretch) * 0.2
    
    -- Landing squash decay
    if p.land_squash > 0 then
        p.land_squash = p.land_squash - 1
    end
    
    -- Enhanced blinking
    p.blink_timer = p.blink_timer - 1
    if p.blink_timer <= 0 and rnd(120) < 3 then
        p.blink_timer = 4
    end
    
    -- Emotion timer
    if p.emotion_timer > 0 then
        p.emotion_timer = p.emotion_timer - 1
    end
end

function update_particles()
    for i = #particles, 1, -1 do
        local part = particles[i]
        part.x = part.x + part.dx
        part.y = part.y + part.dy
        part.dy = part.dy + 0.1 -- gravity
        part.life = part.life - 1
        
        if part.life <= 0 then
            del(particles, part)
        end
    end
end

function create_landing_particles()
    for i = 1, 4 do
        add(particles, {
            x = p.x + rnd(8),
            y = p.y + 8,
            dx = (rnd(2) - 1) * 0.8,
            dy = -rnd(1.5),
            life = 15 + rnd(10),
            col = 7
        })
    end
end

function update_camera()
    local target_x = p.x - 64
    cam_x = cam_x + (target_x - cam_x) * 0.15 -- Slightly faster follow
    cam_x = max(0, cam_x)
    camera(cam_x, 0)
end

function _draw()
    cls(12)
    
    draw_background()
    draw_platforms()
    draw_particles()
    draw_player()
    draw_ui()
end

function draw_background()
    -- Enhanced gradient sky
    for y = 0, 60 do
        local c = 12
        if y > 25 then c = 13 end
        if y > 45 then c = 1 end
        line(cam_x, y, cam_x + 128, y, c)
    end
    
    -- More dynamic clouds
    for i = 1, 5 do
        local cloud_x = (i * 90 + sin(time() * 0.4 + i) * 25) - cam_x * 0.6
        local cloud_y = 15 + sin(time() * 0.3 + i * 1.8) * 10
        
        -- Fluffier cloud shapes
        circfill(cloud_x, cloud_y, 14, 7)
        circfill(cloud_x + 12, cloud_y + 5, 11, 7)
        circfill(cloud_x - 10, cloud_y + 6, 9, 7)
        circfill(cloud_x + 5, cloud_y - 4, 10, 7)
        circfill(cloud_x - 3, cloud_y - 2, 8, 7)
    end
end

function draw_platforms()
    for platform in all(platforms) do
        -- Enhanced grass platforms
        rectfill(platform.x, platform.y, 
                platform.x + platform.w - 1, platform.y + platform.h - 1, 3)
        
        if platform.h > 3 then
            rectfill(platform.x, platform.y + 3, 
                    platform.x + platform.w - 1, platform.y + platform.h - 1, 4)
        end
        
        -- Better grass texture
        for i = 0, platform.w - 1, 3 do
            if rnd(3) < 2 then
                pset(platform.x + i, platform.y, 11)
                if rnd(2) < 1 then
                    pset(platform.x + i + 1, platform.y - 1, 11)
                end
            end
        end
        
        -- Platform highlights
        line(platform.x, platform.y, platform.x + platform.w - 1, platform.y, 11)
        line(platform.x, platform.y, platform.x, platform.y + platform.h - 1, 1)
        line(platform.x + platform.w - 1, platform.y, platform.x + platform.w - 1, platform.y + platform.h - 1, 1)
    end
end

function draw_particles()
    for part in all(particles) do
        local alpha = part.life / 25
        if alpha > 0.3 then
            pset(part.x, part.y, part.col)
        end
    end
end

function draw_player()
    local sprite_id = get_player_sprite()
    local flip_x = p.facing == -1
    local draw_y = p.y + p.bounce_offset - p.land_squash * 0.5
    
    -- Apply squash and stretch visual effect
    if p.squash_stretch != 1 then
        -- This is a visual representation - actual sprite scaling limited in PICO-8
        draw_y = draw_y + (1 - p.squash_stretch) * 2
    end
    
    spr(sprite_id, p.x, draw_y, 1, 1, flip_x)
    
    -- Enhanced eye expressions
    if p.blink_timer > 0 then
        local eye_x = p.facing == 1 and p.x + 2 or p.x + 5
        line(eye_x, draw_y + 2, eye_x + 1, draw_y + 2, 0)
    elseif p.emotion_timer > 0 then
        -- Happy eyes when jumping
        local eye_x = p.facing == 1 and p.x + 2 or p.x + 5
        pset(eye_x, draw_y + 1, 0)
        pset(eye_x + 1, draw_y + 1, 0)
    end
    
    -- Enhanced shadow with squash effect
    if p.on_ground then
        local shadow_w = 6 + p.land_squash * 0.3
        oval(p.x + 4 - shadow_w/2, p.y + 8, p.x + 4 + shadow_w/2, p.y + 9, 0)
    end
end

function get_player_sprite()
    if p.state == "idle" then
        return 1 + p.anim_frame -- Sprites 1-4: enhanced idle
    elseif p.state == "run" then
        return 5 + p.anim_frame -- Sprites 5-8: dynamic run
    elseif p.state == "jump" then
        return 9 -- Sprite 9: jump with anticipation
    else -- fall
        return 10 -- Sprite 10: fall with worry
    end
end

function draw_ui()
    camera(0, 0)
    print("pixar platformer v2", 2, 2, 7)
    print("squash & stretch", 2, 8, 6)
    print("arrows: move  x: jump", 2, 122, 6)
    camera(cam_x, 0)
end

__gfx__
00088000008880000888800000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088a8000888a8000888a8000888a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088aaa80888aaaa8888aaaa8888aaaa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88aaaaaa8aaaaaa88aaaaaa88aaaaaa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa88aa8aaa99aa8aaa00aa8aaa88aa8a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8aaaaaa88aaaaaa88aaaaaa88aaaaaa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088ffff8088ffff8088ffff8088ffff8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888000008880000088800000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088aa800888aaa80888aa880888aaa80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88aaaaa888aaaaa888aaaaa888aaaaa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa99aa8aaa88aa8aaa99aa8aaa88aa8a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8aaaaaa88aaaaaa88aaaaaa88aaaaaa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088fff808888f8808f88f88088eff880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008888000888880008888800088aa800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008800000f00f000088f00000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088aa800888aaaa80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88aaaaa888aaaaa80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa88aa8aaa99aa8a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8aaaaaa88aaaaaa80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088ffff8088fff880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008aaf00088aa8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f00f0008ff80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
