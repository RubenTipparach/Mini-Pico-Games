pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cat coin pusher
-- by claude code
-- drop fish coins, push them
-- off the edge to score!

----------------------------
-- globals
----------------------------
state="title"  -- title,play,gameover
t=0

-- player
dropper_x=64
dropper_speed=1.5
coins_left=30
score=0
high_score=0
combo=0
combo_timer=0
level=1
coins_for_level=30

-- pusher
pusher_y=40
pusher_dir=1
pusher_speed=0.4
pusher_w=80
pusher_h=10
pusher_x=24

-- play field
field_left=16
field_right=112
field_top=20
field_bottom=120
drop_zone_y=26

-- coins
coins={}
falling_coins={}
scored_coins={}
particles={}
specials={}

-- cat animations
cat_blink=0
cat_ear_twitch=0
paw_anim=0
tail_wag=0

-- special items
yarn_balls={}
next_yarn=300

----------------------------
-- helpers
----------------------------
function make_coin(x,y,special)
 local c={
  x=x,y=y,
  vx=0,vy=0,
  r=3,
  grounded=false,
  special=special or false,
  wobble=rnd(1),
  age=0
 }
 return c
end

function make_particle(x,y,col,life)
 add(particles,{
  x=x,y=y,
  vx=rnd(2)-1,
  vy=-rnd(2)-0.5,
  life=life or 20,
  max_life=life or 20,
  col=col
 })
end

function make_score_popup(x,y,val)
 add(scored_coins,{
  x=x,y=y,
  val=val,
  timer=40,
  vy=-0.8
 })
end

function dist(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 return sqrt(dx*dx+dy*dy)
end

function coin_coin_collide(a,b)
 local d=dist(a,b)
 if d < a.r+b.r and d>0 then
  local nx=(b.x-a.x)/d
  local ny=(b.y-a.y)/d
  local overlap=(a.r+b.r)-d
  a.x-=nx*overlap*0.5
  a.y-=ny*overlap*0.5
  b.x+=nx*overlap*0.5
  b.y+=ny*overlap*0.5
  -- transfer velocity
  local rel_vx=a.vx-b.vx
  local rel_vy=a.vy-b.vy
  local rel_dot=rel_vx*nx+rel_vy*ny
  if rel_dot>0 then
   a.vx-=nx*rel_dot*0.5
   a.vy-=ny*rel_dot*0.5
   b.vx+=nx*rel_dot*0.5
   b.vy+=ny*rel_dot*0.5
  end
  sfx(2)
  return true
 end
 return false
end

----------------------------
-- init
----------------------------
function _init()
 cartdata("cat_coin_pusher_1")
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
 level=1
 coins_left=coins_for_level
 coins={}
 falling_coins={}
 scored_coins={}
 particles={}
 yarn_balls={}
 next_yarn=300
 pusher_y=40
 pusher_dir=1
 pusher_speed=0.4
 dropper_x=64
 -- seed some starting coins
 for i=1,8 do
  local c=make_coin(
   field_left+8+rnd(field_right-field_left-16),
   50+rnd(50),
   false
  )
  c.grounded=true
  add(coins,c)
 end
end

----------------------------
-- update
----------------------------
function _update60()
 t+=1
 update_cat_anims()

 if state=="title" then
  update_title()
 elseif state=="play" then
  update_play()
 elseif state=="gameover" then
  update_gameover()
 end

 update_particles()
end

function update_cat_anims()
 -- blink
 if rnd(200)<1 then cat_blink=8 end
 if cat_blink>0 then cat_blink-=1 end
 -- ear twitch
 if rnd(300)<1 then cat_ear_twitch=12 end
 if cat_ear_twitch>0 then cat_ear_twitch-=1 end
 -- tail
 tail_wag=sin(t/60)*3
end

function update_title()
 if btnp(4) or btnp(5) then
  start_game()
  sfx(0)
 end
end

function update_play()
 -- dropper movement
 if btn(0) then dropper_x-=dropper_speed end
 if btn(1) then dropper_x+=dropper_speed end
 dropper_x=mid(field_left+4,dropper_x,field_right-4)

 -- drop coin
 if btnp(4) and coins_left>0 then
  drop_coin(dropper_x,drop_zone_y,false)
  coins_left-=1
  sfx(0)
 end

 -- drop special (yarn ball) with O button
 if btnp(5) and #yarn_balls>0 then
  drop_coin(dropper_x,drop_zone_y,true)
  del(yarn_balls,yarn_balls[#yarn_balls])
  sfx(1)
 end

 -- earn yarn balls over time
 if t%next_yarn==0 and #yarn_balls<3 then
  add(yarn_balls,true)
  next_yarn=max(180,next_yarn-20)
  sfx(3)
 end

 -- update pusher
 update_pusher()

 -- update falling coins
 for c in all(falling_coins) do
  c.vy+=0.15
  c.y+=c.vy
  c.x+=c.vx
  if c.y>=pusher_y+pusher_h+c.r then
   c.grounded=true
   c.vy=0.5
   c.vx*=0.5
   add(coins,c)
   del(falling_coins,c)
   sfx(2)
  end
 end

 -- update grounded coins
 update_coins()

 -- check scoring
 check_scored()

 -- update score popups
 for s in all(scored_coins) do
  s.timer-=1
  s.y+=s.vy
  if s.timer<=0 then
   del(scored_coins,s)
  end
 end

 -- combo timer
 if combo_timer>0 then
  combo_timer-=1
  if combo_timer<=0 then
   combo=0
  end
 end

 -- level up
 if coins_left<=0 and #falling_coins==0 then
  -- check if all coins settled
  local all_slow=true
  for c in all(coins) do
   if abs(c.vx)>0.1 or abs(c.vy)>0.1 then
    all_slow=false
    break
   end
  end
  if all_slow then
   if #coins==0 then
    -- perfect clear bonus!
    score+=100
    make_score_popup(64,60,100)
   end
   level+=1
   if level>10 then
    game_over()
   else
    coins_left=coins_for_level+level*3
    pusher_speed=min(0.8,0.4+level*0.04)
    sfx(4)
   end
  end
 end
end

function update_pusher()
 pusher_y+=pusher_dir*pusher_speed
 if pusher_y>70 then
  pusher_dir=-1
  sfx(1)
 end
 if pusher_y<35 then
  pusher_dir=1
 end

 -- paw animation follows pusher
 if pusher_dir==1 then
  paw_anim=min(paw_anim+0.1,1)
 else
  paw_anim=max(paw_anim-0.1,0)
 end
end

function drop_coin(x,y,special)
 local c=make_coin(x,y,special)
 c.vy=0.5
 c.vx=(rnd(0.6)-0.3)
 add(falling_coins,c)
end

function update_coins()
 for c in all(coins) do
  c.age+=1

  -- pusher pushes coins
  if c.y-c.r < pusher_y+pusher_h and
     c.y+c.r > pusher_y and
     c.x > pusher_x and
     c.x < pusher_x+pusher_w then
   if pusher_dir==1 then
    c.vy+=0.3+rnd(0.2)
    c.vx+=(rnd(0.4)-0.2)
    c.y=pusher_y+pusher_h+c.r
   end
  end

  -- physics
  c.vy+=0.02  -- slight gravity
  c.x+=c.vx
  c.y+=c.vy

  -- friction
  c.vx*=0.96
  c.vy*=0.96

  -- walls
  if c.x<field_left+c.r then
   c.x=field_left+c.r
   c.vx=abs(c.vx)*0.5
  end
  if c.x>field_right-c.r then
   c.x=field_right-c.r
   c.vx=-abs(c.vx)*0.5
  end

  -- top wall
  if c.y<field_top+c.r then
   c.y=field_top+c.r
   c.vy=abs(c.vy)*0.3
  end

  -- wobble
  c.wobble+=0.05
 end

 -- coin-coin collisions
 for i=1,#coins do
  for j=i+1,#coins do
   coin_coin_collide(coins[i],coins[j])
  end
 end
end

function check_scored()
 for c in all(coins) do
  if c.y > field_bottom+c.r then
   -- scored!
   local val=10
   if c.special then
    val=50
    -- yarn ball: push all nearby coins
    for other in all(coins) do
     if other!=c then
      local d=dist(c,other)
      if d<30 then
       other.vy+=2
       other.vx+=(other.x-c.x)*0.1
       make_particle(other.x,other.y,10,15)
      end
     end
    end
   end

   -- combo
   combo+=1
   combo_timer=60
   if combo>1 then
    val=val*min(combo,5)
   end

   score+=val
   make_score_popup(c.x,field_bottom,val)
   del(coins,c)

   -- particles
   for i=1,6 do
    local col=c.special and 11 or 9
    make_particle(c.x,field_bottom,col,25)
   end
   sfx(3)
  end
 end
end

function update_particles()
 for p in all(particles) do
  p.x+=p.vx
  p.y+=p.vy
  p.vy+=0.05
  p.life-=1
  if p.life<=0 then
   del(particles,p)
  end
 end
end

function game_over()
 state="gameover"
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
 -- starry background
 for i=0,30 do
  local sx=(i*37+t)%128
  local sy=(i*53)%128
  local col=({1,5,6,13})[i%4+1]
  pset(sx,sy,col)
 end

 -- title
 local ty=25+sin(t/90)*4

 -- big cat face
 draw_big_cat(64,ty-2)

 -- title text with shadow
 print("cat coin",35,ty+22,0)
 print("cat coin",34,ty+21,10)
 print("pusher",42,ty+30,0)
 print("pusher",41,ty+29,9)

 -- bouncing coin
 local cy=ty+46+sin(t/30)*3
 draw_coin(64,cy,false)

 -- instructions
 if t%60<40 then
  print("\x8e\x91 to start",36,100,7)
 end
 print("\x83\x84:move \x8e:drop",22,110,6)
 print("hi-score: "..high_score,28,118,5)
end

function draw_big_cat(x,y)
 -- head
 circfill(x,y,14,4)
 circfill(x,y,13,10)

 -- ears
 local ear_off=cat_ear_twitch>0 and 1 or 0
 -- left ear
 line(x-10,y-8,x-14,y-18+ear_off,10)
 line(x-14,y-18+ear_off,x-6,y-12,10)
 line(x-11,y-10,x-13,y-16+ear_off,8)
 -- right ear
 line(x+10,y-8,x+14,y-18+ear_off,10)
 line(x+14,y-18+ear_off,x+6,y-12,10)
 line(x+11,y-10,x+13,y-16+ear_off,8)

 -- eyes
 if cat_blink>4 then
  line(x-5,y-2,x-3,y-2,0)
  line(x+3,y-2,x+5,y-2,0)
 else
  circfill(x-5,y-2,2,0)
  circfill(x+5,y-2,2,0)
  -- pupils
  pset(x-5,y-2,7)
  pset(x+5,y-2,7)
 end

 -- nose
 pset(x,y+2,8)

 -- mouth
 line(x-2,y+4,x,y+3,8)
 line(x,y+3,x+2,y+4,8)

 -- whiskers
 line(x-14,y,x-7,y+1,7)
 line(x-13,y+3,x-7,y+2,7)
 line(x+7,y+1,x+14,y,7)
 line(x+7,y+2,x+13,y+3,7)
end

function draw_play()
 -- background
 rectfill(0,0,127,127,1)

 -- play field bg
 rectfill(field_left-1,field_top-1,field_right+1,field_bottom+6,0)

 -- field border
 rect(field_left-2,field_top-2,field_right+2,field_bottom+7,5)

 -- scoring zone glow
 local glow_col=2+flr(t/8)%2
 rectfill(field_left-1,field_bottom,field_right+1,field_bottom+6,glow_col)
 print("score zone",field_left+14,field_bottom+1,7)

 -- side walls with pattern
 for y=field_top,field_bottom,4 do
  local col=(y/4)%2==0 and 4 or 9
  rectfill(field_left-4,y,field_left-2,y+3,col)
  rectfill(field_right+2,y,field_right+4,y+3,col)
 end

 -- draw pusher (cat paw)
 draw_pusher()

 -- draw coins
 for c in all(coins) do
  draw_coin(c.x,c.y,c.special)
 end
 for c in all(falling_coins) do
  draw_coin(c.x,c.y,c.special)
 end

 -- particles
 for p in all(particles) do
  local a=p.life/p.max_life
  if a>0.5 then
   pset(p.x,p.y,p.col)
  else
   pset(p.x,p.y,1)
  end
 end

 -- score popups
 for s in all(scored_coins) do
  local col=7
  if s.val>=50 then col=10 end
  if s.val>=100 then col=11 end
  print("+"..s.val,s.x-6,s.y,col)
 end

 -- dropper (small cat at top)
 draw_dropper()

 -- hud
 draw_hud()
end

function draw_pusher()
 local px=pusher_x
 local py=pusher_y
 local pw=pusher_w
 local ph=pusher_h

 -- paw pad (main body)
 rectfill(px+2,py,px+pw-2,py+ph,4)
 rectfill(px,py+2,px+pw,py+ph-2,4)

 -- paw outline
 rect(px+2,py,px+pw-2,py+ph,9)

 -- toe beans!
 local bean_y=py+3
 local spacing=pw/5
 for i=1,4 do
  local bx=px+spacing*i
  circfill(bx,bean_y,2,8)
  circfill(bx,bean_y,1,2)
 end

 -- big central pad
 circfill(px+pw/2,py+ph-3,3,8)
 circfill(px+pw/2,py+ph-3,2,2)

 -- push direction indicator
 if pusher_dir==1 then
  local arrow_y=py+ph+2
  for i=0,2 do
   pset(px+pw/2-i,arrow_y+i,7)
   pset(px+pw/2+i,arrow_y+i,7)
  end
 end
end

function draw_coin(x,y,special)
 if special then
  -- yarn ball
  circfill(x,y,4,11)
  circfill(x,y,3,3)
  -- yarn pattern
  local a=t/15
  pset(x+cos(a)*2,y+sin(a)*2,11)
  pset(x+cos(a+0.33)*2,y+sin(a+0.33)*2,11)
  pset(x+cos(a+0.66)*2,y+sin(a+0.66)*2,11)
  -- string
  line(x+3,y-1,x+5,y-3,11)
 else
  -- fish coin
  circfill(x,y,3,9)
  circfill(x,y,2,10)

  -- fish silhouette on coin
  local fx=x
  local fy=y
  -- body
  line(fx-1,fy,fx+1,fy,12)
  pset(fx+2,fy-1,12)
  pset(fx+2,fy+1,12)
  -- tail
  pset(fx-2,fy-1,12)
  pset(fx-2,fy+1,12)

  -- shine
  pset(x-1,y-1,7)
 end
end

function draw_dropper()
 local x=dropper_x
 local y=12

 -- cat head (small)
 circfill(x,y,5,10)
 -- ears
 line(x-4,y-3,x-6,y-7,10)
 line(x-6,y-7,x-2,y-5,10)
 line(x+4,y-3,x+6,y-7,10)
 line(x+6,y-7,x+2,y-5,10)
 -- inner ears
 pset(x-4,y-5,8)
 pset(x+4,y-5,8)
 -- eyes
 if cat_blink>4 then
  line(x-2,y-1,x-1,y-1,0)
  line(x+1,y-1,x+2,y-1,0)
 else
  pset(x-2,y-1,0)
  pset(x+2,y-1,0)
 end
 -- nose
 pset(x,y+1,8)
 -- mouth
 pset(x-1,y+2,8)
 pset(x+1,y+2,8)

 -- holding coin indicator
 if coins_left>0 then
  draw_coin(x,y+8,false)
  -- dotted line showing drop path
  for dy=y+12,drop_zone_y,4 do
   if (dy/4)%2==0 then
    pset(x,dy,6)
   end
  end
 end
end

function draw_hud()
 -- top bar bg
 rectfill(0,0,127,6,0)

 -- score
 print("score:"..score,1,1,7)

 -- coins left
 print("\x97"..coins_left,80,1,10)

 -- level
 print("lv"..level,108,1,9)

 -- yarn ball indicators (bottom)
 for i=1,#yarn_balls do
  circfill(118+i*8-8,124,3,11)
  circfill(118+i*8-8,124,2,3)
 end
 if #yarn_balls>0 then
  print("\x91",110,122,6)
 end

 -- combo display
 if combo>1 and combo_timer>0 then
  local cx=64
  local cy=field_top+4
  local txt="x"..combo.." combo!"
  local col=({7,10,9,8,11})[min(combo,5)]
  print(txt,cx-#txt*2,cy,col)
 end

 -- coins on field indicator
 rectfill(0,125,127,127,0)
 print("field:"..#coins,1,125,13)
end

function draw_gameover()
 -- dark bg
 cls(0)

 -- sad cat
 draw_big_cat(64,30)

 -- game over text
 print("game over",38,55,8)
 print("game over",37,54,2)

 -- results
 print("final score",36,68,7)
 print(""..score,56,76,10)

 if score>=high_score and score>0 then
  -- new record!
  if t%30<20 then
   print("new record!",36,88,11)
  end
 else
  print("best: "..high_score,40,88,5)
 end

 print("level reached: "..level,28,98,6)

 if t>60 then
  if t%60<40 then
   print("\x8e\x91 continue",32,115,7)
  end
 end
end

----------------------------
-- sfx data placeholder
-- (pico-8 beeps)
----------------------------
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
