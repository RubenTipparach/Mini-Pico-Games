pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cat coin pusher
-- by claude code

-- a real coin pusher seen from
-- above. pusher slides forward
-- and back. coins that fall off
-- the bottom edge score points!

----------------------------
-- globals
----------------------------
state="title"
t=0

-- field layout (top-down view)
-- wall is at the top
-- player edge (scoring) at bottom
-- pusher slides up/down
fl=10      -- field left
fr=118     -- field right
ft=18      -- field top (back wall)
fb=118     -- field bottom (player edge)
fw=fr-fl   -- field width

-- pusher (wide plate)
push={
 y=30,        -- current y of front edge
 h=20,        -- pusher height
 min_y=28,    -- closest to wall (retracted)
 max_y=58,    -- furthest from wall (extended)
 dir=1,       -- 1=pushing forward, -1=retracting
 speed=0.35
}

-- dispenser (moves left-right at top)
disp={
 x=64,
 dir=1,
 speed=0.6
}

-- coins on the field
coins={}
-- coins that are dropping in (brief animation)
dropping={}
-- scored coins (falling off edge)
falling={}
-- particles
particles={}
-- score popups
popups={}

-- game vars
score=0
high_score=0
coins_left=50
combo=0
combo_timer=0
total_scored=0

-- cat anims
cat_blink=0
cat_ear_twitch=0

----------------------------
-- helpers
----------------------------
function make_coin(x,y)
 return {
  x=x, y=y,
  vx=0, vy=0,
  r=3,
  on_pusher=false
 }
end

function make_particle(x,y,col,life)
 add(particles,{
  x=x,y=y,
  vx=rnd(2)-1,
  vy=rnd(2)-1,
  life=life or 20,
  max_life=life or 20,
  col=col
 })
end

function make_popup(x,y,val)
 add(popups,{
  x=x,y=y,
  val=val,
  timer=45,
  vy=-0.6
 })
end

function cdist(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 return sqrt(dx*dx+dy*dy)
end

function collide_coins(a,b)
 local d=cdist(a,b)
 local min_d=a.r+b.r
 if d<min_d and d>0.1 then
  local nx=(b.x-a.x)/d
  local ny=(b.y-a.y)/d
  local overlap=min_d-d
  -- separate
  a.x-=nx*overlap*0.5
  a.y-=ny*overlap*0.5
  b.x+=nx*overlap*0.5
  b.y+=ny*overlap*0.5
  -- velocity exchange
  local dvx=a.vx-b.vx
  local dvy=a.vy-b.vy
  local dot=dvx*nx+dvy*ny
  if dot>0 then
   a.vx-=nx*dot*0.45
   a.vy-=ny*dot*0.45
   b.vx+=nx*dot*0.45
   b.vy+=ny*dot*0.45
  end
 end
end

-- is point inside pusher?
function on_pusher(x,y,r)
 local ptop=push.y-push.h
 return x>fl and x<fr
    and y-r<push.y
    and y+r>ptop
end

----------------------------
-- init
----------------------------
function _init()
 cartdata("catcoinpush_v2")
 high_score=dget(0)
 start_title()
end

function start_title()
 state="title"
 t=0
end

function start_game()
 state="play"
 t=0
 score=0
 combo=0
 combo_timer=0
 total_scored=0
 coins_left=50
 coins={}
 dropping={}
 falling={}
 particles={}
 popups={}
 push.y=30
 push.dir=1
 disp.x=64
 disp.dir=1

 -- seed ~50 coins on the field
 -- spread them between pusher
 -- front and the bottom edge
 seed_coins(50)
end

function seed_coins(n)
 for i=1,n do
  local attempts=0
  local placed=false
  while not placed and attempts<20 do
   local cx=fl+6+rnd(fw-12)
   local cy=push.max_y+8+rnd(fb-push.max_y-16)
   -- check no overlap with existing
   local ok=true
   for c in all(coins) do
    local dx=cx-c.x
    local dy=cy-c.y
    if sqrt(dx*dx+dy*dy)<7 then
     ok=false
     break
    end
   end
   if ok then
    add(coins,make_coin(cx,cy))
    placed=true
   end
   attempts+=1
  end
 end
end

----------------------------
-- update
----------------------------
function _update60()
 t+=1
 update_cat()

 if state=="title" then
  update_title()
 elseif state=="play" then
  update_play()
 elseif state=="gameover" then
  update_gameover()
 end

 -- particles
 for p in all(particles) do
  p.x+=p.vx
  p.y+=p.vy
  p.vy+=0.03
  p.life-=1
  if p.life<=0 then del(particles,p) end
 end

 -- popups
 for p in all(popups) do
  p.y+=p.vy
  p.timer-=1
  if p.timer<=0 then del(popups,p) end
 end
end

function update_cat()
 if rnd(200)<1 then cat_blink=10 end
 if cat_blink>0 then cat_blink-=1 end
 if rnd(300)<1 then cat_ear_twitch=15 end
 if cat_ear_twitch>0 then cat_ear_twitch-=1 end
end

function update_title()
 -- auto-move dispenser on title
 disp.x+=disp.dir*0.5
 if disp.x>fr-6 then disp.dir=-1 end
 if disp.x<fl+6 then disp.dir=1 end
 if btnp(4) or btnp(5) then
  start_game()
  sfx(0)
 end
end

function update_play()
 -- dispenser auto-moves
 disp.x+=disp.dir*disp.speed
 if disp.x>=fr-6 then
  disp.dir=-1
  disp.x=fr-6
 end
 if disp.x<=fl+6 then
  disp.dir=1
  disp.x=fl+6
 end

 -- player can adjust speed
 -- or press to drop
 if btnp(4) and coins_left>0 then
  -- drop a coin at dispenser pos
  -- it lands just below the wall
  local dc={
   x=disp.x,
   y=ft-4,
   target_y=ft+4+rnd(4),
   timer=12
  }
  add(dropping,dc)
  coins_left-=1
  sfx(0)
 end

 -- speed up/slow dispenser
 if btn(0) then
  disp.speed=max(0.2,disp.speed-0.02)
 end
 if btn(1) then
  disp.speed=min(1.5,disp.speed+0.02)
 end

 -- update dropping coins
 for dc in all(dropping) do
  -- animate coin falling onto field
  dc.y+=(dc.target_y-dc.y)*0.3
  dc.timer-=1
  if dc.timer<=0 then
   -- becomes a real coin on field
   local c=make_coin(dc.x,dc.target_y)
   -- check if it landed on pusher
   if dc.target_y<push.y and dc.target_y>(push.y-push.h) then
    c.on_pusher=true
   end
   add(coins,c)
   del(dropping,dc)
   sfx(2)
  end
 end

 -- update pusher
 update_pusher()

 -- update coins physics
 update_coins()

 -- check coins falling off edge
 check_scored()

 -- combo timer
 if combo_timer>0 then
  combo_timer-=1
  if combo_timer<=0 then combo=0 end
 end

 -- game over when out of coins
 -- to drop and field is settled
 if coins_left<=0 and #dropping==0 then
  local any_moving=false
  for c in all(coins) do
   if abs(c.vx)>0.05 or abs(c.vy)>0.05 then
    any_moving=true
    break
   end
  end
  -- wait a bit for last pushes
  if not any_moving and t>120 then
   -- check if pusher did a full
   -- cycle with no movement
   if push.dir==-1 and push.y<push.min_y+2 then
    game_over()
   end
  end
 end
end

function update_pusher()
 local prev_y=push.y

 push.y+=push.dir*push.speed
 if push.y>=push.max_y then
  push.y=push.max_y
  push.dir=-1
 end
 if push.y<=push.min_y then
  push.y=push.min_y
  push.dir=1
  sfx(1)
 end

 local dy=push.y-prev_y
 local ptop=push.y-push.h

 -- pusher interacts with coins
 for c in all(coins) do
  -- case 1: coin is ON TOP of pusher
  -- (between pusher top and pusher bottom)
  if c.on_pusher then
   -- coin rides with pusher
   c.y+=dy

   -- when retracting (moving up toward wall),
   -- coins on pusher hit the back wall
   if push.dir==-1 then
    if c.y-c.r<=ft then
     -- wall pushes coin off the front
     c.y=ft+c.r
     c.vy=0.5+rnd(0.3)
     c.vx=(rnd(1)-0.5)*0.3
     c.on_pusher=false
    end
   end

   -- if coin slides past front of pusher
   if c.y+c.r>push.y then
    c.on_pusher=false
    c.y=push.y+c.r
    c.vy=0.3
   end

   -- if coin slides behind pusher
   if c.y-c.r<ptop then
    c.on_pusher=false
    c.y=ptop-c.r
   end

  else
   -- case 2: coin is in front of pusher
   -- pusher front edge pushes coins forward
   if push.dir==1 and dy>0 then
    -- check if coin is in contact
    -- with the front edge of pusher
    if c.y-c.r<push.y and
       c.y+c.r>push.y-4 and
       c.x>fl and c.x<fr then
     -- push it forward
     c.vy+=dy*0.8
     c.y=push.y+c.r
     c.vx+=(rnd(0.2)-0.1)
    end
   end

   -- case 3: coin gets caught by
   -- retracting pusher (scooped on top)
   if c.y>ptop and c.y<push.y and
      c.x>fl and c.x<fr then
    if abs(c.vy)<0.3 then
     c.on_pusher=true
     c.vx*=0.5
     c.vy=0
    end
   end
  end
 end
end

function update_coins()
 for c in all(coins) do
  if not c.on_pusher then
   -- apply velocity
   c.x+=c.vx
   c.y+=c.vy

   -- friction
   c.vx*=0.92
   c.vy*=0.92

   -- left wall
   if c.x<fl+c.r then
    c.x=fl+c.r
    c.vx=abs(c.vx)*0.3
   end
   -- right wall
   if c.x>fr-c.r then
    c.x=fr-c.r
    c.vx=-abs(c.vx)*0.3
   end
   -- back wall (top)
   if c.y<ft+c.r then
    c.y=ft+c.r
    c.vy=abs(c.vy)*0.3
   end

   -- don't let coins overlap
   -- with pusher body if not on it
   local ptop=push.y-push.h
   if c.y-c.r<push.y and
      c.y+c.r>ptop and
      c.x>fl and c.x<fr then
    -- push out the front
    if c.y>push.y-push.h/2 then
     c.y=push.y+c.r
     c.vy=max(c.vy,0.1)
    end
   end
  end
 end

 -- coin-coin collisions (multiple passes)
 for pass=1,2 do
  for i=1,#coins do
   for j=i+1,#coins do
    collide_coins(coins[i],coins[j])
   end
  end
 end
end

function check_scored()
 for c in all(coins) do
  if not c.on_pusher and c.y>fb then
   -- coin fell off the player edge!
   local val=10
   combo+=1
   combo_timer=90
   if combo>1 then
    val=val*min(combo,8)
   end
   score+=val
   total_scored+=1
   make_popup(c.x,fb-4,val)

   -- falling animation
   add(falling,{
    x=c.x,y=c.y,
    vy=1+rnd(1),
    vx=rnd(1)-0.5,
    rot=rnd(1),
    life=30
   })

   -- particles
   for k=1,5 do
    make_particle(c.x,fb,9,20)
   end

   del(coins,c)
   sfx(3)
  end
 end
end

function game_over()
 state="gameover"
 t=0
 if score>high_score then
  high_score=score
  dset(0,high_score)
 end
 sfx(5)
end

function update_gameover()
 if t>60 and (btnp(4) or btnp(5)) then
  start_title()
 end
end

----------------------------
-- drawing
----------------------------
function _draw()
 cls(1)
 if state=="title" then
  draw_title()
 elseif state=="play" then
  draw_play()
 elseif state=="gameover" then
  draw_gameover()
 end
end

function draw_title()
 cls(0)
 -- stars
 for i=0,40 do
  local sx=(i*37+t*0.3)%128
  local sy=(i*53+t*0.1)%128
  pset(sx,sy,({1,5,6,13})[i%4+1])
 end

 local ty=20+sin(t/90)*3

 -- big cat face
 draw_big_cat(64,ty)

 -- title
 print("cat coin",35,ty+24,0)
 print("cat coin",34,ty+23,10)
 print("pusher",42,ty+32,0)
 print("pusher",41,ty+31,9)

 -- bouncing fish coin
 local cy=ty+48+sin(t/25)*4
 draw_fish_coin(64,cy)

 -- controls
 if t%60<40 then
  print("\x8e\x91 to start",36,100,7)
 end
 print("\x8e drop coin",38,110,6)
 print("\x83\x84 dispenser speed",18,118,6)
 print("hi-score: "..high_score,28,125,5)
end

function draw_big_cat(x,y)
 -- head
 circfill(x,y,14,4)
 circfill(x,y,13,10)
 -- ears
 local eo=cat_ear_twitch>0 and 1 or 0
 line(x-10,y-8,x-14,y-18+eo,10)
 line(x-14,y-18+eo,x-6,y-12,10)
 line(x-11,y-10,x-13,y-16+eo,8)
 line(x+10,y-8,x+14,y-18+eo,10)
 line(x+14,y-18+eo,x+6,y-12,10)
 line(x+11,y-10,x+13,y-16+eo,8)
 -- eyes
 if cat_blink>5 then
  line(x-5,y-2,x-3,y-2,0)
  line(x+3,y-2,x+5,y-2,0)
 else
  circfill(x-5,y-2,2,0)
  circfill(x+5,y-2,2,0)
  pset(x-5,y-2,7)
  pset(x+5,y-2,7)
 end
 -- nose + mouth
 pset(x,y+2,8)
 line(x-2,y+4,x,y+3,8)
 line(x,y+3,x+2,y+4,8)
 -- whiskers
 line(x-14,y,x-7,y+1,7)
 line(x-13,y+3,x-7,y+2,7)
 line(x+7,y+1,x+14,y,7)
 line(x+7,y+2,x+13,y+3,7)
end

function draw_play()
 -- dark background
 cls(0)

 -- machine body (dark gray surround)
 rectfill(fl-6,ft-6,fr+6,fb+10,5)
 rectfill(fl-4,ft-4,fr+4,fb+8,13)

 -- field surface (green felt)
 rectfill(fl,ft,fr,fb,3)
 -- felt texture dots
 for i=0,60 do
  local fx=(i*17)%(fw-2)+fl+1
  local fy=(i*29)%(fb-ft-2)+ft+1
  pset(fx,fy,11)
 end

 -- back wall (top edge)
 rectfill(fl,ft-3,fr,ft,4)
 rectfill(fl,ft-2,fr,ft-1,9)

 -- side walls
 rectfill(fl-2,ft,fl-1,fb,4)
 rectfill(fr+1,ft,fr+2,fb,4)

 -- draw pusher
 draw_pusher()

 -- draw coins on field
 for c in all(coins) do
  draw_fish_coin(c.x,c.y)
 end

 -- draw dropping coins (incoming)
 for dc in all(dropping) do
  -- shadow
  circfill(dc.x+1,dc.y+1,4,1)
  draw_fish_coin(dc.x,dc.y)
 end

 -- falling scored coins
 for fc in all(falling) do
  fc.y+=fc.vy
  fc.x+=fc.vx
  fc.vy+=0.15
  fc.rot+=0.05
  fc.life-=1
  if fc.life>0 then
   local col=fc.life>15 and 10 or 9
   circfill(fc.x,fc.y,2,col)
  else
   del(falling,fc)
  end
 end

 -- player edge (score zone)
 -- glowing bottom edge
 local gc=({8,2,8,14})[flr(t/10)%4+1]
 rectfill(fl,fb+1,fr,fb+4,gc)
 -- arrow indicators
 for i=0,4 do
  local ax=fl+10+i*(fw-20)/4
  local ay=fb+2
  pset(ax,ay,7)
  pset(ax-1,ay-1,7)
  pset(ax+1,ay-1,7)
 end

 -- dispenser at top
 draw_dispenser()

 -- particles
 for p in all(particles) do
  local a=p.life/p.max_life
  pset(p.x,p.y,a>0.5 and p.col or 5)
 end

 -- popups
 for p in all(popups) do
  local col=7
  if p.val>=30 then col=10 end
  if p.val>=80 then col=11 end
  -- shadow
  print("+"..p.val,p.x-5,p.y+1,0)
  print("+"..p.val,p.x-6,p.y,col)
 end

 -- hud
 draw_hud()
end

function draw_pusher()
 local py=push.y
 local ptop=py-push.h

 -- pusher shadow
 rectfill(fl+2,ptop+2,fr-2,py+2,1)

 -- pusher body (cat paw!)
 rectfill(fl+1,ptop,fr-1,py,4)
 rect(fl+1,ptop,fr-1,py,9)

 -- paw pad pattern
 -- four toe beans along front edge
 local bw=(fr-fl-8)/5
 for i=1,4 do
  local bx=fl+4+i*bw+bw/2
  local by=py-3
  circfill(bx,by,2.5,8)
  circfill(bx,by,1.5,14)
 end

 -- big central pad
 local cx=(fl+fr)/2
 circfill(cx,ptop+push.h*0.35,4,8)
 circfill(cx,ptop+push.h*0.35,3,14)

 -- fur texture on pusher
 for i=0,8 do
  local fx=fl+6+i*((fr-fl-12)/8)
  local fy=ptop+4
  pset(fx,fy,9)
 end

 -- front edge highlight
 line(fl+3,py,fr-3,py,10)
end

function draw_fish_coin(x,y)
 -- coin body
 circfill(x,y,3,9)
 circfill(x,y,2.5,10)

 -- fish design on coin
 -- body
 line(x-1,y,x+1,y,12)
 -- tail
 pset(x-2,y-1,12)
 pset(x-2,y+1,12)
 -- head
 pset(x+2,y,12)

 -- shine
 pset(x-1,y-1,7)
end

function draw_dispenser()
 local x=disp.x
 local y=ft-4

 -- dispenser track
 rectfill(fl,ft-8,fr,ft-5,5)
 line(fl,ft-5,fr,ft-5,13)

 -- cat dispenser head
 -- body
 circfill(x,y-4,6,10)
 -- ears
 local eo=cat_ear_twitch>0 and 1 or 0
 line(x-5,y-8,x-7,y-13+eo,10)
 line(x-7,y-13+eo,x-3,y-9,10)
 line(x+5,y-8,x+7,y-13+eo,10)
 line(x+7,y-13+eo,x+3,y-9,10)
 -- inner ears
 pset(x-5,y-11+eo,8)
 pset(x+5,y-11+eo,8)
 -- eyes
 if cat_blink>5 then
  line(x-3,y-5,x-1,y-5,0)
  line(x+1,y-5,x+3,y-5,0)
 else
  pset(x-2,y-5,0)
  pset(x+2,y-5,0)
 end
 -- nose
 pset(x,y-3,8)
 -- mouth/opening for coins
 rectfill(x-2,y-1,x+2,y+1,0)
 pset(x-1,y,9)
 pset(x+1,y,9)

 -- coin ready indicator
 if coins_left>0 then
  draw_fish_coin(x,y-2)
 end

 -- direction arrow
 if disp.dir==1 then
  pset(x+8,y-4,7)
  pset(x+7,y-5,7)
  pset(x+7,y-3,7)
 else
  pset(x-8,y-4,7)
  pset(x-7,y-5,7)
  pset(x-7,y-3,7)
 end
end

function draw_hud()
 -- top bar
 rectfill(0,0,127,7,0)

 -- score
 print("\f7score:\fa"..score,1,1)

 -- coins left
 print("\fc\x97\fa"..coins_left,70,1)

 -- field count
 print("\fd#\f6"..#coins,98,1)

 -- combo
 if combo>1 and combo_timer>0 then
  local col=({7,10,9,8,11})[min(combo,5)]
  local txt="x"..combo.."!"
  print(txt,56,10,col)
 end

 -- bottom bar
 rectfill(0,125,127,127,0)
 print("\f6\x83slow \x84fast",1,126)
 print("\f5hi:"..high_score,88,126)
end

function draw_gameover()
 cls(0)

 draw_big_cat(64,28)

 -- game over
 print("game over",38,53,8)
 print("game over",37,52,2)

 print("final score",36,66,7)
 local stxt=""..score
 print(stxt,64-#stxt*2,76,10)

 print("coins scored: "..total_scored,22,88,6)

 if score>=high_score and score>0 then
  if t%30<20 then
   print("new record!",36,100,11)
  end
 else
  print("best: "..high_score,40,100,5)
 end

 if t>60 and t%60<40 then
  print("\x8e\x91 continue",32,115,7)
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200001805018050180001800018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000024050240502400024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000c0500c0500c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002405024050300503005030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001805024050300503005036050360500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000030050240501805012050060500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
