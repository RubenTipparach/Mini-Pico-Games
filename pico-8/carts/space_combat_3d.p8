pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 3d space combat
-- flat shaded ships

-- config (tweak these!)
cfg={
 start_hp=100,  -- used for health and shield
 shield_regen_delay=120,shield_regen_rate=0.1,
 rot_accel=0.001,rot_max=0.04,rot_damp=0.85,
 throttle_rate=0.03,max_speed=1.5,
 fire_rate=8,bullet_spd=3,bullet_life=120,enemy_bullet_life=180,
 enemy_hit_r=10,player_hit_r=4,
 bullet_dmg=1,shield_dmg=15,hull_dmg=10,
 -- enemy types
 enemy_normal={hp=20,spd=0.6,fire=20,acc=0.15},
 enemy_heavy={hp=50,spd=0.4,fire=60,acc=0.1},
 enemy_fast={hp=12,spd=0.9,fire=80,acc=0.12},
 -- frigate (capital ship)
 enemy_frigate={hp=200,spd=0.2,fire=40,acc=0.03},
 frigate_subsys_hp=25,  -- hp per subsystem
 frigate_weak_mult=4,
 -- evasion
 evade_hit_threshold=3,
 evade_duration=20,
 -- enemy AI (shortened keys)
 ai_face=0.5,ai_refire=10,ai_refire_r=8,
 ai_burst=4,ai_burst_r=2,ai_break=8,ai_break_r=5,
 ai_evade_n=10,ai_evade_t=1800,ai_evade_r=300,ai_evade_d=35,
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
subsystems={}  -- frigate subsystems (weapons, reactors)
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

-- frigate (capital ship) - large elongated hull
frigate_v={
 {0,0,20},{-8,0,-15},{8,0,-15},  -- nose and rear
 {0,4,5},{0,-4,5},               -- top/bottom mid
 {-10,0,0},{10,0,0},             -- wings
 {0,0,-18},                       -- tail
 {-6,2,-8},{6,2,-8},             -- upper rear
 {-6,-2,-8},{6,-2,-8}            -- lower rear
}
frigate_f={
 {1,4,2,5},{1,3,4,5},            -- top front
 {1,2,5,6},{1,5,3,6},            -- bottom front
 {4,3,8,5},{4,8,2,5},            -- top rear
 {5,8,3,6},{5,2,8,6},            -- bottom rear
 {6,2,1,8},{7,1,3,8},            -- wing fronts
 {6,8,2,5},{7,3,8,5},            -- wing rears
 {9,4,10,11},{11,5,12,11}        -- bridge details
}

-- subsystem marker (small cube for weapons/reactors)
subsys_v={
 {-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1},
 {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1}
}
subsys_f={
 {1,2,3,8},{1,3,4,8},  -- front
 {5,7,6,8},{5,8,7,8},  -- back
 {1,5,6,9},{1,6,2,9},  -- bottom
 {4,3,7,9},{4,7,8,9}   -- top
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

-- helper: distance from player (scaled to avoid overflow)
function dist_from_player(x,y,z)
 local dx,dy,dz=(x-px)/16,(y-py)/16,(z-pz)/16
 return sqrt(dx*dx+dy*dy+dz*dz)*16
end

-- helper: normalize angle to 0-1
function norm_ang(a)
 while a>=1 do a-=1 end
 while a<0 do a+=1 end
 return a
end

-- helper: get target world position (works for enemies and subsystems)
function get_target_pos(t)
 if t.parent then return get_subsys_pos(t) end
 return t.x,t.y,t.z
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
shade_sun={0.5,0.7,-0.5}  -- for ship lighting

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
 -- normalize sun directions
 local l=sqrt(sun_dir[1]^2+sun_dir[2]^2+sun_dir[3]^2)
 sun_dir[1]/=l sun_dir[2]/=l sun_dir[3]/=l
 l=sqrt(shade_sun[1]^2+shade_sun[2]^2+shade_sun[3]^2)
 shade_sun[1]/=l shade_sun[2]/=l shade_sun[3]/=l
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
 health=cfg.start_hp
 shield=cfg.start_hp
 shield_recharge=0
 hit_flash=0
 wave=1
 wave_enemies=1
 spawn_t=0
 enemies={}
 subsystems={}
 bullets={}
 parts={}
 expls={}
 dust={}
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
  -- damp roll when not in alt mode
  rot_roll*=rd
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

-- enemy type lookup table
enemy_types={
 normal={c=cfg.enemy_normal,v=enemy_v,f=enemy_f},
 heavy={c=cfg.enemy_heavy,v=heavy_v,f=heavy_f},
 fast={c=cfg.enemy_fast,v=fast_v,f=fast_f},
 frigate={c=cfg.enemy_frigate,v=frigate_v,f=frigate_f}
}

function spawn_enemy(etype)
 etype=etype or "normal"
 local et=enemy_types[etype]
 local c=et.c
 -- spawn position relative to player
 local ex,ey,ez=rnd(100)-50+px,rnd(60)-30+py,rnd(100)+80+pz
 local dx,dy,dz=px-ex,py-ey,pz-ez
 local e={
  x=ex,y=ey,z=ez,
  rx=-atan2(dy,sqrt(dx*dx+dz*dz)),ry=atan2(dx,dz),rz=0,
  etype=etype,v=et.v,f=et.f,
  hp=c.hp,max_hp=c.hp,spd=c.spd,fire=rnd(30)+c.fire,acc=c.acc,
  ai=0,evade=0,evade_dir=0,breakoff=0,burst=0,total_shots=0
 }
 if etype=="frigate" then
  e.is_frigate=true
  e.subsys_ids={}
  add(enemies,e)
  spawn_frigate_subsystems(e)
 else
  add(enemies,e)
 end
end

-- spawn subsystems attached to a frigate
function spawn_frigate_subsystems(frigate)
 -- subsystem positions relative to frigate (local coords)
 local positions={
  {-6,2,0,"weapon"},   -- left turret
  {6,2,0,"weapon"},    -- right turret
  {0,3,-5,"reactor"},  -- top reactor
  {0,-3,-5,"reactor"}  -- bottom reactor
 }
 for i,pos in pairs(positions) do
  local s={
   parent=frigate,
   lx=pos[1],ly=pos[2],lz=pos[3],  -- local offset
   stype=pos[4],
   hp=cfg.frigate_subsys_hp,
   max_hp=cfg.frigate_subsys_hp,
   v=subsys_v,
   f=subsys_f,
   fire=rnd(60)+30  -- firing cooldown
  }
  add(subsystems,s)
  add(frigate.subsys_ids,s)
 end
end

function spawn_wave()
 -- wave is already incremented when this is called
 -- wave 2: 1 normal
 -- wave 3: 1 frigate!
 -- wave 4: 2 normal + 1 fast
 -- wave 5: 1 frigate + 1 fast
 -- wave 6+: mix, frigate every 3rd wave
 if wave==2 then
  spawn_enemy("normal")
 elseif wave==3 then
  spawn_enemy("frigate")
 elseif wave==4 then
  spawn_enemy("normal")
  spawn_enemy("normal")
  spawn_enemy("fast")
 elseif wave==5 then
  spawn_enemy("frigate")
  spawn_enemy("fast")
 else
  -- wave 6+: random mix, frigate every 3rd wave
  if wave%3==0 then
   spawn_enemy("frigate")
  end
  local count=min(wave-3,3)
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
 -- build combined target list: enemies + live subsystems
 local targets={}
 for e in all(enemies) do
  add(targets,e)
 end
 for s in all(subsystems) do
  if s.hp>0 then
   add(targets,s)
  end
 end

 if #targets==0 then
  target=nil
  return
 end

 -- find current target index
 local cur_idx=0
 for i,t in pairs(targets) do
  if t==target then
   cur_idx=i
   break
  end
 end

 -- cycle to next
 cur_idx+=1
 if cur_idx>#targets then cur_idx=1 end
 target=targets[cur_idx]
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
   -- force evade if too close to player
   if dist<cfg.ai_evade_d and e.state=="attack" then
    e.ry=norm_ang(e.ry+0.4+rnd(0.2)*(rnd(1)<0.5 and 1 or -1))
    e.evade_timer=cfg.ai_evade_t+flr(rnd(cfg.ai_evade_r))
    e.evade_yaw=rnd(1)<0.5 and 1 or -1
    e.state="evade"
    e.burst=0
   -- force pursuit if >300m OR pursuit timer expired (10-20 sec = 300-600 frames)
   elseif dist>300 or e.state_timer>300+rnd(300) then
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

  -- EXECUTE CURRENT STATE
  if e.state=="evade" then
   -- EVADE: fly away from player aggressively after 10 shots
   e.evade_timer=(e.evade_timer or 0)-1

   -- gentle weaving motion while evading
   e.ry=norm_ang(e.ry+e.evade_yaw*0.003)

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

   e.ry,e.rx=norm_ang(e.ry),norm_ang(e.rx)

   -- recalc forward after turning
   fx,fy,fz=rot3d(0,0,1,e.rx,e.ry,e.rz)
   facing=fx*ndx+fy*ndy+fz*ndz

   -- move forward at full speed in attack mode
   e.x+=fx*spd
   e.y+=fy*spd
   e.z+=fz*spd

   -- firing: only when facing player
   e.fire-=1
   if e.fire<=0 and facing>cfg.ai_face then
    fire_enemy_bullet(e.x,e.y,e.z,e.rx,e.ry,e.rz)
    e.fire=cfg.ai_refire+rnd(cfg.ai_refire_r)
    sfx(1)
    e.burst=(e.burst or 0)+1
    e.total_shots=(e.total_shots or 0)+1

    -- check if should enter evade mode (after 10 shots)
    if e.total_shots>=cfg.ai_evade_n then
     -- turn away sharply
     e.ry=norm_ang(e.ry+0.3+rnd(0.2)*(rnd(1)<0.5 and 1 or -1))
     e.evade_timer=cfg.ai_evade_t+flr(rnd(cfg.ai_evade_r))
     e.evade_yaw=rnd(1)<0.5 and 1 or -1
     e.state="evade"
     e.total_shots=0
     e.burst=0
    -- after burst, break off briefly
    elseif e.burst>=cfg.ai_burst+flr(rnd(cfg.ai_burst_r)) then
     e.ry=norm_ang(e.ry+0.25+rnd(0.25)*(rnd(1)<0.5 and 1 or -1))
     e.breakoff=cfg.ai_break+flr(rnd(cfg.ai_break_r))
     e.state="breakoff"
     e.burst=0
    end
   end

  else
   -- PURSUIT: turn toward player (faster) using cross product
   turn=turn*2
   if dist>200 then turn=turn*2 end  -- even faster when far

   e.ry+=cross_y*turn
   e.rx-=cross_x*turn
   e.ry,e.rx=norm_ang(e.ry),norm_ang(e.rx)

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
 local spd=cfg.bullet_spd
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

function fire_enemy_bullet(x,y,z,rx,ry,rz)
 local fx,fy,fz=rot3d(0,0,1,rx,ry,rz)
 local spd=cfg.bullet_spd
 add(bullets,{
  x=x+fx*5,y=y+fy*5,z=z+fz*5,
  vx=fx*spd,vy=fy*spd,vz=fz*spd,
  plr=false,life=cfg.enemy_bullet_life
 })
end

-- get subsystem world position
function get_subsys_pos(s)
 if not s.parent then return s.lx,s.ly,s.lz end
 local p=s.parent
 -- rotate local offset by parent orientation
 local wx,wy,wz=rot3d(s.lx,s.ly,s.lz,p.rx,p.ry,p.rz)
 return p.x+wx,p.y+wy,p.z+wz
end

-- check if frigate has all subsystems destroyed
function frigate_is_weak(e)
 if not e.is_frigate then return false end
 for s in all(e.subsys_ids) do
  if s.hp>0 then return false end
 end
 return true
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
   local hit=false

   -- player bullet -> subsystem collision (check first!)
   for s in all(subsystems) do
    if s.hp>0 then
     local sx,sy,sz=get_subsys_pos(s)
     local dx,dy,dz=(b.x-sx)/16,(b.y-sy)/16,(b.z-sz)/16
     local d=sqrt(dx*dx+dy*dy+dz*dz)*16
     if d<5 then  -- smaller hit radius for subsystems
      s.hp-=cfg.bullet_dmg
      add_parts(b.x,b.y,b.z,6,9)
      add_expl(b.x,b.y,b.z,3)
      del(bullets,b)
      sfx(2)
      if s.hp<=0 then
       -- subsystem destroyed!
       add_ship_expl(sx,sy,sz,"subsys")
       score+=50
       sfx(5)
      end
      hit=true
      break
     end
    end
   end

   -- player bullet -> enemy collision
   if not hit then
    for e in all(enemies) do
     -- scale down before squaring to avoid pico-8 overflow
     local dx,dy,dz=(b.x-e.x)/16,(b.y-e.y)/16,(b.z-e.z)/16
     local d=sqrt(dx*dx+dy*dy+dz*dz)*16
     local hit_r=e.is_frigate and 20 or cfg.enemy_hit_r
     if d<hit_r then
      -- apply damage (4x if frigate with all subsystems down)
      local dmg=cfg.bullet_dmg
      if frigate_is_weak(e) then
       dmg=dmg*cfg.frigate_weak_mult
      end
      e.hp-=dmg
      e.hits=(e.hits or 0)+1
      -- trigger evasion after taking a few hits (not for frigates)
      if not e.is_frigate and e.hits>=cfg.evade_hit_threshold+flr(rnd(3)) then
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
       -- frigates give more score
       score+=e.is_frigate and 500 or 100
       -- remove subsystems when frigate dies
       if e.is_frigate then
        for s in all(e.subsys_ids) do
         del(subsystems,s)
        end
       end
       del(enemies,e)
       sfx(5) -- big explosion sound
      end
      break
     end
    end
   end
  else
   -- enemy bullet -> player collision
   -- scale down before squaring to avoid pico-8 overflow
   local dx,dy,dz=(b.x-px)/16,(b.y-py)/16,(b.z-pz)/16
   local d=sqrt(dx*dx+dy*dy+dz*dz)*16
   if d<cfg.player_hit_r then
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

-- explosion sizes by type
expl_sz={normal=18,heavy=25,fast=12,frigate=40,subsys=10}

function add_ship_expl(x,y,z,etype)
 local sz=expl_sz[etype] or 18
 add(expls,{x,y,z,0,true,sz})
 add(expls,{x+rnd(4)-2,y+rnd(4)-2,z+rnd(4)-2,0,true,sz*0.6})
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
 for s in all(stars) do
  if s[3]>1 then pset(64+s[1]*60/s[3],64-s[2]*60/s[3],7) end
 end
 rectfill(14,28,114,48,1)
 print("space combat 3d",28,32,11)
 print("arrows:move z+arr:spd/roll",10,54,6)
 print("x:fire  dbl-z:target",20,64,6)
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

 -- render live subsystems
 for s in all(subsystems) do
  if s.hp>0 then
   local sx,sy,sz=get_subsys_pos(s)
   local p=s.parent
   -- use parent rotation for subsystem orientation
   add_ship(faces,sx,sy,sz,p.rx,p.ry,p.rz,s.v,s.f)
  end
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
 for i,s in pairs(stars) do
  local svx,svy,svz=dir_to_screen(s[1],s[2],s[3])
  if svz>0.1 then
   local sx,sy=64+svx*90/svz,64-svy*90/svz
   if sx>=0 and sx<128 and sy>=0 and sy<128 then
    pset(sx,sy,({7,12,10,6,5})[1+i%5])
   end
  end
 end

 -- draw planet
 local pvx,pvy,pvz=dir_to_screen(-0.4,0.3,0.6)
 if pvz>0.1 then
  local psx,psy,pr=64+pvx*120/pvz,64-pvy*120/pvz,25/pvz
  if psx>-30 and psx<158 and psy>-30 and psy<158 then
   circfill(psx,psy,pr,12)
   circ(psx,psy,pr,6)
  end
 end

 -- draw sun
 local svx,svy,svz=dir_to_screen(sun_dir[1],sun_dir[2],sun_dir[3])
 if svz>0.1 then
  local ssx,ssy=64+svx*120/svz,64-svy*120/svz
  if ssx>=-20 and ssx<148 and ssy>=-20 and ssy<148 then
   circfill(ssx,ssy,12,10)
   circfill(ssx,ssy,6,7)
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

    local light=(v_dot(n,shade_sun)+1)/2
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
 print("wave:"..wave,95,115,6)

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
 -- speed in m/s
 local spd_display=flr(pspeed*10)
 print(spd_display.."m/s",107,95,match_speed and 11 or 6)

 -- button prompts when holding Z (draw above radar)
 if btn(4) then
  rectfill(2,72,58,97,1)
  rect(2,72,58,97,6)
  print("up/dn:speed",4,74,11)
  print("up+dn:match",4,82,9)
  print("l/r:roll",4,90,11)
 end

 -- radar (bottom left)
 draw_radar()

 -- target info panel
 if target then
  rectfill(50,100,90,126,1)
  rect(50,100,90,126,9)
  local tx,ty,tz=get_target_pos(target)
  local dist=dist_from_player(tx,ty,tz)
  print("rng:"..flr(dist).."m",52,102,9)
  -- show type for subsystems
  if target.stype then
   local lbl=target.stype=="weapon" and "WEAPON" or "REACTOR"
   print(lbl,52,108,10)
  end
  -- health bar (normalized 0-1)
  local hp_y=target.stype and 116 or 112
  print("hp:",52,hp_y,8)
  rectfill(64,hp_y-1,88,hp_y+5,0)
  local max_hp=target.max_hp or 20
  local hp_ratio=target.hp/max_hp
  local ehp=flr(hp_ratio*22)
  if target.hp>0 then
   local hcol=hp_ratio>0.5 and 11 or (hp_ratio>0.25 and 9 or 8)
   rectfill(65,hp_y,65+ehp,hp_y+4,hcol)
  end
  rect(64,hp_y-1,88,hp_y+5,7)
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

-- helper: draw corner brackets
function draw_brackets(sx,sy,sz,col)
 line(sx-sz,sy-sz,sx-sz,sy-sz+sz/2,col)
 line(sx-sz,sy-sz,sx-sz+sz/2,sy-sz,col)
 line(sx+sz,sy-sz,sx+sz,sy-sz+sz/2,col)
 line(sx+sz,sy-sz,sx+sz-sz/2,sy-sz,col)
 line(sx-sz,sy+sz,sx-sz,sy+sz-sz/2,col)
 line(sx-sz,sy+sz,sx-sz+sz/2,sy+sz,col)
 line(sx+sz,sy+sz,sx+sz,sy+sz-sz/2,col)
 line(sx+sz,sy+sz,sx+sz-sz/2,sy+sz,col)
end

function draw_target_brackets()
 -- validate target still exists
 if target then
  local found=false
  for e in all(enemies) do if e==target then found=true break end end
  if not found then
   for s in all(subsystems) do if s==target and s.hp>0 then found=true break end end
  end
  if not found then target=nil end
 end

 -- auto-target nearest if no target
 if not target and #enemies>0 then
  local best_d=99999
  for e in all(enemies) do
   local d=(e.x-px)^2+(e.y-py)^2+(e.z-pz)^2
   if d<best_d then best_d,target=d,e end
  end
 end

 -- draw brackets on all enemies
 for e in all(enemies) do
  local vx,vy,vz=to_cam_space(e.x,e.y,e.z)
  local dist=dist_from_player(e.x,e.y,e.z)
  local is_target=(e==target)
  local col=is_target and 9 or 2

  if vz>1 then
   local sx,sy=proj(vx,vy,vz)
   local sz=max(6,40/vz)
   draw_brackets(sx,sy,sz,col)
   if is_target then print(flr(dist).."m",sx-10,sy+sz+2,9) end
  elseif is_target then
   local ang=atan2(vx,vz)
   local ex,ey=64+cos(ang)*50,64-sin(ang)*50
   circ(ex,ey,4,9)
   print(flr(dist).."m",ex-10,ey+6,9)
  end
 end

 -- draw brackets on live subsystems
 for s in all(subsystems) do
  if s.hp>0 then
   local wx,wy,wz=get_subsys_pos(s)
   local vx,vy,vz=to_cam_space(wx,wy,wz)
   if vz>1 then
    local sx,sy=proj(vx,vy,vz)
    local sz=max(4,20/vz)
    local is_target=(s==target)
    draw_brackets(sx,sy,sz,is_target and 10 or 5)
    if is_target then
     local lbl=s.stype=="weapon" and "WPN" or "RCT"
     print(lbl,sx-6,sy+sz+2,10)
    end
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
