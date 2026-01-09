pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 3d space combat
-- flat shaded rendering

-- globals
cam={x=0,y=0,z=-50}
cam_rot={x=0,y=0,z=0}
player=nil
enemies={}
bullets={}
particles={}
stars={}
explosions={}
score=0
health=100
game_state="title"
wave=1
spawn_timer=0

-- ui controls
mouse_x=64
mouse_y=64
mouse_btn=false
mouse_prev=false
roll_mode=false -- false=yaw, true=roll
target_throttle=0
throttle_dragging=false

-- enable mouse
poke(0x5f2d,1)

-- 3d math functions
function v3_add(a,b)
 return {x=a.x+b.x,y=a.y+b.y,z=a.z+b.z}
end

function v3_sub(a,b)
 return {x=a.x-b.x,y=a.y-b.y,z=a.z-b.z}
end

function v3_mul(v,s)
 return {x=v.x*s,y=v.y*s,z=v.z*s}
end

function v3_dot(a,b)
 return a.x*b.x+a.y*b.y+a.z*b.z
end

function v3_cross(a,b)
 return {
  x=a.y*b.z-a.z*b.y,
  y=a.z*b.x-a.x*b.z,
  z=a.x*b.y-a.y*b.x
 }
end

function v3_len(v)
 return sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
end

function v3_norm(v)
 local l=v3_len(v)
 if l==0 then return {x=0,y=0,z=1} end
 return {x=v.x/l,y=v.y/l,z=v.z/l}
end

-- rotation functions
function rot_x(v,a)
 local c,s=cos(a),sin(a)
 return {
  x=v.x,
  y=v.y*c-v.z*s,
  z=v.y*s+v.z*c
 }
end

function rot_y(v,a)
 local c,s=cos(a),sin(a)
 return {
  x=v.x*c+v.z*s,
  y=v.y,
  z=-v.x*s+v.z*c
 }
end

function rot_z(v,a)
 local c,s=cos(a),sin(a)
 return {
  x=v.x*c-v.y*s,
  y=v.x*s+v.y*c,
  z=v.z
 }
end

-- apply full rotation
function rotate(v,rx,ry,rz)
 local r=rot_x(v,rx)
 r=rot_y(r,ry)
 r=rot_z(r,rz)
 return r
end

-- project 3d to 2d
function project(v)
 local fov=90
 local d=v.z
 if d<1 then d=1 end
 local sx=64+(v.x*fov)/d
 local sy=64-(v.y*fov)/d
 return {x=sx,y=sy,z=d}
end

-- check if point is in rect
function point_in_rect(px,py,x1,y1,x2,y2)
 return px>=x1 and px<=x2 and py>=y1 and py<=y2
end

-- ship models (vertices and faces)
-- player fighter ship
function make_player_ship()
 local verts={
  -- main fuselage
  {x=0,y=0,z=8},    -- 1 nose
  {x=-3,y=1,z=-4},  -- 2 back left top
  {x=3,y=1,z=-4},   -- 3 back right top
  {x=-3,y=-1,z=-4}, -- 4 back left bot
  {x=3,y=-1,z=-4},  -- 5 back right bot
  {x=0,y=0,z=-6},   -- 6 tail
  -- left wing
  {x=-8,y=0,z=-2},  -- 7 left tip
  {x=-3,y=0,z=0},   -- 8 left inner
  {x=-3,y=0,z=-3},  -- 9 left back
  -- right wing
  {x=8,y=0,z=-2},   -- 10 right tip
  {x=3,y=0,z=0},    -- 11 right inner
  {x=3,y=0,z=-3},   -- 12 right back
  -- cockpit
  {x=0,y=1.5,z=2},  -- 13 cockpit top
 }
 -- faces: {v1,v2,v3,color}
 local faces={
  -- main body top
  {1,3,2,12},
  {2,3,6,5},
  -- main body bottom
  {1,4,5,1},
  {4,6,5,1},
  -- main body sides
  {1,2,4,13},
  {1,5,3,13},
  -- left wing top
  {7,8,9,11},
  {8,7,9,1},
  -- right wing top
  {10,12,11,11},
  {11,12,10,1},
  -- cockpit
  {1,13,2,8},
  {1,3,13,8},
  -- engine back
  {2,6,4,8},
  {3,5,6,8},
 }
 return {verts=verts,faces=faces}
end

-- enemy fighter
function make_enemy_ship()
 local verts={
  -- aggressive angular design
  {x=0,y=0,z=6},    -- 1 nose
  {x=-4,y=0,z=-4},  -- 2 back left
  {x=4,y=0,z=-4},   -- 3 back right
  {x=0,y=2,z=-2},   -- 4 top
  {x=0,y=-2,z=-2},  -- 5 bottom
  {x=0,y=0,z=-5},   -- 6 tail
  -- wing spikes
  {x=-6,y=0,z=0},   -- 7 left spike
  {x=6,y=0,z=0},    -- 8 right spike
 }
 local faces={
  -- top faces
  {1,4,2,8},
  {1,3,4,8},
  {4,3,6,5},
  {4,6,2,5},
  -- bottom faces
  {1,2,5,2},
  {1,5,3,2},
  {5,6,3,1},
  {5,2,6,1},
  -- left wing
  {7,2,1,9},
  {7,1,2,1},
  -- right wing
  {8,1,3,9},
  {8,3,1,1},
 }
 return {verts=verts,faces=faces}
end

-- heavy enemy ship
function make_heavy_ship()
 local verts={
  -- boxy heavy design
  {x=0,y=0,z=5},    -- 1 nose
  {x=-5,y=2,z=-5},  -- 2 back left top
  {x=5,y=2,z=-5},   -- 3 back right top
  {x=-5,y=-2,z=-5}, -- 4 back left bot
  {x=5,y=-2,z=-5},  -- 5 back right bot
  {x=0,y=3,z=-2},   -- 6 top fin
  -- guns
  {x=-3,y=0,z=3},   -- 7 left gun
  {x=3,y=0,z=3},    -- 8 right gun
 }
 local faces={
  -- front panels
  {1,2,4,5},
  {1,5,3,5},
  {1,3,2,6},
  {1,4,5,1},
  -- back
  {2,3,5,1},
  {2,5,4,1},
  -- top fin
  {6,2,3,8},
  -- guns
  {7,1,2,9},
  {8,3,1,9},
 }
 return {verts=verts,faces=faces}
end

-- initialize game
function _init()
 -- create stars
 for i=1,80 do
  add(stars,{
   x=rnd(256)-128,
   y=rnd(256)-128,
   z=rnd(200)+50
  })
 end

 init_game()
end

function init_game()
 player={
  x=0,y=0,z=0,
  rx=0,ry=0,rz=0,
  vx=0,vy=0,vz=0,
  speed=0,
  model=make_player_ship(),
  fire_cooldown=0,
  shield=0
 }
 enemies={}
 bullets={}
 particles={}
 explosions={}
 score=0
 health=100
 wave=1
 spawn_timer=60
 cam={x=0,y=3,z=-20}
 target_throttle=0
 roll_mode=false
end

-- spawn enemies
function spawn_enemy(etype)
 local e={
  x=rnd(100)-50,
  y=rnd(60)-30,
  z=rnd(100)+80,
  rx=0,ry=0.5,rz=0,
  vx=0,vy=0,vz=0,
  health=etype==2 and 50 or 20,
  fire_cooldown=rnd(60)+30,
  model=etype==2 and make_heavy_ship() or make_enemy_ship(),
  etype=etype,
  ai_timer=rnd(30)
 }
 add(enemies,e)
end

-- game update
function _update60()
 -- update mouse
 mouse_prev=mouse_btn
 mouse_x=stat(32)
 mouse_y=stat(33)
 mouse_btn=stat(34)>0

 if game_state=="title" then
  if btnp(4) or btnp(5) or (mouse_btn and not mouse_prev) then
   game_state="play"
   init_game()
  end
 elseif game_state=="play" then
  update_ui()
  update_game()
 elseif game_state=="gameover" then
  if btnp(4) or btnp(5) or (mouse_btn and not mouse_prev) then
   game_state="title"
  end
 end
end

function update_ui()
 -- throttle slider (right side: 120,30 to 120,90)
 local throttle_x=118
 local throttle_y1=25
 local throttle_y2=85

 -- check if clicking throttle area
 if mouse_btn then
  if point_in_rect(mouse_x,mouse_y,throttle_x-8,throttle_y1-5,throttle_x+8,throttle_y2+5) then
   throttle_dragging=true
  end
 else
  throttle_dragging=false
 end

 -- drag throttle
 if throttle_dragging then
  local y=mid(throttle_y1,mouse_y,throttle_y2)
  target_throttle=1-((y-throttle_y1)/(throttle_y2-throttle_y1))
 end

 -- yaw/roll toggle button (bottom left: 5,95 to 35,108)
 local toggle_x1=5
 local toggle_y1=92
 local toggle_x2=38
 local toggle_y2=105

 if mouse_btn and not mouse_prev then
  if point_in_rect(mouse_x,mouse_y,toggle_x1,toggle_y1,toggle_x2,toggle_y2) then
   roll_mode=not roll_mode
  end
 end

 -- fire button (bottom center: 50,100 to 78,115)
 local fire_x1=50
 local fire_y1=100
 local fire_x2=78
 local fire_y2=115

 if mouse_btn then
  if point_in_rect(mouse_x,mouse_y,fire_x1,fire_y1,fire_x2,fire_y2) then
   if player.fire_cooldown==0 then
    fire_bullet(player,true)
    player.fire_cooldown=8
    sfx(0)
   end
  end
 end
end

function update_game()
 -- player controls
 local turn_speed=0.015
 local max_speed=1.5

 -- pitch (up/down arrows)
 if btn(2) then player.rx-=turn_speed end
 if btn(3) then player.rx+=turn_speed end

 -- yaw or roll (left/right arrows based on mode)
 if roll_mode then
  -- roll mode
  if btn(0) then player.rz+=turn_speed end
  if btn(1) then player.rz-=turn_speed end
 else
  -- yaw mode (default)
  if btn(0) then player.ry+=turn_speed end
  if btn(1) then player.ry-=turn_speed end
 end

 -- smooth throttle response
 local throttle_lerp=0.05
 player.speed+=(target_throttle*max_speed-player.speed)*throttle_lerp

 -- keyboard thrust override (X button)
 if btn(5) then
  target_throttle=min(target_throttle+0.02,1)
 end

 -- keyboard brake (Z without directions)
 if btn(4) and not btn(0) and not btn(1) and not btn(2) and not btn(3) then
  -- fire instead of brake
  if player.fire_cooldown==0 then
   fire_bullet(player,true)
   player.fire_cooldown=8
   sfx(0)
  end
 end

 -- calculate forward vector
 local fwd={x=0,y=0,z=1}
 fwd=rotate(fwd,player.rx,player.ry,player.rz)

 -- apply velocity
 player.vx=fwd.x*player.speed
 player.vy=fwd.y*player.speed
 player.vz=fwd.z*player.speed

 player.x+=player.vx
 player.y+=player.vy
 player.z+=player.vz

 -- firing cooldown
 player.fire_cooldown=max(0,player.fire_cooldown-1)

 -- update camera (follow player)
 local cam_offset={x=0,y=3,z=-18}
 cam_offset=rotate(cam_offset,player.rx,player.ry,player.rz)
 cam.x=player.x+cam_offset.x
 cam.y=player.y+cam_offset.y
 cam.z=player.z+cam_offset.z
 cam_rot.x=player.rx
 cam_rot.y=player.ry
 cam_rot.z=player.rz

 -- update enemies
 update_enemies()

 -- update bullets
 update_bullets()

 -- update particles
 update_particles()

 -- update explosions
 update_explosions()

 -- spawn enemies
 spawn_timer-=1
 if spawn_timer<=0 and #enemies<5+wave then
  spawn_enemy(rnd(10)<3 and 2 or 1)
  spawn_timer=90-min(wave*5,50)
 end

 -- shield decay
 player.shield=max(0,player.shield-0.5)

 -- check game over
 if health<=0 then
  game_state="gameover"
  create_explosion(player.x,player.y,player.z,20)
 end
end

function update_enemies()
 for e in all(enemies) do
  -- ai behavior
  e.ai_timer-=1
  if e.ai_timer<=0 then
   -- recalculate direction to player
   local dx=player.x-e.x
   local dy=player.y-e.y
   local dz=player.z-e.z
   local dist=sqrt(dx*dx+dy*dy+dz*dz)

   if dist>0 then
    -- adjust rotation to face player
    e.ry=atan2(dx,dz)
    e.rx=-atan2(dy,sqrt(dx*dx+dz*dz))*0.5
   end

   e.ai_timer=20+rnd(30)
  end

  -- move forward
  local fwd={x=0,y=0,z=1}
  fwd=rotate(fwd,e.rx,e.ry,e.rz)
  local spd=e.etype==2 and 0.3 or 0.5

  e.x+=fwd.x*spd
  e.y+=fwd.y*spd
  e.z+=fwd.z*spd

  -- firing
  e.fire_cooldown-=1
  if e.fire_cooldown<=0 then
   local dx=player.x-e.x
   local dy=player.y-e.y
   local dz=player.z-e.z
   local dist=sqrt(dx*dx+dy*dy+dz*dz)

   if dist<150 then
    fire_bullet(e,false)
    e.fire_cooldown=e.etype==2 and 20 or 40
    sfx(1)
   else
    e.fire_cooldown=10
   end
  end

  -- remove if too far
  local dx=e.x-player.x
  local dy=e.y-player.y
  local dz=e.z-player.z
  if dx*dx+dy*dy+dz*dz>40000 then
   del(enemies,e)
  end
 end
end

function fire_bullet(source,is_player)
 local fwd={x=0,y=0,z=1}
 fwd=rotate(fwd,source.rx,source.ry,source.rz)
 local spd=is_player and 3 or 1.5

 add(bullets,{
  x=source.x+fwd.x*5,
  y=source.y+fwd.y*5,
  z=source.z+fwd.z*5,
  vx=fwd.x*spd+(source.vx or 0),
  vy=fwd.y*spd+(source.vy or 0),
  vz=fwd.z*spd+(source.vz or 0),
  is_player=is_player,
  life=120,
  col=is_player and 11 or 8
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
  else
   -- collision check
   if b.is_player then
    -- check enemy hits
    for e in all(enemies) do
     local dx=b.x-e.x
     local dy=b.y-e.y
     local dz=b.z-e.z
     if dx*dx+dy*dy+dz*dz<64 then
      e.health-=10
      create_particles(b.x,b.y,b.z,5,9)
      del(bullets,b)
      sfx(2)

      if e.health<=0 then
       create_explosion(e.x,e.y,e.z,15)
       score+=e.etype==2 and 200 or 100
       del(enemies,e)
       sfx(3)
       -- wave progression
       if #enemies==0 then
        wave+=1
       end
      end
      break
     end
    end
   else
    -- check player hit
    local dx=b.x-player.x
    local dy=b.y-player.y
    local dz=b.z-player.z
    if dx*dx+dy*dy+dz*dz<36 then
     if player.shield<=0 then
      health-=10
      create_particles(player.x,player.y,player.z,8,8)
      sfx(2)
     end
     del(bullets,b)
    end
   end
  end
 end
end

function create_particles(x,y,z,count,col)
 for i=1,count do
  add(particles,{
   x=x,y=y,z=z,
   vx=rnd(2)-1,
   vy=rnd(2)-1,
   vz=rnd(2)-1,
   life=20+rnd(20),
   col=col
  })
 end
end

function create_explosion(x,y,z,size)
 add(explosions,{
  x=x,y=y,z=z,
  size=0,
  max_size=size,
  growing=true
 })
 create_particles(x,y,z,size,10)
 create_particles(x,y,z,size,9)
 create_particles(x,y,z,size,8)
end

function update_particles()
 for p in all(particles) do
  p.x+=p.vx
  p.y+=p.vy
  p.z+=p.vz
  p.vx*=0.95
  p.vy*=0.95
  p.vz*=0.95
  p.life-=1
  if p.life<=0 then
   del(particles,p)
  end
 end
end

function update_explosions()
 for e in all(explosions) do
  if e.growing then
   e.size+=1
   if e.size>=e.max_size then
    e.growing=false
   end
  else
   e.size-=0.5
   if e.size<=0 then
    del(explosions,e)
   end
  end
 end
end

-- rendering
function _draw()
 cls(0)

 if game_state=="title" then
  draw_title()
 elseif game_state=="play" then
  draw_game()
 elseif game_state=="gameover" then
  draw_game()
  draw_gameover()
 end
end

function draw_title()
 -- draw some stars
 for s in all(stars) do
  local sp=project(s)
  if sp.z>0 and sp.x>=0 and sp.x<128 and sp.y>=0 and sp.y<128 then
   pset(sp.x,sp.y,7)
  end
 end

 -- title
 print("space combat 3d",28,30,11)
 print("---------------",28,38,5)
 print("arrows: pitch+yaw/roll",14,52,6)
 print("x: increase throttle",18,60,6)
 print("z: fire weapons",26,68,6)
 print("click throttle slider",14,80,13)
 print("click yaw/roll toggle",14,88,13)
 print("click or press to start",11,105,10)
end

function draw_game()
 -- draw stars (background)
 draw_stars()

 -- collect all faces to render
 local all_faces={}

 -- add player ship faces (slightly in front of camera)
 add_ship_faces(all_faces,player,true)

 -- add enemy faces
 for e in all(enemies) do
  add_ship_faces(all_faces,e,false)
 end

 -- sort by depth (back to front)
 sort_faces(all_faces)

 -- render faces
 for f in all(all_faces) do
  draw_face(f)
 end

 -- draw bullets
 draw_bullets()

 -- draw particles
 draw_particles()

 -- draw explosions
 draw_explosions()

 -- draw hud
 draw_hud()

 -- draw ui controls
 draw_ui_controls()
end

function draw_stars()
 for s in all(stars) do
  -- transform star relative to camera
  local rel={
   x=s.x-cam.x,
   y=s.y-cam.y,
   z=s.z-cam.z
  }

  -- wrap stars
  while rel.z<0 do rel.z+=200 end
  while rel.z>200 do rel.z-=200 end
  while rel.x<-128 do rel.x+=256 end
  while rel.x>128 do rel.x-=256 end
  while rel.y<-128 do rel.y+=256 end
  while rel.y>128 do rel.y-=256 end

  -- apply camera rotation (inverse)
  rel=rotate(rel,-cam_rot.x,-cam_rot.y,-cam_rot.z)

  if rel.z>1 then
   local sp=project(rel)
   if sp.x>=0 and sp.x<128 and sp.y>=0 and sp.y<128 then
    local col=rel.z<50 and 7 or (rel.z<100 and 6 or 5)
    pset(sp.x,sp.y,col)
   end
  end
 end
end

function add_ship_faces(all_faces,ship,is_player)
 local model=ship.model
 local transformed={}

 -- transform vertices
 for i,v in pairs(model.verts) do
  -- rotate by ship orientation
  local tv=rotate(v,ship.rx,ship.ry,ship.rz)
  -- translate to world position
  tv.x+=ship.x
  tv.y+=ship.y
  tv.z+=ship.z
  -- transform relative to camera
  tv.x-=cam.x
  tv.y-=cam.y
  tv.z-=cam.z
  -- apply inverse camera rotation
  tv=rotate(tv,-cam_rot.x,-cam_rot.y,-cam_rot.z)
  transformed[i]=tv
 end

 -- process faces
 for f in all(model.faces) do
  local v1=transformed[f[1]]
  local v2=transformed[f[2]]
  local v3=transformed[f[3]]

  -- skip faces behind camera
  if v1.z>1 and v2.z>1 and v3.z>1 then
   -- calculate face normal for backface culling and lighting
   local e1=v3_sub(v2,v1)
   local e2=v3_sub(v3,v1)
   local normal=v3_cross(e1,e2)
   normal=v3_norm(normal)

   -- view direction (face center to camera)
   local center={
    x=(v1.x+v2.x+v3.x)/3,
    y=(v1.y+v2.y+v3.y)/3,
    z=(v1.z+v2.z+v3.z)/3
   }

   -- backface culling
   local view_dot=v3_dot(normal,v3_norm(center))
   if view_dot<0 then
    -- project vertices
    local p1=project(v1)
    local p2=project(v2)
    local p3=project(v3)

    -- lighting (sun direction)
    local sun={x=0.5,y=0.7,z=-0.5}
    sun=v3_norm(sun)
    local light=v3_dot(normal,sun)
    light=(light+1)/2 -- normalize to 0-1

    -- calculate shaded color
    local base_col=f[4]
    local shaded_col=shade_color(base_col,light)

    add(all_faces,{
     p1=p1,p2=p2,p3=p3,
     depth=center.z,
     col=shaded_col,
     is_player=is_player
    })
   end
  end
 end
end

-- shade color based on light
function shade_color(col,light)
 -- pico-8 color ramps
 local ramps={
  [1]={0,0,1},
  [2]={0,1,2},
  [3]={1,3,11},
  [4]={2,4,4},
  [5]={1,5,6},
  [6]={5,6,7},
  [7]={6,7,7},
  [8]={2,8,14},
  [9]={4,9,10},
  [10]={9,10,10},
  [11]={3,11,11},
  [12]={1,12,12},
  [13]={5,13,6},
  [14]={8,14,14},
  [15]={6,7,15}
 }

 local ramp=ramps[col] or {col,col,col}
 local idx=flr(light*2.99)+1
 return ramp[min(idx,3)]
end

-- simple insertion sort for faces
function sort_faces(faces)
 for i=2,#faces do
  local j=i
  while j>1 and faces[j].depth>faces[j-1].depth do
   faces[j],faces[j-1]=faces[j-1],faces[j]
   j-=1
  end
 end
end

-- draw a filled triangle
function draw_face(f)
 local x1,y1=f.p1.x,f.p1.y
 local x2,y2=f.p2.x,f.p2.y
 local x3,y3=f.p3.x,f.p3.y

 -- simple bounds check
 if (x1<0 and x2<0 and x3<0) or
    (x1>127 and x2>127 and x3>127) or
    (y1<0 and y2<0 and y3<0) or
    (y1>127 and y2>127 and y3>127) then
  return
 end

 -- use trifill
 trifill(x1,y1,x2,y2,x3,y3,f.col)
end

-- filled triangle function
function trifill(x1,y1,x2,y2,x3,y3,col)
 -- sort by y
 if y1>y2 then x1,y1,x2,y2=x2,y2,x1,y1 end
 if y1>y3 then x1,y1,x3,y3=x3,y3,x1,y1 end
 if y2>y3 then x2,y2,x3,y3=x3,y3,x2,y2 end

 if y3==y1 then
  line(x1,y1,x3,y3,col)
  return
 end

 -- draw triangle
 local dx1=(x3-x1)/(y3-y1)
 local dx2,dy2

 if y2~=y1 then
  dx2=(x2-x1)/(y2-y1)
  for y=y1,y2 do
   local xa=x1+(y-y1)*dx1
   local xb=x1+(y-y1)*dx2
   if xa>xb then xa,xb=xb,xa end
   rectfill(xa,y,xb,y,col)
  end
 end

 if y3~=y2 then
  dx2=(x3-x2)/(y3-y2)
  for y=y2,y3 do
   local xa=x1+(y-y1)*dx1
   local xb=x2+(y-y2)*dx2
   if xa>xb then xa,xb=xb,xa end
   rectfill(xa,y,xb,y,col)
  end
 end
end

function draw_bullets()
 for b in all(bullets) do
  -- transform bullet
  local rel={
   x=b.x-cam.x,
   y=b.y-cam.y,
   z=b.z-cam.z
  }
  rel=rotate(rel,-cam_rot.x,-cam_rot.y,-cam_rot.z)

  if rel.z>1 then
   local sp=project(rel)
   if sp.x>=0 and sp.x<128 and sp.y>=0 and sp.y<128 then
    local size=max(1,4/sp.z)
    circfill(sp.x,sp.y,size,b.col)
   end
  end
 end
end

function draw_particles()
 for p in all(particles) do
  local rel={
   x=p.x-cam.x,
   y=p.y-cam.y,
   z=p.z-cam.z
  }
  rel=rotate(rel,-cam_rot.x,-cam_rot.y,-cam_rot.z)

  if rel.z>1 then
   local sp=project(rel)
   if sp.x>=0 and sp.x<128 and sp.y>=0 and sp.y<128 then
    pset(sp.x,sp.y,p.col)
   end
  end
 end
end

function draw_explosions()
 for e in all(explosions) do
  local rel={
   x=e.x-cam.x,
   y=e.y-cam.y,
   z=e.z-cam.z
  }
  rel=rotate(rel,-cam_rot.x,-cam_rot.y,-cam_rot.z)

  if rel.z>1 then
   local sp=project(rel)
   local size=e.size*5/rel.z
   if sp.x>=-size and sp.x<128+size and sp.y>=-size and sp.y<128+size then
    -- multi-layer explosion
    circfill(sp.x,sp.y,size,10)
    circfill(sp.x,sp.y,size*0.7,9)
    circfill(sp.x,sp.y,size*0.4,8)
   end
  end
 end
end

function draw_hud()
 -- health bar
 rectfill(4,4,34,8,0)
 rectfill(5,5,5+health*0.28,7,health>30 and 11 or 8)
 rect(4,4,34,8,7)
 print("hull",5,10,7)

 -- shield indicator
 if player.shield>0 then
  rect(3,3,35,9,12)
 end

 -- score
 print("score:"..score,60,5,7)

 -- wave
 print("wave:"..wave,90,5,6)

 -- targeting reticle
 circ(64,64,10,3)
 line(64,50,64,58,3)
 line(64,70,64,78,3)
 line(50,64,58,64,3)
 line(70,64,78,64,3)

 -- enemy indicator arrows
 for e in all(enemies) do
  local rel={
   x=e.x-cam.x,
   y=e.y-cam.y,
   z=e.z-cam.z
  }
  rel=rotate(rel,-cam_rot.x,-cam_rot.y,-cam_rot.z)

  -- if enemy is behind or off-screen, show arrow
  if rel.z<5 or rel.z>150 then
   local angle=atan2(rel.x,rel.z)
   local ax=64+cos(angle)*50
   local ay=64-sin(angle)*50
   circfill(ax,ay,3,8)
  end
 end
end

function draw_ui_controls()
 -- throttle slider (right side)
 local throttle_x=118
 local throttle_y1=25
 local throttle_y2=85

 -- track
 rectfill(throttle_x-2,throttle_y1,throttle_x+2,throttle_y2,1)
 rect(throttle_x-3,throttle_y1-1,throttle_x+3,throttle_y2+1,5)

 -- fill based on throttle
 local fill_y=throttle_y2-target_throttle*(throttle_y2-throttle_y1)
 rectfill(throttle_x-2,fill_y,throttle_x+2,throttle_y2,11)

 -- handle
 local handle_y=throttle_y2-target_throttle*(throttle_y2-throttle_y1)
 rectfill(throttle_x-5,handle_y-2,throttle_x+5,handle_y+2,throttle_dragging and 10 or 7)
 rect(throttle_x-5,handle_y-2,throttle_x+5,handle_y+2,6)

 -- throttle label
 print("thr",113,throttle_y2+5,5)
 print(flr(target_throttle*100).."%",110,throttle_y2+12,7)

 -- yaw/roll toggle button
 local toggle_x1=5
 local toggle_y1=92
 local toggle_x2=38
 local toggle_y2=105

 -- button background
 local btn_col=roll_mode and 8 or 12
 local hover=point_in_rect(mouse_x,mouse_y,toggle_x1,toggle_y1,toggle_x2,toggle_y2)
 rectfill(toggle_x1,toggle_y1,toggle_x2,toggle_y2,hover and btn_col+1 or btn_col)
 rect(toggle_x1,toggle_y1,toggle_x2,toggle_y2,7)

 -- button text
 local mode_text=roll_mode and "roll" or "yaw"
 print(mode_text,14,96,0)

 -- fire button
 local fire_x1=50
 local fire_y1=100
 local fire_x2=78
 local fire_y2=115

 local fire_hover=point_in_rect(mouse_x,mouse_y,fire_x1,fire_y1,fire_x2,fire_y2)
 rectfill(fire_x1,fire_y1,fire_x2,fire_y2,fire_hover and 9 or 8)
 rect(fire_x1,fire_y1,fire_x2,fire_y2,7)
 print("fire",55,105,0)

 -- mouse cursor
 pset(mouse_x,mouse_y,7)
 pset(mouse_x+1,mouse_y,7)
 pset(mouse_x-1,mouse_y,7)
 pset(mouse_x,mouse_y+1,7)
 pset(mouse_x,mouse_y-1,7)
end

function draw_gameover()
 rectfill(24,50,104,78,0)
 rect(24,50,104,78,8)
 print("game over",42,55,8)
 print("score: "..score,38,65,7)
 print("click to restart",30,85,6)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00030000190301c03020030250302a0302e030310303503037030370303600033000300002e0002b00027000230001e00019000140000f0000a0000500000000000000000000000000000000000000000000000000
000300001d0301d0301d0301b0301b030190301903017030150301303011030110300f0300d0300b030090300903007030050300303001030010300000000000000000000000000000000000000000000000000000
000200000c5300c5300a520085100650004500025000150000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000
001000002c0502c0502a050280502604024040210401e0401b04017040130400f0400c040090400604003040010400004000040000400004000040000400004000040000400004000040000400004000040000400
