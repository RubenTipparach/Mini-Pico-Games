pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- aoe-lite rts for pico-8
-- single-cart prototype by chatgpt
-- controls (keyboard):
-- arrows: move cursor
-- z/o: select / confirm / order
-- x/x: open build/train menu / cancel
-- c/v: cycle selection (player units)
-- s: stop selected
-- p: pause
-- mouse (optional): enable in options below

-- ======= options =======
use_mouse=false
map_w=64
map_h=64
cam_x=0
cam_y=0

-- economy
start_resources={food=200,wood=200,stone=100}

-- ======= helpers =======
function rndi(a,b) return flr(rnd(b-a+1))+a end
function clamp(x,a,b) return max(a,min(b,x)) end
function sign(x) return x>0 and 1 or x<0 and -1 or 0 end

-- ======= data =======
TILE_EMPTY=0
TILE_TREE=1
TILE_ROCK=2
TILE_BUSH=3
TILE_WATER=4
TILE_BUILD=5 -- reserved flag (not drawn)

-- building ids
B_TC=1  -- town center
B_HOUSE=2
B_BARRACKS=3
B_FARM=4

-- unit ids
U_VIL=1
U_SOLD=2

-- players
P_HUM=1
P_AI=2

-- sprite ids (now using embedded __gfx__ art)
SPR={
  villager=0,
  soldier=1,
  tc=2,
  house=3,
  barracks=4,
  farm=5,
  tree=6,
  rock=7,
  bush=8,
}

-- costs
COST={
  [B_HOUSE]={wood=50},
  [B_BARRACKS]={wood=120,stone=50},
  [B_FARM]={wood=60},
  [U_VIL]={food=50},
  [U_SOLD]={food=60,wood=20}
}

-- pop
POP_CAP_PER_HOUSE=4

-- entity containers
units={} buildings={} bullets={}
resnodes={}
players={}
sel={} -- selection list (ids of units)
cursor={x=8,y=8,tx=1,ty=1}

-- ===== map =====
map={} -- tile ids
walk={} -- 1=walkable

function make_map()
  for y=1,map_h do
    map[y]={}
    walk[y]={}
    for x=1,map_w do
      local t=TILE_EMPTY
      if rnd()<0.07 then t=TILE_TREE end
      if rnd()<0.04 then t=TILE_ROCK end
      if rnd()<0.05 then t=TILE_BUSH end
      if rnd()<0.02 then t=TILE_WATER end
      map[y][x]=t
      walk[y][x]=(t==TILE_WATER) and 0 or 1
      if t==TILE_TREE or t==TILE_ROCK or t==TILE_BUSH then
        add(resnodes,{x=x,y=y,t=t,amount=rndi(100,200)})
      end
    end
  end
end

function tile_block(x,y)
  if x<1 or y<1 or x>map_w or y>map_h then return 1 end
  return 1-walk[y][x]
end

-- ===== players =====
function make_player(id,ai)
  local p={id=id,ai=ai,food=0,wood=0,stone=0,pop=0,cap=5}
  for k,v in pairs(start_resources) do p[k]=v end
  players[id]=p
end

-- ===== buildings/units =====
function can_afford(p,cost)
  for k,v in pairs(cost) do if (p[k] or 0)<v then return false end end
  return true
end

function pay(p,cost)
  for k,v in pairs(cost) do p[k]-=v end
end

function refund(p,cost)
  for k,v in pairs(cost) do p[k]+=flr(v*0.5) end
end

function place_building(p,tilex,tiley,bid)
  if tile_block(tilex,tiley)==1 then return false,"blocked" end
  local cost=COST[bid] or {}
  if not can_afford(p,cost) then return false,"need res" end
  pay(p,cost)
  local b={id=#buildings+1,owner=p.id,btype=bid,x=tilex,y=tiley,hp=200,progress=0}
  add(buildings,b)
  walk[tiley][tilex]=0
  map[tiley][tilex]=TILE_BUILD
  if bid==B_HOUSE then p.cap+=POP_CAP_PER_HOUSE end
  return true
end

function spawn_unit(p,ux,uy,ut)
  if p.pop>=p.cap then return false,"pop full" end
  local c=COST[ut] or {}
  if not can_afford(p,c) then return false,"need res" end
  pay(p,c)
  local u={id=#units+1,owner=p.id,utype=ut,x=ux,y=uy,tx=ux,ty=uy,hp=30,carry=0,task=nil,cd=0}
  if ut==U_SOLD then u.hp=40 end
  add(units,u)
  p.pop+=1
  return true
end

-- ===== selection & orders =====
function world_to_tile(x,y) return flr(x/8)+1,flr(y/8)+1 end
function tile_to_world(tx,ty) return (tx-1)*8,(ty-1)*8 end

function select_at(tx,ty)
  sel={}
  for u in all(units) do if u.owner==P_HUM and flr(u.x)==tx and flr(u.y)==ty then add(sel,u.id) end end
end

function order_move(tx,ty)
  for id in all(sel) do
    local u=units[id]
    if u then u.tx=tx u.ty=ty u.task="move" end
  end
end

function order_gather(tx,ty)
  local node=find_resnode(tx,ty)
  if not node then order_move(tx,ty) return end
  for id in all(sel) do
    local u=units[id]
    if u and u.utype==U_VIL then u.task="gather" u.target=node end
  end
end

function order_attack(tx,ty)
  for id in all(sel) do
    local u=units[id]
    if u then u.task="attack" u.tx=tx u.ty=ty end
  end
end

function cancel_orders()
  for id in all(sel) do local u=units[id] if u then u.task=nil end end
end

-- ===== resources =====
function find_resnode(x,y)
  for n in all(resnodes) do if n.x==x and n.y==y and n.amount>0 then return n end end
end

function deposit(u)
  local p=players[u.owner]
  -- deposit at any building owned
  for b in all(buildings) do
    if b.owner==u.owner and abs(b.x-u.x)<=1 and abs(b.y-u.y)<=1 then
      if u.carry>0 then
        if u.task=="gather_wood" then p.wood+=u.carry
        elseif u.task=="gather_stone" then p.stone+=u.carry
        else p.food+=u.carry end
        u.carry=0
        return true
      end
    end
  end
end

-- ===== ai =====
ai_timer=0
function ai_update()
  local p=players[P_AI]
  if not p then return end
  ai_timer+=1
  if ai_timer%60==0 then
    -- train villagers until 6
    local vcount=0
    for u in all(units) do if u.owner==P_AI and u.utype==U_VIL then vcount+=1 end end
    if vcount<6 then
      local b=find_building(P_AI,B_TC)
      if b then spawn_unit(p,b.x,b.y,U_VIL) end
    end
    -- gather: assign idle vils to nearest resource
    for u in all(units) do
      if u.owner==P_AI and u.utype==U_VIL and not u.task then
        local n=nearest_node(u.x,u.y)
        if n then u.task="gather" u.target=n end
      end
    end
    -- build barracks if enough
    if p.wood>=120 and p.stone>=50 and not find_building(P_AI,B_BARRACKS) then
      local bx,by=players[P_AI].base_x+2,players[P_AI].base_y
      place_building(p,bx,by,B_BARRACKS)
    end
    -- train soldiers
    if p.food>=60 and p.wood>=20 then
      local bb=find_building(P_AI,B_BARRACKS) or find_building(P_AI,B_TC)
      if bb then spawn_unit(p,bb.x,bb.y,U_SOLD) end
    end
    -- attack if enough soldiers
    local scount=0
    for u in all(units) do if u.owner==P_AI and u.utype==U_SOLD then scount+=1 end end
    if scount>=4 then
      local hx,hy=players[P_HUM].base_x,players[P_HUM].base_y
      for u in all(units) do if u.owner==P_AI and u.utype==U_SOLD then u.task="attack" u.tx=hx u.ty=hy end end
    end
  end
end

function nearest_node(x,y)
  local best=nil
  local bd=1e9
  for n in all(resnodes) do if n.amount>0 then
    local d=abs(n.x-x)+abs(n.y-y)
    if d<bd then bd=d best=n end
  end
  return best
end

function find_building(owner,btype)
  for b in all(buildings) do if b.owner==owner and b.btype==btype then return b end end
end

-- ===== movement/combat =====
function step_towards(u,tx,ty)
  local dx=sign(tx-u.x)
  local dy=sign(ty-u.y)
  local nx=u.x+dx
  local ny=u.y+dy
  if tile_block(flr(nx),flr(ny))==0 then u.x=nx u.y=ny else
    -- try axis
    if tile_block(flr(u.x+dx),flr(u.y))==0 then u.x+=dx
    elseif tile_block(flr(u.x),flr(u.y+dy))==0 then u.y+=dy end
  end
end

function unit_think(u)
  u.cd=max(0,u.cd-1)
  if u.task=="move" then
    if u.x==u.tx and u.y==u.ty then u.task=nil else step_towards(u,u.tx,u.ty) end
  elseif u.task=="gather" then
    local n=u.target
    if not n or n.amount<=0 then u.task=nil return end
    if abs(u.x-n.x)+abs(u.y-n.y)>1 then step_towards(u,n.x,n.y) else
      -- gather tick
      n.amount-=1
      u.carry+=1
      if n.t==TILE_TREE then u.task="gather_wood"
      elseif n.t==TILE_ROCK then u.task="gather_stone"
      else u.task="gather_food" end
      if u.carry>=10 then u.task=u.task -- keep type
        -- go deposit: move toward nearest own building
        local b=find_building(u.owner,B_TC) or find_building(u.owner,B_HOUSE) or find_building(u.owner,B_BARRACKS)
        if b then u.tx=b.x u.ty=b.y u.task=u.task u.depositing=true step_towards(u,b.x,b.y) end
      end
    end
  elseif u.depositing then
    if deposit(u) then u.depositing=false u.task=nil end
    if u.tx and u.ty then step_towards(u,u.ty,u.ty) end
  elseif u.task=="attack" then
    -- find nearest enemy
    local e,bestd=nil,1e9
    for v in all(units) do if v.owner~=u.owner then
      local d=abs(v.x-u.x)+abs(v.y-u.y)
      if d<bestd then bestd=d e=v end end end
    for bb in all(buildings) do if bb.owner~=u.owner then
      local d=abs(bb.x-u.x)+abs(bb.y-u.y)
      if d<bestd then bestd=d e=bb end end end
    if e then
      if bestd>1 then step_towards(u,e.x,e.y) else
        if u.cd==0 then u.cd=15
          if e.hp then e.hp-= (u.utype==U_SOLD and 6 or 3) end
        end
      end
    else u.task=nil end
  end
end

function cleanup()
  -- remove dead units/buildings/nodes
  for i=#units,1,-1 do local u=units[i] if u.hp<=0 then
    players[u.owner].pop=max(0,players[u.owner].pop-1)
    deli(units,i)
  end end
  for i=#buildings,1,-1 do local b=buildings[i] if b.hp<=0 then
    walk[b.y][b.x]=1
    map[b.y][b.x]=TILE_EMPTY
    deli(buildings,i)
  end end
  for i=#resnodes,1,-1 do if resnodes[i].amount<=0 then deli(resnodes,i) end end
end

-- ===== ui =====
menu_open=false
submenu=nil
msg=""
msgt=0

function say(s) msg=s msgt=90 end

function draw_ui()
  -- resources bar
  rectfill(0,0,127,6,1)
  print("food:"..players[P_HUM].food.." wood:"..players[P_HUM].wood.." stone:"..players[P_HUM].stone.." pop:"..players[P_HUM].pop.."/"..players[P_HUM].cap,1,1,7)
  -- message
  if msgt>0 then print(msg,1,114,10) msgt-=1 end

  -- cursor
  local cx,cy=cursor.x-cam_x,cursor.y-cam_y
  rect(cx*8,cy*8, cx*8+7, cy*8+7,10)

  -- selection highlight
  for id in all(sel) do local u=units[id] if u then
    local sx,sy=u.x-cam_x,u.y-cam_y
    rect(sx*8,sy*8,sx*8+7,sy*8+7,11)
  end end

  if menu_open then
    rectfill(0,64,127,127,0)
    print("build (z=confirm, x=close)",2,66,7)
    if submenu=="build" then
      print("1) house  2) barracks  3) farm",4,76,6)
    elseif submenu=="train" then
      print("1) villager  2) soldier",4,76,6)
    else
      print("z: build here | x: train",4,76,6)
    end
  end
end

function draw_world()
  cls(0)
  -- tiles
  for y=0,15 do
    for x=0,15 do
      local tx=x+cam_x
      local ty=y+cam_y
      if tx>=1 and ty>=1 and tx<=map_w and ty<=map_h then
        local t=map[ty][tx]
        if t==TILE_TREE then spr(SPR.tree,(x)*8,(y)*8)
        elseif t==TILE_ROCK then spr(SPR.rock,x*8,y*8)
        elseif t==TILE_BUSH then spr(SPR.bush,x*8,y*8)
        elseif t==TILE_WATER then rectfill(x*8,y*8,x*8+7,y*8+7,12) end
      end
    end
  end
  -- buildings
  for b in all(buildings) do
    local sx,sy=(b.x-1-cam_x)*8,(b.y-1-cam_y)*8
    local sp=SPR.tc
    if b.btype==B_HOUSE then sp=SPR.house
    elseif b.btype==B_BARRACKS then sp=SPR.barracks
    elseif b.btype==B_FARM then sp=SPR.farm end
    spr(sp,sx,sy)
  end
  -- units
  for u in all(units) do
    local sp=(u.utype==U_VIL) and SPR.villager or SPR.soldier
    spr(sp,(u.x-1-cam_x)*8,(u.y-1-cam_y)*8)
  end
end

function handle_input()
  local p=players[P_HUM]
  -- cursor move
  if btnp(0) then cursor.x=clamp(cursor.x-1,1,map_w) end
  if btnp(1) then cursor.x=clamp(cursor.x+1,1,map_w) end
  if btnp(2) then cursor.y=clamp(cursor.y-1,1,map_h) end
  if btnp(3) then cursor.y=clamp(cursor.y+1,1,map_h) end

  -- camera follows cursor
  cam_x=clamp(cursor.x-8,0,map_w-16)
  cam_y=clamp(cursor.y-8,0,map_h-16)

  if btnp(4) then -- z/o
    if menu_open then
      if not submenu then submenu="build"
      elseif submenu=="build" then
        -- try place selected building cycling keys 1-3
        local k1=stat(28) -- last key
        if k1==49 then --1
          try_place(B_HOUSE)
        elseif k1==50 then
          try_place(B_BARRACKS)
        elseif k1==51 then
          try_place(B_FARM)
        end
      elseif submenu=="train" then
        local k1=stat(28)
        local b=find_building(P_HUM,B_TC)
        if k1==49 then if b then spawn_unit(p,b.x,b.y,U_VIL) else say("need tc") end
        elseif k1==50 then
          local bb=find_building(P_HUM,B_BARRACKS)
          if bb then spawn_unit(p,bb.x,bb.y,U_SOLD) else say("need barracks") end
        end
      end
    else
      -- issue context order: gather/attack/move
      local t=map[cursor.y][cursor.x]
      if t==TILE_TREE or t==TILE_ROCK or t==TILE_BUSH then order_gather(cursor.x,cursor.y)
      else
        -- if enemy near, attack
        order_attack(cursor.x,cursor.y)
      end
    end
  end

  if btnp(5) then -- x/x
    if menu_open and submenu then submenu=nil else menu_open=not menu_open end
    if menu_open and not submenu then submenu=nil end
  end

  -- quick keys
  if stat(28)==99 then -- c cycle fwd
    cycle_sel(1)
  elseif stat(28)==118 then -- v cycle back
    cycle_sel(-1)
  elseif stat(28)==115 then -- s stop
    cancel_orders()
  end

  -- click to select
  if btnp(4)==false and btnp(5)==false and not menu_open then
    if (stat(34)==1 and use_mouse) then
      local mx=clamp(flr((stat(32)/8))+cam_x+1,1,map_w)
      local my=clamp(flr((stat(33)/8))+cam_y+1,1,map_h)
      cursor.x=mx cursor.y=my
      select_at(mx,my)
    elseif btnp(4) then select_at(cursor.x,cursor.y) end
  end
end

function try_place(bid)
  local ok,err=place_building(players[P_HUM],cursor.x,cursor.y,bid)
  if not ok then say(err) else say("building placed") end
end

function cycle_sel(dir)
  local own={}
  for u in all(units) do if u.owner==P_HUM then add(own,u.id) end end
  if #own==0 then return end
  local idx=1
  if #sel>0 then
    for i=1,#own do if own[i]==sel[1] then idx=i break end end
    idx=((idx-1+dir-1)%#own)+1
  end
  sel={own[idx]}
  local u=units[sel[1]]
  if u then cursor.x=u.x cursor.y=u.y end
end

-- ===== init/update/draw =====
function _init()
  make_map()
  make_player(P_HUM,false)
  make_player(P_AI,true)
  -- starting bases
  players[P_HUM].base_x=8 players[P_HUM].base_y=8
  players[P_AI].base_x=map_w-8 players[P_AI].base_y=map_h-8
  place_building(players[P_HUM],players[P_HUM].base_x,players[P_HUM].base_y,B_TC)
  place_building(players[P_AI],players[P_AI].base_x,players[P_AI].base_y,B_TC)
  spawn_unit(players[P_HUM],players[P_HUM].base_x,players[P_HUM].base_y,U_VIL)
  spawn_unit(players[P_HUM],players[P_HUM].base_x,players[P_HUM].base_y,U_VIL)
  spawn_unit(players[P_AI],players[P_AI].base_x,players[P_AI].base_y,U_VIL)
  spawn_unit(players[P_AI],players[P_AI].base_x,players[P_AI].base_y,U_VIL)
end

function _update60()
  if stat(48)==1 then poke(0x5f50,1) end -- unlock 60fps on web export
  handle_input()
  -- unit logic
  for u in all(units) do unit_think(u) end
  -- cleanup and ai
  cleanup()
  ai_update()
end

function _draw()
  draw_world()
  draw_ui()
end

__gfx__
111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000
1aaaaaa118888881199999911cccccc1177777711bbbbbb113333331155555511222222111aaaaaa10000000000000000000000000000000000000000000000000000000000000
1aaaaaa118888881199999911cccccc1177777711bbbbbb113333331155555511222222111aaaaaa10000000000000000000000000000000000000000000000000000000000000
1aaaaaa118888881199999911cccccc1177777711bbbbbb113333331155555511222222111aaaaaa10000000000000000000000000000000000000000000000000000000000000
1aaaaaa118888881199999911cccccc1177777711bbbbbb113333331155555511222222111aaaaaa10000000000000000000000000000000000000000000000000000000000000
1aaaaaa118888881199999911cccccc1177777711bbbbbb113333331155555511222222111aaaaaa10000000000000000000000000000000000000000000000000000000000000
1aaaaaa118888881199999911cccccc1177777711bbbbbb113333331155555511222222111aaaaaa10000000000000000000000000000000000000000000000000000000000000
111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000
__gff__

__map__

__sfx__

__music__
