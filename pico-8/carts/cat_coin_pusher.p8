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
-- shorter field to fit 128px
fl=10      -- field left
fr=118     -- field right
ft=16      -- field top (back wall)
fb=104     -- field bottom (player edge)
fw=fr-fl   -- field width
fh=fb-ft   -- field height

-- pusher (wide plate)
push={
 y=28,        -- current y of front edge
 h=16,        -- pusher height
 min_y=26,    -- closest to wall (retracted)
 max_y=50,    -- furthest from wall (extended)
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
-- coins that are dropping in
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
coins_left=100
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
  a.x-=nx*overlap*0.5
  a.y-=ny*overlap*0.5
  b.x+=nx*overlap*0.5
  b.y+=ny*overlap*0.5
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

----------------------------
-- init
----------------------------
function _init()
 cartdata("catcoinpush_v3")
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
 coins_left=100
 coins={}
 dropping={}
 falling={}
 particles={}
 popups={}
 push.y=28
 push.dir=1
 disp.x=64
 disp.dir=1

 -- seed 100 coins on the field
 seed_coins(100)
end

function seed_coins(n)
 for i=1,n do
  local attempts=0
  local placed=false
  while not placed and attempts<30 do
   local cx=fl+5+rnd(fw-10)
   local cy=push.max_y+6+rnd(fb-push.max_y-10)
   local ok=true
   for c in all(coins) do
    local dx=cx-c.x
    local dy=cy-c.y
    if sqrt(dx*dx+dy*dy)<6.5 then
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

 -- drop coin
 if btnp(4) and coins_left>0 then
  local dc={
   x=disp.x,
   y=ft-4,
   target_y=ft+4+rnd(4),
   timer=12,
   height=8 -- starting height for shadow
  }
  add(dropping,dc)
  coins_left-=1
  sfx(0)
 end

 -- speed controls
 if btn(0) then
  disp.speed=max(0.2,disp.speed-0.02)
 end
 if btn(1) then
  disp.speed=min(1.5,disp.speed+0.02)
 end

 -- update dropping coins
 for dc in all(dropping) do
  dc.y+=(dc.target_y-dc.y)*0.3
  dc.height*=0.75
  dc.timer-=1
  if dc.timer<=0 then
   local c=make_coin(dc.x,dc.target_y)
   if dc.target_y<push.y and
      dc.target_y>(push.y-push.h) then
    c.on_pusher=true
   end
   add(coins,c)
   del(dropping,dc)
   sfx(2)
  end
 end

 update_pusher()
 update_coins()
 check_scored()

 -- combo timer
 if combo_timer>0 then
  combo_timer-=1
  if combo_timer<=0 then combo=0 end
 end

 -- game over check
 if coins_left<=0 and #dropping==0 then
  local any_moving=false
  for c in all(coins) do
   if abs(c.vx)>0.05 or abs(c.vy)>0.05 then
    any_moving=true
    break
   end
  end
  if not any_moving and t>120 then
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

 for c in all(coins) do
  if c.on_pusher then
   c.y+=dy
   -- retract: coins hit back wall
   if push.dir==-1 then
    if c.y-c.r<=ft then
     c.y=ft+c.r
     c.vy=0.5+rnd(0.3)
     c.vx=(rnd(1)-0.5)*0.3
     c.on_pusher=false
    end
   end
   -- slides past front
   if c.y+c.r>push.y then
    c.on_pusher=false
    c.y=push.y+c.r
    c.vy=0.3
   end
   -- slides behind
   if c.y-c.r<ptop then
    c.on_pusher=false
    c.y=ptop-c.r
   end
  else
   -- pusher front pushes coins
   if push.dir==1 and dy>0 then
    if c.y-c.r<push.y and
       c.y+c.r>push.y-4 and
       c.x>fl and c.x<fr then
     c.vy+=dy*0.8
     c.y=push.y+c.r
     c.vx+=(rnd(0.2)-0.1)
    end
   end
   -- scoop onto pusher
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
   c.x+=c.vx
   c.y+=c.vy
   c.vx*=0.92
   c.vy*=0.92

   -- walls
   if c.x<fl+c.r then
    c.x=fl+c.r
    c.vx=abs(c.vx)*0.3
   end
   if c.x>fr-c.r then
    c.x=fr-c.r
    c.vx=-abs(c.vx)*0.3
   end
   if c.y<ft+c.r then
    c.y=ft+c.r
    c.vy=abs(c.vy)*0.3
   end

   -- don't overlap pusher
   local ptop=push.y-push.h
   if c.y-c.r<push.y and
      c.y+c.r>ptop and
      c.x>fl and c.x<fr then
    if c.y>push.y-push.h/2 then
     c.y=push.y+c.r
     c.vy=max(c.vy,0.1)
    end
   end
  end
 end

 -- coin-coin collisions
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
   local val=10
   combo+=1
   combo_timer=90
   if combo>1 then
    val=val*min(combo,8)
   end
   score+=val
   total_scored+=1
   make_popup(c.x,fb-8,val)

   -- falling coin with height for shadow
   add(falling,{
    x=c.x,y=fb+2,
    vy=0.8+rnd(0.5),
    vx=rnd(0.6)-0.3,
    height=0, -- starts at surface
    vheight=0.3, -- falling speed
    life=35
   })

   for k=1,4 do
    make_particle(c.x,fb,9,18)
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
 cls(0)
 if state=="title" then
  draw_title()
 elseif state=="play" then
  draw_play()
 elseif state=="gameover" then
  draw_gameover()
 end
end

function draw_title()
 -- stars
 for i=0,40 do
  local sx=(i*37+t*0.3)%128
  local sy=(i*53+t*0.1)%128
  pset(sx,sy,({1,5,6,13})[i%4+1])
 end

 local ty=18+sin(t/90)*3

 draw_big_cat(64,ty)

 print("cat coin",35,ty+24,0)
 print("cat coin",34,ty+23,10)
 print("pusher",42,ty+32,0)
 print("pusher",41,ty+31,9)

 local cy=ty+48+sin(t/25)*4
 draw_coin_fancy(64,cy,0)

 if t%60<40 then
  print("\x8e\x91 to start",36,96,7)
 end
 print("\x8e drop coin",38,106,6)
 print("\x83\x84 dispenser speed",18,114,6)
 print("hi-score: "..high_score,28,122,5)
end

function draw_big_cat(x,y)
 circfill(x,y,14,4)
 circfill(x,y,13,10)
 local eo=cat_ear_twitch>0 and 1 or 0
 line(x-10,y-8,x-14,y-18+eo,10)
 line(x-14,y-18+eo,x-6,y-12,10)
 line(x-11,y-10,x-13,y-16+eo,8)
 line(x+10,y-8,x+14,y-18+eo,10)
 line(x+14,y-18+eo,x+6,y-12,10)
 line(x+11,y-10,x+13,y-16+eo,8)
 if cat_blink>5 then
  line(x-5,y-2,x-3,y-2,0)
  line(x+3,y-2,x+5,y-2,0)
 else
  circfill(x-5,y-2,2,0)
  circfill(x+5,y-2,2,0)
  pset(x-5,y-2,7)
  pset(x+5,y-2,7)
 end
 pset(x,y+2,8)
 line(x-2,y+4,x,y+3,8)
 line(x,y+3,x+2,y+4,8)
 line(x-14,y,x-7,y+1,7)
 line(x-13,y+3,x-7,y+2,7)
 line(x+7,y+1,x+14,y,7)
 line(x+7,y+2,x+13,y+3,7)
end

-- draw coin with shadow+rim
-- h=height above surface
-- (0=on surface, >0=in air)
function draw_coin_fancy(x,y,h)
 local sx=x+1+h*0.5
 local sy=y+1+h*0.5
 -- shadow (bigger when higher)
 local sr=3+h*0.15
 circfill(sx,sy,sr,1)

 -- coin rim (dark edge)
 circfill(x,y,3.5,4)
 -- coin body
 circfill(x,y,3,9)
 circfill(x,y,2.5,10)

 -- fish design
 line(x-1,y,x+1,y,12)
 pset(x-2,y-1,12)
 pset(x-2,y+1,12)
 pset(x+2,y,12)

 -- shine
 pset(x-1,y-2,7)
 pset(x-1,y-1,7)
end

function draw_play()
 cls(0)

 -- machine surround
 rectfill(fl-5,ft-5,fr+5,fb+6,5)
 rectfill(fl-3,ft-3,fr+3,fb+4,13)

 -- field surface (green felt)
 rectfill(fl,ft,fr,fb,3)
 -- felt texture
 for i=0,50 do
  local fx=(i*17)%(fw-2)+fl+1
  local fy=(i*29)%(fh-2)+ft+1
  pset(fx,fy,11)
 end

 -- back wall
 rectfill(fl,ft-2,fr,ft,4)
 rectfill(fl,ft-1,fr,ft,9)

 -- side walls
 rectfill(fl-1,ft,fl,fb,4)
 rectfill(fr,ft,fr+1,fb,4)

 -- draw pusher
 draw_pusher()

 -- draw all coins (shadows first pass)
 for c in all(coins) do
  circfill(c.x+1,c.y+1,3,1)
 end
 -- then coins on top
 for c in all(coins) do
  draw_coin_fancy(c.x,c.y,0)
 end

 -- dropping coins (in the air)
 for dc in all(dropping) do
  local h=dc.height
  draw_coin_fancy(dc.x,dc.y,h)
 end

 -- falling scored coins
 for fc in all(falling) do
  fc.y+=fc.vy
  fc.x+=fc.vx
  fc.vy+=0.08
  fc.height+=fc.vheight
  fc.vheight+=0.15
  fc.life-=1
  if fc.life>0 then
   -- shadow stays at surface,
   -- coin "rises" away from it
   local h=fc.height
   local sx=fc.x+1+h*0.4
   local sy=fc.y+1+h*0.4
   local sr=3+h*0.2
   -- shadow gets fainter
   if fc.life>15 then
    circfill(sx,sy,sr,1)
   end
   -- coin shrinks as it falls away
   local cr=max(1,3-h*0.1)
   circfill(fc.x,fc.y-h,cr+0.5,4)
   circfill(fc.x,fc.y-h,cr,10)
   pset(fc.x-1,fc.y-h-1,7)
  else
   del(falling,fc)
  end
 end

 -- score zone glow
 local gc=({8,2,8,14})[flr(t/10)%4+1]
 rectfill(fl,fb+1,fr,fb+3,gc)
 -- arrows
 for i=0,4 do
  local ax=fl+10+i*(fw-20)/4
  pset(ax,fb+2,7)
  pset(ax-1,fb+1,7)
  pset(ax+1,fb+1,7)
 end

 -- dispenser
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
  print("+"..p.val,p.x-5,p.y+1,0)
  print("+"..p.val,p.x-6,p.y,col)
 end

 -- hud
 draw_hud()
end

function draw_pusher()
 local py=push.y
 local ptop=py-push.h

 -- shadow
 rectfill(fl+2,ptop+2,fr-2,py+2,1)

 -- body
 rectfill(fl+1,ptop,fr-1,py,4)
 rect(fl+1,ptop,fr-1,py,9)

 -- toe beans along front edge
 local bw=(fr-fl-8)/5
 for i=1,4 do
  local bx=fl+4+i*bw+bw/2
  local by=py-3
  circfill(bx,by,2.5,8)
  circfill(bx,by,1.5,14)
 end

 -- big central pad
 local cx=(fl+fr)/2
 circfill(cx,ptop+push.h*0.4,3.5,8)
 circfill(cx,ptop+push.h*0.4,2.5,14)

 -- fur dots
 for i=0,6 do
  local fx=fl+8+i*((fr-fl-16)/6)
  pset(fx,ptop+3,9)
 end

 -- front edge highlight
 line(fl+3,py,fr-3,py,10)
end

function draw_dispenser()
 local x=disp.x
 local y=ft-3

 -- track
 rectfill(fl,ft-7,fr,ft-4,5)
 line(fl,ft-4,fr,ft-4,13)

 -- cat head
 circfill(x,y-4,5,10)
 -- ears
 local eo=cat_ear_twitch>0 and 1 or 0
 line(x-4,y-7,x-6,y-11+eo,10)
 line(x-6,y-11+eo,x-2,y-8,10)
 line(x+4,y-7,x+6,y-11+eo,10)
 line(x+6,y-11+eo,x+2,y-8,10)
 pset(x-4,y-10+eo,8)
 pset(x+4,y-10+eo,8)
 -- eyes
 if cat_blink>5 then
  line(x-2,y-5,x-1,y-5,0)
  line(x+1,y-5,x+2,y-5,0)
 else
  pset(x-2,y-5,0)
  pset(x+2,y-5,0)
 end
 -- nose
 pset(x,y-3,8)
 -- mouth opening
 rectfill(x-2,y-1,x+2,y,0)

 -- coin ready indicator
 if coins_left>0 then
  circfill(x,y-2,2,10)
  pset(x,y-2,12)
 end

 -- direction arrow
 if disp.dir==1 then
  pset(x+7,y-4,7)
  pset(x+6,y-5,7)
  pset(x+6,y-3,7)
 else
  pset(x-7,y-4,7)
  pset(x-6,y-5,7)
  pset(x-6,y-3,7)
 end
end

function draw_hud()
 -- top-left: score (drawn over machine)
 rectfill(0,0,127,6,0)
 print("\f7\x97\fa"..score,1,1)
 -- coins left
 print("\fcx\fa"..coins_left,44,1)
 -- field count
 print("\fd#\f6"..#coins,78,1)
 -- hi
 print("\f5hi:"..high_score,100,1)

 -- combo overlay (inside field)
 if combo>1 and combo_timer>0 then
  local col=({7,10,9,8,11})[min(combo,5)]
  local txt="x"..combo.."!"
  print(txt,60-#txt*2,9,col)
 end

 -- bottom bar
 rectfill(0,121,127,127,0)
 print("\f6\x83slow \x84fast",1,122)
 print("\fd scored:"..total_scored,64,122)
end

function draw_gameover()
 cls(0)

 draw_big_cat(64,26)

 print("game over",38,50,8)
 print("game over",37,49,2)

 print("final score",36,62,7)
 local stxt=""..score
 print(stxt,64-#stxt*2,72,10)

 print("coins scored: "..total_scored,22,84,6)

 if score>=high_score and score>0 then
  if t%30<20 then
   print("new record!",36,96,11)
  end
 else
  print("best: "..high_score,40,96,5)
 end

 if t>60 and t%60<40 then
  print("\x8e\x91 continue",32,112,7)
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
