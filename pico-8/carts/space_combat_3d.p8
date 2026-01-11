pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 3d space combat
-- flat shaded ships

-- config (tweak these!)
cfg={
 -- player
 start_health=100,
 start_shield=100,
 shield_regen_delay=120,
 shield_regen_rate=0.1,
 -- rotation
 rot_accel=0.001,
 rot_max=0.04,
 rot_damp=0.85,
 -- throttle
 throttle_rate=0.03,
 max_speed=1.5,
 -- weapons
 fire_rate=8,
 bullet_speed=3,
 bullet_life=120,
 enemy_bullet_spd=3,
 enemy_bullet_life=180,
 -- collision
 enemy_hit_radius=10,
 player_hit_radius=4,
 -- damage
 bullet_dmg=1,
 shield_dmg=15,
 hull_dmg=10,
 -- enemy types
 enemy_normal={hp=20,spd=0.6,fire=20,acc=0.15},
 enemy_heavy={hp=50,spd=0.4,fire=60,acc=0.1},
 enemy_fast={hp=12,spd=0.9,fire=80,acc=0.12},
 -- explosions
 expl_normal={sz=18,dur=30,debris=8,col=9},
 expl_heavy={sz=25,dur=40,debris=12,col=8},
 expl_fast={sz=12,dur=20,debris=6,col=9},
 -- evasion
 evade_hit_threshold=3,
 evade_duration=20,
 -- enemy AI
 ai_facing_threshold=0.5,
 ai_fire_range=300,
 ai_refire_delay=10,
 ai_refire_random=8,
 ai_burst_shots=4,
 ai_burst_random=2,
 ai_breakoff_time=8,
 ai_breakoff_random=5,
 ai_reaim_time=5,
 ai_reaim_random=8,
 -- shot-based evade mode
 ai_evade_shots=10,      -- enter evade after this many shots
 ai_evade_duration=90,   -- how long to evade (frames)
 ai_evade_random=30,     -- random variance
}

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
-- rotational velocities (pitch, yaw, roll)
rot_pitch=0
rot_yaw=0
rot_roll=0

-- targeting
target=nil
last_tap_time=-99
prev_btn4=false
match_speed=false
match_speed_held=false

-- tables
stars={}
enemies={}
bullets={}
parts={}
expls={}
dust={}
debris={}

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
 health=cfg.start_health
 shield=cfg.start_shield
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
 debris={}
 target=nil
 last_b_tap=-99
 rot_pitch=0
 rot_yaw=0
 rot_roll=0
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
 -- rotation uses config values
 local ra,rm,rd=cfg.rot_accel,cfg.rot_max,cfg.rot_damp

 -- check if holding B (btn 4) for alternate mode
 local alt_mode=btn(4)

 if alt_mode then
  -- alternate mode: up/down = speed, left/right = roll
  -- Z + up + down together = toggle match speed
  if btn(2) and btn(3) then
   if not match_speed_held then
    match_speed=not match_speed
    match_speed_held=true
    sfx(4) -- beep to confirm toggle
   end
  else
   match_speed_held=false
   -- manual throttle adjustments disable match speed
   if btn(2) then
    throttle=min(throttle+cfg.throttle_rate,1)
    match_speed=false
   end
   if btn(3) then
    throttle=max(throttle-cfg.throttle_rate,0)
    match_speed=false
   end
  end
  -- roll around forward axis (with acceleration)
  if btn(0) then
   rot_roll=max(-rm,rot_roll-ra)
  elseif btn(1) then
   rot_roll=min(rm,rot_roll+ra)
  else
   rot_roll*=rd
  end
 else
  -- regular mode: pitch/yaw with acceleration
  if btn(2) then
   rot_pitch=max(-rm,rot_pitch-ra)
  elseif btn(3) then
   rot_pitch=min(rm,rot_pitch+ra)
  else
   rot_pitch*=rd
  end
  if btn(0) then
   rot_yaw=min(rm,rot_yaw+ra)
  elseif btn(1) then
   rot_yaw=max(-rm,rot_yaw-ra)
  else
   rot_yaw*=rd
  end
 end

 -- apply rotational velocities
 if rot_pitch!=0 then
  p_fwd=rot_axis(p_fwd,p_rgt,rot_pitch)
  p_up=rot_axis(p_up,p_rgt,rot_pitch)
 end
 if rot_yaw!=0 then
  p_fwd=rot_axis(p_fwd,p_up,rot_yaw)
  p_rgt=rot_axis(p_rgt,p_up,rot_yaw)
 end
 if rot_roll!=0 then
  p_rgt=rot_axis(p_rgt,p_fwd,rot_roll)
  p_up=rot_axis(p_up,p_fwd,rot_roll)
 end

 -- re-orthonormalize to prevent error accumulation
 orthonorm()

 -- smooth speed (or match target speed)
 local target_speed=throttle*cfg.max_speed
 if match_speed and target then
  target_speed=target.spd or 0.5
 end
 pspeed+=(target_speed-pspeed)*0.08

 -- double-tap Z to cycle targets (detect rising edge only)
 local btn4_down=btn(4)
 local btn4_tap=btn4_down and not prev_btn4
 prev_btn4=btn4_down

 if btn4_tap then
  if t()-last_tap_time<0.3 then
   cycle_target()
   last_tap_time=-99 -- reset to prevent triple-tap
  else
   last_tap_time=t()
  end
 end

 -- A button (btn 5) = fire
 pfire=max(0,pfire-1)
 if btn(5) and pfire==0 then
  fire_player_bullet()
  pfire=cfg.fire_rate
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

 -- debris triangles
 for d in all(debris) do
  d.x+=d.vx
  d.y+=d.vy
  d.z+=d.vz
  d.rx+=d.rvx
  d.ry+=d.rvy
  d.life-=1
  if d.life<=0 then del(debris,d) end
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

 -- shield recharge
 if shield<shield_max then
  shield_recharge+=1
  if shield_recharge>cfg.shield_regen_delay then
   shield=min(shield+cfg.shield_regen_rate,shield_max)
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
 -- spawn position relative to player
 local ex=rnd(100)-50+px
 local ey=rnd(60)-30+py
 local ez=rnd(100)+80+pz
 -- calculate direction to player for initial aim
 local dx,dy,dz=px-ex,py-ey,pz-ez
 local iry=atan2(dx,dz)
 local irx=-atan2(dy,sqrt(dx*dx+dz*dz))
 local e={
  x=ex,y=ey,z=ez,
  rx=irx,ry=iry,rz=0,
  etype=etype,
  ai=0,
  evade=0,
  evade_dir=0,
  breakoff=0,
  burst=0,
  total_shots=0  -- track total shots for evade mode
 }
 -- type-specific stats from config
 local c
 if etype=="normal" then
  c=cfg.enemy_normal
  e.v=enemy_v
  e.f=enemy_f
 elseif etype=="heavy" then
  c=cfg.enemy_heavy
  e.v=heavy_v
  e.f=heavy_f
 elseif etype=="fast" then
  c=cfg.enemy_fast
  e.v=fast_v
  e.f=fast_f
 end
 e.hp=c.hp
 e.max_hp=c.hp
 e.spd=c.spd
 e.fire=rnd(30)+c.fire
 e.acc=c.acc
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
 sfx(4)
end

function update_enemies()
 for e in all(enemies) do
  -- get direction to player
  local dx=px-e.x
  local dy=py-e.y
  local dz=pz-e.z
  -- scale to avoid overflow
  local sdx,sdy,sdz=dx/16,dy/16,dz/16
  local dist=sqrt(sdx*sdx+sdy*sdy+sdz*sdz)*16
  local hdist=sqrt(sdx*sdx+sdz*sdz)*16

  -- use enemy speed
  local spd=e.spd or 0.4

  -- turn rate for this enemy
  local turn=e.acc or 0.02

  -- get current forward vector
  local fx,fy,fz=rot3d(0,0,1,e.rx,e.ry,e.rz)

  -- normalize direction to player
  local ndx,ndy,ndz=0,0,1
  if dist>1 then
   ndx,ndy,ndz=dx/dist,dy/dist,dz/dist
  end

  -- facing = dot product (1=toward, -1=away)
  local facing=fx*ndx+fy*ndy+fz*ndz

  -- cross product for turn direction
  -- Y component: fx*ndz - fz*ndx (positive=turn right/increase ry)
  -- X component: fy*ndz - fz*ndy (positive=pitch down/increase rx)
  local cross_y=fx*ndz-fz*ndx
  local cross_x=fy*ndz-fz*ndy

  -- initialize state if needed
  -- states: "pursuit", "attack", "breakoff", "evade"
  if not e.state then e.state="pursuit" end
  if not e.state_timer then e.state_timer=0 end

  -- STATE TRANSITIONS
  -- don't interrupt evade state - let it complete
  e.state_timer+=1
  if e.state!="evade" then
   -- force pursuit if >300m OR pursuit timer expired (10-20 sec = 300-600 frames)
   if dist>300 or e.state_timer>300+rnd(300) then
    if e.state!="pursuit" then
     e.state="pursuit"
     e.state_timer=0
     e.burst=0
    end
   end

   -- pursuit->attack: when close enough (<150m)
   if e.state=="pursuit" and dist<150 then
    e.state="attack"
    e.state_timer=0
    e.burst=0
   end
  end

  -- attack->breakoff: after firing burst (4-5 shots)
  -- (handled in attack state below)

  -- breakoff->pursuit: after breakoff timer OR if >300m
  if e.state=="breakoff" then
   if e.breakoff<=0 or dist>300 then
    e.state="pursuit"
    e.state_timer=0
   end
  end

  -- DEBUG: print state info every ~30 frames
  if e.state_timer%30==1 then
   printh("["..e.state.."] d="..flr(dist).." fac="..flr(facing*100)/100 .." cy="..flr(cross_y*100)/100 .." cx="..flr(cross_x*100)/100)
  end

  -- EXECUTE CURRENT STATE
  if e.state=="evade" then
   -- EVADE: fly away from player aggressively after 10 shots
   e.evade_timer=(e.evade_timer or 0)-1

   -- slight weaving motion while evading
   e.ry+=e.evade_yaw*turn*0.5
   while e.ry>=1 do e.ry-=1 end
   while e.ry<0 do e.ry+=1 end

   -- recalc forward after turning
   fx,fy,fz=rot3d(0,0,1,e.rx,e.ry,e.rz)

   -- fly away fast!
   e.x+=fx*spd*1.5
   e.y+=fy*spd*1.5
   e.z+=fz*spd*1.5

   -- transition back to pursuit when timer expires
   if e.evade_timer<=0 then
    e.state="pursuit"
    e.state_timer=0
   end

  elseif e.state=="breakoff" then
   -- BREAKOFF: fly away from player
   e.breakoff-=1
   e.x+=fx*spd*1.2
   e.y+=fy*spd*1.2
   e.z+=fz*spd*1.2

  elseif e.state=="attack" then
   -- ATTACK: turn toward player using cross product, fly forward, fire when facing
   -- cross_y: positive = turn right (increase ry)
   -- cross_x: positive = pitch up (decrease rx)
   e.ry+=cross_y*turn
   e.rx-=cross_x*turn

   -- normalize angles
   while e.ry>=1 do e.ry-=1 end
   while e.ry<0 do e.ry+=1 end
   while e.rx>=1 do e.rx-=1 end
   while e.rx<0 do e.rx+=1 end

   -- recalc forward after turning
   fx,fy,fz=rot3d(0,0,1,e.rx,e.ry,e.rz)
   facing=fx*ndx+fy*ndy+fz*ndz

   -- move forward at full speed in attack mode
   e.x+=fx*spd
   e.y+=fy*spd
   e.z+=fz*spd

   -- firing: only when facing player
   e.fire-=1
   if e.fire<=0 and facing>cfg.ai_facing_threshold then
    fire_enemy_bullet(e.x,e.y,e.z,e.rx,e.ry,e.rz)
    e.fire=cfg.ai_refire_delay+rnd(cfg.ai_refire_random)
    sfx(1)
    e.burst=(e.burst or 0)+1
    e.total_shots=(e.total_shots or 0)+1

    -- check if should enter evade mode (after 10 shots)
    if e.total_shots>=cfg.ai_evade_shots then
     -- turn away sharply
     e.ry+=0.3+rnd(0.2)*(rnd(1)<0.5 and 1 or -1)
     while e.ry>=1 do e.ry-=1 end
     while e.ry<0 do e.ry+=1 end
     e.evade_timer=cfg.ai_evade_duration+flr(rnd(cfg.ai_evade_random))
     e.evade_yaw=rnd(1)<0.5 and 1 or -1  -- random turn direction
     e.state="evade"
     e.total_shots=0
     e.burst=0
    -- after burst, break off briefly
    elseif e.burst>=cfg.ai_burst_shots+flr(rnd(cfg.ai_burst_random)) then
     e.ry+=0.25+rnd(0.25)*(rnd(1)<0.5 and 1 or -1)
     while e.ry>=1 do e.ry-=1 end
     while e.ry<0 do e.ry+=1 end
     e.breakoff=cfg.ai_breakoff_time+flr(rnd(cfg.ai_breakoff_random))
     e.state="breakoff"
     e.burst=0
    end
   end

  else
   -- PURSUIT: turn toward player (faster) using cross product
   turn=turn*2
   if dist>200 then turn=turn*2 end  -- even faster when far

   -- cross_y: positive = turn right (increase ry)
   -- cross_x: positive = pitch up (decrease rx)
   e.ry+=cross_y*turn
   e.rx-=cross_x*turn

   -- normalize angles
   while e.ry>=1 do e.ry-=1 end
   while e.ry<0 do e.ry+=1 end
   while e.rx>=1 do e.rx-=1 end
   while e.rx<0 do e.rx+=1 end

   -- recalc forward after turning
   fx,fy,fz=rot3d(0,0,1,e.rx,e.ry,e.rz)
   facing=fx*ndx+fy*ndy+fz*ndz

   -- slow down when facing away, speed up when facing toward
   local move_spd=spd
   if facing<0 then
    move_spd=spd*0.3
   elseif facing<0.5 then
    move_spd=spd*0.6
   end

   e.x+=fx*move_spd
   e.y+=fy*move_spd
   e.z+=fz*move_spd
  end

  -- handle evasion (can interrupt any state)
  if e.evade and e.evade>0 then
   e.evade-=1
   local ex,ey,ez=rot3d(1,0,0,e.rx,e.ry,e.rz)
   local estr=e.evade_dir*spd*1.5
   e.x+=ex*estr
   e.y+=ey*estr
   e.z+=ez*estr
  end

 end
end

function fire_player_bullet()
 local spd=cfg.bullet_speed
 add(bullets,{
  x=px+p_fwd[1]*5,
  y=py+p_fwd[2]*5,
  z=pz+p_fwd[3]*5,
  vx=p_fwd[1]*spd+p_fwd[1]*pspeed,
  vy=p_fwd[2]*spd+p_fwd[2]*pspeed,
  vz=p_fwd[3]*spd+p_fwd[3]*pspeed,
  plr=true,life=cfg.bullet_life
 })
end

function fire_bullet(x,y,z,rx,ry,rz,plr)
 local fx,fy,fz=rot3d(0,0,1,rx,ry,rz)
 local spd=plr and cfg.bullet_speed or 1.5
 add(bullets,{
  x=x+fx*5,y=y+fy*5,z=z+fz*5,
  vx=fx*spd,vy=fy*spd,vz=fz*spd,
  plr=plr,life=cfg.bullet_life
 })
end

function fire_enemy_bullet(x,y,z,rx,ry,rz)
 local fx,fy,fz=rot3d(0,0,1,rx,ry,rz)
 local spd=cfg.enemy_bullet_spd
 add(bullets,{
  x=x+fx*5,y=y+fy*5,z=z+fz*5,
  vx=fx*spd,vy=fy*spd,vz=fz*spd,
  plr=false,life=cfg.enemy_bullet_life
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
   -- player bullet -> enemy collision
   for e in all(enemies) do
    -- scale down before squaring to avoid pico-8 overflow
    local dx,dy,dz=(b.x-e.x)/16,(b.y-e.y)/16,(b.z-e.z)/16
    local d=sqrt(dx*dx+dy*dy+dz*dz)*16
    if d<cfg.enemy_hit_radius then
     e.hp-=cfg.bullet_dmg
     e.hits=(e.hits or 0)+1
     -- trigger evasion after taking a few hits
     if e.hits>=cfg.evade_hit_threshold+flr(rnd(3)) then
      e.evade=cfg.evade_duration+rnd(15)
      e.evade_dir=rnd(1)<0.5 and -1 or 1
      e.hits=0 -- reset hit counter
     end
     add_parts(b.x,b.y,b.z,8,9)
     add_expl(b.x,b.y,b.z,5) -- small explosion on hit
     del(bullets,b)
     sfx(2)
     if e.hp<=0 then
      add_ship_expl(e.x,e.y,e.z,e.etype)
      score+=100
      del(enemies,e)
      sfx(5) -- big explosion sound
     end
     break
    end
   end
  else
   -- enemy bullet -> player collision
   -- scale down before squaring to avoid pico-8 overflow
   local dx,dy,dz=(b.x-px)/16,(b.y-py)/16,(b.z-pz)/16
   local d=sqrt(dx*dx+dy*dy+dz*dz)*16
   if d<cfg.player_hit_radius then
    shield_recharge=0
    hit_flash=10
    if shield>0 then
     shield=max(0,shield-cfg.shield_dmg)
     add_parts(px,py,pz,4,12)
    else
     health-=cfg.hull_dmg
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

-- spectacular ship explosion with flying triangles
function add_ship_expl(x,y,z,etype)
 -- get explosion config based on ship type
 local ec
 if etype=="heavy" then
  ec=cfg.expl_heavy
 elseif etype=="fast" then
  ec=cfg.expl_fast
 else -- normal
  ec=cfg.expl_normal
 end
 local sz,dur,debris_n,col=ec.sz,ec.dur,ec.debris,ec.col

 -- multiple expanding explosions
 add(expls,{x,y,z,0,true,sz})
 add(expls,{x+rnd(4)-2,y+rnd(4)-2,z+rnd(4)-2,0,true,sz*0.7})
 add(expls,{x+rnd(6)-3,y+rnd(6)-3,z+rnd(6)-3,0,true,sz*0.5})

 -- lots of particles
 add_parts(x,y,z,sz*2,10)
 add_parts(x,y,z,sz*2,9)
 add_parts(x,y,z,sz,8)
 add_parts(x,y,z,sz,7)

 -- flying debris triangles
 for i=1,debris_n do
  local spd=0.3+rnd(0.5)
  local vx,vy,vz=rnd(2)-1,rnd(2)-1,rnd(2)-1
  local len=sqrt(vx*vx+vy*vy+vz*vz)
  if len>0 then vx,vy,vz=vx/len*spd,vy/len*spd,vz/len*spd end
  add(debris,{
   x=x,y=y,z=z,
   vx=vx,vy=vy,vz=vz,
   rx=rnd(1),ry=rnd(1),rz=rnd(1),
   rvx=rnd(0.1)-0.05,rvy=rnd(0.1)-0.05,
   sz=1+rnd(2),
   life=dur+rnd(20),
   col=col
  })
 end
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
 draw_debris()
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
   if sx>=-20 and sx<148 and sy>=-20 and sy<148 then
    -- draw tracer streak (tail behind bullet)
    local tlen=b.plr and 3 or 5
    local tx,ty,tz=b.x-b.vx*tlen,b.y-b.vy*tlen,b.z-b.vz*tlen
    local tvx,tvy,tvz=to_cam_space(tx,ty,tz)
    if tvz>1 then
     local tsx,tsy=proj(tvx,tvy,tvz)
     local col=b.plr and 11 or 8
     line(tsx,tsy,sx,sy,col)
    end
    -- bullet head
    circfill(sx,sy,max(1,3/vz),b.plr and 10 or 9)
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

function draw_debris()
 for d in all(debris) do
  local vx,vy,vz=to_cam_space(d.x,d.y,d.z)
  if vz>1 then
   local sx,sy=proj(vx,vy,vz)
   local sz=d.sz*8/vz
   if sx>-20 and sx<148 and sy>-20 and sy<148 then
    -- spinning triangle
    local a=d.rx
    local x1,y1=sx+cos(a)*sz,sy+sin(a)*sz
    local x2,y2=sx+cos(a+0.33)*sz,sy+sin(a+0.33)*sz
    local x3,y3=sx+cos(a+0.66)*sz,sy+sin(a+0.66)*sz
    -- fade color as life decreases
    local col=d.col
    if d.life<10 then col=5 end
    line(x1,y1,x2,y2,col)
    line(x2,y2,x3,y3,col)
    line(x3,y3,x1,y1,col)
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
 local sw=flr(shield*28/100)
 if shield>0 then rectfill(5,5,5+sw,7,12) end -- blue
 rect(4,4,34,8,7)
 print("shld",5,10,12)

 -- health bar (below shield)
 rectfill(4,16,34,20,0)
 local hw=flr(health*28/100)
 if health>0 then rectfill(5,17,5+hw,19,health>30 and 11 or 8) end
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
 -- match speed indicator
 if match_speed then
  print("mtch",109,95,11)
 end

 -- radar (bottom left)
 draw_radar()

 -- target info panel
 if target then
  rectfill(50,100,90,126,1)
  rect(50,100,90,126,9)
  -- scale to avoid overflow
  local dx,dy,dz=(target.x-px)/16,(target.y-py)/16,(target.z-pz)/16
  local dist=sqrt(dx*dx+dy*dy+dz*dz)*16
  print("rng:"..flr(dist).."m",52,102,9)
  -- enemy health bar (normalized 0-1)
  print("hp:",52,112,8)
  rectfill(64,111,88,117,0)
  local max_hp=target.max_hp or 20
  local hp_ratio=target.hp/max_hp
  local ehp=flr(hp_ratio*22)
  if target.hp>0 then
   local hcol=hp_ratio>0.5 and 11 or (hp_ratio>0.25 and 9 or 8)
   rectfill(65,112,65+ehp,116,hcol)
  end
  rect(64,111,88,117,7)
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
  -- scale to avoid overflow
  local dx,dy,dz=(e.x-px)/16,(e.y-py)/16,(e.z-pz)/16
  local dist=sqrt(dx*dx+dy*dy+dz*dz)*16

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
   -- off-screen/behind indicator
   if e==target then
    -- use camera-space coords to find direction
    local ang=atan2(vx,vz)
    local ex=64+cos(ang)*50
    local ey=64-sin(ang)*50
    -- draw arrow pointing toward target
    circfill(ex,ey,5,2)
    circ(ex,ey,5,9)
    -- arrow pointing direction
    local ax,ay=cos(ang)*8,sin(ang)*8
    line(ex,ey,ex+ax,ey-ay,9)
    -- show range
    print(flr(dist).."m",ex-10,ey+8,9)
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
000100001867016670146600e6600a660086600566003660016600060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
000200001563013620116200e6200b62008620056200362001620006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100001865018650186001860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002b5502855028550255002450021500205001d5001a50016500125000e5000b50008500065000450002500015000050000500005000050000500005000050000500005000050000500005000050000500005000
