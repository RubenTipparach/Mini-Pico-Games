pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 3d sailing game
-- flat shaded with animated water

-- game state
boat_x,boat_z=0,0
boat_vx,boat_vz=0,0
boat_rot=0 -- boat heading
sail_ang=0 -- sail angle (relative to boat)
boat_speed=0

-- camera (orbits around boat)
cam_ang=0.25 -- camera angle around boat
cam_dist=40
cam_height=25

-- wind
wind_ang=0.1 -- wind direction (0-1)
wind_spd=0.8 -- wind strength
wind_t=0

-- water grid
water_size=4 -- tiles per side (4x4=32 triangles)
water_scale=48 -- world units per tile (larger to compensate)

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

-- rotation functions
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

-- camera
cx,cy,cz=0,25,-40
c_fwd={0,0,1}
c_rgt={1,0,0}
c_up={0,1,0}

function update_cam()
 -- camera orbits around boat
 local ang=cam_ang
 cx=boat_x+sin(ang)*cam_dist
 cy=cam_height
 cz=boat_z+cos(ang)*cam_dist

 -- look at boat
 local dx,dy,dz=boat_x-cx,4-cy,boat_z-cz
 local l=sqrt(dx*dx+dy*dy+dz*dz)
 if l>0 then
  c_fwd={dx/l,dy/l,dz/l}
 end

 -- right vector (cross up with fwd)
 c_rgt={c_fwd[3],0,-c_fwd[1]}
 l=sqrt(c_rgt[1]*c_rgt[1]+c_rgt[3]*c_rgt[3])
 if l>0 then
  c_rgt[1]/=l
  c_rgt[3]/=l
 end

 -- up vector (cross fwd with rgt)
 c_up=v_cross(c_fwd,c_rgt)
end

-- transform to camera space
function to_cam(wx,wy,wz)
 local rx=wx-cx
 local ry=wy-cy
 local rz=wz-cz
 return
  rx*c_rgt[1]+ry*c_rgt[2]+rz*c_rgt[3],
  rx*c_up[1]+ry*c_up[2]+rz*c_up[3],
  rx*c_fwd[1]+ry*c_fwd[2]+rz*c_fwd[3]
end

function proj(x,y,z)
 if z<1 then z=1 end
 return 64+x*90/z,64-y*90/z,z
end

-- boat vertices (hull)
hull_v={
 -- bow (front)
 {0,1,6},
 -- stern (back)
 {-2.5,1,-4},{2.5,1,-4},
 -- bottom
 {0,-1,-3},
 -- sides
 {-3,0,0},{3,0,0},
 -- deck points
 {-2,1,2},{2,1,2}
}

hull_f={
 -- deck
 {1,7,2,12},{1,8,7,12},{1,3,8,12},{2,7,8,12},{2,8,3,12},
 -- port side
 {1,5,7,1},{7,5,2,1},{5,4,2,1},
 -- starboard side
 {1,8,6,1},{8,3,6,1},{6,3,4,1},
 -- bow bottom
 {1,4,5,2},{1,6,4,2},
 -- stern
 {2,4,3,5},{4,2,3,5}
}

-- mast
mast_v={
 {0,1,0},{0,12,0}
}

function _init()
 -- nothing special
end

function _update60()
 -- camera rotation (arrows)
 if btn(0) then cam_ang-=0.01 end
 if btn(1) then cam_ang+=0.01 end

 -- sail rotation (z/x buttons)
 if btn(4) then sail_ang-=0.015 end
 if btn(5) then sail_ang+=0.015 end
 sail_ang=mid(-0.2,sail_ang,0.2)

 -- wind changes slowly
 wind_t+=0.003
 wind_ang=0.15+sin(wind_t*0.5)*0.1
 wind_spd=0.6+sin(wind_t*0.3)*0.2

 -- sailing physics
 update_sailing()

 -- update camera
 update_cam()
end

function update_sailing()
 -- calculate effective sail angle to wind
 -- wind_ang is absolute direction (0=+z)
 -- boat_rot is boat heading
 -- sail_ang is sail relative to boat

 -- apparent wind relative to boat
 local rel_wind=wind_ang-boat_rot
 while rel_wind<0 do rel_wind+=1 end
 while rel_wind>=1 do rel_wind-=1 end

 -- sail angle in world
 local abs_sail=boat_rot+sail_ang

 -- wind vector
 local wx=sin(wind_ang)*wind_spd
 local wz=cos(wind_ang)*wind_spd

 -- boat forward vector
 local bfx=sin(boat_rot)
 local bfz=cos(boat_rot)

 -- sail normal (perpendicular to sail)
 local snx=sin(abs_sail+0.25)
 local snz=cos(abs_sail+0.25)

 -- force = wind dot sail_normal
 local force=wx*snx+wz*snz

 -- project force onto boat forward
 local fwd_force=force*(bfx*snx+bfz*snz)

 -- can't sail directly into wind
 -- check if close-hauled (within ~45 degrees)
 local wind_diff=abs(rel_wind-0.5)
 if wind_diff>0.35 then
  -- too close to wind, reduce power
  fwd_force*=max(0,(0.5-wind_diff)*3)
 end

 -- apply force
 boat_speed+=fwd_force*0.02

 -- drag
 boat_speed*=0.995
 boat_speed=mid(-0.5,boat_speed,1.5)

 -- move boat
 boat_vx=bfx*boat_speed
 boat_vz=bfz*boat_speed
 boat_x+=boat_vx
 boat_z+=boat_vz

 -- slight turning based on sail
 boat_rot+=sail_ang*boat_speed*0.01
end

function _draw()
 cls(0)

 -- sky gradient
 for y=0,40 do
  local c=12
  if y<15 then c=7
  elseif y<30 then c=12 end
  line(0,y,127,y,c)
 end

 -- draw voxel water (no sorting needed)
 draw_water_voxels()

 -- collect boat faces
 local faces={}
 add_boat(faces)

 -- sort boat faces by depth
 sort_faces(faces)

 -- render boat
 for f in all(faces) do
  trifill(f[1],f[2],f[3],f[4],f[5],f[6],f[7])
 end

 -- draw mast and sail (lines, always on top)
 draw_mast_sail()

 -- draw wind indicator
 draw_wind()

 -- draw HUD
 draw_hud()
end

function draw_water_voxels()
 -- fat pixel water with noise
 local t=time()*2
 local pix=4 -- fat pixel size

 -- draw from horizon down
 for sy=41,127,pix do
  for sx=0,127,pix do
   -- cast ray from screen to water plane
   -- approximate: further up screen = further away
   local depth=(sy-40)*2
   if depth>5 then
    -- world position from screen
    local ang=cam_ang
    local ray_x=(sx-64)/90*depth
    local ray_z=depth

    -- rotate by camera angle
    local wx=boat_x+ray_x*cos(ang)+ray_z*sin(ang)
    local wz=boat_z-ray_x*sin(ang)+ray_z*cos(ang)

    -- wave height affects y
    local wy=get_wave(wx,wz,t)

    -- noise for color variation
    local noise=sin(wx*0.1+t*0.5)+sin(wz*0.13+t*0.3)+sin((wx+wz)*0.07)
    noise+=wy*0.5 -- wave height affects color

    -- pick blue shade based on noise
    local col
    if noise>1.2 then
     col=7 -- white foam
    elseif noise>0.3 then
     col=12 -- light blue
    elseif noise>-0.5 then
     col=1 -- dark blue
    else
     col=129 -- darker blue (dark blue alt)
    end

    -- draw fat pixel
    rectfill(sx,sy,sx+pix-1,sy+pix-1,col)
   end
  end
 end
end

function get_wave(x,z,t)
 -- combine multiple sine waves
 local h=0
 h+=sin((x*0.05+t*0.3))*0.8
 h+=sin((z*0.07+t*0.2))*0.6
 h+=sin((x*0.03+z*0.04+t*0.25))*0.4
 return h
end

function water_shade(l)
 -- blue shading ramp
 if l<0.3 then return 1  -- dark blue
 elseif l<0.6 then return 12 -- light blue
 else return 6 end -- light gray/white (foam)
end

function add_boat(faces)
 -- transform hull
 local tv={}
 for i,v in pairs(hull_v) do
  -- rotate by boat heading
  local x,y,z=roty(v[1],v[2],v[3],boat_rot)
  -- translate to boat position
  x+=boat_x
  z+=boat_z
  -- add bob
  y+=get_wave(boat_x,boat_z,time()*2)*0.5+2
  -- to camera space
  x,y,z=to_cam(x,y,z)
  tv[i]={x,y,z}
 end

 -- add faces
 for f in all(hull_f) do
  local v1=tv[f[1]]
  local v2=tv[f[2]]
  local v3=tv[f[3]]

  if v1[3]>1 and v2[3]>1 and v3[3]>1 then
   local e1=v_sub(v2,v1)
   local e2=v_sub(v3,v1)
   local n=v_norm(v_cross(e1,e2))

   local ctr={(v1[1]+v2[1]+v3[1])/3,
              (v1[2]+v2[2]+v3[2])/3,
              (v1[3]+v2[3]+v3[3])/3}

   -- backface culling
   if v_dot(n,v_norm(ctr))<0 then
    local p1x,p1y=proj(v1[1],v1[2],v1[3])
    local p2x,p2y=proj(v2[1],v2[2],v2[3])
    local p3x,p3y=proj(v3[1],v3[2],v3[3])

    -- shading
    local sun={0.3,0.8,0.3}
    local light=(v_dot(n,sun)+1)/2
    local col=boat_shade(f[4],light)

    add(faces,{p1x,p1y,p2x,p2y,p3x,p3y,col,ctr[3]})
   end
  end
 end
end

function boat_shade(c,l)
 local r={
  [1]={0,1,1},    -- dark wood
  [2]={1,2,4},    -- shadow
  [5]={4,5,6},    -- medium wood
  [12]={1,12,7},  -- deck
  [9]={2,9,10}    -- accent
 }
 local ramp=r[c] or {c,c,c}
 return ramp[min(flr(l*2.99)+1,3)]
end

function draw_mast_sail()
 -- boat bob height
 local bob=get_wave(boat_x,boat_z,time()*2)*0.5+2

 -- mast base and top in world coords
 local mx,my,mz=boat_x,bob+1,boat_z
 local tx,ty,tz=boat_x,bob+12,boat_z

 -- transform
 local mx2,my2,mz2=to_cam(mx,my,mz)
 local tx2,ty2,tz2=to_cam(tx,ty,tz)

 if mz2>1 and tz2>1 then
  local msx,msy=proj(mx2,my2,mz2)
  local tsx,tsy=proj(tx2,ty2,tz2)

  -- draw mast
  line(msx,msy,tsx,tsy,4)

  -- sail (triangle from mast top)
  -- sail rotates with sail_ang relative to boat
  local abs_sail=boat_rot+sail_ang
  local s_dx=sin(abs_sail)*8
  local s_dz=cos(abs_sail)*8

  -- sail corners
  local s1x,s1y,s1z=boat_x,bob+11,boat_z
  local s2x,s2y,s2z=boat_x+s_dx,bob+3,boat_z+s_dz
  local s3x,s3y,s3z=boat_x-s_dx,bob+3,boat_z-s_dz

  -- transform sail points
  local sv1x,sv1y,sv1z=to_cam(s1x,s1y,s1z)
  local sv2x,sv2y,sv2z=to_cam(s2x,s2y,s2z)
  local sv3x,sv3y,sv3z=to_cam(s3x,s3y,s3z)

  if sv1z>1 and sv2z>1 and sv3z>1 then
   local sp1x,sp1y=proj(sv1x,sv1y,sv1z)
   local sp2x,sp2y=proj(sv2x,sv2y,sv2z)
   local sp3x,sp3y=proj(sv3x,sv3y,sv3z)

   -- fill sail (white with shading)
   trifill(sp1x,sp1y,sp2x,sp2y,sp3x,sp3y,7)

   -- sail outline
   line(sp1x,sp1y,sp2x,sp2y,6)
   line(sp1x,sp1y,sp3x,sp3y,6)
   line(sp2x,sp2y,sp3x,sp3y,6)
  end
 end
end

function draw_wind()
 -- 3D wind indicator arrows near boat
 local bob=get_wave(boat_x,boat_z,time()*2)*0.5+2

 -- wind direction vector
 local wdx=sin(wind_ang)
 local wdz=cos(wind_ang)

 -- draw multiple wind lines around boat
 for i=1,5 do
  -- offset position
  local ox=(i-3)*8
  local ox2,oz2=ox*cos(wind_ang+0.25),ox*sin(wind_ang+0.25)

  -- animate along wind direction
  local phase=(time()*2+i*0.3)%1
  local len=8

  -- start and end of wind line
  local p1x=boat_x+ox2-wdx*(10-phase*20)
  local p1z=boat_z+oz2-wdz*(10-phase*20)
  local p2x=p1x+wdx*len
  local p2z=p1z+wdz*len

  -- height varies
  local wy=bob+10+sin(time()+i)*2

  -- transform
  local v1x,v1y,v1z=to_cam(p1x,wy,p1z)
  local v2x,v2y,v2z=to_cam(p2x,wy,p2z)

  if v1z>1 and v2z>1 then
   local s1x,s1y=proj(v1x,v1y,v1z)
   local s2x,s2y=proj(v2x,v2y,v2z)

   -- fade based on phase
   local c=phase<0.5 and 13 or 6
   line(s1x,s1y,s2x,s2y,c)

   -- arrowhead
   if phase>0.3 and phase<0.8 then
    local ax=s2x-s1x
    local ay=s2y-s1y
    local al=sqrt(ax*ax+ay*ay)
    if al>0 then
     ax/=al ay/=al
     -- perpendicular
     local px,py=-ay,ax
     line(s2x,s2y,s2x-ax*3+px*2,s2y-ay*3+py*2,c)
     line(s2x,s2y,s2x-ax*3-px*2,s2y-ay*3-py*2,c)
    end
   end
  end
 end
end

function draw_hud()
 -- speed indicator
 rectfill(2,2,50,10,1)
 print("spd:"..flr(boat_speed*100)/100,4,4,7)

 -- sail angle indicator (mini compass)
 local cx,cy=115,12
 rectfill(cx-10,cy-10,cx+10,cy+10,1)
 circ(cx,cy,9,5)

 -- boat direction
 local ba=-boat_rot
 line(cx,cy,cx+sin(ba)*7,cy-cos(ba)*7,11)

 -- sail direction
 local sa=-boat_rot-sail_ang
 line(cx,cy,cx+sin(sa)*6,cy-cos(sa)*6,7)

 -- wind direction
 local wa=-wind_ang
 local wx,wy=cx+sin(wa)*8,cy-cos(wa)*8
 pset(wx,wy,8)
 pset(wx+1,wy,8)
 pset(wx,wy+1,8)

 -- labels
 print("wind",cx-8,cy+12,8)

 -- controls help
 rectfill(2,115,80,126,1)
 print("< > cam  z x sail",4,118,6)
end

function sort_faces(f)
 -- insertion sort by depth
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

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
