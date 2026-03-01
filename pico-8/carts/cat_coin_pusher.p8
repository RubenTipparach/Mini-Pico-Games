pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cat coin pusher
-- by claude code

-- a cat-themed arcade coin
-- pusher! drop fish coins
-- onto the shelf. the pusher
-- slides back and forth,
-- nudging coins off the edge
-- to score points. collect
-- special items for bonuses!

-------------------------------
-- globals
-------------------------------
gamestate="title"
score=0
coins_left=20
max_coins=20
combo=0
combo_timer=0
best_score=0
shake=0
t=0

-- pusher
pusher={
 x=32,y=48,
 w=64,h=10,
 dir=1,spd=0.6
}

-- shelf area
shelf={
 x=16,y=40,
 w=96,h=56,
 edge_y=96
}

-- coins on the board
board_coins={}

-- falling coins (off edge)
falling={}

-- particles
particles={}

-- special items
specials={}

-- drop cursor
cursor_x=64
cursor_spd=1.5

-- cat player
cat={
 x=56,y=112,
 frame=0,timer=0,
 happy=0
}

-------------------------------
-- helpers
-------------------------------
function make_coin(x,y,vx,vy)
 local c={
  x=x,y=y,
  vx=vx or 0,
  vy=vy or 0,
  r=3,
  type=flr(rnd(6)),
  bounce=0,
  on_board=true,
  settled=false
 }
 add(board_coins,c)
 return c
end

function make_special(x,y)
 local s={
  x=x,y=y,
  vx=0,vy=0,
  type=flr(rnd(3)),
  on_board=true
 }
 add(specials,s)
 return s
end

function make_particle(x,y,c,life)
 add(particles,{
  x=x,y=y,
  vx=rnd(2)-1,
  vy=-rnd(2),
  c=c,
  life=life or 20,
  max_life=life or 20
 })
end

function burst(x,y,c,n)
 for i=1,n do
  make_particle(x,y,c,10+rnd(15))
 end
end

function dist(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 return sqrt(dx*dx+dy*dy)
end

function coin_coin_push(a,b)
 local dx=b.x-a.x
 local dy=b.y-a.y
 local d=sqrt(dx*dx+dy*dy)
 if d<6 and d>0 then
  local nx=dx/d
  local ny=dy/d
  local overlap=6-d
  b.x+=nx*overlap*0.5
  b.y+=ny*overlap*0.5
  a.x-=nx*overlap*0.5
  a.y-=ny*overlap*0.5
  b.vx+=nx*0.3
  b.vy+=ny*0.3
  a.vx-=nx*0.1
  a.vy-=ny*0.1
 end
end

-------------------------------
-- init
-------------------------------
function _init()
 gamestate="title"
 score=0
 coins_left=max_coins
 combo=0
 combo_timer=0
end

function start_game()
 gamestate="playing"
 score=0
 coins_left=max_coins
 combo=0
 combo_timer=0
 board_coins={}
 falling={}
 particles={}
 specials={}
 pusher.x=32
 pusher.dir=1
 cat.happy=0
 shake=0

 -- pre-place some coins
 for i=1,8 do
  local cx=shelf.x+8+rnd(shelf.w-16)
  local cy=shelf.y+20+rnd(20)
  local c=make_coin(cx,cy)
  c.settled=true
 end

 -- place a special item
 local sx=shelf.x+16+rnd(shelf.w-32)
 local sy=shelf.y+25+rnd(10)
 make_special(sx,sy)
end

-------------------------------
-- update
-------------------------------
function _update60()
 t+=1
 if shake>0 then shake-=1 end
 if combo_timer>0 then
  combo_timer-=1
  if combo_timer<=0 then
   combo=0
  end
 end

 if gamestate=="title" then
  update_title()
 elseif gamestate=="playing" then
  update_game()
 elseif gamestate=="gameover" then
  update_gameover()
 end

 -- always update particles
 update_particles()
end

function update_title()
 if btnp(4) or btnp(5) then
  start_game()
 end
end

function update_gameover()
 if btnp(4) or btnp(5) then
  start_game()
 end
end

function update_game()
 -- move cursor
 if btn(0) then cursor_x-=cursor_spd end
 if btn(1) then cursor_x+=cursor_spd end
 cursor_x=mid(shelf.x+4,cursor_x,shelf.x+shelf.w-4)

 -- drop coin
 if btnp(4) or btnp(5) then
  if coins_left>0 then
   coins_left-=1
   local c=make_coin(cursor_x,shelf.y-2,0,0.5)
   c.settled=false
   sfx(0)
  end
 end

 -- move pusher
 pusher.x+=pusher.dir*pusher.spd
 if pusher.x<=shelf.x then
  pusher.dir=1
 elseif pusher.x+pusher.w>=shelf.x+shelf.w then
  pusher.dir=-1
 end

 -- update board coins
 for c in all(board_coins) do
  if not c.settled then
   -- gravity
   c.vy+=0.02
   -- friction
   c.vx*=0.92
   c.vy*=0.92
  else
   c.vx*=0.85
   c.vy*=0.85
   if abs(c.vx)<0.01 then c.vx=0 end
   if abs(c.vy)<0.01 then c.vy=0 end
  end

  -- pusher collision
  if c.y>pusher.y and
     c.y<pusher.y+pusher.h and
     c.x>pusher.x and
     c.x<pusher.x+pusher.w then
   c.vy+=0.4
   c.y=pusher.y+pusher.h+1
   c.vx+=pusher.dir*0.2
   c.settled=false
  end

  -- move
  c.x+=c.vx
  c.y+=c.vy

  -- wall bounds
  if c.x<shelf.x+3 then
   c.x=shelf.x+3
   c.vx*=-0.3
  end
  if c.x>shelf.x+shelf.w-3 then
   c.x=shelf.x+shelf.w-3
   c.vx*=-0.3
  end

  -- top bound
  if c.y<shelf.y+2 then
   c.y=shelf.y+2
   c.vy*=-0.3
  end

  -- settle on shelf
  if c.y>shelf.y+10 and abs(c.vy)<0.1 and abs(c.vx)<0.1 then
   c.settled=true
  end

  -- fell off edge!
  if c.y>shelf.edge_y then
   del(board_coins,c)
   combo+=1
   combo_timer=90
   local pts=10*combo
   score+=pts
   cat.happy=30
   shake=4
   burst(c.x,shelf.edge_y,10,8)
   burst(c.x,shelf.edge_y,7,4)
   sfx(1)
  end
 end

 -- coin-to-coin collisions
 for i=1,#board_coins do
  for j=i+1,#board_coins do
   coin_coin_push(board_coins[i],board_coins[j])
  end
 end

 -- update specials
 for s in all(specials) do
  -- pusher push
  if s.y>pusher.y and
     s.y<pusher.y+pusher.h and
     s.x>pusher.x and
     s.x<pusher.x+pusher.w then
   s.vy+=0.4
   s.y=pusher.y+pusher.h+1
   s.vx+=pusher.dir*0.15
  end

  s.vx*=0.9
  s.vy*=0.9
  s.x+=s.vx
  s.y+=s.vy

  -- coin push on specials
  for c in all(board_coins) do
   local dx=s.x-c.x
   local dy=s.y-c.y
   local d=sqrt(dx*dx+dy*dy)
   if d<7 and d>0 then
    s.vx+=dx/d*0.2
    s.vy+=dy/d*0.2
   end
  end

  -- bounds
  s.x=mid(shelf.x+4,s.x,shelf.x+shelf.w-4)
  if s.y<shelf.y+2 then
   s.y=shelf.y+2
   s.vy*=-0.3
  end

  -- fell off!
  if s.y>shelf.edge_y then
   del(specials,s)
   if s.type==0 then
    -- yarn ball: +5 coins
    coins_left=min(coins_left+5,max_coins)
    burst(s.x,shelf.edge_y,12,12)
    sfx(2)
   elseif s.type==1 then
    -- golden fish: x3 score
    score+=50
    burst(s.x,shelf.edge_y,10,15)
    sfx(2)
   else
    -- mouse toy: bonus
    score+=30
    coins_left=min(coins_left+3,max_coins)
    burst(s.x,shelf.edge_y,11,10)
    sfx(2)
   end
   cat.happy=60
   shake=6
  end
 end

 -- cat animation
 cat.timer+=1
 if cat.timer>10 then
  cat.timer=0
  cat.frame=(cat.frame+1)%2
 end
 if cat.happy>0 then cat.happy-=1 end

 -- check game over
 if coins_left<=0 and #board_coins==0 then
  gamestate="gameover"
  if score>best_score then
   best_score=score
  end
  sfx(3)
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

-------------------------------
-- draw
-------------------------------
function _draw()
 local sx,sy=0,0
 if shake>0 then
  sx=rnd(3)-1.5
  sy=rnd(3)-1.5
 end
 camera(sx,sy)
 cls(1)

 if gamestate=="title" then
  draw_title()
 elseif gamestate=="playing" then
  draw_game()
 elseif gamestate=="gameover" then
  draw_game()
  draw_gameover()
 end

 draw_particles()
 camera(0,0)
end

function draw_title()
 -- background
 for i=0,15 do
  local y=i*8+t%8
  line(0,y,127,y,2)
 end

 -- title box
 rectfill(14,20,114,55,0)
 rect(14,20,114,55,7)
 rect(15,21,113,54,5)

 -- title
 print("🐱 cat coin pusher 🐱",18,26,10)
 print("drop fish coins and",22,36,7)
 print("push them off!",32,44,6)

 -- cat face
 draw_big_cat(52,62)

 -- prompt
 if t%60<40 then
  print("❎ press to start ❎",20,108,7)
 end

 -- credits
 print("by claude code",34,120,5)
end

function draw_big_cat(x,y)
 -- big cat face for title
 circfill(x+12,y+14,14,4)
 -- ears
 local ear_c=4
 -- left ear
 line(x+1,y+3,x+5,y,ear_c)
 line(x+5,y,x+9,y+5,ear_c)
 pset(x+5,y+2,15)
 -- right ear
 line(x+15,y+5,x+19,y,ear_c)
 line(x+19,y,x+23,y+3,ear_c)
 pset(x+19,y+2,15)
 -- eyes
 circfill(x+7,y+12,2,7)
 circfill(x+17,y+12,2,7)
 pset(x+7,y+12,0)
 pset(x+17,y+12,0)
 -- nose
 pset(x+12,y+16,8)
 -- mouth
 line(x+10,y+18,x+12,y+19,8)
 line(x+12,y+19,x+14,y+18,8)
 -- whiskers
 line(x-2,y+15,x+5,y+16,7)
 line(x-2,y+18,x+5,y+17,7)
 line(x+19,y+16,x+26,y+15,7)
 line(x+19,y+17,x+26,y+18,7)
end

function draw_game()
 -- background pattern
 for yy=0,127,8 do
  for xx=0,127,8 do
   if (xx+yy)%16==0 then
    rectfill(xx,yy,xx+7,yy+7,1)
   end
  end
 end

 -- shelf back wall
 rectfill(shelf.x-1,shelf.y-2,
  shelf.x+shelf.w,shelf.y+6,5)
 -- shelf main area
 rectfill(shelf.x,shelf.y+6,
  shelf.x+shelf.w-1,shelf.edge_y,0)
 -- shelf border
 rect(shelf.x-1,shelf.y-2,
  shelf.x+shelf.w,shelf.edge_y+1,5)
 -- shelf glass sides
 line(shelf.x-1,shelf.y-2,
  shelf.x-1,shelf.edge_y+1,6)
 line(shelf.x+shelf.w,shelf.y-2,
  shelf.x+shelf.w,shelf.edge_y+1,6)
 -- edge line
 line(shelf.x,shelf.edge_y,
  shelf.x+shelf.w-1,shelf.edge_y,8)
 -- edge glow
 if t%4<2 then
  line(shelf.x,shelf.edge_y,
   shelf.x+shelf.w-1,shelf.edge_y,9)
 end

 -- draw pusher
 draw_pusher()

 -- draw specials
 for s in all(specials) do
  draw_special(s)
 end

 -- draw board coins
 for c in all(board_coins) do
  draw_coin(c)
 end

 -- cursor
 if gamestate=="playing" then
  draw_cursor()
 end

 -- tray area
 rectfill(0,shelf.edge_y+2,127,127,2)
 rectfill(shelf.x-4,shelf.edge_y+2,
  shelf.x+shelf.w+3,shelf.edge_y+6,5)

 -- cat
 draw_cat()

 -- hud
 draw_hud()
end

function draw_pusher()
 -- pusher body
 rectfill(pusher.x,pusher.y,
  pusher.x+pusher.w-1,
  pusher.y+pusher.h-1,13)
 -- pusher face
 rect(pusher.x,pusher.y,
  pusher.x+pusher.w-1,
  pusher.y+pusher.h-1,5)
 -- pusher stripe
 line(pusher.x+2,pusher.y+4,
  pusher.x+pusher.w-3,pusher.y+4,5)
 -- paw prints on pusher
 for i=0,3 do
  local px=pusher.x+8+i*14
  if px<pusher.x+pusher.w-4 then
   pset(px,pusher.y+3,15)
   pset(px+1,pusher.y+2,15)
   pset(px-1,pusher.y+2,15)
   pset(px,pusher.y+5,15)
  end
 end
end

function draw_coin(c)
 local cx=flr(c.x)
 local cy=flr(c.y)
 -- shadow
 circfill(cx+1,cy+1,3,1)
 -- coin body
 if c.type<3 then
  -- fish coin (gold)
  circfill(cx,cy,3,10)
  circ(cx,cy,3,9)
  -- fish icon
  pset(cx-1,cy,4)
  pset(cx,cy,4)
  pset(cx+1,cy-1,4)
  pset(cx+1,cy+1,4)
 else
  -- paw coin (silver)
  circfill(cx,cy,3,7)
  circ(cx,cy,3,6)
  -- paw icon
  pset(cx,cy,5)
  pset(cx-1,cy-1,5)
  pset(cx+1,cy-1,5)
 end
end

function draw_special(s)
 local sx=flr(s.x)
 local sy=flr(s.y)
 -- glow
 if t%4<2 then
  circfill(sx,sy,5,
   s.type==0 and 12 or
   s.type==1 and 10 or 11)
 end
 if s.type==0 then
  -- yarn ball
  circfill(sx,sy,4,12)
  circ(sx,sy,4,1)
  -- yarn lines
  line(sx-2,sy-1,sx+2,sy+1,14)
  line(sx-1,sy+2,sx+1,sy-2,14)
 elseif s.type==1 then
  -- golden fish
  -- body
  circfill(sx,sy,3,10)
  -- tail
  line(sx+3,sy,sx+5,sy-2,9)
  line(sx+3,sy,sx+5,sy+2,9)
  -- eye
  pset(sx-1,sy-1,0)
 else
  -- mouse toy
  circfill(sx,sy,3,15)
  circ(sx,sy,3,5)
  -- ears
  circfill(sx-2,sy-3,1,15)
  circfill(sx+2,sy-3,1,15)
  -- eyes
  pset(sx-1,sy-1,0)
  pset(sx+1,sy-1,0)
  -- tail
  line(sx+3,sy+1,sx+5,sy+3,5)
 end
end

function draw_cursor()
 local cx=flr(cursor_x)
 -- arrow
 line(cx,shelf.y-8,cx,shelf.y-4,7)
 pset(cx-1,shelf.y-5,7)
 pset(cx+1,shelf.y-5,7)

 -- coin preview
 if coins_left>0 then
  circfill(cx,shelf.y-12,2,10)
  circ(cx,shelf.y-12,2,9)
 end

 -- dotted guide line
 for yy=shelf.y-3,shelf.y+4,3 do
  pset(cx,yy,6)
 end
end

function draw_cat()
 local cx=flr(cat.x)
 local cy=flr(cat.y)
 local happy=cat.happy>0

 -- body
 circfill(cx+6,cy+6,7,4)
 -- head
 circfill(cx+6,cy-1,5,4)
 -- ears
 line(cx+1,cy-4,cx+3,cy-7,4)
 line(cx+3,cy-7,cx+5,cy-4,4)
 line(cx+7,cy-4,cx+9,cy-7,4)
 line(cx+9,cy-7,cx+11,cy-4,4)
 -- inner ear
 pset(cx+3,cy-5,15)
 pset(cx+9,cy-5,15)

 -- eyes
 if happy then
  -- happy squint
  line(cx+3,cy-2,cx+5,cy-3,0)
  line(cx+5,cy-3,cx+7,cy-2,0)
  line(cx+7,cy-2,cx+9,cy-3,0)
  line(cx+9,cy-3,cx+11,cy-2,0)
 else
  circfill(cx+4,cy-1,1,7)
  circfill(cx+8,cy-1,1,7)
  pset(cx+4,cy-1,0)
  pset(cx+8,cy-1,0)
  -- blink
  if t%120>115 then
   rectfill(cx+3,cy-2,cx+5,cy,4)
   rectfill(cx+7,cy-2,cx+9,cy,4)
  end
 end

 -- nose
 pset(cx+6,cy+1,8)
 -- mouth
 if happy then
  line(cx+4,cy+2,cx+6,cy+3,8)
  line(cx+6,cy+3,cx+8,cy+2,8)
 else
  line(cx+5,cy+2,cx+7,cy+2,8)
 end

 -- whiskers
 line(cx-2,cy,cx+3,cy,7)
 line(cx-2,cy+2,cx+3,cy+1,7)
 line(cx+9,cy,cx+14,cy,7)
 line(cx+9,cy+1,cx+14,cy+2,7)

 -- tail
 local tail_wave=sin(t/30)*3
 line(cx+12,cy+8,cx+18,cy+4+tail_wave,4)
 line(cx+18,cy+4+tail_wave,
  cx+20,cy+2+tail_wave,4)

 -- paws
 rectfill(cx+1,cy+11,cx+4,cy+13,4)
 rectfill(cx+8,cy+11,cx+11,cy+13,4)
 -- paw pads
 pset(cx+2,cy+12,15)
 pset(cx+9,cy+12,15)
end

function draw_hud()
 -- top bar
 rectfill(0,0,127,9,0)
 line(0,10,127,10,5)

 -- score
 print("score:"..score,2,2,7)

 -- coins left
 print("coins:"..coins_left,68,2,10)

 -- combo
 if combo>1 and combo_timer>0 then
  local cc=10
  if t%4<2 then cc=9 end
  print("x"..combo.." combo!",44,2,cc)
 end

 -- best score
 if best_score>0 then
  print("best:"..best_score,90,2,5)
 end
end

function draw_gameover()
 -- overlay
 rectfill(20,35,108,95,0)
 rect(20,35,108,95,7)
 rect(21,36,107,94,5)

 print("game over!",38,42,8)
 print("final score: "..score,30,54,7)

 if score>=best_score and score>0 then
  if t%30<20 then
   print("★ new best! ★",34,64,10)
  end
 end

 if t%60<40 then
  print("❎ play again",36,82,7)
 end
end

function draw_particles()
 for p in all(particles) do
  local a=p.life/p.max_life
  if a>0.5 then
   circfill(p.x,p.y,1,p.c)
  else
   pset(p.x,p.y,p.c)
  end
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
000200001505015050130501005007050050500305003050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500
000400002a0502a0502805026050240502205020050200501e0501c0501a050180501605014050130501305012050110501005010050100500f0500f0500e0500e0500d0500d0500c0500c0500b0500b0500a0500a050
000800001805024050300502a050260502205020050200501f0501f0501e0501e0501d0501d0501c0501c0501b0501b0501a0501a05019050190501805018050170501705016050160501505015050140501405013050
001000000c0500c0500a05008050060500405003050020500105001050010500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
