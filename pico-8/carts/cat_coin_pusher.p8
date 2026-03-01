pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cat coin pusher roguelike
-- by claude code

-------------------------------
-- special coin definitions
-- 1=bomb 2=whirlpool 3=blackhole
-- 4=magnet 5=goldfish 6=multiplier
-- 7=earthquake 8=ice 9=clone
-- 10=crown
-------------------------------
spc_names={"bomb","whirl","b.hole",
 "magnet","gold","multi",
 "quake","ice","clone","crown"}
spc_cols={8,12,0,12,10,9,4,12,11,10}
spc_icons={} -- drawn procedurally
spc_costs={30,25,40,20,15,35,30,25,20,45}
spc_descs={
 "blast coins to edge",
 "spin coins to center",
 "suck then release",
 "pull coins together",
 "worth 5x when scored",
 "2x score 3 seconds",
 "shake all coins",
 "freeze pusher forward",
 "spawn 5 extra coins",
 "3x combo 5 seconds"
}

-------------------------------
-- globals
-------------------------------
state="title"
t=0

-- field
fl=10  fr=118
ft=16  fb=60
fw=fr-fl fh=fb-ft

-- pusher
push={y=24,h=10,min_y=22,max_y=38,
 dir=1,speed=0.35,frozen=0}

-- dispenser
disp={x=64,dir=1,speed=0.6}

-- coin lists
coins={}
dropping={}
falling={}
particles={}
popups={}

-- roguelike state
round=1
round_score=0
target=0
gold=0 -- currency for shop
coins_left=0
total_scored=0
high_score=0
run_over=false

-- multiplier/crown buffs
score_mult=1
mult_timer=0
combo_mult=1
combo_buff_timer=0

-- combo
combo=0
combo_timer=0

-- inventory: up to 5 special coins
inv={} -- {type=1..10}
inv_sel=1 -- selected slot
inv_max=5

-- shop offerings
shop_items={}
shop_sel=1
shop_page="buy" -- buy or done

-- cat anims
cat_blink=0
cat_ear_twitch=0

-- end-round button
end_round_btn=false
end_round_sel=false

-------------------------------
-- helpers
-------------------------------
function make_coin(x,y,stype)
 return {
  x=x,y=y,vx=0,vy=0,
  r=2.5,on_pusher=false,
  stype=stype or 0, -- 0=normal
  activated=false,
  val=1
 }
end

function make_particle(x,y,col,life)
 add(particles,{x=x,y=y,
  vx=rnd(2)-1,vy=rnd(2)-1,
  life=life or 20,
  max_life=life or 20,col=col})
end

function make_popup(x,y,val)
 add(popups,{x=x,y=y,val=val,
  timer=45,vy=-0.6})
end

function cdist(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 return sqrt(dx*dx+dy*dy)
end

function collide_coins(a,b)
 local d=cdist(a,b)
 local m=a.r+b.r
 if d<m and d>0.1 then
  local nx=(b.x-a.x)/d
  local ny=(b.y-a.y)/d
  local ov=m-d
  a.x-=nx*ov*0.5
  a.y-=ny*ov*0.5
  b.x+=nx*ov*0.5
  b.y+=ny*ov*0.5
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

function get_target(r)
 return 80+r*60+r*r*10
end

-------------------------------
-- init
-------------------------------
function _init()
 cartdata("catcoinpush_rl1")
 high_score=dget(0)
 start_title()
end

function start_title()
 state="title" t=0
end

function start_run()
 round=1
 gold=0
 inv={}
 run_over=false
 score_mult=1
 mult_timer=0
 combo_mult=1
 combo_buff_timer=0
 start_round()
end

function start_round()
 state="play" t=0
 round_score=0
 combo=0
 combo_timer=0
 total_scored=0
 target=get_target(round)
 coins_left=30+round*5
 coins={}
 dropping={}
 falling={}
 particles={}
 popups={}
 push.y=24
 push.dir=1
 push.frozen=0
 disp.x=64
 disp.dir=1
 end_round_btn=false
 end_round_sel=false
 seed_coins(50+round*8)
end

function seed_coins(n)
 for i=1,n do
  local att=0
  local ok=false
  while not ok and att<40 do
   local cx=fl+4+rnd(fw-8)
   local cy=push.max_y+3+rnd(fb-push.max_y-5)
   local pass=true
   for c in all(coins) do
    local dx=cx-c.x
    local dy=cy-c.y
    if sqrt(dx*dx+dy*dy)<5 then
     pass=false break
    end
   end
   if pass then
    add(coins,make_coin(cx,cy))
    ok=true
   end
   att+=1
  end
 end
end

-------------------------------
-- special coin effects
-------------------------------
function activate_special(c)
 if c.activated or c.stype==0 then return end
 c.activated=true
 local st=c.stype

 if st==1 then -- bomb
  for o in all(coins) do
   if o!=c then
    local d=cdist(c,o)
    if d<20 then
     local nx=(o.x-c.x)/(d+0.1)
     local ny=(o.y-c.y)/(d+0.1)
     o.vx+=nx*3
     o.vy+=ny*3
    end
   end
  end
  for i=1,12 do
   make_particle(c.x,c.y,8,20)
   make_particle(c.x,c.y,10,15)
  end
  sfx(5)
 elseif st==2 then -- whirlpool
  local cx=(fl+fr)/2
  for o in all(coins) do
   if o!=c then
    local d=cdist(c,o)
    if d<25 then
     local ang=atan2(o.x-c.x,o.y-c.y)
     o.vx+=cos(ang+0.25)*1.5
     o.vy+=sin(ang+0.25)*1.5+0.5
    end
   end
  end
  for i=1,8 do
   make_particle(c.x,c.y,12,25)
  end
  sfx(4)
 elseif st==3 then -- black hole
  for o in all(coins) do
   if o!=c then
    local d=cdist(c,o)
    if d<30 then
     local nx=(c.x-o.x)/(d+0.1)
     local ny=(c.y-o.y)/(d+0.1)
     o.vx+=nx*2
     o.vy+=ny*2
    end
   end
  end
  -- delayed release handled by timer
  for i=1,10 do
   make_particle(c.x,c.y,0,20)
   make_particle(c.x,c.y,1,18)
  end
  sfx(5)
 elseif st==4 then -- magnet
  for o in all(coins) do
   if o!=c then
    local d=cdist(c,o)
    if d<22 then
     local nx=(c.x-o.x)/(d+0.1)
     local ny=(c.y-o.y)/(d+0.1)
     o.vx+=nx*1.5
     o.vy+=ny*1.5
    end
   end
  end
  for i=1,6 do
   make_particle(c.x,c.y,12,15)
  end
  sfx(3)
 elseif st==5 then -- goldfish
  -- passive: scored at 5x (handled in check_scored)
 elseif st==6 then -- multiplier
  score_mult=2
  mult_timer=180
  for i=1,6 do
   make_particle(c.x,c.y,9,20)
  end
  sfx(4)
 elseif st==7 then -- earthquake
  for o in all(coins) do
   o.vx+=rnd(2)-1
   o.vy+=rnd(2)-1
  end
  for i=1,8 do
   make_particle(c.x,c.y,4,15)
  end
  sfx(5)
 elseif st==8 then -- ice
  push.frozen=180
  for i=1,8 do
   make_particle(c.x,c.y,12,20)
   make_particle(c.x,c.y,7,15)
  end
  sfx(4)
 elseif st==9 then -- clone
  for i=1,5 do
   local nc=make_coin(
    c.x+rnd(10)-5,
    c.y+rnd(10)-5)
   nc.vy=0.5+rnd(0.5)
   nc.vx=rnd(1)-0.5
   add(coins,nc)
  end
  for i=1,6 do
   make_particle(c.x,c.y,11,15)
  end
  sfx(3)
 elseif st==10 then -- crown
  combo_mult=3
  combo_buff_timer=300
  for i=1,8 do
   make_particle(c.x,c.y,10,20)
  end
  sfx(4)
 end
end

-------------------------------
-- update
-------------------------------
function _update60()
 t+=1
 update_cat()

 if state=="title" then
  update_title()
 elseif state=="play" then
  update_play()
 elseif state=="endround" then
  update_endround()
 elseif state=="shop" then
  update_shop()
 elseif state=="gameover" then
  update_gameover()
 end

 for p in all(particles) do
  p.x+=p.vx p.y+=p.vy
  p.vy+=0.03 p.life-=1
  if p.life<=0 then del(particles,p) end
 end
 for p in all(popups) do
  p.y+=p.vy p.timer-=1
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
  start_run()
  sfx(0)
 end
end

function update_play()
 -- dispenser auto-moves
 disp.x+=disp.dir*disp.speed
 if disp.x>=fr-6 then
  disp.dir=-1 disp.x=fr-6
 end
 if disp.x<=fl+6 then
  disp.dir=1 disp.x=fl+6
 end

 -- left/right: select inventory
 if btnp(0) then
  inv_sel=max(1,inv_sel-1)
 end
 if btnp(1) then
  inv_sel=min(#inv,inv_sel+1)
 end

 -- Z: drop normal coin
 if btnp(4) and coins_left>0 and
    not end_round_sel then
  local dc={x=disp.x,y=ft-4,
   target_y=ft+4+rnd(4),
   timer=12,height=8,stype=0}
  add(dropping,dc)
  coins_left-=1
  sfx(0)
 end

 -- X: use selected special coin
 if btnp(5) then
  if end_round_btn and not end_round_sel then
   end_round_sel=true
  elseif end_round_sel then
   -- confirm end round
   finish_round()
   return
  elseif #inv>=inv_sel and inv_sel>0 then
   local item=inv[inv_sel]
   local dc={x=disp.x,y=ft-4,
    target_y=ft+4+rnd(4),
    timer=12,height=8,
    stype=item.type}
   add(dropping,dc)
   del(inv,item)
   if inv_sel>#inv then
    inv_sel=max(1,#inv)
   end
   sfx(0)
  end
 end

 -- update dropping
 for dc in all(dropping) do
  dc.y+=(dc.target_y-dc.y)*0.3
  dc.height*=0.75
  dc.timer-=1
  if dc.timer<=0 then
   local c=make_coin(dc.x,dc.target_y,dc.stype)
   if dc.target_y<push.y and
      dc.target_y>(push.y-push.h) then
    c.on_pusher=true
   end
   add(coins,c)
   del(dropping,dc)
   sfx(2)
   -- activate on land if special
   if c.stype>0 and c.stype!=5 then
    activate_special(c)
   end
  end
 end

 -- buff timers
 if mult_timer>0 then
  mult_timer-=1
  if mult_timer<=0 then score_mult=1 end
 end
 if combo_buff_timer>0 then
  combo_buff_timer-=1
  if combo_buff_timer<=0 then combo_mult=1 end
 end

 -- pusher
 update_pusher()
 update_coins()
 check_scored()

 -- combo
 if combo_timer>0 then
  combo_timer-=1
  if combo_timer<=0 then combo=0 end
 end

 -- show end round button when out of coins
 if coins_left<=0 and #dropping==0 and
    #inv==0 then
  end_round_btn=true
 end
 -- also allow ending early if only
 -- specials remain and no normals
 if coins_left<=0 and #dropping==0 then
  end_round_btn=true
 end
end

function finish_round()
 if round_score>=target then
  -- success! gold reward
  gold+=flr(round_score/10)
  gold+=round*5
  open_shop()
 else
  -- failed to reach target
  game_over()
 end
end

function open_shop()
 state="shop"
 t=0
 shop_sel=1
 shop_page="buy"
 -- generate 4 random items
 shop_items={}
 local used={}
 for i=1,4 do
  local st
  repeat
   st=flr(rnd(10))+1
  until not used[st]
  used[st]=true
  add(shop_items,{
   type=st,
   cost=spc_costs[st]+round*5,
   sold=false
  })
 end
end

function update_endround()
 if btnp(4) or btnp(5) then
  if round_score>=target then
   open_shop()
  else
   game_over()
  end
 end
end

function update_shop()
 -- navigate
 if btnp(0) then
  shop_sel=max(1,shop_sel-1)
 end
 if btnp(1) then
  shop_sel=min(#shop_items+1,shop_sel+1)
 end

 -- buy or continue
 if btnp(4) or btnp(5) then
  if shop_sel<=#shop_items then
   local item=shop_items[shop_sel]
   if not item.sold and
      gold>=item.cost and
      #inv<inv_max then
    gold-=item.cost
    add(inv,{type=item.type})
    item.sold=true
    sfx(0)
   else
    sfx(5) -- can't buy
   end
  else
   -- "continue" selected
   round+=1
   start_round()
  end
 end
end

function update_pusher()
 local prev_y=push.y

 -- frozen pusher stays extended
 if push.frozen>0 then
  push.frozen-=1
  push.y=push.max_y
 else
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
 end

 local dy=push.y-prev_y
 local ptop=push.y-push.h

 for c in all(coins) do
  if c.on_pusher then
   c.y+=dy
   if push.dir==-1 then
    if c.y-c.r<=ft then
     c.y=ft+c.r
     c.vy=0.5+rnd(0.3)
     c.vx=(rnd(1)-0.5)*0.3
     c.on_pusher=false
    end
   end
   if c.y+c.r>push.y then
    c.on_pusher=false
    c.y=push.y+c.r
    c.vy=0.3
   end
   if c.y-c.r<ptop then
    c.on_pusher=false
    c.y=ptop-c.r
   end
  else
   if push.dir==1 and dy>0 then
    if c.y-c.r<push.y and
       c.y+c.r>push.y-4 and
       c.x>fl and c.x<fr then
     c.vy+=dy*0.8
     c.y=push.y+c.r
     c.vx+=(rnd(0.2)-0.1)
    end
   end
   if c.y>ptop and c.y<push.y and
      c.x>fl and c.x<fr then
    if abs(c.vy)<0.3 then
     c.on_pusher=true
     c.vx*=0.5 c.vy=0
    end
   end
  end
 end
end

function update_coins()
 for c in all(coins) do
  if not c.on_pusher then
   c.x+=c.vx c.y+=c.vy
   c.vx*=0.92 c.vy*=0.92
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
   if c.stype==5 then val=50 end --goldfish
   combo+=1
   combo_timer=90
   local cmult=min(combo,8)*combo_mult
   if combo>1 then
    val=val*cmult
   end
   val=flr(val*score_mult)
   round_score+=val
   total_scored+=1
   make_popup(c.x,fb-8,val)
   -- gold from scored coins
   gold+=max(1,flr(val/20))

   add(falling,{x=c.x,y=fb+2,
    vy=0.8+rnd(0.5),
    vx=rnd(0.6)-0.3,
    height=0,vheight=0.3,life=35})
   for k=1,4 do
    local col=c.stype>0 and spc_cols[c.stype] or 9
    make_particle(c.x,fb,col,18)
   end
   del(coins,c)
   sfx(3)
  end
 end
end

function game_over()
 state="gameover" t=0
 local total=0
 for r=1,round-1 do
  total+=get_target(r)
 end
 total+=round_score
 if total>high_score then
  high_score=total
  dset(0,high_score)
 end
 sfx(5)
end

function update_gameover()
 if t>60 and (btnp(4) or btnp(5)) then
  start_title()
 end
end

-------------------------------
-- drawing
-------------------------------
function _draw()
 cls(0)
 if state=="title" then
  draw_title()
 elseif state=="play" then
  draw_play()
 elseif state=="shop" then
  draw_shop()
 elseif state=="gameover" then
  draw_gameover()
 end
end

function draw_title()
 for i=0,40 do
  local sx=(i*37+t*0.3)%128
  local sy=(i*53+t*0.1)%128
  pset(sx,sy,({1,5,6,13})[i%4+1])
 end
 local ty=15+sin(t/90)*3
 draw_big_cat(64,ty)
 print("cat coin",35,ty+24,0)
 print("cat coin",34,ty+23,10)
 print("pusher",42,ty+32,0)
 print("pusher",41,ty+31,9)
 print("roguelike",36,ty+40,0)
 print("roguelike",35,ty+39,8)
 local cy=ty+55+sin(t/25)*4
 draw_coin_at(64,cy,0)
 if t%60<40 then
  print("\x8e\x91 to start",36,100,7)
 end
 print("reach the target each",14,110,6)
 print("round or it's game over!",10,118,6)
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
  pset(x-5,y-2,7) pset(x+5,y-2,7)
 end
 pset(x,y+2,8)
 line(x-2,y+4,x,y+3,8)
 line(x,y+3,x+2,y+4,8)
 line(x-14,y,x-7,y+1,7)
 line(x-13,y+3,x-7,y+2,7)
 line(x+7,y+1,x+14,y,7)
 line(x+7,y+2,x+13,y+3,7)
end

-- draw a coin (normal or special)
function draw_coin_at(x,y,stype)
 -- shadow
 circfill(x+1,y+1,2.5,1)
 -- rim
 circfill(x,y,3,stype>0 and spc_cols[stype] or 4)
 -- body
 if stype==0 then
  circfill(x,y,2.5,9)
  circfill(x,y,2,10)
  line(x-1,y,x+1,y,12)
  pset(x-2,y,12) pset(x+2,y,12)
 elseif stype==1 then --bomb
  circfill(x,y,2.5,8)
  circfill(x,y,2,2)
  pset(x,y,10) pset(x-1,y-1,10)
 elseif stype==2 then --whirlpool
  circfill(x,y,2.5,12)
  circfill(x,y,2,1)
  pset(x,y,12)
  pset(x+1,y-1,7)
 elseif stype==3 then --blackhole
  circfill(x,y,2.5,0)
  circfill(x,y,2,0)
  circ(x,y,2,5)
  pset(x,y,5)
 elseif stype==4 then --magnet
  circfill(x,y,2.5,12)
  circfill(x,y,2,6)
  pset(x-1,y,8) pset(x+1,y,8)
 elseif stype==5 then --goldfish
  circfill(x,y,2.5,10)
  circfill(x,y,2,9)
  line(x-1,y,x+1,y,7)
 elseif stype==6 then --multiplier
  circfill(x,y,2.5,9)
  circfill(x,y,2,4)
  print("x",x-1,y-2,9)
 elseif stype==7 then --earthquake
  circfill(x,y,2.5,4)
  circfill(x,y,2,5)
  line(x-2,y,x+2,y,9)
 elseif stype==8 then --ice
  circfill(x,y,2.5,12)
  circfill(x,y,2,7)
  pset(x,y-1,12) pset(x,y+1,12)
 elseif stype==9 then --clone
  circfill(x,y,2.5,11)
  circfill(x,y,2,3)
  pset(x-1,y,11) pset(x+1,y,11)
 elseif stype==10 then --crown
  circfill(x,y,2.5,10)
  circfill(x,y,2,9)
  pset(x-1,y-2,10) pset(x,y-2,10)
  pset(x+1,y-2,10)
 end
 pset(x-1,y-1,7)
end

function draw_play()
 cls(0)

 -- machine surround
 rectfill(fl-5,ft-5,fr+5,fb+6,5)
 rectfill(fl-3,ft-3,fr+3,fb+4,13)

 -- field surface
 rectfill(fl,ft,fr,fb,3)
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

 -- pusher
 draw_pusher()

 -- coins shadows
 for c in all(coins) do
  circfill(c.x+1,c.y+1,2.5,1)
 end
 -- coins
 for c in all(coins) do
  draw_coin_at(c.x,c.y,c.stype)
 end

 -- dropping
 for dc in all(dropping) do
  draw_coin_at(dc.x,dc.y,dc.stype)
 end

 -- falling scored
 for fc in all(falling) do
  fc.y+=fc.vy fc.x+=fc.vx
  fc.vy+=0.08
  fc.height+=fc.vheight
  fc.vheight+=0.15
  fc.life-=1
  if fc.life>0 then
   local h=fc.height
   if fc.life>15 then
    circfill(fc.x+1+h*0.4,fc.y+1+h*0.4,2.5+h*0.2,1)
   end
   local cr=max(1,2.5-h*0.1)
   circfill(fc.x,fc.y-h,cr+0.5,4)
   circfill(fc.x,fc.y-h,cr,10)
  else
   del(falling,fc)
  end
 end

 -- score zone
 local gc=({8,2,8,14})[flr(t/10)%4+1]
 rectfill(fl,fb+1,fr,fb+3,gc)

 -- dispenser
 draw_dispenser()

 -- particles
 for p in all(particles) do
  pset(p.x,p.y,
   p.life/p.max_life>0.5 and p.col or 5)
 end

 -- popups
 for p in all(popups) do
  local col=7
  if p.val>=30 then col=10 end
  if p.val>=80 then col=11 end
  print("+"..p.val,p.x-5,p.y+1,0)
  print("+"..p.val,p.x-6,p.y,col)
 end

 -- hud + inventory
 draw_hud()
 draw_inventory()
end

function draw_pusher()
 local py=push.y
 local ptop=py-push.h
 rectfill(fl+2,ptop+2,fr-2,py+2,1)
 local bcol=push.frozen>0 and 12 or 4
 rectfill(fl+1,ptop,fr-1,py,bcol)
 rect(fl+1,ptop,fr-1,py,9)
 local bw=(fr-fl-8)/5
 for i=1,4 do
  local bx=fl+4+i*bw+bw/2
  circfill(bx,py-2,2,8)
  circfill(bx,py-2,1,14)
 end
 local cx=(fl+fr)/2
 circfill(cx,ptop+push.h*0.4,2.5,8)
 circfill(cx,ptop+push.h*0.4,1.5,14)
 line(fl+3,py,fr-3,py,10)
 -- ice effect
 if push.frozen>0 then
  for i=0,3 do
   local fx=fl+10+i*25
   pset(fx,ptop+2,7)
   pset(fx+1,ptop+3,12)
  end
 end
end

function draw_dispenser()
 local x=disp.x
 local y=ft-3
 rectfill(fl,ft-7,fr,ft-4,5)
 line(fl,ft-4,fr,ft-4,13)
 circfill(x,y-4,5,10)
 local eo=cat_ear_twitch>0 and 1 or 0
 line(x-4,y-7,x-6,y-11+eo,10)
 line(x-6,y-11+eo,x-2,y-8,10)
 line(x+4,y-7,x+6,y-11+eo,10)
 line(x+6,y-11+eo,x+2,y-8,10)
 pset(x-4,y-10+eo,8)
 pset(x+4,y-10+eo,8)
 if cat_blink>5 then
  line(x-2,y-5,x-1,y-5,0)
  line(x+1,y-5,x+2,y-5,0)
 else
  pset(x-2,y-5,0) pset(x+2,y-5,0)
 end
 pset(x,y-3,8)
 rectfill(x-2,y-1,x+2,y,0)
 if coins_left>0 then
  circfill(x,y-2,2,10)
  pset(x,y-2,12)
 end
 if disp.dir==1 then
  pset(x+7,y-4,7) pset(x+6,y-5,7)
  pset(x+6,y-3,7)
 else
  pset(x-7,y-4,7) pset(x-6,y-5,7)
  pset(x-6,y-3,7)
 end
end

function draw_hud()
 -- top bar
 rectfill(0,0,127,6,0)
 -- round
 print("\f7r"..round,1,1)
 -- score vs target
 local scol=round_score>=target and "\fb" or "\fa"
 print(scol..round_score.."\f6/"..target,16,1)
 -- coins left
 print("\fcx"..coins_left,82,1)
 -- gold
 print("\fag"..gold,104,1)

 -- buffs
 if mult_timer>0 then
  print("\f92x",70,1)
 end
 if combo_buff_timer>0 then
  print("\fa3c",60,1)
 end

 -- combo
 if combo>1 and combo_timer>0 then
  local col=({7,10,9,8,11})[min(combo,5)]
  print("x"..combo.."!",58,9,col)
 end

 -- end round button
 if end_round_btn then
  local bx=50
  local by=fb+6
  local bcol=end_round_sel and 11 or 6
  rectfill(bx,by,bx+28,by+7,
   end_round_sel and 3 or 1)
  rect(bx,by,bx+28,by+7,bcol)
  print("end\x91",bx+4,by+1,bcol)
 end
end

function draw_inventory()
 -- inventory bar in the empty space
 -- below the field (y=68 to y=127)
 local iy=72
 rectfill(0,68,127,127,0)

 -- label
 print("\f6power coins:",2,69)
 print("\f6\x83\x84sel \x91use",70,69)

 -- draw 5 slots
 for i=1,inv_max do
  local sx=4+(i-1)*25
  local sy=iy

  -- slot bg
  local sel=i==inv_sel
  rectfill(sx,sy,sx+22,sy+18,sel and 1 or 0)
  rect(sx,sy,sx+22,sy+18,sel and 7 or 5)

  if i<=#inv then
   local item=inv[i]
   -- draw coin icon
   draw_coin_at(sx+11,sy+7,item.type)
   -- name
   local nm=spc_names[item.type]
   print(nm,sx+1,sy+13,spc_cols[item.type])
  else
   -- empty slot
   print("-",sx+10,sy+8,5)
  end
 end

 -- selected description
 if inv_sel>0 and inv_sel<=#inv then
  local item=inv[inv_sel]
  local d=spc_descs[item.type]
  print(d,2,iy+22,7)
 end

 -- round info
 local pct=flr(round_score*100/target)
 print("\f6target:",2,iy+30)
 -- progress bar
 rectfill(38,iy+30,120,iy+35,1)
 local bw=min(82,flr(82*round_score/target))
 if bw>0 then
  local bc=round_score>=target and 11 or 8
  rectfill(38,iy+30,38+bw,iy+35,bc)
 end
 print(round_score.."/"..target,42,iy+31,7)

 -- gold display
 print("\fagold:"..gold,2,iy+39)
 print("\f6#"..#coins.." on field",50,iy+39)

 -- round status
 if round_score>=target then
  if t%40<25 then
   print("\fbtarget reached!",30,iy+47)
  end
 end
end

function draw_shop()
 cls(0)
 -- shop header
 rectfill(0,0,127,12,1)
 print("\f7cat's shop",36,2)
 print("\f6round "..round.." complete!",28,8)

 -- gold display
 print("\fagold: "..gold,4,18)
 print("\f6inventory: "..#inv.."/"..inv_max,60,18)

 -- items
 for i=1,#shop_items do
  local item=shop_items[i]
  local y=26+(i-1)*20
  local sel=i==shop_sel
  -- bg
  rectfill(4,y,123,y+17,sel and 1 or 0)
  rect(4,y,123,y+17,sel and 7 or 5)

  -- coin icon
  draw_coin_at(14,y+6,item.type)

  -- name
  local nm=spc_names[item.type]
  local col=item.sold and 5 or spc_cols[item.type]
  print(nm,24,y+2,col)

  -- desc
  print(spc_descs[item.type],24,y+9,item.sold and 5 or 6)

  -- cost
  if item.sold then
   print("sold",100,y+5,5)
  else
   print("g"..item.cost,100,y+5,
    gold>=item.cost and 10 or 8)
  end
 end

 -- continue button
 local cy=26+#shop_items*20
 local sel=shop_sel==#shop_items+1
 rectfill(30,cy,97,cy+12,sel and 3 or 1)
 rect(30,cy,97,cy+12,sel and 7 or 5)
 print("continue \x8e",38,cy+3,sel and 7 or 6)

 -- controls
 print("\f6\x83\x84 select  \x8e buy",20,120)
end

function draw_gameover()
 cls(0)
 draw_big_cat(64,22)
 print("game over",38,46,8)
 print("game over",37,45,2)

 print("reached round "..round,28,60,7)
 print("round score: "..round_score,24,70,6)
 print("target was: "..target,28,78,
  round_score>=target and 11 or 8)

 if high_score>0 then
  print("best: "..high_score,40,92,5)
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
__sfx__
000200001805018050180001800018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000024050240502400024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000c0500c0500c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002405024050300503005030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001805024050300503005036050360500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000030050240501805012050060500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
