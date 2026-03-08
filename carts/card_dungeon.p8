pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- card dungeon crawler
-- a pico-8 card battler

-- game states
st_title=0
st_town=1
st_dungeon=2
st_combat=3
st_shop=4
st_inn=5
st_gameover=6
st_victory=7
st_loot=8

state=st_title
prev_state=st_title

-- player stats
p={
 hp=20,maxhp=20,
 mp=5,maxmp=5,
 gold=10,
 atk=2,def=1,
 floor=1,
 x=3,y=3,
 inn_buff=0
}

-- card definitions
-- type: 1=atk,2=heal,3=shield,4=buff
cards={}
function make_card(name,type,cost,val,desc,onuse)
 return {
  name=name,type=type,
  cost=cost,val=val,
  desc=desc,onuse=onuse
 }
end

-- all card templates
card_db={
 make_card("slash",1,0,3,"3 dmg free"),
 make_card("h.slash",1,1,6,"6 dmg 1mp"),
 make_card("fireball",1,2,10,"10 dmg 2mp"),
 make_card("heal",2,1,5,"heal 5 1mp"),
 make_card("gr.heal",2,2,10,"heal 10 2mp"),
 make_card("shield",3,1,3,"+3 def 1mp"),
 make_card("barrier",3,2,6,"+6 def 2mp"),
 make_card("rage",4,1,3,"+3 atk 1mp"),
 make_card("focus",4,1,2,"+2 mp 1mp"),
}

-- copy a card from db
function copy_card(c)
 return make_card(
  c.name,c.type,
  c.cost,c.val,
  c.desc,c.onuse)
end

-- player deck and hand
deck={}
hand={}
discard={}
hand_sel=0
max_hand=4

-- combat vars
enemy={}
combat_msg=""
msg_t=0
p_shield=0
p_turn=true
combat_anim=0
combat_result=0 -- 0=ongoing,1=win,2=lose

-- dungeon map
dmap={}
dw=15
dh=15
rooms={}

-- town cursor
town_sel=0
shop_sel=0
shop_items={}
inn_cost=5

-- enemy templates per floor
function make_enemy(name,hp,atk,def,gold,spr)
 return {
  name=name,hp=hp,maxhp=hp,
  atk=atk,def=def,
  gold=gold,spr=spr
 }
end

enemy_db={
 -- floor 1
 {make_enemy("rat",8,2,0,3,32),
  make_enemy("bat",6,3,0,4,34),
  make_enemy("slime",10,2,1,5,36)},
 -- floor 2
 {make_enemy("goblin",15,4,1,8,38),
  make_enemy("skeleton",18,5,2,10,40),
  make_enemy("spider",12,6,0,7,42)},
 -- floor 3
 {make_enemy("orc",25,6,3,15,44),
  make_enemy("wraith",20,8,1,18,46),
  make_enemy("dragon",40,10,4,30,48)},
}

-- scroll/transition
trans_t=0
trans_to=-1

-- loot vars
loot_gold=0
loot_card=nil

-->8
-- init and main loop

function _init()
 state=st_title
 init_player()
end

function init_player()
 p.hp=20
 p.maxhp=20
 p.mp=5
 p.maxmp=5
 p.gold=10
 p.atk=2
 p.def=1
 p.floor=1
 p.inn_buff=0
 -- starter deck
 deck={}
 add(deck,copy_card(card_db[1])) -- slash
 add(deck,copy_card(card_db[1])) -- slash
 add(deck,copy_card(card_db[2])) -- h.slash
 add(deck,copy_card(card_db[4])) -- heal
 add(deck,copy_card(card_db[6])) -- shield
 hand={}
 discard={}
end

function _update60()
 if trans_t>0 then
  trans_t-=1
  if trans_t<=0 and trans_to>=0 then
   state=trans_to
   trans_to=-1
  end
  return
 end

 if state==st_title then
  update_title()
 elseif state==st_town then
  update_town()
 elseif state==st_dungeon then
  update_dungeon()
 elseif state==st_combat then
  update_combat()
 elseif state==st_shop then
  update_shop()
 elseif state==st_inn then
  update_inn()
 elseif state==st_gameover then
  update_gameover()
 elseif state==st_victory then
  update_victory()
 elseif state==st_loot then
  update_loot()
 end
end

function _draw()
 cls(0)

 if state==st_title then
  draw_title()
 elseif state==st_town then
  draw_town()
 elseif state==st_dungeon then
  draw_dungeon()
 elseif state==st_combat then
  draw_combat()
 elseif state==st_shop then
  draw_shop()
 elseif state==st_inn then
  draw_inn()
 elseif state==st_gameover then
  draw_gameover()
 elseif state==st_victory then
  draw_victory()
 elseif state==st_loot then
  draw_loot()
 end

 -- transition effect
 if trans_t>0 then
  local r=trans_t*8
  for y=0,15 do
   for x=0,15 do
    if (x+y)%2==flr(trans_t/2)%2 then
     rectfill(x*8,y*8,x*8+7,y*8+7,0)
    end
   end
  end
 end
end

function go_to(s)
 trans_to=s
 trans_t=10
 sfx(0)
end

-->8
-- title screen

function update_title()
 if btnp(4) or btnp(5) then
  init_player()
  go_to(st_town)
 end
end

function draw_title()
 local t=time()
 -- bg
 for i=0,127 do
  local c=1
  if (i+flr(t*8))%16<2 then c=5 end
  line(0,i,127,i,c)
 end

 -- title
 local tx="card dungeon"
 local tw=#tx*4
 print_border(tx,64-tw/2,30,7,0)

 print_center("a dungeon card battler",50,6)

 if flr(t*2)%2==0 then
  print_center("press x or o to start",80,10)
 end

 print_center("arrows: move/select",100,5)
 print_center("x: confirm  o: back",108,5)
end

function print_center(s,y,c)
 local w=#s*4
 print(s,64-w/2,y,c)
end

function print_border(s,x,y,c,bc)
 for dx=-1,1 do
  for dy=-1,1 do
   print(s,x+dx,y+dy,bc)
  end
 end
 print(s,x,y,c)
end

-->8
-- town

function update_town()
 if btnp(0) then town_sel-=1 end
 if btnp(1) then town_sel+=1 end
 town_sel=mid(0,town_sel,2)

 if btnp(4) then
  if town_sel==0 then
   -- enter dungeon
   gen_dungeon()
   go_to(st_dungeon)
  elseif town_sel==1 then
   -- shop
   gen_shop()
   go_to(st_shop)
  elseif town_sel==2 then
   -- inn
   go_to(st_inn)
  end
 end
end

function draw_town()
 -- sky
 rectfill(0,0,127,40,12)
 -- buildings
 rectfill(10,20,40,60,4)
 rectfill(15,35,25,55,3)
 rectfill(50,15,90,60,5)
 rectfill(60,30,70,50,6)
 rectfill(75,30,85,50,6)
 rectfill(95,25,120,60,4)
 rectfill(100,40,115,55,3)
 -- ground
 rectfill(0,60,127,127,3)
 -- road
 rectfill(0,70,127,85,4)

 -- title
 print_border("~ town ~",42,2,7,0)

 -- stats bar
 draw_stats_bar()

 -- menu
 local opts={"dungeon","shop","inn"}
 for i=1,#opts do
  local y=90+(i-1)*12
  local c=6
  if town_sel==i-1 then
   c=10
   print("\x96",20,y,10)
  end
  print(opts[i],28,y,c)
 end
end

function draw_stats_bar()
 rectfill(0,120,127,127,1)
 print("hp:"..p.hp.."/"..p.maxhp,2,122,8)
 print("mp:"..p.mp.."/"..p.maxmp,42,122,12)
 print("g:"..p.gold,82,122,10)
 print("f:"..p.floor,108,122,7)
end

-->8
-- dungeon generation & exploration

function gen_dungeon()
 -- clear map
 dmap={}
 rooms={}
 for y=0,dh-1 do
  dmap[y]={}
  for x=0,dw-1 do
   dmap[y][x]=1 -- wall
  end
 end

 -- generate rooms
 local num_rooms=4+p.floor
 if num_rooms>8 then num_rooms=8 end
 for i=1,num_rooms do
  local rw=flr(rnd(3))+2
  local rh=flr(rnd(3))+2
  local rx=flr(rnd(dw-rw-2))+1
  local ry=flr(rnd(dh-rh-2))+1
  add(rooms,{x=rx,y=ry,w=rw,h=rh})
  for y=ry,ry+rh-1 do
   for x=rx,rx+rw-1 do
    dmap[y][x]=0 -- floor
   end
  end
 end

 -- connect rooms with corridors
 for i=1,#rooms-1 do
  local r1=rooms[i]
  local r2=rooms[i+1]
  local cx1=r1.x+flr(r1.w/2)
  local cy1=r1.y+flr(r1.h/2)
  local cx2=r2.x+flr(r2.w/2)
  local cy2=r2.y+flr(r2.h/2)

  -- horizontal then vertical
  local x=cx1
  while x~=cx2 do
   dmap[cy1][x]=0
   if x<cx2 then x+=1 else x-=1 end
  end
  local y=cy1
  while y~=cy2 do
   dmap[y][cx2]=0
   if y<cy2 then y+=1 else y-=1 end
  end
 end

 -- place player in first room
 p.x=rooms[1].x+flr(rooms[1].w/2)
 p.y=rooms[1].y+flr(rooms[1].h/2)

 -- place exit stairs in last room
 local lr=rooms[#rooms]
 dmap[lr.y+flr(lr.h/2)][lr.x+flr(lr.w/2)]=3 -- stairs

 -- place enemies (2=enemy)
 for i=2,#rooms-1 do
  local r=rooms[i]
  local ex=r.x+flr(rnd(r.w))
  local ey=r.y+flr(rnd(r.h))
  if dmap[ey][ex]==0 then
   dmap[ey][ex]=2
  end
 end

 -- place town exit at first room edge
 dmap[rooms[1].y][rooms[1].x]=4 -- town portal
end

function update_dungeon()
 local nx,ny=p.x,p.y
 if btnp(0) then nx-=1 end
 if btnp(1) then nx+=1 end
 if btnp(2) then ny-=1 end
 if btnp(3) then ny+=1 end

 -- check bounds
 if nx>=0 and nx<dw and ny>=0 and ny<dh then
  local tile=dmap[ny][nx]
  if tile~=1 then -- not wall
   p.x=nx
   p.y=ny

   if tile==2 then
    -- enemy encounter
    dmap[ny][nx]=0
    start_combat()
   elseif tile==3 then
    -- stairs - next floor
    p.floor+=1
    if p.floor>3 then
     go_to(st_victory)
    else
     sfx(1)
     gen_dungeon()
    end
   elseif tile==4 then
    -- return to town
    go_to(st_town)
   end
  end
 end

 -- o button = leave dungeon
 if btnp(5) then
  go_to(st_town)
 end
end

function draw_dungeon()
 -- camera centered on player
 local cx=p.x-7
 local cy=p.y-6

 for sy=0,13 do
  for sx=0,15 do
   local mx=cx+sx
   local my=cy+sy
   local px=sx*8
   local py=sy*8

   if mx>=0 and mx<dw and my>=0 and my<dh then
    local t=dmap[my][mx]
    if t==1 then
     -- wall
     rectfill(px,py,px+7,py+7,5)
     rect(px,py,px+7,py+7,1)
    elseif t==0 then
     -- floor
     rectfill(px,py,px+7,py+7,1)
     if (mx+my)%2==0 then
      pset(px+3,py+3,2)
     end
    elseif t==2 then
     -- enemy
     rectfill(px,py,px+7,py+7,1)
     print("!",px+2,py+1,8)
    elseif t==3 then
     -- stairs
     rectfill(px,py,px+7,py+7,1)
     print(">",px+2,py+1,11)
    elseif t==4 then
     -- town portal
     rectfill(px,py,px+7,py+7,1)
     print("<",px+2,py+1,12)
    end
   else
    rectfill(px,py,px+7,py+7,0)
   end
  end
 end

 -- draw player
 local ppx=(p.x-cx)*8
 local ppy=(p.y-cy)*8
 rectfill(ppx+1,ppy+1,ppx+6,ppy+6,7)
 rectfill(ppx+2,ppy+2,ppx+3,ppy+3,12)
 rectfill(ppx+4,ppy+2,ppx+5,ppy+3,12)

 -- hud
 draw_stats_bar()

 -- floor label
 rectfill(0,112,55,119,0)
 print("floor "..p.floor,2,113,7)
 print("\x97:leave",60,113,6)
end

-->8
-- combat system

function start_combat()
 -- pick random enemy for floor
 local fl=mid(1,p.floor,3)
 local pool=enemy_db[fl]
 local tmpl=pool[flr(rnd(#pool))+1]
 enemy={
  name=tmpl.name,
  hp=tmpl.hp,maxhp=tmpl.maxhp,
  atk=tmpl.atk,def=tmpl.def,
  gold=tmpl.gold,spr=tmpl.spr
 }
 -- scale a bit with floor
 enemy.hp+=p.floor*2
 enemy.atk+=flr(p.floor/2)

 p_shield=0
 p_turn=true
 combat_msg=""
 msg_t=0
 combat_result=0
 combat_anim=0
 hand_sel=0

 -- shuffle deck into draw pile
 discard={}
 hand={}
 -- combine deck
 local draw_pile={}
 for c in all(deck) do
  add(draw_pile,c)
 end
 -- shuffle
 for i=#draw_pile,2,-1 do
  local j=flr(rnd(i))+1
  draw_pile[i],draw_pile[j]=draw_pile[j],draw_pile[i]
 end
 -- draw hand
 for i=1,min(max_hand,#draw_pile) do
  add(hand,draw_pile[i])
 end
 for i=max_hand+1,#draw_pile do
  add(discard,draw_pile[i])
 end

 sfx(2)
 state=st_combat
end

function update_combat()
 if msg_t>0 then
  msg_t-=1
  return
 end

 -- check win/lose
 if combat_result==1 then
  -- won
  loot_gold=enemy.gold
  -- chance for card loot
  if rnd(100)<50 then
   loot_card=copy_card(
    card_db[flr(rnd(#card_db))+1])
  else
   loot_card=nil
  end
  go_to(st_loot)
  return
 elseif combat_result==2 then
  go_to(st_gameover)
  return
 end

 if p_turn then
  -- player turn
  if btnp(0) then
   hand_sel-=1
   sfx(3)
  end
  if btnp(1) then
   hand_sel+=1
   sfx(3)
  end
  if #hand>0 then
   hand_sel=hand_sel%#hand
   if hand_sel<0 then
    hand_sel=#hand-1
   end
  end

  if btnp(4) and #hand>0 then
   -- play selected card
   play_card(hand_sel+1)
  end

  -- pass turn with o
  if btnp(5) then
   p_turn=false
   combat_msg="pass turn"
   msg_t=30
   sfx(3)
  end
 else
  -- enemy turn
  enemy_act()
  p_turn=true
 end
end

function play_card(idx)
 local c=hand[idx]
 if not c then return end

 -- check mana
 if c.cost>p.mp then
  combat_msg="not enough mp!"
  msg_t=30
  sfx(3)
  return
 end

 -- spend mana
 p.mp-=c.cost
 sfx(1)
 combat_anim=10

 if c.type==1 then
  -- attack
  local dmg=c.val+p.atk-enemy.def
  if dmg<1 then dmg=1 end
  enemy.hp-=dmg
  combat_msg=c.name.." "..dmg.." dmg!"
  if enemy.hp<=0 then
   enemy.hp=0
   combat_result=1
   combat_msg="enemy defeated!"
   msg_t=45
  end
 elseif c.type==2 then
  -- heal
  p.hp=min(p.hp+c.val,p.maxhp)
  combat_msg="heal +"..c.val.."hp"
 elseif c.type==3 then
  -- shield
  p_shield+=c.val
  combat_msg="shield +"..c.val
 elseif c.type==4 then
  -- buff
  if c.name=="rage" then
   p.atk+=c.val
   combat_msg="atk +"..c.val
  elseif c.name=="focus" then
   p.mp+=c.val
   p.maxmp+=c.val
   combat_msg="mp +"..c.val
  end
 end

 -- remove from hand
 -- heal cards destroyed on use
 if c.type==2 then
  del(hand,c)
  -- also remove from deck
  for d in all(deck) do
   if d==c then
    del(deck,d)
    break
   end
  end
  combat_msg=combat_msg.." (gone!)"
 else
  del(hand,c)
  add(discard,c)
 end

 hand_sel=min(hand_sel,#hand-1)
 if hand_sel<0 then hand_sel=0 end

 msg_t=40

 -- auto end turn after playing
 if combat_result==0 then
  p_turn=false
 end
end

function enemy_act()
 local dmg=enemy.atk-p.def
 -- apply shield
 if p_shield>0 then
  dmg-=p_shield
  p_shield=max(0,p_shield-enemy.atk)
 end
 if dmg<1 then dmg=1 end
 p.hp-=dmg
 combat_msg=enemy.name.." hits "..dmg.."!"
 msg_t=40
 sfx(2)
 combat_anim=10

 if p.hp<=0 then
  p.hp=0
  combat_result=2
  combat_msg="you were slain..."
  msg_t=60
 end

 -- refill hand if empty
 if #hand==0 and #discard>0 then
  -- shuffle discard back
  for c in all(discard) do
   add(hand,c)
  end
  discard={}
  -- shuffle
  for i=#hand,2,-1 do
   local j=flr(rnd(i))+1
   hand[i],hand[j]=hand[j],hand[i]
  end
  -- keep max hand
  while #hand>max_hand do
   local c=hand[#hand]
   del(hand,c)
   add(discard,c)
  end
 end
end

function draw_combat()
 -- bg
 rectfill(0,0,127,127,0)

 -- arena
 rectfill(0,0,127,50,1)
 line(0,50,127,50,5)

 -- enemy
 local ex=64
 local ey=15
 draw_enemy_sprite(ex,ey)

 -- enemy hp bar
 local ehp_w=40
 local ehp_fill=ehp_w*(enemy.hp/enemy.maxhp)
 rectfill(ex-20,ey+20,ex-20+ehp_w,ey+24,2)
 rectfill(ex-20,ey+20,ex-20+ehp_fill,ey+24,8)
 print(enemy.name,ex-#enemy.name*2,ey+27,7)
 print(enemy.hp.."/"..enemy.maxhp,ex-12,ey-6,8)

 -- player stats
 rectfill(0,52,127,62,1)
 print("hp:"..p.hp.."/"..p.maxhp,2,54,8)
 print("mp:"..p.mp.."/"..p.maxmp,42,54,12)
 print("shd:"..p_shield,80,54,11)
 print("atk:"..p.atk,105,54,9)

 -- hand area
 rectfill(0,64,127,127,0)

 if p_turn and combat_result==0 then
  print("your turn",46,66,11)
 else
  print("enemy turn",44,66,8)
 end

 -- draw hand cards
 if #hand>0 then
  local cw=28
  local total_w=cw*#hand+2*(#hand-1)
  local sx=64-total_w/2
  for i=1,#hand do
   local cx=sx+(i-1)*(cw+2)
   local cy=76
   local sel=i-1==hand_sel and p_turn
   draw_card(hand[i],cx,cy,sel)
  end
 else
  print("no cards!",42,90,6)
 end

 -- arrows
 if p_turn and #hand>0 then
  print("\x91\x94 select  \x97 play  \x96 pass",4,120,6)
 end

 -- combat message
 if msg_t>0 and combat_msg~="" then
  local mw=#combat_msg*4+4
  rectfill(64-mw/2,44,64+mw/2,52,0)
  print(combat_msg,64-#combat_msg*2,46,
   combat_result==2 and 8 or
   combat_result==1 and 11 or 7)
 end

 -- anim flash
 if combat_anim>0 then
  combat_anim-=1
  if combat_anim%4<2 then
   rectfill(0,0,127,127,7)
  end
 end
end

function draw_card(c,x,y,sel)
 local bg=1
 local fg=7
 local border=5
 if sel then
  border=10
  bg=2
  y-=3
 end
 -- card bg
 rectfill(x,y,x+27,y+44,bg)
 rect(x,y,x+27,y+44,border)
 -- card type color stripe
 local tc=6
 if c.type==1 then tc=8
 elseif c.type==2 then tc=11
 elseif c.type==3 then tc=12
 elseif c.type==4 then tc=9
 end
 rectfill(x+1,y+1,x+26,y+6,tc)
 -- name
 print(c.name,x+2,y+2,0)
 -- cost
 if c.cost>0 then
  circfill(x+23,y+12,3,12)
  print(c.cost,x+22,y+10,7)
 else
  circfill(x+23,y+12,3,3)
  print("0",x+22,y+10,7)
 end
 -- value
 print(c.val,x+4,y+12,fg)
 -- desc
 local d=c.desc
 if #d>8 then
  print(sub(d,1,8),x+2,y+22,6)
  print(sub(d,9),x+2,y+28,6)
 else
  print(d,x+2,y+22,6)
 end
 -- type icon
 if c.type==1 then
  print("\x88",x+4,y+34,8)
 elseif c.type==2 then
  print("+",x+4,y+34,11)
 elseif c.type==3 then
  print("o",x+4,y+34,12)
 elseif c.type==4 then
  print("^",x+4,y+34,9)
 end
end

function draw_enemy_sprite(x,y)
 -- procedural enemy based on name
 local n=enemy.name
 local c1=8
 local c2=2
 if n=="rat" then c1=4 c2=15
 elseif n=="bat" then c1=5 c2=1
 elseif n=="slime" then c1=3 c2=11
 elseif n=="goblin" then c1=3 c2=11
 elseif n=="skeleton" then c1=7 c2=6
 elseif n=="spider" then c1=5 c2=0
 elseif n=="orc" then c1=3 c2=4
 elseif n=="wraith" then c1=13 c2=1
 elseif n=="dragon" then c1=8 c2=2
 end

 -- body
 circfill(x,y,8,c1)
 circfill(x,y,6,c2)
 -- eyes
 circfill(x-3,y-2,2,7)
 circfill(x+3,y-2,2,7)
 pset(x-3,y-2,0)
 pset(x+3,y-2,0)
 -- mouth
 line(x-2,y+3,x+2,y+3,0)
end

-->8
-- shop & inn

function gen_shop()
 shop_items={}
 shop_sel=0
 -- offer 3 random cards
 for i=1,3 do
  local c=copy_card(
   card_db[flr(rnd(#card_db))+1])
  local price=5+c.cost*3+c.val
  add(shop_items,{card=c,price=price})
 end
end

function update_shop()
 if btnp(2) then shop_sel-=1 sfx(3) end
 if btnp(3) then shop_sel+=1 sfx(3) end
 shop_sel=mid(0,shop_sel,#shop_items-1)

 if btnp(4) and #shop_items>0 then
  local item=shop_items[shop_sel+1]
  if p.gold>=item.price then
   p.gold-=item.price
   add(deck,item.card)
   del(shop_items,item)
   shop_sel=min(shop_sel,#shop_items-1)
   if shop_sel<0 then shop_sel=0 end
   sfx(1)
  else
   sfx(3)
  end
 end

 if btnp(5) then
  go_to(st_town)
 end
end

function draw_shop()
 rectfill(0,0,127,127,1)
 print_border("~ card shop ~",34,4,10,0)
 print("gold: "..p.gold,4,14,10)
 print("deck: "..#deck.." cards",60,14,7)

 for i=1,#shop_items do
  local item=shop_items[i]
  local y=26+(i-1)*30
  local sel=i-1==shop_sel
  draw_card(item.card,4,y,sel)
  -- price
  local pc=10
  if p.gold<item.price then pc=8 end
  print(item.price.."g",36,y+10,pc)
  -- extra desc
  print(item.card.desc,36,y+18,6)
 end

 if #shop_items==0 then
  print("sold out!",42,60,6)
 end

 print("\x97:buy  \x96:leave",30,120,6)
end

function update_inn()
 if btnp(4) then
  if p.gold>=inn_cost then
   p.gold-=inn_cost
   -- rest: full heal + mp restore
   p.hp=p.maxhp
   p.mp=p.maxmp
   -- buff
   p.maxhp+=2
   p.hp=p.maxhp
   p.maxmp+=1
   p.mp=p.maxmp
   p.inn_buff+=1
   sfx(1)
   go_to(st_town)
  else
   sfx(3)
  end
 end
 if btnp(5) then
  go_to(st_town)
 end
end

function draw_inn()
 rectfill(0,0,127,127,1)
 print_border("~ inn ~",46,4,14,0)

 -- inn illustration
 rectfill(44,20,84,50,4)
 rectfill(54,30,74,50,3)
 rectfill(48,22,52,30,14)
 rectfill(76,22,80,30,14)

 print("rest at the inn?",32,58,7)
 print("cost: "..inn_cost.." gold",36,68,10)
 print("effects:",36,80,6)
 print(" - full hp & mp restore",16,88,11)
 print(" - +2 max hp",16,96,11)
 print(" - +1 max mp",16,104,11)

 local c=10
 if p.gold<inn_cost then c=8 end
 print("gold: "..p.gold,4,114,c)

 print("\x97:rest  \x96:leave",30,122,6)
end

-->8
-- loot, gameover, victory

function update_loot()
 if btnp(4) or btnp(5) then
  p.gold+=loot_gold
  if loot_card then
   add(deck,loot_card)
  end
  go_to(st_dungeon)
 end
end

function draw_loot()
 rectfill(0,0,127,127,0)
 print_border("~ victory! ~",36,10,11,0)

 print("loot:",52,30,7)
 print("+"..loot_gold.." gold",46,42,10)

 if loot_card then
  print("new card:",42,56,7)
  draw_card(loot_card,40,66,false)
 else
  print("no card drop",36,56,6)
 end

 print("press x to continue",22,118,6)
end

function update_gameover()
 if btnp(4) or btnp(5) then
  go_to(st_title)
 end
end

function draw_gameover()
 rectfill(0,0,127,127,0)

 local t=time()
 -- dramatic bg
 for i=0,20 do
  local r=10+i*3+sin(t+i/10)*5
  circ(64,64,r,2)
 end

 print_border("game over",40,40,8,0)
 print_center("you reached floor "..p.floor,60,7)
 print_center("gold earned: "..p.gold,70,10)

 if flr(t*2)%2==0 then
  print_center("press x to restart",100,6)
 end
end

function update_victory()
 if btnp(4) or btnp(5) then
  go_to(st_title)
 end
end

function draw_victory()
 rectfill(0,0,127,127,0)
 local t=time()
 -- stars
 for i=0,30 do
  local sx=rnd(128)
  local sy=rnd(128)
  pset(sx,sy,rnd()>.5 and 10 or 7)
 end

 print_border("you win!",42,30,10,0)
 print_center("you conquered the",50,7)
 print_center("dungeon!",60,11)
 print_center("floors cleared: "..p.floor,76,7)
 print_center("final gold: "..p.gold,86,10)
 print_center("deck size: "..#deck,96,12)

 if flr(t*2)%2==0 then
  print_center("press x to play again",114,6)
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
__sfx__
000100001505015050150501505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002405024050280502b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000c0500c0500805005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001005010050130500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
