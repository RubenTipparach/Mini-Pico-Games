pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cat coin pusher roguelike
-- by claude code

-------------------------------
-- special coin definitions
-------------------------------
spc_names={"bomb","whirl","b.hole",
 "magnet","gold","multi",
 "quake","ice","clone","crown",
 "cash"}
spc_cols={8,12,0,12,10,9,4,12,11,10,14}
spc_costs={30,25,40,20,15,35,30,25,20,45,50}
spc_descs={
 "blast coins to edge",
 "spin coins to center",
 "suck then release",
 "pull coins together",
 "worth 5x when scored",
 "2x score 6 seconds",
 "shake all coins",
 "freeze pusher 5 sec",
 "spawn 5 extra coins",
 "3x combo 8 seconds",
 "score nearby coins!"
}
num_specials=11

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
gold=0
coins_left=0
total_scored=0
high_score=0
score_per_gold=1
round_gold_given=0

-- buffs
score_mult=1
mult_timer=0
combo_mult=1
combo_buff_timer=0

-- combo tracking
combo=0
combo_timer=0
-- combo threshold for spinner
combo_best=0 -- best combo this round
combo_threshold=5 -- coins in combo to trigger spinner
spinner_pending=false

-- spinner state
spin_items={} -- 3 prize options
spin_sel=0    -- current spinning index
spin_speed=0
spin_timer=0
spin_result=0
spin_done=false
spin_mult=1   -- combo multiplier for prize

-- inventory
inv={}
inv_sel=1
inv_max=5

-- shop
shop_items={}
shop_sel=1
refresh_cost=10
refresh_base=10

-- end-round
end_round_btn=false
end_round_sel=false

-- cat anims
cat_blink=0
cat_ear_twitch=0

-------------------------------
-- helpers
-------------------------------
-- buy coins cost
buy_coin_cost=5
buy_coin_amt=5

function make_coin(x,y,stype)
 return {
  x=x,y=y,vx=0,vy=0,
  r=2.5,on_pusher=false,
  stype=stype or 0,
  activated=false,val=1,
  fuse=0 -- >0 means waiting to activate
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

max_rounds=10

function get_target(r)
 return flr(150*1.5^(r-1))
end

-------------------------------
-- init
-------------------------------
function _init()
 cartdata("catcoinpush_rl2")
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
 combo_best=0
 total_scored=0
 target=get_target(round)
 coins_left=flr(30*1.3^(round-1))
 score_per_gold=max(1,flr(target/10))
 round_gold_given=0
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
 spinner_pending=false
 seed_coins(100+round*10)
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

function continue_round()
 state="play" t=0
 round_score=0
 combo=0
 combo_timer=0
 combo_best=0
 total_scored=0
 target=get_target(round)
 coins_left=flr(30*1.3^(round-1))
 score_per_gold=max(1,flr(target/10))
 round_gold_given=0
 dropping={}
 falling={}
 particles={}
 popups={}
 end_round_btn=false
 end_round_sel=false
 spinner_pending=false
end

-------------------------------
-- special coin effects
-------------------------------
function activate_special(c)
 if c.activated or c.stype==0 then return end
 c.activated=true
 local st=c.stype

 if st==1 then -- bomb (stronger)
  for o in all(coins) do
   if o!=c then
    local d=cdist(c,o)
    if d<28 then
     local nx=(o.x-c.x)/(d+0.1)
     local ny=(o.y-c.y)/(d+0.1)
     o.vx+=nx*4
     o.vy+=ny*4
    end
   end
  end
  for i=1,12 do
   make_particle(c.x,c.y,8,25)
   make_particle(c.x,c.y,10,20)
  end
  sfx(5)
 elseif st==2 then -- whirlpool
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
  -- passive
 elseif st==6 then -- multiplier (6 sec)
  score_mult=2
  mult_timer=360
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
 elseif st==8 then -- ice (5 sec)
  push.frozen=300
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
 elseif st==10 then -- crown (8 sec)
  combo_mult=3
  combo_buff_timer=480
  for i=1,8 do
   make_particle(c.x,c.y,10,20)
  end
  sfx(4)
 elseif st==11 then -- cashout
  -- instantly score nearby coins!
  local scored_list={}
  for o in all(coins) do
   if o!=c then
    local d=cdist(c,o)
    if d<22 then
     add(scored_list,o)
    end
   end
  end
  for o in all(scored_list) do
   -- teleport past scoring edge
   o.y=fb+5
   o.on_pusher=false
   for i=1,3 do
    make_particle(o.x,o.y-5,14,20)
   end
  end
  for i=1,10 do
   make_particle(c.x,c.y,14,25)
   make_particle(c.x,c.y,7,20)
  end
  sfx(4)
 end
end

-- trigger all fused specials early
function trigger_all_fused()
 for c in all(coins) do
  if c.stype>0 and c.fuse>0
     and not c.activated then
   c.fuse=0
   activate_special(c)
  end
 end
end

-------------------------------
-- spinner
-------------------------------
function open_spinner(cmult)
 state="spinner"
 t=0
 spin_mult=max(1,flr(cmult))
 -- 3 random prizes with more coins
 spin_items={}
 -- prize 1: big coin bonus
 local camt=15*spin_mult
 add(spin_items,{
  kind="coins",
  label="+"..camt.." coins",
  col=10,
  amt=camt})
 -- prize 2: gold or even more coins
 if rnd(1)<0.5 then
  add(spin_items,{
   kind="gold",
   label="+"..10*spin_mult.." gold",
   col=9,
   amt=10*spin_mult})
 else
  local c2=10*spin_mult
  add(spin_items,{
   kind="coins",
   label="+"..c2.." coins",
   col=10,
   amt=c2})
 end
 -- prize 3: random special
 local rs=flr(rnd(num_specials))+1
 add(spin_items,{
  kind="special",
  label=spc_names[rs].." coin",
  col=spc_cols[rs],
  stype=rs})
 -- shuffle order
 for i=#spin_items,2,-1 do
  local j=flr(rnd(i))+1
  spin_items[i],spin_items[j]=
   spin_items[j],spin_items[i]
 end
 spin_sel=1
 spin_speed=0.15+rnd(0.05)
 spin_timer=90+flr(rnd(40))
 spin_result=0
 spin_done=false
end

function update_spinner()
 t+=1
 if not spin_done then
  spin_timer-=1
  -- spin through items
  spin_sel+=spin_speed
  if spin_sel>=#spin_items+1 then
   spin_sel=1
  end
  -- slow down
  if spin_timer<40 then
   spin_speed*=0.97
  end
  if spin_timer<=0 or spin_speed<0.02 then
   -- stop
   spin_done=true
   spin_result=flr(spin_sel)
   if spin_result<1 then spin_result=1 end
   if spin_result>#spin_items then
    spin_result=#spin_items
   end
   -- award prize
   local prize=spin_items[spin_result]
   if prize.kind=="coins" then
    coins_left+=prize.amt
   elseif prize.kind=="gold" then
    gold+=prize.amt
   elseif prize.kind=="special" then
    if #inv<inv_max then
     add(inv,{type=prize.stype})
    else
     -- overflow: give gold instead
     gold+=20
    end
   end
   sfx(4)
  end
 else
  -- wait for button press
  if btnp(4) or btnp(5) then
   state="play"
   sfx(0)
  end
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
 elseif state=="shop" then
  update_shop()
 elseif state=="spinner" then
  update_spinner()
 elseif state=="gameover" then
  update_gameover()
 elseif state=="victory" then
  update_victory()
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

 -- X: use special or end round
 if btnp(5) then
  if end_round_btn and not end_round_sel then
   end_round_sel=true
  elseif end_round_sel then
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

 -- down: buy coins with gold
 if btnp(3) and gold>=buy_coin_cost then
  gold-=buy_coin_cost
  coins_left+=buy_coin_amt
  -- also trigger all fused specials!
  trigger_all_fused()
  sfx(0)
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
   -- specials get a 2-second fuse
   -- (goldfish is passive, no fuse)
   if c.stype>0 and c.stype!=5 then
    c.fuse=120
   end
  end
 end

 -- update fuse timers on field
 for c in all(coins) do
  if c.fuse>0 then
   c.fuse-=1
   if c.fuse<=0 then
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

 update_pusher()
 update_coins()
 check_scored()

 -- combo decay
 if combo_timer>0 then
  combo_timer-=1
  if combo_timer<=0 then
   -- combo ended: check threshold
   if combo>=combo_threshold and
      not spinner_pending then
    spinner_pending=true
    local cmult=flr(combo/combo_threshold)
    open_spinner(cmult)
    combo=0
    return
   end
   combo=0
  end
 end

 -- show end round button
 if coins_left<=0 and #dropping==0 then
  end_round_btn=true
 end
end

function finish_round()
 if round_score>=target then
  if round>=max_rounds then
   game_victory()
  else
   open_shop()
  end
 else
  game_over()
 end
end

function gen_shop_items()
 shop_items={}
 local used={}
 for i=1,3 do
  local st
  repeat
   st=flr(rnd(num_specials))+1
  until not used[st]
  used[st]=true
  add(shop_items,{
   type=st,
   cost=spc_costs[st]+round*5,
   sold=false
  })
 end
end

function open_shop()
 state="shop"
 t=0
 shop_sel=1
 refresh_cost=refresh_base+round*5
 gen_shop_items()
end

function update_shop()
 -- up/down navigation
 if btnp(2) then
  shop_sel=max(1,shop_sel-1)
 end
 if btnp(3) then
  -- 3 items + refresh + continue = 5 options
  shop_sel=min(5,shop_sel+1)
 end

 -- buy/select
 if btnp(4) or btnp(5) then
  if shop_sel<=3 then
   -- buy item
   local item=shop_items[shop_sel]
   if not item.sold and
      gold>=item.cost and
      #inv<inv_max then
    gold-=item.cost
    add(inv,{type=item.type})
    item.sold=true
    sfx(0)
   else
    sfx(5)
   end
  elseif shop_sel==4 then
   -- refresh
   if gold>=refresh_cost then
    gold-=refresh_cost
    refresh_cost=flr(refresh_cost*1.5)
    gen_shop_items()
    sfx(0)
   else
    sfx(5)
   end
  else
   -- continue
   round+=1
   continue_round()
  end
 end
end

function update_pusher()
 local prev_y=push.y
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
   if c.stype==5 then val=50 end
   combo+=1
   combo_timer=90
   if combo>combo_best then
    combo_best=combo
   end
   local cmult=min(combo,8)*combo_mult
   if combo>1 then
    val=val*cmult
   end
   val=flr(val*score_mult)
   round_score+=val
   total_scored+=1
   local new_g=flr(round_score/score_per_gold)
   local dg=new_g-round_gold_given
   if dg>0 then
    gold+=dg
    round_gold_given=new_g
   end
   make_popup(c.x,fb-8,val)

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

function game_victory()
 state="victory" t=0
 local total=0
 for r=1,max_rounds do
  total+=get_target(r)
 end
 total+=round_score-target
 if total>high_score then
  high_score=total
  dset(0,high_score)
 end
 sfx(4)
end

function update_victory()
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
 elseif state=="spinner" then
  draw_spinner()
 elseif state=="gameover" then
  draw_gameover()
 elseif state=="victory" then
  draw_victory()
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

function draw_coin_at(x,y,stype)
 circfill(x+1,y+1,2.5,1)
 circfill(x,y,3,stype>0 and spc_cols[stype] or 4)
 if stype==0 then
  circfill(x,y,2.5,9)
  circfill(x,y,2,10)
  line(x-1,y,x+1,y,12)
  pset(x-2,y,12) pset(x+2,y,12)
 elseif stype==1 then
  circfill(x,y,2.5,8)
  circfill(x,y,2,2)
  pset(x,y,10) pset(x-1,y-1,10)
 elseif stype==2 then
  circfill(x,y,2.5,12)
  circfill(x,y,2,1)
  pset(x,y,12)
 elseif stype==3 then
  circfill(x,y,2.5,0)
  circ(x,y,2,5)
  pset(x,y,5)
 elseif stype==4 then
  circfill(x,y,2.5,12)
  circfill(x,y,2,6)
  pset(x-1,y,8) pset(x+1,y,8)
 elseif stype==5 then
  circfill(x,y,2.5,10)
  circfill(x,y,2,9)
  line(x-1,y,x+1,y,7)
 elseif stype==6 then
  circfill(x,y,2.5,9)
  circfill(x,y,2,4)
  print("x",x-1,y-2,9)
 elseif stype==7 then
  circfill(x,y,2.5,4)
  circfill(x,y,2,5)
  line(x-2,y,x+2,y,9)
 elseif stype==8 then
  circfill(x,y,2.5,12)
  circfill(x,y,2,7)
  pset(x,y-1,12) pset(x,y+1,12)
 elseif stype==9 then
  circfill(x,y,2.5,11)
  circfill(x,y,2,3)
  pset(x-1,y,11) pset(x+1,y,11)
 elseif stype==10 then
  circfill(x,y,2.5,10)
  circfill(x,y,2,9)
  pset(x-1,y-2,10) pset(x,y-2,10)
  pset(x+1,y-2,10)
 elseif stype==11 then -- cashout
  circfill(x,y,2.5,14)
  circfill(x,y,2,15)
  pset(x,y,14)
  pset(x-1,y,7) pset(x+1,y,7)
 end
 pset(x-1,y-1,7)
end

function draw_play()
 cls(0)
 rectfill(fl-5,ft-5,fr+5,fb+6,5)
 rectfill(fl-3,ft-3,fr+3,fb+4,13)
 rectfill(fl,ft,fr,fb,3)
 for i=0,50 do
  local fx=(i*17)%(fw-2)+fl+1
  local fy=(i*29)%(fh-2)+ft+1
  pset(fx,fy,11)
 end
 rectfill(fl,ft-2,fr,ft,4)
 rectfill(fl,ft-1,fr,ft,9)
 rectfill(fl-1,ft,fl,fb,4)
 rectfill(fr,ft,fr+1,fb,4)

 draw_pusher()

 for c in all(coins) do
  circfill(c.x+1,c.y+1,2.5,1)
 end
 for c in all(coins) do
  draw_coin_at(c.x,c.y,c.stype)
  -- fuse countdown glow
  if c.fuse>0 then
   local pulse=sin(t/8)*2+4
   circ(c.x,c.y,pulse,
    spc_cols[c.stype] or 7)
   -- countdown dots
   local dots=flr(c.fuse/30)
   for d=0,min(dots,3) do
    pset(c.x-2+d*2,c.y-5,7)
   end
  end
 end
 for dc in all(dropping) do
  draw_coin_at(dc.x,dc.y,dc.stype)
 end

 for fc in all(falling) do
  fc.y+=fc.vy fc.x+=fc.vx
  fc.vy+=0.08
  fc.height+=fc.vheight
  fc.vheight+=0.15
  fc.life-=1
  if fc.life>0 then
   local h=fc.height
   if fc.life>15 then
    circfill(fc.x+1+h*0.4,
     fc.y+1+h*0.4,2.5+h*0.2,1)
   end
   local cr=max(1,2.5-h*0.1)
   circfill(fc.x,fc.y-h,cr+0.5,4)
   circfill(fc.x,fc.y-h,cr,10)
  else
   del(falling,fc)
  end
 end

 local gc=({8,2,8,14})[flr(t/10)%4+1]
 rectfill(fl,fb+1,fr,fb+3,gc)

 draw_dispenser()

 for p in all(particles) do
  pset(p.x,p.y,
   p.life/p.max_life>0.5 and p.col or 5)
 end
 for p in all(popups) do
  local col=7
  if p.val>=30 then col=10 end
  if p.val>=80 then col=11 end
  print("+"..p.val,p.x-5,p.y+1,0)
  print("+"..p.val,p.x-6,p.y,col)
 end

 draw_hud()
 draw_bottom_panel()
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
 rectfill(0,0,127,6,0)
 print("\f7r"..round,1,1)
 local scol=round_score>=target
  and "\fb" or "\fa"
 print(scol..round_score.."\f6/"..target,16,1)
 local bx=70
 if mult_timer>0 then
  print("\f92x",bx,1) bx+=12
 end
 if combo_buff_timer>0 then
  print("\fa3c",bx,1) bx+=12
 end
 print("\fcx"..coins_left,92,1)
 print("\fag"..gold,112,1)

 if combo>1 and combo_timer>0 then
  local col=({7,10,9,8,11})[min(combo,5)]
  local txt="x"..combo
  if combo>=combo_threshold then
   txt=txt.."!"
  end
  print(txt,56,9,col)
  -- combo meter
  local pct=min(1,combo/combo_threshold)
  rectfill(44,8,44+40,8,5)
  if pct>0 then
   rectfill(44,8,44+flr(40*pct),8,
    pct>=1 and 11 or 8)
  end
 end
end

function draw_bottom_panel()
 rectfill(0,64,127,127,0)

 -- progress bar (y=64-69)
 rectfill(1,64,126,69,1)
 local bw=min(124,
  flr(124*round_score/target))
 if bw>0 then
  local bc=round_score>=target and 11 or 8
  rectfill(2,65,2+bw,68,bc)
 end
 local stxt=round_score.."/"..target
 print(stxt,64-#stxt*2,65,7)

 -- inventory slots (y=71-82)
 print("\f6\x83\x84",1,72)
 for i=1,inv_max do
  local sx=10+(i-1)*22
  local sy=71
  local sel=i==inv_sel
  rectfill(sx,sy,sx+19,sy+11,
   sel and 1 or 0)
  rect(sx,sy,sx+19,sy+11,
   sel and 7 or 5)
  if i<=#inv then
   draw_coin_at(sx+10,sy+5,inv[i].type)
  else
   pset(sx+10,sy+5,5)
  end
 end
 print("\f6\x91",120,72)

 -- desc or end-round (y=84-93)
 if end_round_btn then
  local bcol=end_round_sel and 11 or 6
  rectfill(36,84,91,93,
   end_round_sel and 3 or 1)
  rect(36,84,91,93,bcol)
  print("end round\x91",39,87,bcol)
 elseif inv_sel>0 and inv_sel<=#inv then
  local item=inv[inv_sel]
  print(spc_names[item.type],2,85,
   spc_cols[item.type])
  print(spc_descs[item.type],2,92,6)
 end

 -- status + buy coins (y=98)
 print("\f6#"..#coins,2,99)
 -- buy coins prompt
 if gold>=buy_coin_cost then
  print("\f6\x83:buy "..buy_coin_amt.."coins g"..buy_coin_cost,30,99)
 end
 if round_score>=target and t%40<25 then
  print("\fbtarget!",96,99)
 end
end

function draw_spinner()
 cls(0)
 -- title
 rectfill(0,0,127,12,1)
 print("\f7combo prize!",30,1)
 print("\f6x"..spin_mult.." multiplier",32,7)

 -- spinner box
 rectfill(10,20,117,95,1)
 rect(10,20,117,95,7)

 -- draw 3 items vertically
 for i=1,3 do
  local iy=25+(i-1)*23
  local item=spin_items[i]
  local cur=flr(spin_sel)==i
   or (spin_done and spin_result==i)
  -- highlight current
  if not spin_done and
     flr(spin_sel)==i then
   rectfill(13,iy,114,iy+19,2)
  end
  if spin_done and spin_result==i then
   local fc=t%20<10 and 11 or 10
   rectfill(13,iy,114,iy+19,3)
   rect(13,iy,114,iy+19,fc)
  else
   rect(13,iy,114,iy+19,5)
  end

  -- icon
  if item.kind=="coins" then
   draw_coin_at(26,iy+10,0)
   draw_coin_at(32,iy+10,0)
  elseif item.kind=="gold" then
   circfill(28,iy+10,4,10)
   circfill(28,iy+10,3,9)
   print("g",26,iy+8,7)
  elseif item.kind=="special" then
   draw_coin_at(28,iy+10,item.stype)
  end

  -- label
  print(item.label,42,iy+7,item.col)
 end

 -- instruction
 if spin_done then
  local prize=spin_items[spin_result]
  if t%40<28 then
   print("\f7you won: "..prize.label,14,102)
  end
  print("\f6\x8e continue",40,112)
 else
  print("\f6spinning...",40,105)
 end
end

function draw_shop()
 cls(0)
 -- header (y=0-11)
 rectfill(0,0,127,11,1)
 print("\f7cat's shop",36,1)
 print("\f6round "..round.." clear!",32,7)

 -- gold + inv (y=14)
 print("\fagold:"..gold,4,14)
 print("\f6bag:"..#inv.."/"..inv_max,70,14)

 -- 3 items (y=22-76), 18px each
 for i=1,#shop_items do
  local item=shop_items[i]
  local iy=22+(i-1)*18
  local sel=i==shop_sel
  rectfill(4,iy,123,iy+15,
   sel and 1 or 0)
  rect(4,iy,123,iy+15,
   sel and 7 or 5)
  draw_coin_at(14,iy+5,item.type)
  local nm=spc_names[item.type]
  local col=item.sold and 5
   or spc_cols[item.type]
  print(nm,24,iy+1,col)
  print(spc_descs[item.type],24,iy+8,
   item.sold and 5 or 6)
  if item.sold then
   print("sold",100,iy+4,5)
  else
   print("g"..item.cost,100,iy+4,
    gold>=item.cost and 10 or 8)
  end
 end

 -- refresh button (shop_sel==4)
 local ry=78
 local rsel=shop_sel==4
 rectfill(4,ry,123,ry+12,rsel and 1 or 0)
 rect(4,ry,123,ry+12,rsel and 7 or 5)
 print("refresh items",14,ry+3,
  rsel and 7 or 6)
 print("g"..refresh_cost,100,ry+3,
  gold>=refresh_cost and 10 or 8)

 -- continue (shop_sel==5)
 local cy=94
 local csel=shop_sel==5
 rectfill(30,cy,97,cy+10,csel and 3 or 1)
 rect(30,cy,97,cy+10,csel and 7 or 5)
 print("continue \x8e",38,cy+2,
  csel and 7 or 6)

 -- controls (y=112)
 print("\f6\x8b\x83 select  \x8e buy",20,112)
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

function draw_victory()
 cls(0)
 for i=0,60 do
  local sx=(i*23+t*0.5)%128
  local sy=(i*41+t*0.2)%128
  pset(sx,sy,({10,9,11,7})[i%4+1])
 end
 draw_big_cat(64,18)
 print("you win!",40,44,0)
 print("you win!",39,43,11)
 print("all 10 rounds clear!",16,56,10)
 print("total gold: "..gold,32,70,9)
 if high_score>0 then
  print("best: "..high_score,40,82,5)
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
