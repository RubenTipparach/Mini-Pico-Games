pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- f-zero pod racer
-- by claude

function _init()
 -- game state
 gamestate="race"
 
 -- player pod
 player={
  x=64,
  y=100,
  speed=0,
  maxspeed=8,
  acceleration=0.2,
  friction=0.1,
  turn=0,
  angle=0
 }
 
 -- track variables
 track_pos=0
 track_width=40
 track_segments={}
 horizon=60
 
 -- camera
 camera_height=300
 road_width=2000
 
 -- lap system
 lap=1
 max_laps=3
 checkpoint=0
 
 -- initialize track
 init_track()
end

function init_track()
 -- create straight track segments for testing
 for i=1,200 do
  track_segments[i]={
   curve=0, -- straight track
   y=0      -- flat track
  }
 end
end

function _update60()
 if gamestate=="race" then
  update_player()
  update_camera()
 end
end

function update_player()
 -- direct lateral movement (responsive even when not moving forward)
 if btn(0) then -- left
  player.x=max(player.x-1.5,10) -- direct movement, not angle-based
 end
 if btn(1) then -- right  
  player.x=min(player.x+1.5,118) -- direct movement, not angle-based
 end
 
 if btn(2) then -- up (accelerate)
  player.speed=min(player.speed+player.acceleration,player.maxspeed)
  if player.speed>1 and rnd(30)<1 then sfx(1) end -- engine sound
 else
  player.speed=max(player.speed-player.friction,0)
 end
 
 -- speed boost
 if btn(4) and player.speed>4 then
  player.speed=min(player.speed+0.5,player.maxspeed*1.5)
  if rnd(10)<3 then sfx(2) end -- boost sound
 end
 
 -- update position
 -- removed angle-based movement for direct control
 track_pos+=player.speed
 
 -- lateral movement now handled directly in input section
 
 -- track boundary collision (simplified for straight track)
 local track_left=64-25   -- slightly wider track
 local track_right=64+25  -- slightly wider track
 
 if player.x<track_left then
  player.x=track_left
  player.speed=max(player.speed*0.9,1) -- gentler slowdown, minimum speed of 1
  if rnd(20)<1 then sfx(3) end -- less frequent crash sound
 elseif player.x>track_right then
  player.x=track_right  
  player.speed=max(player.speed*0.9,1) -- gentler slowdown, minimum speed of 1
  if rnd(20)<1 then sfx(3) end
 end
 
 -- lap counter
 if track_pos>=#track_segments*100 then
  track_pos=0
  lap+=1
  if lap>max_laps then
   gamestate="finish"
  end
 end
end

function update_camera()
 -- nothing for now
end

function _draw()
 cls(1) -- dark blue sky
 
 if gamestate=="race" then
  draw_track()
  draw_hud()
  draw_player()
 elseif gamestate=="finish" then
  draw_finish_screen()
 end
end

function draw_track()
 -- draw sky
 rectfill(0,0,127,horizon,12)
 
 -- draw ground (green background)
 rectfill(0,horizon,127,127,3)
 
 -- draw parallax background elements
 draw_background()
 
 -- draw track with vanishing point perspective
 local vanishing_x=64 -- center vanishing point
 local vanishing_y=horizon
 
 -- player's lateral offset affects track rendering
 local player_offset=(player.x-64)*0.5 -- reduce sensitivity
 
 -- render track segments from back to front
 for z=200,1,-1 do
  local distance=track_pos+z*10
  local seg_idx=flr(distance/50)
  
  -- 3d to 2d projection with vanishing point
  local scale=200/z
  local proj_y=vanishing_y+scale*0.3
  
  if proj_y>vanishing_y and proj_y<=127 and scale>0.1 then
   -- track width decreases with distance
   local track_w=min(60,track_width*scale)
   
   -- offset track based on player position (perspective effect)
   local track_offset=player_offset*(1-scale/200) -- less offset for distant segments
   
   local left_x=vanishing_x-track_w+track_offset
   local right_x=vanishing_x+track_w+track_offset
   
   -- clip to screen bounds
   left_x=max(0,left_x)
   right_x=min(127,right_x)
   
   if left_x<right_x then
    -- alternating track segments for speed indication
    local is_stripe=(seg_idx%2==0)
    local track_col
    
    -- dithered depth colors
    if z>150 then
     track_col=is_stripe and 5 or 1 -- far: dark gray/black
    elseif z>100 then
     track_col=is_stripe and 6 or 5 -- med: gray/dark gray  
    elseif z>50 then
     track_col=is_stripe and 7 or 6 -- close: light gray/gray
    else
     track_col=is_stripe and 7 or 15 -- very close: light gray/white
    end
    
    -- draw track segment
    local seg_height=max(1,scale*0.4)
    rectfill(left_x,proj_y,right_x,proj_y+seg_height,track_col)
    
    -- track edges (yellow barriers)
    if scale>1 then
     line(left_x,proj_y,left_x,proj_y+seg_height,10)
     line(right_x,proj_y,right_x,proj_y+seg_height,10)
    end
    
    -- center line (every few segments)
    if seg_idx%4==0 and scale>2 then
     local center_w=max(1,scale*0.1)
     local center_x=vanishing_x+track_offset
     rectfill(center_x-center_w,proj_y,center_x+center_w,proj_y+seg_height,8)
    end
    
    -- boost strips occasionally
    if seg_idx%20==0 and scale>3 then
     local boost_w=scale*0.15
     rectfill(left_x+boost_w,proj_y,left_x+boost_w*2,proj_y+seg_height,11)
     rectfill(right_x-boost_w*2,proj_y,right_x-boost_w,proj_y+seg_height,11)
    end
   end
  end
 end
 
 -- draw minimap
 draw_minimap()
end

function draw_background()
 local scroll_x=track_pos*0.1
 
 -- distant mountains (slow parallax)
 for i=0,3 do
  local x=(i*40-scroll_x*0.2)%140-10
  rectfill(x,horizon-25,x+30,horizon,5)
  rectfill(x+5,horizon-20,x+25,horizon,13)
 end
 
 -- mid-distance buildings (medium parallax)
 for i=0,5 do
  local x=(i*25-scroll_x*0.5)%140-10
  local h=15+i%3*5
  rectfill(x,horizon-h,x+20,horizon,1)
  rectfill(x+2,horizon-h+2,x+18,horizon-2,6)
 end
end

function draw_minimap()
 -- minimap background
 rectfill(100,5,125,25,1)
 rect(99,4,126,26,7)
 
 -- draw track preview (next 20 segments)
 local start_seg=flr(track_pos/100)
 for i=0,19 do
  local seg_idx=(start_seg+i)%#track_segments+1
  local segment=track_segments[seg_idx]
  
  local map_y=6+i
  local curve_intensity=segment.curve*50
  local center_x=112+curve_intensity
  
  -- track representation
  if i==0 then
   -- player position
   pset(center_x,map_y,11)
  else
   -- track curve
   local col=6
   if abs(curve_intensity)>2 then col=8 end -- highlight sharp turns
   pset(center_x-1,map_y,col)
   pset(center_x,map_y,7)
   pset(center_x+1,map_y,col)
  end
 end
end

function draw_player()
 -- draw pod racer (anakin style)
 local px=player.x
 local py=player.y
 local tilt=player.turn*10
 
 -- shadow
 oval(px-8,py+8,px+8,py+10,1)
 
 -- left engine pod
 local lx=px-8+tilt*0.3
 local ly=py+tilt*0.1
 rectfill(lx-3,ly-2,lx+1,ly+2,9)
 rectfill(lx-2,ly-1,lx,ly+1,10) -- inner glow
 
 -- right engine pod  
 local rx=px+8+tilt*0.3
 local ry=py-tilt*0.1
 rectfill(rx-1,ry-2,rx+3,ry+2,9)
 rectfill(rx,ry-1,rx+2,ry+1,10) -- inner glow
 
 -- connecting energy streams
 line(lx+1,ly,px-2,py,11)
 line(rx-1,ry,px+2,py,11)
 
 -- cockpit/pilot area
 rectfill(px-2,py-1,px+2,py+1,8)
 pset(px,py,7) -- pilot
 
 -- engine exhaust effects
 if player.speed>1 then
  local intensity=flr(player.speed/2)+1
  for i=1,intensity do
   -- left exhaust
   pset(lx-4-i,ly+rnd(3)-1,10+rnd(2))
   pset(lx-4-i,ly+rnd(3)-1,9)
   
   -- right exhaust
   pset(rx+4+i,ry+rnd(3)-1,10+rnd(2))
   pset(rx+4+i,ry+rnd(3)-1,9)
  end
 end
 
 -- speed boost visual
 if btn(4) and player.speed>4 then
  for i=0,5 do
   local trail_x=px+rnd(16)-8
   local trail_y=py+15+i*2
   pset(trail_x,trail_y,10+rnd(4))
  end
 end
end

function draw_hud()
 -- speed indicator
 local speed_pct=player.speed/player.maxspeed
 rectfill(5,5,5+speed_pct*30,10,11)
 rect(4,4,36,11,7)
 print("speed",5,15,7)
 
 -- lap counter
 print("lap "..lap.."/"..max_laps,90,5,7)
 
 -- position indicator
 local track_pct=track_pos/(#track_segments*100)
 rectfill(5,115,5+track_pct*30,120,11)
 rect(4,114,36,121,7)
 print("track",5,105,7)
end

function draw_finish_screen()
 cls(0)
 
 -- victory message
 print("race complete!",35,50,7)
 
 -- final stats
 local final_time=flr(time())
 print("final time: "..final_time.."s",30,60,6)
 
 -- rank based on time
 local rank="champion"
 if final_time>60 then rank="pilot"
 elseif final_time>45 then rank="racer"
 end
 
 print("rank: "..rank,40,70,11)
 
 -- restart prompt
 print("press any key",35,90,5)
 print("to race again",38,100,5)
 
 -- restart functionality
 if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
  _init() -- restart game
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
