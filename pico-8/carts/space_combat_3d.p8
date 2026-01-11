pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 3d space combat
-- flat shaded ships

-- game state
gstate="title"
score=0
health=100
shield=100
shield_max=100
shield_recharge=0
hit_flash=0
wave=1
spawn_t=60
wave_enemies=0

-- player position
px,py,pz=0,0,0
pspeed=0
pfire=0

-- player orientation (local axes)
p_fwd={0,0,1}   -- forward vector
p_rgt={1,0,0}   -- right vector
p_up={0,1,0}    -- up vector

-- camera
cx,cy,cz=0,3,-20
c_fwd={0,0,1}
c_rgt={1,0,0}
c_up={0,1,0}

-- controls
roll_mode=false
throttle=0
mx,my,mb,mp=64,64,false,false

-- targeting
target=nil
last_b_tap=0
tap_window=15

-- tables
stars={}
enemies={}
bullets={}
parts={}
expls={}
dust={}

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

-- heavy enemy (slower, tougher)
heavy_v={
 {0,0,8},{-5,0,-5},{5,0,-5},
 {0,3,0},{0,-3,0},{0,0,-7},
 {-7,0,-2},{7,0,-2},{-3,2,-3},{3,2,-3}
}
heavy_f={
 {1,4,2,9},{1,3,4,9},
 {4,3,6,5},{4,6,2,5},
 {1,2,5,2},{1,5,3,2},
 {5,6,3,1},{5,2,6,1},
 {7,2,1,8},{8,1,3,8},
 {9,4,1,11},{10,1,4,11}
}

-- fast enemy (agile, weak)
fast_v={
 {0,0,5},{-3,0,-3},{3,0,-3},
 {0,1,-1},{0,-1,-1},{0,0,-4}
}
fast_f={
 {1,4,2,11},{1,3,4,11},
 {4,3,6,3},{4,6,2,3},
 {1,2,5,2},{1,5,3,2},
 {5,6,3,1},{5,2,6,1}
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

-- rotate vector v around axis by angle a
function rot_axis(v,axis,a)
 local c,s=cos(a),sin(a)
 local ax,ay,az=axis[1],axis[2],axis[3]
 local vx,vy,vz=v[1],v[2],v[3]

 -- rodrigues rotation formula
 local dot=ax*vx+ay*vy+az*vz
 local cx=ay*vz-az*vy
 local cy=az*vx-ax*vz
 local cz=ax*vy-ay*vx

 return {
  vx*c+cx*s+ax*dot*(1-c),
  vy*c+cy*s+ay*dot*(1-c),
  vz*c+cz*s+az*dot*(1-c)
 }
end

-- re-orthonormalize vectors (gram-schmidt)
function orthonorm()
 -- normalize forward
 local l=sqrt(p_fwd[1]^2+p_fwd[2]^2+p_fwd[3]^2)
 p_fwd[1]/=l p_fwd[2]/=l p_fwd[3]/=l

 -- right = right - (right.fwd)*fwd
 local d=p_rgt[1]*p_fwd[1]+p_rgt[2]*p_fwd[2]+p_rgt[3]*p_fwd[3]
 p_rgt[1]-=d*p_fwd[1]
 p_rgt[2]-=d*p_fwd[2]
 p_rgt[3]-=d*p_fwd[3]
 l=sqrt(p_rgt[1]^2+p_rgt[2]^2+p_rgt[3]^2)
 p_rgt[1]/=l p_rgt[2]/=l p_rgt[3]/=l

 -- up = fwd x rgt
 p_up[1]=p_fwd[2]*p_rgt[3]-p_fwd[3]*p_rgt[2]
 p_up[2]=p_fwd[3]*p_rgt[1]-p_fwd[1]*p_rgt[3]
 p_up[3]=p_fwd[1]*p_rgt[2]-p_fwd[2]*p_rgt[1]
end

-- transform point by orientation matrix (fwd,rgt,up)
function orient_point(x,y,z,fwd,rgt,up)
 return
  x*rgt[1]+y*up[1]+z*fwd[1],
  x*rgt[2]+y*up[2]+z*fwd[2],
  x*rgt[3]+y*up[3]+z*fwd[3]
end

-- transform to camera space
function to_cam_space(wx,wy,wz)
 local rx=wx-cx
 local ry=wy-cy
 local rz=wz-cz
 -- project onto camera axes
 return
  rx*c_rgt[1]+ry*c_rgt[2]+rz*c_rgt[3],
  rx*c_up[1]+ry*c_up[2]+rz*c_up[3],
  rx*c_fwd[1]+ry*c_fwd[2]+rz*c_fwd[3]
end

function proj(x,y,z)
 if z<1 then z=1 end
 return 64+x*90/z,64-y*90/z,z
end

-- celestial objects
sun_dir={0.6,0.3,0.7}
planet_pos={-500,200,800}
planet_r=80

function _init()
 poke(0x5f2d,1)
 -- stars as normalized direction vectors
 for i=1,200 do
  local x,y,z=rnd(2)-1,rnd(2)-1,rnd(2)-1
  local l=sqrt(x*x+y*y+z*z)
  if l>0.1 then
   add(stars,{x/l,y/l,z/l})
  end
 end
 -- normalize sun direction
 local l=sqrt(sun_dir[1]^2+sun_dir[2]^2+sun_dir[3]^2)
 sun_dir[1]/=l
 sun_dir[2]/=l
 sun_dir[3]/=l
end

function _update60()
 mp=mb
 mx=stat(32)
 my=stat(33)
 mb=stat(34)>0

 if gstate=="title" then
  if btnp(5) then
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
 pspeed=0
 pfire=0
 throttle=0.3
 score=0
 health=100
 shield=100
 shield_recharge=0
 hit_flash=0
 wave=1
 wave_enemies=1
 spawn_t=0
 enemies={}
 bullets={}
 parts={}
 expls={}
 dust={}
 target=nil
 last_b_tap=-99
 -- spawn dust particles around player
 for i=1,40 do
  add(dust,{
   x=rnd(60)-30,
   y=rnd(60)-30,
   z=rnd(60)-30
  })
 end
 -- reset player orientation
 p_fwd={0,0,1}
 p_rgt={1,0,0}
 p_up={0,1,0}
 -- reset camera
 cx,cy,cz=0,4,-22
 c_fwd={0,0,1}
 c_rgt={1,0,0}
 c_up={0,1,0}
 -- spawn wave 1: just 1 enemy
 spawn_enemy("normal")
 -- auto-target first enemy
 if #enemies>0 then
  target=enemies[1]
 end
end

function update_play()
 local ts=0.02

 -- check if holding B (btn 4) for alternate mode
 local alt_mode=btn(4)

 if alt_mode then
  -- alternate mode: up/down = speed, left/right = roll
  if btn(2) then
   throttle=min(throttle+0.03,1)
  end
  if btn(3) then
   throttle=max(throttle-0.03,0)
  end
  -- roll around forward axis
  if btn(0) then
   p_rgt=rot_axis(p_rgt,p_fwd,-ts)
   p_up=rot_axis(p_up,p_fwd,-ts)
  end
  if btn(1) then
   p_rgt=rot_axis(p_rgt,p_fwd,ts)
   p_up=rot_axis(p_up,p_fwd,ts)
  end
 else
  -- regular mode: pitch around right (inverted), yaw around up
  if btn(2) then
   p_fwd=rot_axis(p_fwd,p_rgt,-ts)
   p_up=rot_axis(p_up,p_rgt,-ts)
  end
  if btn(3) then
   p_fwd=rot_axis(p_fwd,p_rgt,ts)
   p_up=rot_axis(p_up,p_rgt,ts)
  end
  if btn(0) then
   p_fwd=rot_axis(p_fwd,p_up,ts)
   p_rgt=rot_axis(p_rgt,p_up,ts)
  end
  if btn(1) then
   p_fwd=rot_axis(p_fwd,p_up,-ts)
   p_rgt=rot_axis(p_rgt,p_up,-ts)
  end
 end

 -- re-orthonormalize to prevent error accumulation
 orthonorm()

 -- smooth speed
 pspeed+=(throttle*1.5-pspeed)*0.08

 -- double-tap B to cycle targets
 if btnp(4) then
  if t()-last_b_tap<0.25 then
   cycle_target()
  end
  last_b_tap=t()
 end

 -- A button (btn 5) = fire
 pfire=max(0,pfire-1)
 if btn(5) and pfire==0 then
  fire_player_bullet()
  pfire=8
  sfx(0)
 end

 -- move player along forward vector
 px+=p_fwd[1]*pspeed
 py+=p_fwd[2]*pspeed
 pz+=p_fwd[3]*pspeed

 -- camera follows behind player
 local cam_dist=22
 local cam_up=4
 local tcx=px-p_fwd[1]*cam_dist+p_up[1]*cam_up
 local tcy=py-p_fwd[2]*cam_dist+p_up[2]*cam_up
 local tcz=pz-p_fwd[3]*cam_dist+p_up[3]*cam_up

 -- lerp camera position
 local cl=0.1
 cx+=(tcx-cx)*cl
 cy+=(tcy-cy)*cl
 cz+=(tcz-cz)*cl

 -- lerp camera orientation
 c_fwd[1]+=(p_fwd[1]-c_fwd[1])*cl
 c_fwd[2]+=(p_fwd[2]-c_fwd[2])*cl
 c_fwd[3]+=(p_fwd[3]-c_fwd[3])*cl
 c_rgt[1]+=(p_rgt[1]-c_rgt[1])*cl
 c_rgt[2]+=(p_rgt[2]-c_rgt[2])*cl
 c_rgt[3]+=(p_rgt[3]-c_rgt[3])*cl
 c_up[1]+=(p_up[1]-c_up[1])*cl
 c_up[2]+=(p_up[2]-c_up[2])*cl
 c_up[3]+=(p_up[3]-c_up[3])*cl

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

 -- dust particles (move opposite to player velocity)
 for d in all(dust) do
  d.x-=p_fwd[1]*pspeed
  d.y-=p_fwd[2]*pspeed
  d.z-=p_fwd[3]*pspeed
  -- wrap around player
  local dx,dy,dz=d.x,d.y,d.z
  if dx<-30 then d.x+=60 end
  if dx>30 then d.x-=60 end
  if dy<-30 then d.y+=60 end
  if dy>30 then d.y-=60 end
  if dz<-30 then d.z+=60 end
  if dz>30 then d.z-=60 end
 end

 -- shield recharge (recharge after 2 sec of no damage)
 if shield<shield_max then
  shield_recharge+=1
  if shield_recharge>120 then
   shield=min(shield+0.5,shield_max)
  end
 end

 -- decrement hit flash timer
 if hit_flash>0 then
  hit_flash-=1
 end

 -- wave progression
 if #enemies==0 then
  wave+=1
  spawn_wave()
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
end

function spawn_enemy(etype)
 etype=etype or "normal"
 local e={
  x=rnd(100)-50+px,
  y=rnd(60)-30+py,
  z=rnd(100)+80+pz,
  rx=0,ry=0.5,rz=0,
  etype=etype,
  ai=rnd(40)+20,
  evade=0,
  evade_dir=0,
  breakoff=0
 }
 -- type-specific stats
 if etype=="normal" then
  e.hp=20
  e.spd=0.6
  e.fire=rnd(120)+90
  e.acc=0.15
  e.v=enemy_v
  e.f=enemy_f
 elseif etype=="heavy" then
  e.hp=50
  e.spd=0.4
  e.fire=rnd(150)+120
  e.acc=0.1
  e.v=heavy_v
  e.f=heavy_f
 elseif etype=="fast" then
  e.hp=12
  e.spd=0.9
  e.fire=rnd(100)+80
  e.acc=0.12
  e.v=fast_v
  e.f=fast_f
 end
 add(enemies,e)
end

function spawn_wave()
 -- wave is already incremented when this is called
 -- wave 2: 1 normal (after beating wave 1)
 -- wave 3: 2 normal
 -- wave 4: 2 normal + 1 fast
 -- wave 5: 1 normal + 1 heavy + 1 fast
 -- wave 6+: mix up to 4
 if wave==2 then
  spawn_enemy("normal")
 elseif wave==3 then
  spawn_enemy("normal")
  spawn_enemy("normal")
 elseif wave==4 then
  spawn_enemy("normal")
  spawn_enemy("normal")
  spawn_enemy("fast")
 elseif wave==5 then
  spawn_enemy("normal")
  spawn_enemy("heavy")
  spawn_enemy("fast")
 else
  -- wave 6+: random mix, max 4
  local count=min(wave-2,4)
  for i=1,count do
   local r=rnd(10)
   if r<4 then
    spawn_enemy("normal")
   elseif r<7 then
    spawn_enemy("fast")
   else
    spawn_enemy("heavy")
   end
  end
 end
end

function cycle_target()
 if #enemies==0 then
  target=nil
  return
 end

 -- find current target index
 local cur_idx=0
 for i,e in pairs(enemies) do
  if e==target then
   cur_idx=i
   break
  end
 end

 -- cycle to next
 cur_idx+=1
 if cur_idx>#enemies then cur_idx=1 end
 target=enemies[cur_idx]
 sfx(0)
end

function update_enemies()
 for e in all(enemies) do
  -- get direction to player
  local dx=px-e.x
  local dy=py-e.y
  local dz=pz-e.z
  local dist=sqrt(dx*dx+dy*dy+dz*dz)

  -- get enemy forward vector
  local fx,fy,fz=rot3d(0,0,1,e.rx,e.ry,e.rz)

  -- dot product to check if facing player
  local facing=0
  if dist>0 then
   facing=(fx*dx+fy*dy+fz*dz)/dist
  end

  -- use enemy speed
  local spd=e.spd or 0.4

  -- AI state machine
  if e.breakoff and e.breakoff>0 then
   -- breaking off after attack run
   e.breakoff-=1
   e.x+=fx*spd*1.2
   e.y+=fy*spd*1.2
   e.z+=fz*spd*1.2
  elseif e.evade>0 then
   -- evasion behavior when hit
   e.evade-=1
   local ex,ey,ez=rot3d(1,0,0,e.rx,e.ry,e.rz)
   local estr=e.evade_dir*spd*1.5
   e.x+=ex*estr+fx*spd*0.3
   e.y+=ey*estr+fy*spd*0.3
   e.z+=ez*estr+fz*spd*0.3
  else
   -- normal pursuit: rotate toward player
   e.ai-=1
   if e.ai<=0 then
    if dist>0 then
     e.ry=atan2(dx,dz)
     e.rx=-atan2(dy,sqrt(dx*dx+dz*dz))*0.5
    end
    e.ai=20+rnd(30)
   end
   -- move forward
   e.x+=fx*spd
   e.y+=fy*spd
   e.z+=fz*spd
  end

  -- firing: only when facing player (dot > 0.9) and in range
  e.fire-=1
  if e.fire<=0 and facing>0.9 and dist<200 then
   -- fire forward (enemy's facing direction)
   fire_enemy_bullet(e.x,e.y,e.z,e.rx,e.ry,e.rz)
   e.fire=80+rnd(60)
   -- break off after firing
   e.breakoff=40+rnd(30)
   -- turn away slightly for break off
   e.ry+=0.25-rnd(0.5)
   sfx(1)
  elseif e.fire<=0 then
   e.fire=20 -- check again soon
  end

 end
end

function fire_player_bullet()
 local spd=3
 add(bullets,{
  x=px+p_fwd[1]*5,
  y=py+p_fwd[2]*5,
  z=pz+p_fwd[3]*5,
  vx=p_fwd[1]*spd+p_fwd[1]*pspeed,
  vy=p_fwd[2]*spd+p_fwd[2]*pspeed,
  vz=p_fwd[3]*spd+p_fwd[3]*pspeed,
  plr=true,life=120
 })
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

function fire_enemy_bullet(x,y,z,rx,ry,rz)
 local fx,fy,fz=rot3d(0,0,1,rx,ry,rz)
 local spd=0.8 -- slower enemy bullets
 add(bullets,{
  x=x+fx*5,y=y+fy*5,z=z+fz*5,
  vx=fx*spd,vy=fy*spd,vz=fz*spd,
  plr=false,life=180
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
    local d=v_len({b.x-e.x,b.y-e.y,b.z-e.z})
    if d<5 then -- 5 unit radius collision sphere
     e.hp-=10
     -- trigger evasion when hit
     e.evade=20+rnd(15)
     e.evade_dir=rnd(1)<0.5 and -1 or 1
     add_parts(b.x,b.y,b.z,5,9)
     del(bullets,b)
     sfx(2)
     if e.hp<=0 then
      add_expl(e.x,e.y,e.z,15)
      score+=100
      del(enemies,e)
      sfx(3)
      -- wave progression handled in update_play()
     end
     break
    end
   end
  else
   local d=v_len({b.x-px,b.y-py,b.z-pz})
   if d<6 then -- 6 unit radius for player
    -- damage shields first, then health
    shield_recharge=0 -- reset recharge timer
    hit_flash=10 -- flash red when hit
    if shield>0 then
     shield=max(0,shield-15)
     add_parts(px,py,pz,4,12) -- blue shield sparks
    else
     health-=10
     add_parts(px,py,pz,8,8)
    end
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

 rectfill(14,28,114,48,1)
 print("space combat 3d",28,32,11)
 print("---------------",28,40,5)

 print("arrows: pitch/yaw",23,54,6)
 print("hold z+arrows:",27,62,6)
 print("speed/roll",39,70,13)
 print("x: fire",47,80,6)

 print("press x to start",28,100,10)
end

function draw_play()
 draw_stars()
 draw_dust()

 local faces={}
 add_player_ship(faces,ship_v,ship_f)

 for e in all(enemies) do
  local ev=e.v or enemy_v
  local ef=e.f or enemy_f
  add_ship(faces,e.x,e.y,e.z,e.rx,e.ry,e.rz,ev,ef)
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

-- project direction vector to screen (skybox style)
function dir_to_screen(dx,dy,dz)
 -- project direction onto camera axes
 local vx=dx*c_rgt[1]+dy*c_rgt[2]+dz*c_rgt[3]
 local vy=dx*c_up[1]+dy*c_up[2]+dz*c_up[3]
 local vz=dx*c_fwd[1]+dy*c_fwd[2]+dz*c_fwd[3]
 return vx,vy,vz
end

function draw_stars()
 -- draw stars first (background layer, twinkling)
 local tm=t()*3
 for i,s in pairs(stars) do
  local svx,svy,svz=dir_to_screen(s[1],s[2],s[3])
  if svz>0.1 then
   local sx=64+svx*90/svz
   local sy=64-svy*90/svz
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    -- twinkle based on star index and time
    local twinkle=sin(tm+i*0.1)
    -- varied colors: white, light blue, yellow, dim
    local cols={7,12,10,6,5}
    local ci=1+(i%5)
    -- twinkle affects brightness
    if twinkle<-0.3 then
     ci=min(ci+1,5)
    elseif twinkle>0.5 then
     ci=max(ci-1,1)
    end
    pset(sx,sy,cols[ci])
   end
  end
 end

 -- draw planet (in front of stars)
 local pdx,pdy,pdz=-0.4,0.3,0.6
 local pvx,pvy,pvz=dir_to_screen(pdx,pdy,pdz)
 if pvz>0.1 then
  local psx=64+pvx*120/pvz
  local psy=64-pvy*120/pvz
  local pr=25/pvz
  if psx>-pr-10 and psx<138+pr and psy>-pr-10 and psy<138+pr then
   circfill(psx,psy,pr,1)
   circfill(psx,psy,pr*0.92,12)
   circ(psx,psy,pr,6)
   if pr>4 then
    circfill(psx-pr*0.3,psy-pr*0.2,pr*0.25,3)
    circfill(psx+pr*0.2,psy+pr*0.25,pr*0.2,3)
   end
  end
 end

 -- draw sun last (in front of everything)
 local svx,svy,svz=dir_to_screen(sun_dir[1],sun_dir[2],sun_dir[3])
 if svz>0.1 then
  local ssx=64+svx*120/svz
  local ssy=64-svy*120/svz
  if ssx>=-20 and ssx<148 and ssy>=-20 and ssy<148 then
   circfill(ssx,ssy,14,10)
   circfill(ssx,ssy,10,9)
   circfill(ssx,ssy,6,10)
   circfill(ssx,ssy,3,7)
  end
 end
end

-- draw player ship using orientation vectors
function add_player_ship(faces,verts,fcs)
 local tv={}
 for i,v in pairs(verts) do
  local x,y,z=orient_point(v[1],v[2],v[3],p_fwd,p_rgt,p_up)
  x+=px
  y+=py
  z+=pz
  x,y,z=to_cam_space(x,y,z)
  tv[i]={x,y,z}
 end
 -- flash red when hit
 if hit_flash>0 then
  add_faces_flash(faces,tv,fcs)
 else
  add_faces(faces,tv,fcs)
 end
end

-- add faces with red flash (for damage)
function add_faces_flash(faces,tv,fcs)
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

    -- flash red color (8)
    add(faces,{p1x,p1y,p2x,p2y,p3x,p3y,8,ctr[3]})
   end
  end
 end
end

-- draw enemy ship using euler angles
function add_ship(faces,sx,sy,sz,rx,ry,rz,verts,fcs)
 local tv={}
 for i,v in pairs(verts) do
  local x,y,z=rot3d(v[1],v[2],v[3],rx,ry,rz)
  x+=sx
  y+=sy
  z+=sz
  x,y,z=to_cam_space(x,y,z)
  tv[i]={x,y,z}
 end
 add_faces(faces,tv,fcs)
end

function add_faces(faces,tv,fcs)

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
  local vx,vy,vz=to_cam_space(b.x,b.y,b.z)
  if vz>1 then
   local sx,sy=proj(vx,vy,vz)
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    circfill(sx,sy,max(1,4/vz),b.plr and 11 or 8)
   end
  end
 end
end

function draw_parts()
 for p in all(parts) do
  local vx,vy,vz=to_cam_space(p[1],p[2],p[3])
  if vz>1 then
   local sx,sy=proj(vx,vy,vz)
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    pset(sx,sy,p[8])
   end
  end
 end
end

function draw_dust()
 for d in all(dust) do
  -- dust is relative to player position
  local wx=px+d.x
  local wy=py+d.y
  local wz=pz+d.z
  local vx,vy,vz=to_cam_space(wx,wy,wz)
  if vz>1 and vz<50 then
   local sx,sy=proj(vx,vy,vz)
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    -- grey colors: 5 (dark), 6 (med), 13 (light)
    local col=5
    if vz<15 then col=6
    elseif vz<8 then col=13 end
    pset(sx,sy,col)
   end
  end
 end
end

function draw_expls()
 for e in all(expls) do
  local vx,vy,vz=to_cam_space(e[1],e[2],e[3])
  if vz>1 then
   local sx,sy=proj(vx,vy,vz)
   local sz=e[4]*5/vz
   circfill(sx,sy,sz,10)
   circfill(sx,sy,sz*0.7,9)
   circfill(sx,sy,sz*0.4,8)
  end
 end
end

function draw_hud()
 -- shield bar (top)
 rectfill(4,4,34,8,0)
 rectfill(5,5,5+shield*0.28,7,12) -- blue
 rect(4,4,34,8,7)
 print("shld",5,10,12)

 -- health bar (below shield)
 rectfill(4,16,34,20,0)
 rectfill(5,17,5+health*0.28,19,health>30 and 11 or 8)
 rect(4,16,34,20,7)
 print("hull",5,22,7)

 -- score/wave
 print("score:"..score,60,5,7)
 print("wave:"..wave,90,115,6)

 -- reticle
 circ(64,64,10,3)
 line(64,50,64,58,3)
 line(64,70,64,78,3)
 line(50,64,58,64,3)
 line(70,64,78,64,3)

 -- wing commander style targeting
 draw_target_brackets()

 -- throttle
 rectfill(116,25,120,85,1)
 rect(115,24,121,86,5)
 local fy=85-throttle*60
 rectfill(116,fy,120,85,11)
 rectfill(113,fy-2,123,fy+2,7)
 print("thr",111,88,5)

 -- radar (bottom left)
 draw_radar()

 -- target info panel
 if target then
  rectfill(55,110,80,124,1)
  rect(55,110,80,124,9)
  local dx=target.x-px
  local dy=target.y-py
  local dz=target.z-pz
  local dist=sqrt(dx*dx+dy*dy+dz*dz)
  print("rng",57,112,9)
  print(flr(dist).."m",57,118,7)
 end
end

function draw_radar()
 -- radar background (bottom left corner)
 local rx,ry,rr=28,112,14
 circfill(rx,ry,rr,1)
 circ(rx,ry,rr,5)
 circ(rx,ry,rr/2,5)
 -- crosshair
 line(rx-rr,ry,rx+rr,ry,5)
 line(rx,ry-rr,rx,ry+rr,5)

 -- draw enemies on radar
 for e in all(enemies) do
  -- get enemy position relative to player
  local dx=e.x-px
  local dy=e.y-py
  local dz=e.z-pz

  -- project onto player's local axes (x=right, z=forward)
  local lx=dx*p_rgt[1]+dy*p_rgt[2]+dz*p_rgt[3]
  local lz=dx*p_fwd[1]+dy*p_fwd[2]+dz*p_fwd[3]

  -- scale to radar (200 units = full radar radius)
  local scale=rr/200
  local ex=rx+lx*scale
  local ey=ry-lz*scale

  -- clamp to radar bounds
  local edx,edy=ex-rx,ey-ry
  local ed=sqrt(edx*edx+edy*edy)
  if ed>rr-2 then
   ex=rx+edx*(rr-2)/ed
   ey=ry+edy*(rr-2)/ed
  end

  -- draw blip (bigger for visibility)
  local col=(e==target) and 11 or 8
  if e==target then
   rectfill(ex-1,ey-1,ex+1,ey+1,11)
  else
   pset(ex,ey,col)
   pset(ex+1,ey,col)
   pset(ex,ey+1,col)
  end
 end

 -- player dot in center
 pset(rx,ry,7)
end

function draw_target_brackets()
 -- validate target still exists
 if target then
  local found=false
  for e in all(enemies) do
   if e==target then found=true break end
  end
  if not found then target=nil end
 end

 -- auto-target nearest if no target
 if not target and #enemies>0 then
  local best_d=99999
  for e in all(enemies) do
   local dx=e.x-px
   local dy=e.y-py
   local dz=e.z-pz
   local d=dx*dx+dy*dy+dz*dz
   if d<best_d then
    best_d=d
    target=e
   end
  end
 end

 -- draw brackets on all enemies
 for e in all(enemies) do
  local vx,vy,vz=to_cam_space(e.x,e.y,e.z)
  local dx=e.x-px
  local dy=e.y-py
  local dz=e.z-pz
  local dist=sqrt(dx*dx+dy*dy+dz*dz)

  if vz>1 then
   local sx,sy=proj(vx,vy,vz)
   local sz=max(6,40/vz)
   local is_target=(e==target)
   -- orange (9) for target, dark red (2) for others
   local col=is_target and 9 or 2

   -- corner brackets (wing commander style)
   -- top-left
   line(sx-sz,sy-sz,sx-sz,sy-sz+sz/2,col)
   line(sx-sz,sy-sz,sx-sz+sz/2,sy-sz,col)
   -- top-right
   line(sx+sz,sy-sz,sx+sz,sy-sz+sz/2,col)
   line(sx+sz,sy-sz,sx+sz-sz/2,sy-sz,col)
   -- bottom-left
   line(sx-sz,sy+sz,sx-sz,sy+sz-sz/2,col)
   line(sx-sz,sy+sz,sx-sz+sz/2,sy+sz,col)
   -- bottom-right
   line(sx+sz,sy+sz,sx+sz,sy+sz-sz/2,col)
   line(sx+sz,sy+sz,sx+sz-sz/2,sy+sz,col)

   -- current target: show range below brackets
   if is_target then
    -- diamond marker above
    local tdy=-sz-5
    line(sx,sy+tdy-3,sx-3,sy+tdy,9)
    line(sx,sy+tdy-3,sx+3,sy+tdy,9)
    line(sx-3,sy+tdy,sx,sy+tdy+3,9)
    line(sx+3,sy+tdy,sx,sy+tdy+3,9)
    -- range below
    print(flr(dist).."m",sx-10,sy+sz+2,9)
   end
  else
   -- off-screen target indicator (arrow at edge)
   if e==target then
    -- project direction to screen edge
    local ang=atan2(vx,-vz)
    local ex=64+cos(ang)*50
    local ey=64+sin(ang)*50
    -- draw arrow pointing toward target
    circfill(ex,ey,4,2)
    circ(ex,ey,4,9)
    -- show range
    print(flr(dist).."m",ex-10,ey+6,9)
   end
  end
 end
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
