pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- italian restaurant
-- a cooking game!

-- game states
gs_menu=0
gs_play=1
gs_over=2
gs_win=3
state=gs_menu

-- chef player
chef={
  x=64,y=80,
  dir=1, -- 1=right,-1=left
  frame=0,
  anim_t=0,
  holding=nil,
  speed=1.2
}

-- cooking stations
stations={
  {id=1,name="oven",x=16,y=24,w=24,h=20,
   cook_time=180,cooking=nil,progress=0,
   makes={"pizza","lasagna"}},
  {id=2,name="stove",x=52,y=24,w=24,h=20,
   cook_time=150,cooking=nil,progress=0,
   makes={"pasta","meatballs"}},
  {id=3,name="prep",x=88,y=24,w=24,h=20,
   cook_time=120,cooking=nil,progress=0,
   makes={"tiramisu","ravioli"}}
}

-- ingredient boxes
ingredients={
  {name="dough",x=8,y=100,spr=32},
  {name="tomato",x=28,y=100,spr=33},
  {name="cheese",x=48,y=100,spr=34},
  {name="pasta",x=68,y=100,spr=35},
  {name="meat",x=88,y=100,spr=36},
  {name="cream",x=108,y=100,spr=37}
}

-- recipes
recipes={
  pizza={ing={"dough","tomato","cheese"},
         station="oven",spr=48,price=30},
  lasagna={ing={"pasta","tomato","cheese","meat"},
           station="oven",spr=49,price=45},
  pasta={ing={"pasta","tomato"},
         station="stove",spr=50,price=20},
  meatballs={ing={"meat","tomato"},
             station="stove",spr=51,price=25},
  tiramisu={ing={"cream","cream"},
            station="prep",spr=52,price=35},
  ravioli={ing={"dough","meat","cheese"},
           station="prep",spr=53,price=40}
}

-- customers queue
customers={}
max_customers=4
spawn_timer=0
spawn_delay=300

-- game variables
score=0
day=1
day_timer=0
day_length=3600 -- 60 sec
orders_done=0
orders_failed=0
goal=5 -- orders per day
combo=0
tip_mult=1

-- particles for effects
particles={}

-- served dish animation
served_dish=nil
served_timer=0

-- collected ingredients
collected={}

function _init()
  cartdata("italian_resto")
  init_sprites()
end

function init_sprites()
  -- sprites are defined in __gfx__
end

function _update60()
  if state==gs_menu then
    update_menu()
  elseif state==gs_play then
    update_game()
  elseif state==gs_over then
    update_gameover()
  elseif state==gs_win then
    update_win()
  end
  update_particles()
end

function _draw()
  cls(1)
  if state==gs_menu then
    draw_menu()
  elseif state==gs_play then
    draw_game()
  elseif state==gs_over then
    draw_gameover()
  elseif state==gs_win then
    draw_win()
  end
end

-- menu functions
function update_menu()
  if btnp(4) or btnp(5) then
    start_game()
  end
end

function draw_menu()
  -- restaurant sign
  rectfill(20,15,108,45,2)
  rectfill(22,17,106,43,0)

  -- title with italian flag colors
  print("🅾️ italiano 🅾️",28,22,8)
  print("ristorante",38,30,10)

  -- decorative pizza
  circfill(40,65,12,4)
  circfill(40,65,10,9)
  circfill(40,65,8,15)
  -- pepperoni
  circfill(37,62,2,8)
  circfill(43,67,2,8)
  circfill(40,69,2,8)

  -- decorative pasta
  for i=0,4 do
    local x=80+sin(i*0.2)*8
    local y=58+i*3
    line(x,y,x+10,y,15)
  end
  circfill(85,75,5,8)

  print("press ❎ to start",24,90,7)
  print("cook italian dishes",20,102,6)
  print("serve customers fast!",16,110,6)

  -- high score
  local hi=dget(0)
  if hi>0 then
    print("best: $"..hi,42,120,5)
  end
end

function start_game()
  state=gs_play
  score=0
  day=1
  day_timer=day_length
  orders_done=0
  orders_failed=0
  combo=0
  tip_mult=1
  customers={}
  particles={}
  collected={}
  served_dish=nil
  chef.x=64
  chef.y=80
  chef.holding=nil
  for s in all(stations) do
    s.cooking=nil
    s.progress=0
  end
  spawn_timer=60
  sfx(0)
end

-- game update
function update_game()
  update_chef()
  update_stations()
  update_customers()
  update_served()

  day_timer-=1
  if day_timer<=0 then
    end_day()
  end
end

function update_chef()
  local dx,dy=0,0
  if btn(0) then dx=-1 chef.dir=-1 end
  if btn(1) then dx=1 chef.dir=1 end
  if btn(2) then dy=-1 end
  if btn(3) then dy=1 end

  -- normalize diagonal
  if dx~=0 and dy~=0 then
    dx*=0.707
    dy*=0.707
  end

  chef.x+=dx*chef.speed
  chef.y+=dy*chef.speed

  -- bounds
  chef.x=mid(8,chef.x,120)
  chef.y=mid(48,chef.y,116)

  -- animation
  if dx~=0 or dy~=0 then
    chef.anim_t+=0.15
    chef.frame=flr(chef.anim_t)%4
  else
    chef.frame=0
  end

  -- actions
  if btnp(4) then do_action() end
  if btnp(5) then drop_item() end
end

function do_action()
  -- check ingredient pickup
  if chef.holding==nil then
    for ing in all(ingredients) do
      if near(chef,ing,12) then
        add(collected,ing.name)
        sfx(1)
        spawn_particles(ing.x+4,ing.y+4,11,3)
        -- check if we can make a dish
        check_recipe()
        return
      end
    end
  end

  -- check station interaction
  for st in all(stations) do
    if near_station(chef,st) then
      if chef.holding then
        -- place cooked dish to serve
        serve_dish(st)
      elseif st.cooking and st.progress>=st.cook_time then
        -- pick up finished dish
        pickup_dish(st)
      elseif #collected>0 and not st.cooking then
        -- start cooking
        start_cooking(st)
      end
      return
    end
  end

  -- check customer serving
  for c in all(customers) do
    if near(chef,{x=c.x,y=c.y},16) and chef.holding then
      if chef.holding==c.order then
        -- correct order!
        complete_order(c)
      else
        -- wrong order
        sfx(5)
        combo=0
      end
      return
    end
  end
end

function check_recipe()
  for name,r in pairs(recipes) do
    if matches_recipe(collected,r.ing) then
      chef.holding=name
      collected={}
      sfx(2)
      spawn_particles(chef.x,chef.y-8,11,5)
      return
    end
  end
  -- limit collected items
  if #collected>4 then
    del(collected,collected[1])
  end
end

function matches_recipe(have,need)
  if #have~=#need then return false end
  local temp={}
  for i in all(have) do add(temp,i) end
  for n in all(need) do
    local found=false
    for i=1,#temp do
      if temp[i]==n then
        del(temp,temp[i])
        found=true
        break
      end
    end
    if not found then return false end
  end
  return true
end

function start_cooking(st)
  -- check if collected matches station
  for name,r in pairs(recipes) do
    if r.station==st.name and matches_recipe(collected,r.ing) then
      st.cooking=name
      st.progress=0
      collected={}
      sfx(2)
      return
    end
  end
end

function pickup_dish(st)
  if st.cooking and st.progress>=st.cook_time then
    chef.holding=st.cooking
    st.cooking=nil
    st.progress=0
    sfx(1)
  end
end

function serve_dish(st)
  -- if holding prepared ingredients, start cooking
  if chef.holding and not st.cooking then
    local r=recipes[chef.holding]
    if r and r.station==st.name then
      st.cooking=chef.holding
      st.progress=0
      chef.holding=nil
      sfx(2)
    end
  end
end

function complete_order(c)
  local r=recipes[c.order]
  local base=r.price

  -- bonus for speed
  local speed_bonus=flr(c.patience/c.max_patience*20)

  -- combo bonus
  combo+=1
  if combo>=3 then
    tip_mult=1.5
  elseif combo>=5 then
    tip_mult=2
  else
    tip_mult=1
  end

  local total=flr((base+speed_bonus)*tip_mult)
  score+=total
  orders_done+=1

  -- celebration!
  served_dish={
    name=c.order,
    price=total,
    x=c.x,y=c.y-10
  }
  served_timer=60

  spawn_particles(c.x,c.y,10,8)
  spawn_particles(c.x,c.y,11,8)
  del(customers,c)
  chef.holding=nil
  sfx(3)
end

function drop_item()
  if #collected>0 then
    del(collected,collected[#collected])
    sfx(4)
  elseif chef.holding then
    chef.holding=nil
    sfx(4)
  end
end

function update_stations()
  for st in all(stations) do
    if st.cooking then
      st.progress+=1
      -- cooking particles
      if st.progress<st.cook_time and t()%0.2<0.1 then
        local px=st.x+rnd(st.w)
        local py=st.y+st.h-4
        spawn_particle(px,py,0,-0.5,7,20)
      end
      -- done particles
      if st.progress>=st.cook_time and t()%0.3<0.15 then
        spawn_particle(st.x+st.w/2,st.y+8,rnd(2)-1,-1,10,15)
      end
    end
  end
end

function update_customers()
  -- spawn new customers
  spawn_timer-=1
  if spawn_timer<=0 and #customers<max_customers then
    spawn_customer()
    spawn_timer=spawn_delay-day*30
    spawn_timer=max(120,spawn_timer)
  end

  -- update existing
  for c in all(customers) do
    c.patience-=1
    c.anim_t+=0.1

    -- angry animation
    if c.patience<c.max_patience*0.3 then
      c.angry=true
    end

    if c.patience<=0 then
      -- customer leaves angry
      del(customers,c)
      orders_failed+=1
      combo=0
      sfx(5)
      spawn_particles(c.x,c.y,8,5)
    end
  end
end

function spawn_customer()
  local dishes={"pizza","pasta","meatballs",
                "lasagna","tiramisu","ravioli"}
  local order=dishes[flr(rnd(#dishes))+1]

  -- position based on customer count
  local slot=#customers
  local c={
    x=20+slot*28,
    y=118,
    order=order,
    patience=600-day*50,
    max_patience=600-day*50,
    anim_t=0,
    angry=false,
    face=flr(rnd(3))
  }
  c.patience=max(300,c.patience)
  c.max_patience=c.patience
  add(customers,c)
  sfx(6)
end

function update_served()
  if served_timer>0 then
    served_timer-=1
    if served_dish then
      served_dish.y-=0.5
    end
  else
    served_dish=nil
  end
end

function end_day()
  if orders_done>=goal then
    day+=1
    goal+=2
    day_timer=day_length
    orders_done=0
    customers={}
    sfx(3)
    -- save high score
    if score>dget(0) then
      dset(0,score)
    end
    if day>5 then
      state=gs_win
    end
  else
    state=gs_over
    if score>dget(0) then
      dset(0,score)
    end
  end
end

-- drawing functions
function draw_game()
  -- floor
  rectfill(0,48,127,127,4)
  for i=0,16 do
    for j=0,10 do
      if (i+j)%2==0 then
        rectfill(i*8,48+j*8,i*8+7,48+j*8+7,2)
      end
    end
  end

  -- back wall
  rectfill(0,0,127,47,5)
  rectfill(0,44,127,47,6)

  -- draw stations
  draw_stations()

  -- draw ingredients
  draw_ingredients()

  -- draw customers
  draw_customers()

  -- draw chef
  draw_chef()

  -- draw particles
  draw_particles()

  -- draw served animation
  draw_served()

  -- draw hud
  draw_hud()
end

function draw_stations()
  for st in all(stations) do
    local cooking=st.cooking~=nil

    if st.name=="oven" then
      draw_oven(st)
    elseif st.name=="stove" then
      draw_stove(st)
    elseif st.name=="prep" then
      draw_prep(st)
    end

    -- cooking indicator
    if cooking then
      local pct=st.progress/st.cook_time
      local bw=st.w-4
      rectfill(st.x+2,st.y-6,st.x+2+bw,st.y-3,0)
      rectfill(st.x+2,st.y-5,st.x+2+bw*pct,st.y-4,
               pct>=1 and 11 or 8)

      -- dish preview
      if st.progress>=st.cook_time then
        local r=recipes[st.cooking]
        spr(r.spr,st.x+st.w/2-4,st.y+6)
        -- ready sparkle
        if t()%0.4<0.2 then
          print("✽",st.x+st.w-6,st.y,11)
        end
      end
    end
  end
end

function draw_oven(st)
  -- oven body
  rectfill(st.x,st.y,st.x+st.w,st.y+st.h,6)
  rectfill(st.x+1,st.y+1,st.x+st.w-1,st.y+st.h-1,7)

  -- oven door
  rectfill(st.x+2,st.y+4,st.x+st.w-2,st.y+st.h-2,0)
  rectfill(st.x+3,st.y+5,st.x+st.w-3,st.y+st.h-3,1)

  -- handle
  rectfill(st.x+st.w/2-4,st.y+2,st.x+st.w/2+4,st.y+3,5)

  -- glow if cooking
  if st.cooking then
    local flicker=sin(t()*4)*0.5+0.5
    rectfill(st.x+4,st.y+st.h-6,st.x+st.w-4,st.y+st.h-4,
             flicker>0.5 and 9 or 8)
  end

  -- label
  print("oven",st.x+4,st.y+st.h+2,6)
end

function draw_stove(st)
  -- stove body
  rectfill(st.x,st.y,st.x+st.w,st.y+st.h,6)
  rectfill(st.x+1,st.y+1,st.x+st.w-1,st.y+st.h-1,5)

  -- burners
  local burner_on=st.cooking~=nil
  for i=0,1 do
    local bx=st.x+6+i*12
    local by=st.y+8
    circfill(bx,by,4,0)
    circfill(bx,by,3,burner_on and 8 or 5)
    if burner_on then
      -- flames
      local ft=t()*8+i
      for f=0,3 do
        local fx=bx+sin(ft+f)*3
        local fy=by-2-sin(ft*2+f)*2
        pset(fx,fy,rnd()>0.5 and 9 or 10)
      end
    end
  end

  -- pan if cooking
  if st.cooking then
    local px=st.x+st.w/2
    ovalfill(px-8,st.y+4,px+8,st.y+12,5)
    ovalfill(px-6,st.y+5,px+6,st.y+11,6)
  end

  print("stove",st.x+2,st.y+st.h+2,6)
end

function draw_prep(st)
  -- prep table
  rectfill(st.x,st.y,st.x+st.w,st.y+st.h,4)
  rectfill(st.x+1,st.y+1,st.x+st.w-1,st.y+2,15)
  rectfill(st.x+1,st.y+3,st.x+st.w-1,st.y+st.h-1,15)

  -- wood grain
  for i=1,3 do
    line(st.x+1,st.y+4+i*4,st.x+st.w-1,st.y+4+i*4,4)
  end

  -- bowl if prepping
  if st.cooking then
    circfill(st.x+st.w/2,st.y+10,6,6)
    circfill(st.x+st.w/2,st.y+10,4,7)
    -- mixing animation
    local mx=sin(t()*4)*3
    line(st.x+st.w/2-3+mx,st.y+8,st.x+st.w/2+3+mx,st.y+12,5)
  end

  print("prep",st.x+4,st.y+st.h+2,6)
end

function draw_ingredients()
  for ing in all(ingredients) do
    -- box
    rectfill(ing.x-2,ing.y-2,ing.x+10,ing.y+10,4)
    rectfill(ing.x-1,ing.y-1,ing.x+9,ing.y+9,15)

    -- ingredient sprite
    draw_ingredient(ing.name,ing.x,ing.y)

    -- label below
    local short={
      dough="d",tomato="t",cheese="c",
      pasta="p",meat="m",cream="cr"
    }
    print(short[ing.name],ing.x+2,ing.y+12,6)
  end

  -- collected indicator
  if #collected>0 then
    local str="have:"
    for c in all(collected) do
      str=str..sub(c,1,1)
    end
    print(str,4,90,11)
  end
end

function draw_ingredient(name,x,y)
  if name=="dough" then
    circfill(x+4,y+4,4,15)
    circfill(x+4,y+4,3,7)
  elseif name=="tomato" then
    circfill(x+4,y+5,4,8)
    line(x+4,y+1,x+4,y+2,3)
  elseif name=="cheese" then
    rectfill(x+1,y+2,x+7,y+7,10)
    pset(x+2,y+4,0)
    pset(x+5,y+5,0)
  elseif name=="pasta" then
    for i=0,4 do
      line(x+1+i,y+2,x+3+i,y+7,15)
    end
  elseif name=="meat" then
    circfill(x+4,y+4,4,8)
    circfill(x+4,y+4,2,2)
  elseif name=="cream" then
    rectfill(x+2,y+3,x+6,y+7,7)
    rectfill(x+1,y+2,x+7,y+3,6)
    print("~",x+2,y+4,15)
  end
end

function draw_chef()
  local x,y=chef.x,chef.y
  local f=chef.frame
  local flip=chef.dir<0

  -- shadow
  ovalfill(x-6,y+4,x+6,y+8,1)

  -- body (white coat)
  rectfill(x-4,y-4,x+4,y+4,7)
  rectfill(x-3,y-3,x+3,y+5,7)

  -- chef hat
  rectfill(x-4,y-12,x+4,y-6,7)
  rectfill(x-5,y-7,x+5,y-6,7)

  -- face
  circfill(x,y-3,3,15)

  -- eyes
  local ex=flip and -1 or 1
  pset(x-1,y-4,0)
  pset(x+1,y-4,0)

  -- mustache
  line(x-2,y-1,x-1,y,0)
  line(x+2,y-1,x+1,y,0)

  -- legs (animate)
  local leg_off=sin(f*0.25)*2
  line(x-2,y+5,x-2-leg_off,y+8,0)
  line(x+2,y+5,x+2+leg_off,y+8,0)

  -- arms
  local arm_y=y
  if chef.holding or #collected>0 then
    arm_y=y-2
  end
  line(x-4,y,x-6,arm_y,15)
  line(x+4,y,x+6,arm_y,15)

  -- holding item
  if chef.holding then
    local r=recipes[chef.holding]
    spr(r.spr,x+4,y-12)
    -- sparkle
    if t()%0.5<0.25 then
      pset(x+8+rnd(4),y-14+rnd(4),10)
    end
  end
end

function draw_customers()
  for c in all(customers) do
    local x,y=c.x,c.y
    local bounce=sin(c.anim_t)*2

    -- body
    local body_col=c.angry and 8 or 12
    rectfill(x-5,y-8+bounce,x+5,y+2+bounce,body_col)

    -- head
    circfill(x,y-12+bounce,5,15)

    -- face
    local face_x=0
    if c.angry then
      -- angry face
      line(x-3,y-14+bounce,x-1,y-13+bounce,0)
      line(x+3,y-14+bounce,x+1,y-13+bounce,0)
      pset(x-2,y-12+bounce,0)
      pset(x+2,y-12+bounce,0)
      line(x-2,y-9+bounce,x+2,y-9+bounce,0)
    else
      -- happy/neutral
      pset(x-2,y-13+bounce,0)
      pset(x+2,y-13+bounce,0)
      if c.patience>c.max_patience*0.5 then
        -- smile
        line(x-1,y-9+bounce,x+1,y-9+bounce,0)
        pset(x-2,y-10+bounce,0)
        pset(x+2,y-10+bounce,0)
      else
        line(x-1,y-9+bounce,x+1,y-9+bounce,0)
      end
    end

    -- hair based on face type
    if c.face==0 then
      rectfill(x-4,y-17+bounce,x+4,y-15+bounce,0)
    elseif c.face==1 then
      for i=-3,3 do
        pset(x+i,y-17+bounce+abs(i)*0.5,4)
      end
    else
      circfill(x,y-17+bounce,4,4)
    end

    -- order bubble
    draw_order_bubble(c)

    -- patience bar
    local pct=c.patience/c.max_patience
    local bw=12
    rectfill(x-6,y+5,x+6,y+7,0)
    local bar_col=8
    if pct>0.6 then bar_col=11
    elseif pct>0.3 then bar_col=10
    end
    rectfill(x-5,y+5,x-5+bw*pct,y+6,bar_col)
  end
end

function draw_order_bubble(c)
  local bx,by=c.x+8,c.y-28

  -- bubble
  rectfill(bx-2,by-2,bx+14,by+10,7)
  rectfill(bx-1,by-3,bx+13,by+11,7)

  -- pointer
  pset(bx+4,by+12,7)
  pset(bx+5,by+13,7)
  pset(bx+4,by+13,7)

  -- dish icon
  local r=recipes[c.order]
  spr(r.spr,bx,by)
end

function draw_served()
  if served_dish and served_timer>0 then
    local x,y=served_dish.x,served_dish.y

    -- floating price
    local col=11
    if served_timer%10<5 then col=10 end
    print("+$"..served_dish.price,x-8,y,col)

    -- combo display
    if combo>=3 then
      print("combo x"..combo.."!",x-16,y-8,9)
    end
  end
end

function draw_hud()
  -- top bar
  rectfill(0,0,127,10,0)

  -- score
  print("$"..score,2,2,10)

  -- day
  print("day "..day,50,2,7)

  -- timer
  local time_left=flr(day_timer/60)
  local tcol=time_left<10 and 8 or 7
  print(time_left.."s",100,2,tcol)

  -- orders goal
  local goal_str=orders_done.."/"..goal
  print(goal_str,2,120,orders_done>=goal and 11 or 6)

  -- controls hint
  if t()<5 then
    print("❎=pick ⭕=drop",40,120,5)
  end
end

function draw_gameover()
  -- dark overlay
  for y=0,127,2 do
    for x=0,127,2 do
      if (x+y)%4==0 then pset(x,y,0) end
    end
  end

  rectfill(20,35,108,95,0)
  rectfill(22,37,106,93,1)

  print("ristorante",38,42,8)
  print("closed",48,50,8)

  print("final: $"..score,38,62,10)
  print("days survived: "..day,24,72,7)

  print("press ❎ to retry",22,85,6)
end

function draw_win()
  rectfill(15,30,112,100,0)
  rectfill(17,32,110,98,3)

  print("★ congratulazioni! ★",20,38,10)
  print("you are a master",28,50,7)
  print("italian chef!",36,58,7)

  print("earnings: $"..score,32,72,11)

  -- celebratory pasta
  for i=0,5 do
    local px=40+rnd(48)
    local py=85+sin(t()+i)*3
    print("🍝",px,py,rnd(6)+8)
  end

  print("❎ play again",34,95,6)
end

function update_gameover()
  if btnp(4) or btnp(5) then
    start_game()
  end
end

function update_win()
  spawn_particles(rnd(128),rnd(64)+32,
    flr(rnd(4))+8,1)
  if btnp(4) or btnp(5) then
    start_game()
  end
end

-- utility functions
function near(a,b,d)
  return abs(a.x-b.x)<d and abs(a.y-b.y)<d
end

function near_station(c,st)
  return c.x>st.x-8 and c.x<st.x+st.w+8 and
         c.y>st.y and c.y<st.y+st.h+16
end

-- particle system
function spawn_particles(x,y,col,n)
  for i=1,n do
    spawn_particle(x,y,rnd(4)-2,rnd(4)-3,col,20+rnd(20))
  end
end

function spawn_particle(x,y,dx,dy,col,life)
  add(particles,{
    x=x,y=y,dx=dx,dy=dy,
    col=col,life=life,max_life=life
  })
end

function update_particles()
  for p in all(particles) do
    p.x+=p.dx
    p.y+=p.dy
    p.dy+=0.1 -- gravity
    p.life-=1
    if p.life<=0 then
      del(particles,p)
    end
  end
end

function draw_particles()
  for p in all(particles) do
    local a=p.life/p.max_life
    if a>0.5 then
      circfill(p.x,p.y,2,p.col)
    else
      pset(p.x,p.y,p.col)
    end
  end
end

__gfx__
00077000007770000077700000777000007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700077777000777770007777700077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770077077700770777007707770077077700770777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700770077777700777777007777770077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770077007700770077007700770077007700770077000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700077777700777777007777770077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007770000077700000777000007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007700000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700007007000077770000777700011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07ffff700070070007ffff70077777701166611000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ff00ff70070070077f00f77077777701666661000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f0000f70007700077f00f77077007701666661000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07ffff700000000007ffff70077777701666661000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000077770000777700011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
007ff70000033000000aa00000fff000002220000667000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07ffff700033330000aaa0000fffff0002222200677776000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ff77ff700333300000a0a00fa0a0af002a0a20067006700000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7ff7f70003300000a000a0faa0aaf0020002006700076000000000000000000000000000000000000000000000000000000000000000000000000000000000
7f7ff7f70033330000000a00fa0a0af002a0a200677776000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07ffff700333333000000000ffffff000222220006776000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007ff7000033330000000000000000000022200000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04499440009aa900006666000555550006666600065556000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f98889409aaaa9006ffff600fff8f0066777760655555600000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f88888409a88a906f8ff8f0058885006788876055fff5000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f88888409a88a906ffffff005fff500677776005fffff500000000000000000000000000000000000000000000000000000000000000000000000000000000000
04988940009aa9000666666005555500667766006555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000990000066660000555000006660000655560000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001a0501d0501f05020050210501f0501d0501a05018050150501205010050100500f0500d0500c0500a050080500605005050030500205001050000000000000000000000000000000000000000000000
000200002c0502a05027050230501f0501a05016050120500e0500a0500605003050010500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000024050260502805029050290502a0502b0502c0502c0502d0502d0502d0502d0502c0502b050290502705025050220501f0501c05019050160501305010050000000000000000000000000000000000
00020000300503205034050360503705038050380503705036050340503205030050300502e0502c0502a0502805025050220501f0501c05019050160501305010050000000000000000000000000000000000
000300000c0500a050090500805007050060500505004050030500205001050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001405012050100500e0500c0500a050080500605004050020500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000180501a0501c0501e05020050220502405026050280502a0502c0502c0502c0502a05028050260502405022050200501e0501c0501a050180501605015050140501305012050000000000000000000
