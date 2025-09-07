pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- dog grooming game
-- by claude

game_state = "grooming"
score = 0

dog = {
 x = 64,
 y = 90,
 dirty = 8,
 wet = 0,
 brushed = 0,
 happy = 5
}

tools = {
 current = 1,
 names = {"brush", "shampoo", "dryer"},
 icons = {1, 2, 3}
}

cursor = {
 x = 64,
 y = 70
}

particles = {}
bubbles = {}
timer = 0

function _init()
 cls()
end

function _update()
 timer += 1
 
 if game_state == "grooming" then
  -- cursor movement
  if btn(0) then cursor.x -= 1 end
  if btn(1) then cursor.x += 1 end
  if btn(2) then cursor.y -= 1 end
  if btn(3) then cursor.y += 1 end
  
  -- keep cursor on screen
  cursor.x = mid(8, cursor.x, 120)
  cursor.y = mid(25, cursor.y, 110)
  
  -- tool selection
  if btnp(4) then
   tools.current = tools.current % 3 + 1
  end
  
  -- use tool
  if btn(5) then
   use_tool()
  end
 end
 
 -- update particles
 for p in all(particles) do
  p.y -= p.dy
  p.x += p.dx
  p.life -= 1
  if p.life <= 0 then
   del(particles, p)
  end
 end
 
 -- update bubbles
 for b in all(bubbles) do
  b.y -= b.dy
  b.x += sin(b.t) * 0.5
  b.t += 0.1
  b.life -= 1
  if b.life <= 0 then
   del(bubbles, b)
  end
 end
 
 -- dog happiness
 local old_happy = dog.happy
 if dog.dirty <= 2 and dog.wet <= 1 and dog.brushed >= 7 then
  dog.happy = min(10, dog.happy + 0.2)
 elseif dog.dirty >= 6 then
  dog.happy = max(0, dog.happy - 0.1)
 elseif dog.wet >= 8 then
  dog.happy = max(0, dog.happy - 0.05)
 elseif dog.dirty <= 5 and dog.wet <= 5 then
  dog.happy = min(10, dog.happy + 0.05)
 end
 
 -- bonus points for making dog happy
 if dog.happy > old_happy and dog.happy >= 8 then
  score += 25
 end
end

function _draw()
 cls(12)
 draw_grooming_scene()
end

function draw_grooming_scene()
 -- background
 rectfill(0, 96, 127, 127, 3)
 
 -- bathtub
 -- tub base and shadow
 rectfill(25, 80, 103, 120, 5)
 -- main tub body
 rectfill(28, 78, 100, 118, 6)
 -- inner tub
 rectfill(30, 80, 98, 116, 7)
 -- tub rim highlight
 rectfill(30, 78, 98, 82, 7)
 line(30, 79, 98, 79, 6)
 
 -- rounded corners for softer look
 pset(30, 80, 6)
 pset(98, 80, 6)
 pset(30, 116, 6)
 pset(98, 116, 6)
 
 -- drain
 circfill(64, 112, 2, 5)
 circfill(64, 112, 1, 1)
 
 -- water level
 if dog.wet > 3 then
  local water_level = 88 + (dog.wet * 2)
  rectfill(32, water_level, 96, 114, 12)
  rectfill(32, water_level, 96, water_level + 2, 1)
  -- water ripples
  for i=1,4 do
   local ripple_x = 40 + i*12
   line(ripple_x, water_level + sin(timer/6 + i) * 1, ripple_x + 8, water_level + sin(timer/6 + i) * 1, 1)
  end
  -- water bubbles on surface
  for i=1,3 do
   local bx = 45 + i*15 + sin(timer/10 + i) * 3
   circfill(bx, water_level - 1, 1, 7)
  end
 end
 
 -- faucet assembly
 -- faucet base
 rectfill(42, 65, 86, 75, 6)
 rectfill(43, 66, 85, 74, 7)
 -- faucet spout
 rectfill(58, 70, 70, 78, 6)
 rectfill(59, 71, 69, 77, 7)
 line(70, 74, 75, 78, 6)
 line(70, 75, 75, 79, 7)
 -- spout end
 circfill(75, 78, 2, 6)
 circfill(75, 78, 1, 7)
 
 -- hot/cold handles
 circfill(48, 70, 3, 6)
 circfill(48, 70, 2, 7)
 print("h", 46, 68, 8)
 circfill(80, 70, 3, 6)
 circfill(80, 70, 2, 7)
 print("c", 78, 68, 12)
 
 -- tub feet
 rectfill(32, 116, 38, 122, 6)
 rectfill(33, 117, 37, 121, 7)
 rectfill(90, 116, 96, 122, 6)
 rectfill(91, 117, 95, 121, 7)
 
 -- draw dog
 draw_dog()
 
 -- draw particles
 for p in all(particles) do
  pset(p.x, p.y, p.col)
 end
 
 -- draw bubbles
 for b in all(bubbles) do
  circfill(b.x, b.y, b.size, 12)
  circfill(b.x, b.y, b.size-1, 7)
  pset(b.x-1, b.y-1, 7)
 end
 
 -- draw ui
 draw_ui()
 
 -- draw cursor range indicator
 if btn(5) then
  circ(cursor.x, cursor.y, 25, 5)
 end
end


function draw_dog()
 -- adjust color based on dirtiness
 local col = 4
 if dog.dirty > 7 then
  col = 8
 elseif dog.dirty > 4 then
  col = 2
 end
 
 -- body
 ovalfill(dog.x-12, dog.y-8, dog.x+12, dog.y+8, col)
 
 -- head
 ovalfill(dog.x-8, dog.y-16, dog.x+8, dog.y-4, col)
 
 -- ears
 ovalfill(dog.x-12, dog.y-20, dog.x-4, dog.y-8, col)
 ovalfill(dog.x+4, dog.y-20, dog.x+12, dog.y-8, col)
 
 -- eyes
 pset(dog.x-3, dog.y-12, 0)
 pset(dog.x+3, dog.y-12, 0)
 if dog.happy > 7 then
  pset(dog.x-3, dog.y-13, 0)
  pset(dog.x+3, dog.y-13, 0)
 end
 
 -- nose
 pset(dog.x, dog.y-8, 0)
 
 -- mouth/smile
 if dog.happy > 7 then
  -- happy smile
  line(dog.x-2, dog.y-6, dog.x+2, dog.y-6, 0)
  pset(dog.x-2, dog.y-7, 0)
  pset(dog.x+2, dog.y-7, 0)
 elseif dog.happy < 3 then
  -- sad frown
  line(dog.x-2, dog.y-5, dog.x+2, dog.y-5, 0)
  pset(dog.x-2, dog.y-4, 0)
  pset(dog.x+2, dog.y-4, 0)
 else
  -- neutral mouth
  line(dog.x-1, dog.y-6, dog.x+1, dog.y-6, 0)
 end
 
 -- tail
 local wag_speed = 10
 local wag_amount = 2
 if dog.happy > 7 then
  wag_speed = 5
  wag_amount = 4
 elseif dog.happy < 3 then
  wag_speed = 20
  wag_amount = 0.5
 end
 local tail_y = dog.y + sin(timer/wag_speed) * wag_amount
 line(dog.x+10, dog.y, dog.x+16, tail_y-4, col)
 
 -- legs
 line(dog.x-8, dog.y+8, dog.x-8, dog.y+16, col)
 line(dog.x-3, dog.y+8, dog.x-3, dog.y+16, col)
 line(dog.x+3, dog.y+8, dog.x+3, dog.y+16, col)
 line(dog.x+8, dog.y+8, dog.x+8, dog.y+16, col)
 
 -- wetness effect
 if dog.wet > 0 then
  for i=1,dog.wet do
   pset(dog.x+rnd(20)-10, dog.y+rnd(16)-8, 12)
  end
 end
end

function draw_ui()
 -- tool display
 rectfill(0, 0, 127, 20, 1)
 print("tool: "..tools.names[tools.current], 2, 2, 7)
-- print("arrows:move z:use x:switch", 2, 8, 6)
 
 -- stats - aligned columns
 print("score:"..score, 2, 14, 11)
 print("dirty:"..flr(dog.dirty), 75, 2, 7)
 print("happy:"..flr(dog.happy), 75, 8, 7)
 print("wet:"..flr(dog.wet), 75, 14, 7)
 
 -- draw tool cursor
 if tools.current == 1 then
  -- brush
  rect(cursor.x-3, cursor.y-3, cursor.x+3, cursor.y+3, 4)
  rect(cursor.x-2, cursor.y-2, cursor.x+2, cursor.y+2, 9)
 elseif tools.current == 2 then
  -- shampoo bubble
  circfill(cursor.x, cursor.y, 4, 12)
  circfill(cursor.x, cursor.y, 2, 7)
 else
  -- dryer
  rectfill(cursor.x-4, cursor.y-2, cursor.x+4, cursor.y+2, 10)
  line(cursor.x+5, cursor.y-1, cursor.x+8, cursor.y-1, 7)
  line(cursor.x+5, cursor.y, cursor.x+8, cursor.y, 7)
  line(cursor.x+5, cursor.y+1, cursor.x+8, cursor.y+1, 7)
 end
end

function use_tool()
 local tool = tools.names[tools.current]
 
 -- check if cursor is near dog
 local dist = sqrt((cursor.x - dog.x)^2 + (cursor.y - dog.y)^2)
 if dist > 25 then return end
 
 if tool == "brush" then
  if dog.wet <= 2 then
   dog.brushed = min(10, dog.brushed + 0.3)
   local old_dirty = dog.dirty
   dog.dirty = max(0, dog.dirty - 0.2)
   if dog.dirty < old_dirty then
    score += 5
   end
   add_particles(cursor.x, cursor.y, 4, 3)
   sfx(0)
  end
 elseif tool == "shampoo" then
  dog.wet = min(10, dog.wet + 0.4)
  local old_dirty = dog.dirty
  dog.dirty = max(0, dog.dirty - 0.4)
  if dog.dirty < old_dirty then
   score += 10
  end
  add_bubbles(cursor.x, cursor.y, 8)
  sfx(1)
 elseif tool == "dryer" then
  if dog.wet > 0 then
   local old_wet = dog.wet
   dog.wet = max(0, dog.wet - 0.5)
   if dog.wet < old_wet then
    score += 3
   end
   add_particles(cursor.x, cursor.y, 7, 8)
   sfx(2)
  end
 end
end

function add_particles(x, y, col, count)
 for i=1,count do
  add(particles, {
   x = x + rnd(10) - 5,
   y = y + rnd(6) - 3,
   dx = rnd(2) - 1,
   dy = rnd(2) + 1,
   col = col,
   life = 15 + rnd(10)
  })
 end
end

function add_bubbles(x, y, count)
 for i=1,count do
  add(bubbles, {
   x = x + rnd(16) - 8,
   y = y + rnd(8) - 4,
   dy = rnd(1) + 0.5,
   t = rnd(1),
   size = rnd(2) + 1,
   life = 30 + rnd(20)
  })
 end
end

function ovalfill(x1, y1, x2, y2, color)
 local cx = (x1 + x2) / 2
 local cy = (y1 + y2) / 2
 local rx = abs(x2 - x1) / 2
 local ry = abs(y2 - y1) / 2
 
 for x = flr(x1), flr(x2) do
  for y = flr(y1), flr(y2) do
   local dx = (x - cx) / rx
   local dy = (y - cy) / ry
   if dx*dx + dy*dy <= 1 then
    pset(x, y, color)
   end
  end
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
001000000f0500e0500d0500c0500b0500a0500905007050060500505004050030500205001050000500
001000001805018050180501f0501f0501f0501c0501c0501c0501a0501a0501a05017050170501705014050
001000002405024050240502b0502b0502b05028050280502805026050260502605023050230502305020050