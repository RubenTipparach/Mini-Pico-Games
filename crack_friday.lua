-- title:  Crack Friday!
-- author:  Ruben Tipparach
-- desc:    Rush to grab deals before other shoppers!
-- script:  lua

-- TIC-80 Sweetie-16 palette indices:
-- 0: #1a1c2c (dark blue/black)
-- 1: #5d275d (dark purple)
-- 2: #b13e53 (red)
-- 3: #ef7d57 (orange)
-- 4: #ffcd75 (yellow)
-- 5: #a7f070 (lime green)
-- 6: #38b764 (green)
-- 7: #257179 (teal)
-- 8: #29366f (navy)
-- 9: #3b5dc9 (blue)
-- 10: #41a6f6 (sky blue)
-- 11: #73eff7 (cyan)
-- 12: #f4f4f4 (white)
-- 13: #94b0c2 (light gray)
-- 14: #566c86 (gray)
-- 15: #333c57 (dark gray)

-- Game states
STATE_SPLASH=0
STATE_TITLE=1
STATE_PLAY=2
STATE_CHECKOUT=3
STATE_LEVELCOMPLETE=4
STATE_GAMEOVER=5

-- Game variables
state=STATE_SPLASH
level=1
t=0
splashTimer=0

-- Player
player={
 x=120,y=68,
 w=10,h=10,
 vx=0,vy=0,
 cart={},
 cartValue=0,
 cartSavings=0,
 stunned=0,
 dir=1,
 invuln=0,
 shieldTimer=0 -- immunity powerup timer
}

-- Level configs with target values
levels={
 {name="Corner Mart",w=200,h=136,shoppers=3,toys=12,time=45,target=100,premiums=2},
 {name="MegaMart",w=280,h=170,shoppers=5,toys=20,time=60,target=250,premiums=3},
 {name="GigaPlex",w=360,h=200,shoppers=8,toys=30,time=75,target=500,premiums=4}
}

-- AI difficulty per level
aiConfig={
 {maxSpeed=0.5,accel=0.05,retargetTime=180,wanderChance=0.15},
 {maxSpeed=0.85,accel=0.12,retargetTime=90,wanderChance=0.08},
 {maxSpeed=1.25,accel=0.2,retargetTime=45,wanderChance=0.02},
}

-- Toy types with prices and discounts
toyTypes={
 {name="Robot",price=50,discount=30,combo="Drone",icon=1},
 {name="Drone",price=60,discount=25,combo="Robot",icon=2},
 {name="Teddy",price=25,discount=50,combo="Doll",icon=3},
 {name="Doll",price=30,discount=40,combo="Teddy",icon=4},
 {name="Train",price=80,discount=35,combo="Blocks",icon=5},
 {name="Blocks",price=20,discount=20,combo="Train",icon=6},
 {name="Console",price=200,discount=15,combo=nil,icon=7},
 {name="Bike",price=150,discount=20,combo=nil,icon=8},
 {name="Puzzle",price=15,discount=60,combo="Board",icon=9},
 {name="Board",price=35,discount=45,combo="Puzzle",icon=10},
}

-- Active game objects
toys={}
premiumToys={} -- shield powerups
shoppers={}
particles={}
aisles={}
aisleProducts={}
droppedItems={}
checkout={x=0,y=0,w=24,h=16}
timer=0
camX=0
camY=0
storeW=200
storeH=136
totalScore=0
checkoutOpen=false
CHECKOUT_WARNING_TIME=10
DROPPED_ITEM_LIFETIME=180
SHIELD_DURATION=600 -- 10 seconds at 60fps for player buff
SHIELD_PICKUP_LIFETIME=600 -- 10 seconds at 60fps for pickup to exist
SHIELD_SPAWN_INTERVAL=1800 -- 30 seconds at 60fps
checkoutBeepTimer=0
shieldSpawnTimer=0
activeShield=nil -- only one shield at a time

-- Draw toy icon based on type
function drawToyIcon(x,y,icon,scale)
 scale=scale or 1
 if icon==1 then -- Robot
  rect(x+4,y+2,6,8,14)
  rect(x+5,y+3,4,3,10)
  rect(x+5,y+4,1,1,2)
  rect(x+8,y+4,1,1,2)
  rect(x+3,y+4,1,4,14)
  rect(x+10,y+4,1,4,14)
  rect(x+5,y+10,2,2,14)
  rect(x+7,y+10,2,2,14)
  rect(x+5,y,4,2,2)
 elseif icon==2 then -- Drone
  rect(x+4,y+5,6,4,14)
  rect(x+5,y+6,4,2,10)
  line(x+2,y+4,x+5,y+6,13)
  line(x+12,y+4,x+9,y+6,13)
  rect(x+1,y+3,3,2,15)
  rect(x+10,y+3,3,2,15)
 elseif icon==3 then -- Teddy
  circ(x+7,y+4,3,3)
  circ(x+4,y+3,1,3)
  circ(x+10,y+3,1,3)
  rect(x+5,y+7,4,5,3)
  rect(x+6,y+5,1,1,0)
  rect(x+8,y+5,1,1,0)
  rect(x+7,y+6,1,1,0)
 elseif icon==4 then -- Doll
  circ(x+7,y+4,3,3)
  rect(x+5,y+7,4,5,1)
  rect(x+6,y+3,3,2,4)
  rect(x+4,y+2,2,3,4)
  rect(x+9,y+2,2,3,4)
  pix(x+6,y+5,0)
  pix(x+8,y+5,0)
 elseif icon==5 then -- Train
  rect(x+2,y+6,10,5,2)
  rect(x+3,y+4,4,3,2)
  rect(x+8,y+5,3,2,0)
  circ(x+4,y+12,2,15)
  circ(x+10,y+12,2,15)
  rect(x+4,y+7,2,2,4)
 elseif icon==6 then -- Blocks
  rect(x+2,y+7,4,5,2)
  rect(x+6,y+7,4,5,9)
  rect(x+4,y+3,4,5,5)
 elseif icon==7 then -- Console
  rect(x+2,y+4,10,7,15)
  rect(x+3,y+5,8,5,0)
  rect(x+4,y+6,3,3,9)
  rect(x+4,y+11,2,1,13)
  rect(x+8,y+11,2,1,13)
 elseif icon==8 then -- Bike
  circ(x+4,y+8,3,15)
  circ(x+10,y+8,3,15)
  line(x+4,y+8,x+7,y+4,2)
  line(x+7,y+4,x+10,y+8,2)
  line(x+7,y+4,x+7,y+2,2)
  line(x+5,y+2,x+9,y+2,2)
 elseif icon==9 then -- Puzzle
  rect(x+2,y+3,5,5,9)
  rect(x+7,y+3,5,5,5)
  rect(x+2,y+8,5,5,4)
  rect(x+7,y+8,5,5,2)
  circ(x+7,y+5,1,9)
  circ(x+7,y+10,1,4)
 elseif icon==10 then -- Board game
  rect(x+2,y+4,10,8,3)
  rect(x+3,y+5,8,6,4)
  rect(x+4,y+6,2,2,2)
  rect(x+7,y+7,2,2,9)
  rect(x+5,y+9,3,1,0)
 end
end

-- Draw shield/premium powerup
function drawShieldIcon(x,y)
 -- Shield shape
 rect(x+3,y+2,8,10,11)
 rect(x+4,y+3,6,8,10)
 -- Star in center
 pix(x+7,y+5,4)
 pix(x+6,y+6,4)
 pix(x+7,y+6,4)
 pix(x+8,y+6,4)
 pix(x+7,y+7,4)
 pix(x+5,y+7,4)
 pix(x+9,y+7,4)
end

-- Draw shopper with cart
function drawShopper(x,y,color,stunned,cartCount,dir,isPlayer,invuln,hasShield)
 if invuln and invuln>0 and t%6<3 then
  return
 end
 
 -- Shield glow effect
 if hasShield then
  local pulse=math.sin(t*0.2)*2
  circ(x+8,y+8,14+pulse,11)
  circ(x+8,y+8,12+pulse,10)
 end
 
 elli(x+8,y+18,8,3,0)
 
 if stunned then
  rect(x+5,y+6,6,8,color)
  circ(x+8,y+4,4,isPlayer and 3 or color)
  print("X",x+5,y+2,12)
  print("X",x+9,y+2,12)
  local st=t*0.2
  print("*",x+math.cos(st)*10,y-2+math.sin(st)*2,4)
  print("*",x+math.cos(st+2)*10,y-2+math.sin(st+2)*2,4)
 else
  local legOff=math.sin(t*0.3)*2
  rect(x+5,y+12,2,4,isPlayer and 9 or 8)
  rect(x+9,y+12,2,4,isPlayer and 9 or 8)
  
  rect(x+4,y+6,8,7,color)
  
  if dir>0 then
   line(x+11,y+8,x+14,y+10,color)
   line(x+11,y+10,x+14,y+10,color)
  else
   line(x+5,y+8,x+2,y+10,color)
   line(x+5,y+10,x+2,y+10,color)
  end
  
  circ(x+8,y+4,4,isPlayer and 3 or color)
  
  if isPlayer then
   pix(x+6,y+3,0)
   pix(x+10,y+3,0)
   line(x+6,y+6,x+10,y+6,0)
  else
   pix(x+6,y+3,12)
   pix(x+10,y+3,12)
   line(x+6,y+6,x+10,y+5,0)
  end
  
  if isPlayer then
   rect(x+5,y,6,2,4)
  else
   rect(x+5,y,6,2,0)
  end
 end
 
 local cartX=dir>0 and x+12 or x-8
 local cartY=y+8
 
 rect(cartX,cartY,10,8,13)
 rect(cartX+1,cartY+1,8,6,7)
 
 if dir>0 then
  line(cartX,cartY,cartX-2,cartY-3,13)
 else
  line(cartX+10,cartY,cartX+12,cartY-3,13)
 end
 
 circ(cartX+2,cartY+9,1,15)
 circ(cartX+8,cartY+9,1,15)
 
 if cartCount>0 then
  for i=1,math.min(cartCount,4) do
   local ix=cartX+2+((i-1)%2)*3
   local iy=cartY+1+math.floor((i-1)/2)*3
   rect(ix,iy,3,3,1+(i*2)%6)
  end
  if cartCount>4 then
   circ(cartX+9,cartY-2,4,2)
   print(cartCount,cartX+7,cartY-4,12)
  end
 end
end

-- Spawn dropped items (only 10% of cart)
function spawnDroppedItems(x,y,items)
 local dropCount=math.max(1,math.floor(#items*0.1))
 local dropped={}
 
 -- Randomly select items to drop
 local indices={}
 for i=1,#items do indices[i]=i end
 for i=1,dropCount do
  if #indices==0 then break end
  local idx=math.random(#indices)
  local itemIdx=indices[idx]
  table.remove(indices,idx)
  
  local angle=(i/dropCount)*math.pi*2+math.random()*0.5
  local speed=1.5+math.random()*1.5
  table.insert(droppedItems,{
   x=x,
   y=y,
   vx=math.cos(angle)*speed,
   vy=math.sin(angle)*speed-1,
   type=items[itemIdx],
   lifetime=DROPPED_ITEM_LIFETIME,
   bounce=0
  })
  table.insert(dropped,itemIdx)
 end
 
 -- Remove dropped items from original cart (in reverse order)
 table.sort(dropped,function(a,b) return a>b end)
 for _,idx in ipairs(dropped) do
  table.remove(items,idx)
 end
 
 return items
end

function updateDroppedItems()
 for i=#droppedItems,1,-1 do
  local item=droppedItems[i]
  
  item.vy=item.vy+0.08
  item.x=item.x+item.vx
  item.y=item.y+item.vy
  item.vx=item.vx*0.98
  item.vy=item.vy*0.98
  
  if item.y>storeH-25 then
   item.y=storeH-25
   item.vy=-item.vy*0.5
   item.bounce=item.bounce+1
  end
  
  if item.x<10 then item.x=10; item.vx=-item.vx*0.5 end
  if item.x>storeW-24 then item.x=storeW-24; item.vx=-item.vx*0.5 end
  if item.y<20 then item.y=20; item.vy=-item.vy*0.5 end
  
  local col=isCollidingWithAisles(item.x,item.y,10,10)
  if col then
   item.vx=-item.vx*0.5
   item.vy=-item.vy*0.5
   item.x=item.x+item.vx*2
   item.y=item.y+item.vy*2
  end
  
  item.lifetime=item.lifetime-1
  
  if player.invuln<=0 and player.stunned<=0 then
   if boxCollide(player,{x=item.x,y=item.y,w=12,h=12}) then
    table.insert(player.cart,item.type)
    player.cartValue=player.cartValue+item.type.price
    local saved=math.floor(item.type.price*item.type.discount/100)
    player.cartSavings=player.cartSavings+saved
    spawnParticle(item.x,item.y,"GOT!",5)
    sfx(0,50,6,0)
    table.remove(droppedItems,i)
    goto continue
   end
  end
  
  for _,s in ipairs(shoppers) do
   if s.stunned<=0 and boxCollide({x=s.x,y=s.y,w=10,h=10},{x=item.x,y=item.y,w=12,h=12}) then
    table.insert(s.cart,item.type)
    spawnParticle(item.x,item.y,"STOLEN!",2)
    sfx(0,30,6,0)
    table.remove(droppedItems,i)
    goto continue
   end
  end
  
  if item.lifetime<=0 then
   spawnParticle(item.x,item.y,"POOF",14)
   table.remove(droppedItems,i)
  end
  
  ::continue::
 end
end

function drawDroppedItems()
 for _,item in ipairs(droppedItems) do
  local x=item.x-camX
  local y=item.y-camY
  
  -- Flashing when about to expire
  if item.lifetime<60 and t%10<5 then
   goto skip
  end
  
  -- Flashing border
  local borderCol=t%8<4 and 4 or 12
  
  -- Draw box with flashing border
  rect(x-1,y-1,16,16,borderCol)
  rect(x,y,14,14,4)
  rect(x+1,y+1,12,12,15)
  
  -- Draw actual toy icon
  drawToyIcon(x,y,item.type.icon)
  
  ::skip::
 end
end

-- Play victory jingle
function playVictoryJingle()
 sfx(0,60,8,0)
 sfx(0,64,8,1)
 sfx(0,67,8,2)
 sfx(0,72,16,3)
end

-- Play sad jingle
function playSadJingle()
 sfx(0,50,12,0)
 sfx(0,47,12,1)
 sfx(0,44,16,2)
end

-- Play collision beep
function playCollisionBeep()
 sfx(1,35,8,0)
 sfx(1,30,10,1)
end

-- Play checkout beep
function playCheckoutBeep()
 sfx(2,70,4,3)
end

function generateAisles()
 aisles={}
 aisleProducts={}
 local cfg=levels[level]
 
 if level==1 then
  table.insert(aisles,{x=30,y=40,w=60,h=12})
  table.insert(aisles,{x=110,y=40,w=60,h=12})
  table.insert(aisles,{x=30,y=80,w=60,h=12})
  table.insert(aisles,{x=110,y=80,w=60,h=12})
 elseif level==2 then
  for row=0,2 do
   for col=0,2 do
    local ax=30+col*85
    local ay=35+row*45
    if not(row==2 and col==1) then
     table.insert(aisles,{x=ax,y=ay,w=50,h=12})
    end
   end
  end
 else
  for row=0,3 do
   for col=0,3 do
    local ax=30+col*80
    local ay=35+row*40
    if not((row==3 and col==1) or (row==3 and col==2)) then
     if math.random()>0.2 then
      table.insert(aisles,{x=ax,y=ay,w=45,h=12})
     end
    end
   end
  end
 end
 
 for i,a in ipairs(aisles) do
  aisleProducts[i]={}
  for px=a.x+4,a.x+a.w-8,8 do
   table.insert(aisleProducts[i],{
    x=px,
    color=math.random(1,5)
   })
  end
 end
end

function isCollidingWithAisles(x,y,w,h)
 for _,a in ipairs(aisles) do
  if x<a.x+a.w and x+w>a.x and y<a.y+a.h and y+h>a.y then
   return true,a
  end
 end
 return false,nil
end

function resolveAisleCollision(entity,oldX,oldY)
 local col,aisle=isCollidingWithAisles(entity.x,entity.y,entity.w or 10,entity.h or 10)
 if col then
  local colX=isCollidingWithAisles(entity.x,oldY,entity.w or 10,entity.h or 10)
  local colY=isCollidingWithAisles(oldX,entity.y,entity.w or 10,entity.h or 10)
  
  if colX and colY then
   entity.x=oldX
   entity.y=oldY
  elseif colX then
   entity.x=oldX
   entity.vx=0
  elseif colY then
   entity.y=oldY
   entity.vy=0
  else
   entity.x=oldX
   entity.y=oldY
  end
  return true
 end
 return false
end

function findValidSpawn()
 for attempt=1,50 do
  local x=math.random(20,storeW-36)
  local y=math.random(20,storeH-50)
  if not isCollidingWithAisles(x,y,14,14) then
   return x,y
  end
 end
 return math.random(20,storeW-36),math.random(20,storeH-50)
end

function resetLevel()
 local cfg=levels[level]
 storeW=cfg.w
 storeH=cfg.h
 timer=cfg.time*60
 checkoutOpen=false
 checkoutBeepTimer=0
 droppedItems={}
 
 generateAisles()
 
 player.x=storeW/2
 player.y=storeH-24
 player.vx=0
 player.vy=0
 player.cart={}
 player.cartValue=0
 player.cartSavings=0
 player.stunned=0
 player.w=10
 player.h=10
 player.dir=1
 player.invuln=0
 player.shieldTimer=0
 
 checkout.x=storeW/2-12
 checkout.y=storeH-12
 
 -- Spawn regular toys
 toys={}
 for i=1,cfg.toys do
  local tt=toyTypes[math.random(#toyTypes)]
  local tx,ty=findValidSpawn()
  local toy={
   x=tx,y=ty,
   w=14,h=14,
   type=tt,
   taken=false,
   respawn=0,
   flash=0
  }
  table.insert(toys,toy)
 end

 -- Shield spawning - only 1 at a time, spawns every 30 seconds
 activeShield=nil
 shieldSpawnTimer=SHIELD_SPAWN_INTERVAL -- spawn first one after 30 seconds
 premiumToys={} -- keep empty for compatibility
 
 shoppers={}
 for i=1,cfg.shoppers do
  local sx,sy=findValidSpawn()
  local s={
   x=sx,y=sy,
   w=10,h=10,
   vx=(math.random()-0.5)*0.5,
   vy=(math.random()-0.5)*0.5,
   target=nil,
   cart={},
   stunned=0,
   rushingToCheckout=false,
   color=({1,2,6,7,9})[math.random(1,5)],
   retargetTimer=math.random(60,120),
   wanderAngle=math.random()*6.28,
   baseSpeed=0.3+math.random()*0.2,
   dir=math.random()>0.5 and 1 or -1
  }
  table.insert(shoppers,s)
 end
 
 particles={}
end

function spawnParticle(x,y,text,col)
 table.insert(particles,{
  x=x,y=y,
  text=text,
  col=col,
  life=60,
  vy=-0.5
 })
end

function updateParticles()
 for i=#particles,1,-1 do
  local p=particles[i]
  p.y=p.y+p.vy
  p.life=p.life-1
  if p.life<=0 then
   table.remove(particles,i)
  end
 end
end

function drawParticles()
 for _,p in ipairs(particles) do
  local a=p.life/60
  if a>0.5 then
   print(p.text,p.x-camX,p.y-camY,p.col)
  end
 end
end

function boxCollide(a,b)
 return a.x<b.x+b.w and a.x+a.w>b.x and
        a.y<b.y+b.h and a.y+a.h>b.y
end

function dist(x1,y1,x2,y2)
 return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

function findNearestToy(x,y)
 local nearest=nil
 local nearDist=9999
 for _,toy in ipairs(toys) do
  if not toy.taken then
   local d=dist(x,y,toy.x,toy.y)
   if d<nearDist then
    nearDist=d
    nearest=toy
   end
  end
 end
 return nearest,nearDist
end

function updatePlayer()
 local oldX,oldY=player.x,player.y
 
 if player.invuln>0 then
  player.invuln=player.invuln-1
 end
 
 if player.shieldTimer>0 then
  player.shieldTimer=player.shieldTimer-1
 end
 
 if player.stunned>0 then
  player.stunned=player.stunned-1
  player.vx=player.vx*0.8
  player.vy=player.vy*0.8
 else
  local accel=0.2
  local maxSpd=1.25
  
  if btn(0) then player.vy=player.vy-accel end
  if btn(1) then player.vy=player.vy+accel end
  if btn(2) then player.vx=player.vx-accel; player.dir=-1 end
  if btn(3) then player.vx=player.vx+accel; player.dir=1 end
  
  if btn(4) then maxSpd=1.75 end
  
  local spd=math.sqrt(player.vx^2+player.vy^2)
  if spd>maxSpd then
   player.vx=player.vx/spd*maxSpd
   player.vy=player.vy/spd*maxSpd
  end
 end
 
 player.vx=player.vx*0.92
 player.vy=player.vy*0.92
 
 player.x=player.x+player.vx
 player.y=player.y+player.vy
 
 resolveAisleCollision(player,oldX,oldY)
 
 player.x=math.max(8,math.min(storeW-player.w-8,player.x))
 player.y=math.max(16,math.min(storeH-player.h-4,player.y))
 
 -- Grab regular toys
 for _,toy in ipairs(toys) do
  if not toy.taken and boxCollide(player,toy) then
   toy.taken=true
   toy.respawn=300
   table.insert(player.cart,toy.type)
   player.cartValue=player.cartValue+toy.type.price
   local saved=math.floor(toy.type.price*toy.type.discount/100)
   player.cartSavings=player.cartSavings+saved
   spawnParticle(toy.x,toy.y,"-$"..saved,5)
   sfx(0,40,8,0)
  end
 end
 
 -- Grab shield powerup (only one exists at a time)
 if activeShield and boxCollide(player,activeShield) then
  player.shieldTimer=SHIELD_DURATION
  spawnParticle(activeShield.x,activeShield.y,"PROTECTED!",11)
  sfx(0,72,12,0)
  sfx(0,76,12,1)
  activeShield=nil
  shieldSpawnTimer=SHIELD_SPAWN_INTERVAL -- reset timer for next spawn
 end
 
 -- Collision with shoppers
 for _,s in ipairs(shoppers) do
  if player.invuln<=0 and player.shieldTimer<=0 and s.stunned<=0 and boxCollide(player,{x=s.x,y=s.y,w=10,h=10}) then
   local dx=s.x-player.x
   local dy=s.y-player.y
   local d=math.sqrt(dx^2+dy^2)
   if d>0 then
    s.vx=dx/d*3
    s.vy=dy/d*3
    player.vx=-dx/d*2
    player.vy=-dy/d*2
   end
   
   s.stunned=60
   player.stunned=45
   player.invuln=90
   
   -- Play collision beep
   playCollisionBeep()
   
   -- AI drops 10% of items
   if #s.cart>0 then
    s.cart=spawnDroppedItems(s.x,s.y,s.cart)
    spawnParticle(s.x,s.y,"CRASH!",3)
   end
   
   -- Player drops 10% of items
   if #player.cart>0 then
    local oldCart={}
    for _,item in ipairs(player.cart) do
     table.insert(oldCart,item)
    end
    player.cart=spawnDroppedItems(player.x,player.y,oldCart)
    -- Recalculate cart value
    player.cartValue=0
    player.cartSavings=0
    for _,item in ipairs(player.cart) do
     player.cartValue=player.cartValue+item.price
     player.cartSavings=player.cartSavings+math.floor(item.price*item.discount/100)
    end
    spawnParticle(player.x,player.y,"OUCH!",2)
   end
  elseif player.shieldTimer>0 and s.stunned<=0 and boxCollide(player,{x=s.x,y=s.y,w=10,h=10}) then
   -- With shield, just push them away
   local dx=s.x-player.x
   local dy=s.y-player.y
   local d=math.sqrt(dx^2+dy^2)
   if d>0 then
    s.vx=dx/d*4
    s.vy=dy/d*4
    s.stunned=30
   end
   spawnParticle(s.x,s.y,"BLOCKED!",11)
   sfx(0,60,4,0)
  end
 end
 
 -- Auto checkout
 if checkoutOpen and #player.cart>0 then
  local checkArea={x=checkout.x-4,y=checkout.y-4,w=checkout.w+8,h=checkout.h+8}
  if boxCollide(player,checkArea) then
   state=STATE_CHECKOUT
   calculateScore()
   local cfg=levels[level]
   if player.finalScore>=cfg.target then
    playVictoryJingle()
   else
    playSadJingle()
   end
  end
 end
end

function updateShoppers()
 local secs=math.ceil(timer/60)
 local timeAlmostUp=secs<=CHECKOUT_WARNING_TIME
 local ai=aiConfig[level]
 
 for _,s in ipairs(shoppers) do
  local oldX,oldY=s.x,s.y
  
  if s.stunned>0 then
   s.stunned=s.stunned-1
   s.vx=s.vx*0.85
   s.vy=s.vy*0.85
  else
   local maxSpeed=ai.maxSpeed*s.baseSpeed*2
   local accel=ai.accel
   
   if timeAlmostUp and #s.cart>0 then
    s.rushingToCheckout=true
   end
   
   if s.rushingToCheckout and checkoutOpen then
    local dx=checkout.x-s.x
    local dy=checkout.y-s.y
    local d=math.sqrt(dx^2+dy^2)
    if d>4 then
     s.vx=s.vx+(dx/d*accel)
     s.vy=s.vy+(dy/d*accel)
     if dx>0 then s.dir=1 else s.dir=-1 end
    else
     s.cart={}
     s.rushingToCheckout=false
    end
   else
    s.retargetTimer=s.retargetTimer-1
    
    local shouldWander=math.random()<ai.wanderChance
    
    if shouldWander or s.retargetTimer<=0 then
     if shouldWander then
      s.wanderAngle=s.wanderAngle+(math.random()-0.5)*1.5
      s.target=nil
     else
      s.target=findNearestToy(s.x,s.y)
     end
     s.retargetTimer=ai.retargetTime+math.random(30)
    end
    
    if s.target and not s.target.taken then
     local dx=s.target.x-s.x
     local dy=s.target.y-s.y
     local d=math.sqrt(dx^2+dy^2)
     if d>4 then
      s.vx=s.vx+(dx/d*accel)
      s.vy=s.vy+(dy/d*accel)
      if dx>0 then s.dir=1 else s.dir=-1 end
     end
    else
     s.wanderAngle=s.wanderAngle+(math.random()-0.5)*0.3
     s.vx=s.vx+math.cos(s.wanderAngle)*accel*0.5
     s.vy=s.vy+math.sin(s.wanderAngle)*accel*0.5
     if math.cos(s.wanderAngle)>0 then s.dir=1 else s.dir=-1 end
    end
   end
   
   local spd=math.sqrt(s.vx^2+s.vy^2)
   if spd>maxSpeed then
    s.vx=s.vx/spd*maxSpeed
    s.vy=s.vy/spd*maxSpeed
   end
   if spd<0.1 then
    s.vx=math.cos(s.wanderAngle)*0.15
    s.vy=math.sin(s.wanderAngle)*0.15
   end
  end
  
  s.vx=s.vx*0.94
  s.vy=s.vy*0.94
  
  s.x=s.x+s.vx
  s.y=s.y+s.vy
  
  local col,aisle=isCollidingWithAisles(s.x,s.y,s.w,s.h)
  if col then
   s.x=oldX
   s.y=oldY
   s.wanderAngle=s.wanderAngle+math.pi*0.5+math.random()*0.5
   s.vx=math.cos(s.wanderAngle)*0.3
   s.vy=math.sin(s.wanderAngle)*0.3
   s.target=nil
  end
  
  if s.x<8 then s.x=8; s.vx=math.abs(s.vx)*0.5; s.wanderAngle=math.random()*1.5-0.75; s.dir=1 end
  if s.x>storeW-18 then s.x=storeW-18; s.vx=-math.abs(s.vx)*0.5; s.wanderAngle=math.pi+math.random()*1.5-0.75; s.dir=-1 end
  if s.y<16 then s.y=16; s.vy=math.abs(s.vy)*0.5; s.wanderAngle=math.pi*0.5+math.random()*1.5-0.75 end
  if s.y>storeH-18 then s.y=storeH-18; s.vy=-math.abs(s.vy)*0.5; s.wanderAngle=-math.pi*0.5+math.random()*1.5-0.75 end
  
  if s.stunned<=0 and not s.rushingToCheckout then
   for _,toy in ipairs(toys) do
    if not toy.taken and boxCollide({x=s.x,y=s.y,w=10,h=10},toy) then
     toy.taken=true
     toy.respawn=600
     table.insert(s.cart,toy.type)
     s.target=nil
     sfx(0,35,6,0)
    end
   end
  end
 end
end

function updateToys()
 for _,toy in ipairs(toys) do
  if toy.taken and toy.respawn>0 then
   toy.respawn=toy.respawn-1
   if toy.respawn<=0 then
    toy.type=toyTypes[math.random(#toyTypes)]
    toy.taken=false
    toy.flash=30
   end
  end
  if toy.flash>0 then toy.flash=toy.flash-1 end
 end

 -- Shield spawning logic: only 1 shield at a time, spawns every 30 seconds
 if activeShield==nil then
  shieldSpawnTimer=shieldSpawnTimer-1
  if shieldSpawnTimer<=0 then
   -- Spawn a new shield
   local px,py=findValidSpawn()
   activeShield={
    x=px,y=py,
    w=14,h=14,
    lifetime=SHIELD_PICKUP_LIFETIME
   }
   shieldSpawnTimer=SHIELD_SPAWN_INTERVAL
   spawnParticle(px,py,"SHIELD!",11)
   sfx(0,65,10,0)
  end
 else
  -- Shield exists, count down its lifetime
  activeShield.lifetime=activeShield.lifetime-1
  if activeShield.lifetime<=0 then
   -- Shield disappears
   spawnParticle(activeShield.x,activeShield.y,"GONE!",14)
   activeShield=nil
   shieldSpawnTimer=SHIELD_SPAWN_INTERVAL
  end
 end
end

function calculateScore()
 local baseScore=player.cartValue
 local savings=player.cartSavings
 local comboBonus=0
 
 local names={}
 for _,t in ipairs(player.cart) do
  names[t.name]=true
 end
 for _,t in ipairs(player.cart) do
  if t.combo and names[t.combo] then
   comboBonus=comboBonus+25
  end
 end
 
 player.finalScore=baseScore+savings+comboBonus
 player.comboBonus=comboBonus
end

function updateCamera()
 local targetX=player.x-120+player.w/2
 local targetY=player.y-68+player.h/2
 camX=camX+(targetX-camX)*0.1
 camY=camY+(targetY-camY)*0.1
 camX=math.max(0,math.min(storeW-240,camX))
 camY=math.max(0,math.min(storeH-136,camY))
end

function drawStore()
 for y=0,storeH,8 do
  for x=0,storeW,8 do
   local c=((x+y)/8)%2==0 and 13 or 12
   rect(x-camX,y-camY,8,8,c)
  end
 end
 
 rect(0-camX,0-camY,storeW,12,8)
 rect(0-camX,0-camY,8,storeH,8)
 rect(storeW-8-camX,0-camY,8,storeH,8)
 
 for i,a in ipairs(aisles) do
  rect(a.x-camX,a.y-camY,a.w,a.h,15)
  rect(a.x-camX,a.y-camY,a.w,3,14)
  if aisleProducts[i] then
   for _,prod in ipairs(aisleProducts[i]) do
    rect(prod.x-camX,a.y+3-camY,6,6,prod.color)
   end
  end
 end
 
 local cfg=levels[level]
 print(cfg.name,storeW/2-#cfg.name*3-camX,2-camY,12)
 
 if checkoutOpen then
  -- Flashing checkout when open
  local col=t%30<15 and 6 or 5
  rect(checkout.x-camX,checkout.y-camY,checkout.w,checkout.h,col)
  print("EXIT",checkout.x+2-camX,checkout.y+4-camY,12)
 else
  rect(checkout.x-camX,checkout.y-camY,checkout.w,checkout.h,2)
  print("CLOSED",checkout.x-2-camX,checkout.y+4-camY,12)
 end
end

function drawToys()
 for _,toy in ipairs(toys) do
  if not toy.taken then
   local blink=toy.flash>0 and toy.flash%6<3
   local x=toy.x-camX
   local y=toy.y-camY
   elli(x+7,y+16,6,2,0)
   rect(x,y,14,14,blink and 12 or 4)
   rect(x+1,y+1,12,12,blink and 4 or 15)
   drawToyIcon(x,y,toy.type.icon)
   local disc=toy.type.discount
   rect(x-2,y-8,20,7,disc>=40 and 2 or 3)
   print("-"..disc.."%",x,y-7,12)
   print("$"..toy.type.price,x,y+16,12)
  end
 end
 
 -- Draw active shield powerup (only one at a time)
 if activeShield then
  local x=activeShield.x-camX
  local y=activeShield.y-camY

  -- Flashing when about to expire (last 3 seconds)
  if activeShield.lifetime<180 and t%10<5 then
   -- skip drawing for flash effect
  else
   -- Glowing effect
   local pulse=math.sin(t*0.15)*2
   circ(x+7,y+7,10+pulse,11)
   circ(x+7,y+7,8+pulse,10)
   -- Box
   rect(x,y,14,14,11)
   rect(x+1,y+1,12,12,10)
   -- Shield icon
   drawShieldIcon(x,y)
   -- Label with countdown
   local secsLeft=math.ceil(activeShield.lifetime/60)
   print("SHIELD "..secsLeft.."s",x-8,y-8,11)
  end
 end
end

function drawShoppers()
 for _,s in ipairs(shoppers) do
  local x=s.x-camX
  local y=s.y-camY
  drawShopper(x-4,y-6,s.color,s.stunned>0,#s.cart,s.dir,false,0,false)
  
  if s.rushingToCheckout and s.stunned<=0 then
   print("!",x+12,y-10,2)
  end
 end
end

function drawPlayer()
 local x=player.x-camX
 local y=player.y-camY
 drawShopper(x-4,y-6,6,player.stunned>0,#player.cart,player.dir,true,player.invuln,player.shieldTimer>0)
 
 if btn(4) and player.stunned<=0 then
  for i=1,3 do
   local px=x-player.vx*i*2+math.random(-2,2)
   local py=y-player.vy*i*2+math.random(-2,2)
   pix(px,py+6,13)
  end
 end
end

function drawHUD()
 rect(0,0,240,14,0)
 
 local secs=math.ceil(timer/60)
 local tcol=12
 if secs<=CHECKOUT_WARNING_TIME then
  tcol=t%20<10 and 2 or 4
 end
 print("TIME:"..secs,4,2,tcol)
 
 print("CART:"..#player.cart,55,2,12)
 print("$"..player.cartValue,100,2,5)
 
 local cfg=levels[level]
 print("TARGET:$"..cfg.target,140,2,player.cartValue>=cfg.target and 5 or 4)
 
 print("LV"..level,220,2,11)
 
 -- Shield timer bar
 if player.shieldTimer>0 then
  local barW=math.floor((player.shieldTimer/SHIELD_DURATION)*50)
  rect(4,126,52,6,0)
  rect(5,127,barW,4,11)
  print("SHIELD",6,128,0)
 end
 
 if checkoutOpen then
  if #player.cart>0 then
   print("GO TO CHECKOUT!",80,125,t%10<5 and 5 or 6)
  else
   print("CHECKOUT OPEN!",85,125,6)
  end
 end
end

function drawSplash()
 cls(0)

 -- Draw infinite aisle background scrolling down
 local scrollY=(t*2)%16

 -- Draw store floor tiles (scrolling to create running effect)
 for y=-16,150,16 do
  for x=40,200,16 do
   local tileY=y+scrollY
   local c=((x+y)/16)%2==0 and 13 or 12
   rect(x,tileY,16,16,c)
  end
 end

 -- Draw aisle shelves on left and right
 for y=-20,150,40 do
  local shelfY=y+scrollY*2.5
  if shelfY>-40 and shelfY<150 then
   -- Left shelf
   rect(10,shelfY,30,35,15)
   rect(12,shelfY+2,26,8,2)
   rect(12,shelfY+12,26,8,5)
   rect(12,shelfY+22,26,8,9)
   -- Right shelf
   rect(200,shelfY,30,35,15)
   rect(202,shelfY+2,26,8,4)
   rect(202,shelfY+12,26,8,6)
   rect(202,shelfY+22,26,8,3)
  end
 end

 -- Draw floating toys being collected (moving up toward player)
 for i=1,5 do
  local toyY=130-((t*3+i*50)%180)
  local toyX=80+math.sin(t*0.05+i)*40
  if toyY>20 and toyY<120 then
   -- Toy box
   rect(toyX,toyY,14,14,4)
   rect(toyX+1,toyY+1,12,12,15)
   drawToyIcon(toyX,toyY,(i%10)+1)
   -- Sparkle effect
   if t%20<10 then
    pix(toyX-2,toyY-2,4)
    pix(toyX+16,toyY-2,4)
   end
  end
 end

 -- Draw the running player at center
 local playerBob=math.sin(t*0.4)*2
 local legAnim=math.sin(t*0.5)*3

 -- Shadow
 elli(120,105+playerBob,12,4,0)

 -- Running guy (larger scale for splash)
 -- Legs (animated)
 rect(112,90+playerBob+legAnim,4,12,9)
 rect(120,90+playerBob-legAnim,4,12,9)

 -- Body
 rect(110,75+playerBob,16,18,6)

 -- Arms (pumping)
 local armAnim=math.sin(t*0.5)*4
 line(110,80+playerBob,105,85+playerBob+armAnim,6)
 line(126,80+playerBob,131,85+playerBob-armAnim,6)

 -- Head
 circ(118,68+playerBob,8,3)

 -- Happy face
 pix(115,66+playerBob,0)
 pix(121,66+playerBob,0)
 line(114,71+playerBob,122,71+playerBob,0)

 -- Hair/cap
 rect(110,60+playerBob,16,5,4)

 -- Cart being pushed (bouncing)
 local cartX=128
 local cartY=82+playerBob
 rect(cartX,cartY,16,12,13)
 rect(cartX+1,cartY+1,14,10,7)
 circ(cartX+3,cartY+14,2,15)
 circ(cartX+13,cartY+14,2,15)
 -- Items in cart
 rect(cartX+2,cartY+2,5,4,2)
 rect(cartX+8,cartY+2,5,4,5)
 rect(cartX+4,cartY-2,6,4,4)

 -- Draw Logo
 local logoY=15+math.sin(t*0.08)*3

 -- "CRACK FRIDAY!" title with shadow
 print("CRACK FRIDAY!",52,logoY+2,0)
 print("CRACK FRIDAY!",50,logoY,2)
 print("CRACK FRIDAY!",51,logoY,4)

 -- "By Ruben Tipparach" subtitle
 print("By Ruben Tipparach",65,logoY+16,13)

 -- Flashing "Press Z" at bottom
 if t%40<25 then
  print("PRESS Z",100,125,12)
 end

 -- Transition after delay or button press
 splashTimer=splashTimer+1
 if btnp(4) or splashTimer>300 then
  state=STATE_TITLE
  splashTimer=0
 end
end

function drawTitle()
 cls(0)

 for i=0,30 do
  local c=t%20<10 and 2 or 4
  if i%2==0 then c=t%20<10 and 4 or 2 end
  rect(i*8,0,8,4,c)
  rect(i*8,132,8,4,c)
 end

 local titleY=30+math.sin(t*0.05)*3
 print("CRACK FRIDAY!",60,titleY,0)
 print("CRACK FRIDAY!",59,titleY-1,2)

 drawShopper(100,55,6,false,3,1,true,0,false)

 print("GRAB DEALS! AVOID COLLISIONS!",35,95,12)
 print("ARROWS:Move Z:Sprint",50,105,13)
 print("GET SHIELDS FOR PROTECTION!",42,115,11)

 print("PRESS Z TO START",72,125,t%30<15 and 12 or 6)

 if btnp(4) then
  state=STATE_PLAY
  level=1
  totalScore=0
  resetLevel()
 end
end

function drawCheckout()
 cls(0)
 
 local cfg=levels[level]
 local metTarget=player.finalScore>=cfg.target
 
 if metTarget then
  print("=== SUCCESS! ===",72,10,5)
 else
  print("=== CHECKOUT ===",72,10,4)
 end
 
 local y=30
 print("Items grabbed: "..#player.cart,60,y,12)
 y=y+12
 print("Original value: $"..player.cartValue,60,y,13)
 y=y+10
 print("You saved: $"..player.cartSavings,60,y,5)
 y=y+10
 if player.comboBonus>0 then
  print("Combo bonus: $"..player.comboBonus,60,y,11)
  y=y+10
 end
 
 y=y+10
 print("SCORE: "..player.finalScore,80,y,metTarget and 5 or 4)
 print("TARGET: "..cfg.target,80,y+10,metTarget and 5 or 2)
 
 totalScore=totalScore+player.finalScore
 
 y=y+30
 if level<3 then
  if metTarget then
   print("Great job! Press Z for next store!",40,y,12)
  else
   print("Try harder! Press Z to continue",45,y,12)
  end
  if btnp(4) then
   level=level+1
   state=STATE_PLAY
   resetLevel()
  end
 else
  print("TOTAL SCORE: "..totalScore,70,y,5)
  if metTarget then
   print("SHOPPING CHAMPION!",70,y+12,5)
  end
  print("Press Z to play again",60,y+24,12)
  if btnp(4) then
   state=STATE_TITLE
  end
 end
end

function drawGameOver()
 cls(0)
 
 print("TIME'S UP!",88,40,2)
 print("The store is closing!",68,55,13)
 
 if #player.cart>0 then
  print("You couldn't check out in time!",50,75,14)
 else
  print("You didn't grab anything!",58,75,14)
 end
 
 print("Final Score: "..totalScore,75,95,4)
 print("Press Z to try again",64,115,12)
 
 if btnp(4) then
  state=STATE_TITLE
 end
end

function TIC()
 t=t+1

 if state==STATE_SPLASH then
  drawSplash()
 elseif state==STATE_TITLE then
  drawTitle()
 elseif state==STATE_PLAY then
  timer=timer-1
  
  local secs=math.ceil(timer/60)
  if secs<=CHECKOUT_WARNING_TIME and not checkoutOpen then
   checkoutOpen=true
   sfx(2,60,20,0)
  end
  
  -- Checkout beeping
  if checkoutOpen then
   checkoutBeepTimer=checkoutBeepTimer+1
   if checkoutBeepTimer%45==0 then -- beep every 0.75 seconds
    playCheckoutBeep()
   end
  end
  
  if timer<=0 then
   state=STATE_GAMEOVER
   playSadJingle()
  end
  
  updatePlayer()
  updateShoppers()
  updateToys()
  updateDroppedItems()
  updateParticles()
  updateCamera()
  
  cls(0)
  drawStore()
  drawToys()
  drawDroppedItems()
  drawShoppers()
  drawPlayer()
  drawParticles()
  drawHUD()
  
 elseif state==STATE_CHECKOUT then
  drawCheckout()
 elseif state==STATE_GAMEOVER then
  drawGameOver()
 end
end
