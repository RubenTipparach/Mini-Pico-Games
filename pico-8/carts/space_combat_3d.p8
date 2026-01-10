pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 3d space combat
-- flat shaded ships

-- game state
gstate="title"
score=0
health=100
wave=1
spawn_t=60

-- player
px,py,pz=0,0,0
prx,pry,prz=0,0,0
pspeed=0
pfire=0

-- camera
cx,cy,cz=0,3,-20
crx,cry,crz=0,0,0

-- controls
roll_mode=false
throttle=0
mx,my,mb,mp=64,64,false,false

-- tables
stars={}
enemies={}
bullets={}
parts={}
expls={}

-- ship verts/faces
ship_v={
 {0,0,8},{-3,1,-4},{3,1,-4},
 {-3,-1,-4},{3,-1,-4},{0,0,-6},
 {-8,0,-2},{-3,0,0},{-3,0,-3},
 {8,0,-2},{3,0,0},{3,0,-3},
 {0,1.5,2}
}
ship_f={
 {1,3,2,12},{2,3,6,5},
 {1,4,5,1},{4,6,5,1},
 {1,2,4,13},{1,5,3,13},
 {7,8,9,11},{10,12,11,11},
 {1,13,2,8},{1,3,13,8},
 {2,6,4,8},{3,5,6,8}
}

enemy_v={
 {0,0,6},{-4,0,-4},{4,0,-4},
 {0,2,-2},{0,-2,-2},{0,0,-5},
 {-6,0,0},{6,0,0}
}
enemy_f={
 {1,4,2,8},{1,3,4,8},
 {4,3,6,5},{4,6,2,5},
 {1,2,5,2},{1,5,3,2},
 {5,6,3,1},{5,2,6,1},
 {7,2,1,9},{8,1,3,9}
}

-- 3d math
function v_sub(a,b)
 return {a[1]-b[1],a[2]-b[2],a[3]-b[3]}
end

function v_cross(a,b)
 return {
  a[2]*b[3]-a[3]*b[2],
  a[3]*b[1]-a[1]*b[3],
  a[1]*b[2]-a[2]*b[1]
 }
end

function v_dot(a,b)
 return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end

function v_len(v)
 return sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
end

function v_norm(v)
 local l=v_len(v)
 if l==0 then return {0,0,1} end
 return {v[1]/l,v[2]/l,v[3]/l}
end

function rotx(x,y,z,a)
 local c,s=cos(a),sin(a)
 return x,y*c-z*s,y*s+z*c
end

function roty(x,y,z,a)
 local c,s=cos(a),sin(a)
 return x*c+z*s,y,-x*s+z*c
end

function rotz(x,y,z,a)
 local c,s=cos(a),sin(a)
 return x*c-y*s,x*s+y*c,z
end

function rot3d(x,y,z,rx,ry,rz)
 x,y,z=rotx(x,y,z,rx)
 x,y,z=roty(x,y,z,ry)
 x,y,z=rotz(x,y,z,rz)
 return x,y,z
end

function proj(x,y,z)
 if z<1 then z=1 end
 return 64+x*90/z,64-y*90/z,z
end

function _init()
 poke(0x5f2d,1)
 for i=1,80 do
  add(stars,{
   rnd(256)-128,
   rnd(256)-128,
   rnd(200)+50
  })
 end
end

function _update60()
 mp=mb
 mx=stat(32)
 my=stat(33)
 mb=stat(34)>0

 if gstate=="title" then
  if btnp(4) or btnp(5) then
   start_game()
  end
 elseif gstate=="play" then
  update_play()
 elseif gstate=="dead" then
  if btnp(4) or btnp(5) then
   gstate="title"
  end
 end
end

function start_game()
 gstate="play"
 px,py,pz=0,0,0
 prx,pry,prz=0,0,0
 pspeed=0
 pfire=0
 throttle=0
 score=0
 health=100
 wave=1
 spawn_t=60
 enemies={}
 bullets={}
 parts={}
 expls={}
end

function update_play()
 local ts=0.015

 -- pitch
 if btn(2) then prx-=ts end
 if btn(3) then prx+=ts end

 -- yaw or roll
 if roll_mode then
  if btn(0) then prz+=ts end
  if btn(1) then prz-=ts end
 else
  if btn(0) then pry+=ts end
  if btn(1) then pry-=ts end
 end

 -- throttle
 if btn(5) then
  throttle=min(throttle+0.02,1)
 end
 pspeed+=(throttle*1.5-pspeed)*0.05

 -- fire
 pfire=max(0,pfire-1)
 if btn(4) and pfire==0 then
  fire_bullet(px,py,pz,prx,pry,prz,true)
  pfire=8
  sfx(0)
 end

 -- move player
 local fx,fy,fz=rot3d(0,0,1,prx,pry,prz)
 px+=fx*pspeed
 py+=fy*pspeed
 pz+=fz*pspeed

 -- camera follow
 local ox,oy,oz=rot3d(0,3,-18,prx,pry,prz)
 cx=px+ox
 cy=py+oy
 cz=pz+oz
 crx,cry,crz=prx,pry,prz

 -- ui clicks
 update_ui()

 -- enemies
 update_enemies()

 -- bullets
 update_bullets()

 -- particles
 for p in all(parts) do
  p[1]+=p[4]
  p[2]+=p[5]
  p[3]+=p[6]
  p[7]-=1
  if p[7]<=0 then del(parts,p) end
 end

 -- explosions
 for e in all(expls) do
  if e[5] then
   e[4]+=1
   if e[4]>=e[6] then e[5]=false end
  else
   e[4]-=0.5
   if e[4]<=0 then del(expls,e) end
  end
 end

 -- spawn
 spawn_t-=1
 if spawn_t<=0 and #enemies<5+wave then
  spawn_enemy()
  spawn_t=90-min(wave*5,50)
 end

 -- death
 if health<=0 then
  gstate="dead"
  add_expl(px,py,pz,20)
 end
end

function update_ui()
 -- throttle slider 115-123, 25-85
 if mb then
  if mx>=110 and mx<=126 and my>=20 and my<=90 then
   local y=mid(25,my,85)
   throttle=1-(y-25)/60
  end
 end

 -- roll toggle 5-38, 92-105
 if mb and not mp then
  if mx>=5 and mx<=38 and my>=92 and my<=105 then
   roll_mode=not roll_mode
  end
 end
end

function spawn_enemy()
 add(enemies,{
  x=rnd(100)-50+px,
  y=rnd(60)-30+py,
  z=rnd(100)+80+pz,
  rx=0,ry=0.5,rz=0,
  hp=20,
  fire=rnd(60)+30,
  ai=rnd(30)
 })
end

function update_enemies()
 for e in all(enemies) do
  e.ai-=1
  if e.ai<=0 then
   local dx=px-e.x
   local dy=py-e.y
   local dz=pz-e.z
   local d=sqrt(dx*dx+dy*dy+dz*dz)
   if d>0 then
    e.ry=atan2(dx,dz)
    e.rx=-atan2(dy,sqrt(dx*dx+dz*dz))*0.5
   end
   e.ai=20+rnd(30)
  end

  local fx,fy,fz=rot3d(0,0,1,e.rx,e.ry,e.rz)
  e.x+=fx*0.5
  e.y+=fy*0.5
  e.z+=fz*0.5

  e.fire-=1
  if e.fire<=0 then
   local dx=px-e.x
   local dy=py-e.y
   local dz=pz-e.z
   if dx*dx+dy*dy+dz*dz<22500 then
    fire_bullet(e.x,e.y,e.z,e.rx,e.ry,e.rz,false)
    e.fire=40
    sfx(1)
   else
    e.fire=10
   end
  end

  local dx=e.x-px
  local dy=e.y-py
  local dz=e.z-pz
  if dx*dx+dy*dy+dz*dz>40000 then
   del(enemies,e)
  end
 end
end

function fire_bullet(x,y,z,rx,ry,rz,plr)
 local fx,fy,fz=rot3d(0,0,1,rx,ry,rz)
 local spd=plr and 3 or 1.5
 add(bullets,{
  x=x+fx*5,y=y+fy*5,z=z+fz*5,
  vx=fx*spd,vy=fy*spd,vz=fz*spd,
  plr=plr,life=120
 })
end

function update_bullets()
 for b in all(bullets) do
  b.x+=b.vx
  b.y+=b.vy
  b.z+=b.vz
  b.life-=1

  if b.life<=0 then
   del(bullets,b)
  elseif b.plr then
   for e in all(enemies) do
    local dx=b.x-e.x
    local dy=b.y-e.y
    local dz=b.z-e.z
    if dx*dx+dy*dy+dz*dz<64 then
     e.hp-=10
     add_parts(b.x,b.y,b.z,5,9)
     del(bullets,b)
     sfx(2)
     if e.hp<=0 then
      add_expl(e.x,e.y,e.z,15)
      score+=100
      del(enemies,e)
      sfx(3)
      if #enemies==0 then wave+=1 end
     end
     break
    end
   end
  else
   local dx=b.x-px
   local dy=b.y-py
   local dz=b.z-pz
   if dx*dx+dy*dy+dz*dz<36 then
    health-=10
    add_parts(px,py,pz,8,8)
    del(bullets,b)
    sfx(2)
   end
  end
 end
end

function add_parts(x,y,z,n,c)
 for i=1,n do
  add(parts,{x,y,z,rnd(2)-1,rnd(2)-1,rnd(2)-1,20+rnd(20),c})
 end
end

function add_expl(x,y,z,sz)
 add(expls,{x,y,z,0,true,sz})
 add_parts(x,y,z,sz,10)
 add_parts(x,y,z,sz,9)
end

function _draw()
 cls(0)

 if gstate=="title" then
  draw_title()
 elseif gstate=="play" then
  draw_play()
 elseif gstate=="dead" then
  draw_play()
  draw_dead()
 end
end

function draw_title()
 -- stars
 for s in all(stars) do
  if s[3]>1 then
   local sx=64+s[1]*60/s[3]
   local sy=64-s[2]*60/s[3]
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    pset(sx,sy,7)
   end
  end
 end

 rectfill(20,28,108,48,1)
 print("space combat 3d",28,32,11)
 print("---------------",28,40,5)

 print("arrows: pitch/yaw",23,56,6)
 print("x: thrust",43,64,6)
 print("z: fire",47,72,6)

 print("press z or x",34,100,10)
end

function draw_play()
 draw_stars()

 local faces={}
 add_ship(faces,px,py,pz,prx,pry,prz,ship_v,ship_f)

 for e in all(enemies) do
  add_ship(faces,e.x,e.y,e.z,e.rx,e.ry,e.rz,enemy_v,enemy_f)
 end

 sort_faces(faces)

 for f in all(faces) do
  trifill(f[1],f[2],f[3],f[4],f[5],f[6],f[7])
 end

 draw_bullets_()
 draw_parts()
 draw_expls()
 draw_hud()
end

function draw_stars()
 for s in all(stars) do
  local rx=s[1]-cx
  local ry=s[2]-cy
  local rz=s[3]-cz

  while rz<0 do rz+=200 end
  while rz>200 do rz-=200 end
  while rx<-128 do rx+=256 end
  while rx>128 do rx-=256 end
  while ry<-128 do ry+=256 end
  while ry>128 do ry-=256 end

  rx,ry,rz=rot3d(rx,ry,rz,-crx,-cry,-crz)

  if rz>1 then
   local sx,sy=proj(rx,ry,rz)
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    pset(sx,sy,rz<50 and 7 or 6)
   end
  end
 end
end

function add_ship(faces,sx,sy,sz,rx,ry,rz,verts,fcs)
 local tv={}
 for i,v in pairs(verts) do
  local x,y,z=rot3d(v[1],v[2],v[3],rx,ry,rz)
  x+=sx-cx
  y+=sy-cy
  z+=sz-cz
  x,y,z=rot3d(x,y,z,-crx,-cry,-crz)
  tv[i]={x,y,z}
 end

 for f in all(fcs) do
  local v1=tv[f[1]]
  local v2=tv[f[2]]
  local v3=tv[f[3]]

  if v1[3]>1 and v2[3]>1 and v3[3]>1 then
   local e1=v_sub(v2,v1)
   local e2=v_sub(v3,v1)
   local n=v_norm(v_cross(e1,e2))

   local ctr={(v1[1]+v2[1]+v3[1])/3,(v1[2]+v2[2]+v3[2])/3,(v1[3]+v2[3]+v3[3])/3}

   if v_dot(n,v_norm(ctr))<0 then
    local p1x,p1y=proj(v1[1],v1[2],v1[3])
    local p2x,p2y=proj(v2[1],v2[2],v2[3])
    local p3x,p3y=proj(v3[1],v3[2],v3[3])

    local sun=v_norm({0.5,0.7,-0.5})
    local light=(v_dot(n,sun)+1)/2
    local col=shade(f[4],light)

    add(faces,{p1x,p1y,p2x,p2y,p3x,p3y,col,ctr[3]})
   end
  end
 end
end

function shade(c,l)
 local r={
  [1]={0,0,1},[2]={0,1,2},[5]={1,5,6},
  [6]={5,6,7},[8]={2,8,14},[9]={4,9,10},
  [11]={3,11,11},[12]={1,12,12},[13]={5,13,6}
 }
 local ramp=r[c] or {c,c,c}
 return ramp[min(flr(l*2.99)+1,3)]
end

function sort_faces(f)
 for i=2,#f do
  local j=i
  while j>1 and f[j][8]>f[j-1][8] do
   f[j],f[j-1]=f[j-1],f[j]
   j-=1
  end
 end
end

function trifill(x1,y1,x2,y2,x3,y3,c)
 if y1>y2 then x1,y1,x2,y2=x2,y2,x1,y1 end
 if y1>y3 then x1,y1,x3,y3=x3,y3,x1,y1 end
 if y2>y3 then x2,y2,x3,y3=x3,y3,x2,y2 end

 if y3==y1 then return end

 local d1=(x3-x1)/(y3-y1)

 if y2~=y1 then
  local d2=(x2-x1)/(y2-y1)
  for y=y1,y2 do
   local a=x1+(y-y1)*d1
   local b=x1+(y-y1)*d2
   if a>b then a,b=b,a end
   rectfill(a,y,b,y,c)
  end
 end

 if y3~=y2 then
  local d2=(x3-x2)/(y3-y2)
  for y=y2,y3 do
   local a=x1+(y-y1)*d1
   local b=x2+(y-y2)*d2
   if a>b then a,b=b,a end
   rectfill(a,y,b,y,c)
  end
 end
end

function draw_bullets_()
 for b in all(bullets) do
  local rx=b.x-cx
  local ry=b.y-cy
  local rz=b.z-cz
  rx,ry,rz=rot3d(rx,ry,rz,-crx,-cry,-crz)
  if rz>1 then
   local sx,sy=proj(rx,ry,rz)
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    circfill(sx,sy,max(1,4/rz),b.plr and 11 or 8)
   end
  end
 end
end

function draw_parts()
 for p in all(parts) do
  local rx=p[1]-cx
  local ry=p[2]-cy
  local rz=p[3]-cz
  rx,ry,rz=rot3d(rx,ry,rz,-crx,-cry,-crz)
  if rz>1 then
   local sx,sy=proj(rx,ry,rz)
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    pset(sx,sy,p[8])
   end
  end
 end
end

function draw_expls()
 for e in all(expls) do
  local rx=e[1]-cx
  local ry=e[2]-cy
  local rz=e[3]-cz
  rx,ry,rz=rot3d(rx,ry,rz,-crx,-cry,-crz)
  if rz>1 then
   local sx,sy=proj(rx,ry,rz)
   local sz=e[4]*5/rz
   circfill(sx,sy,sz,10)
   circfill(sx,sy,sz*0.7,9)
   circfill(sx,sy,sz*0.4,8)
  end
 end
end

function draw_hud()
 -- health
 rectfill(4,4,34,8,0)
 rectfill(5,5,5+health*0.28,7,health>30 and 11 or 8)
 rect(4,4,34,8,7)
 print("hull",5,10,7)

 -- score/wave
 print("score:"..score,60,5,7)
 print("wave:"..wave,90,115,6)

 -- reticle
 circ(64,64,10,3)
 line(64,50,64,58,3)
 line(64,70,64,78,3)
 line(50,64,58,64,3)
 line(70,64,78,64,3)

 -- throttle
 rectfill(116,25,120,85,1)
 rect(115,24,121,86,5)
 local fy=85-throttle*60
 rectfill(116,fy,120,85,11)
 rectfill(113,fy-2,123,fy+2,7)
 print("thr",111,88,5)

 -- roll/yaw toggle
 local bc=roll_mode and 8 or 12
 rectfill(5,92,38,105,bc)
 rect(5,92,38,105,7)
 print(roll_mode and "roll" or "yaw",14,96,0)

 -- mouse
 pset(mx,my,7)
end

function draw_dead()
 rectfill(24,50,104,78,0)
 rect(24,50,104,78,8)
 print("game over",42,55,8)
 print("score:"..score,40,65,7)
 print("press z/x",42,85,6)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001903020030270302e03033030350303500033000300002c0002700022000190001100009000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001d0301b03019030170301503013030110300f0300d0300b03009030070300503003030010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000c5300a5200850006500045000250001500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050
001000002c0502a0502605022040210401e0401b04017040130400f0400c0400904006040030400104000040000400004000040000400004000040000400004000040000400004000040000400004000040000400000
