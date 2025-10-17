pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- isometric rts game
-- camera and world
cx,cy=0,0
gx,gy=64,64 -- grid size

-- units and buildings
units={}
buildings={}
enemies={}
resources_deposits={}
selected={}
selected_building=nil
menu_open=false
build_menu=false
unit_build_menu=false
build_type=1
hover_unit=nil
hover_building=nil
hover_resource=nil

-- box selection
box_start_x=nil
box_start_y=nil
box_dragging=false

-- building placement
placing_building=false
placing_type=nil
placing_cost=0

-- resources
resources=100

-- ui element bounds (for click detection and sizing)
ui_bounds={
 build_button={x=44,y=120,w=36,h=8},
 build_menu={x=32,y=90,w=64,h=32},
 unit_build_menu={x=32,y=100,w=64,h=32},
 hover_info={
  unit={w=40,h=12},
  building={w=50,h=12},
  resource={w=45,h=12}
 }
}

-- unit templates
unit_templates={
 drone={
  type="drone",
  hp=50,
  maxhp=50,
  cost=50,
  spr_h=2, -- horizontal sprite
  spr_v=3  -- vertical sprite
 },
 marine={
  type="marine",
  hp=100,
  maxhp=100,
  cost=75,
  spr_h=4, -- horizontal sprite
  spr_v=nil, -- no vertical sprite
  flip_reverse=true -- reverse flip direction
 }
}

-- building templates
building_templates={
 hq={
  type="hq",
  hp=500,
  maxhp=500,
  cost=400,
  w=2,
  h=2
 },
 barracks={
  type="barracks",
  hp=300,
  maxhp=300,
  cost=150,
  w=2,
  h=1
 }
}

function _init()
 poke(0x5f2d,1) -- enable mouse

 -- spawn player drone
 local tmpl=unit_templates.drone
 add(units,{
  x=5,y=5,
  type=tmpl.type,
  hp=tmpl.hp,
  maxhp=tmpl.maxhp,
  team=1,
  task=nil,
  target=nil,
  path=nil
 })
 
 -- spawn hq
 local tmpl=building_templates.hq
 add(buildings,{
  x=4,y=4,
  type=tmpl.type,
  hp=tmpl.hp,
  maxhp=tmpl.maxhp,
  team=1,
  w=tmpl.w,
  h=tmpl.h
 })
 
 -- spawn resource deposits near hq
 for i=1,8 do
  local angle=i*0.785 -- spread around hq
  local dist=5+rnd(3)
  local rx=mid(1,4+cos(angle)*dist,gx-2)
  local ry=mid(1,4+sin(angle)*dist,gy-2)
  add(resources_deposits,{
   x=rx,
   y=ry,
   amount=500,
   type="minerals"
  })
 end

 -- spawn enemies on opposite side of map from hq
 for i=1,5 do
  -- spawn in far corner (opposite from hq at 4,4)
  local ex=mid(1,flr(gx*0.7+rnd(gx*0.25)),gx-2)
  local ey=mid(1,flr(gy*0.7+rnd(gy*0.25)),gy-2)
  add(enemies,{
   x=ex,
   y=ey,
   hp=30,
   maxhp=30,
   type="enemy",
   target=nil,
   cooldown=0
  })
 end
end

function _update()
 handle_input()
 update_units()
 separate_drones()
 update_enemies()
 update_buildings()
end

function _draw()
 cls(1)

 -- draw world
 draw_terrain()
 draw_resources()
 draw_buildings()
 draw_units()
 draw_enemies()

 -- draw selection box
 if box_dragging then
  local mx,my=stat(32),stat(33)
  rect(box_start_x,box_start_y,mx,my,7)
 end

 -- draw building placement preview
 if placing_building then
  draw_placement_preview()
 end

 -- draw ui
 draw_ui()
 draw_hover_info()

 if menu_open then
  draw_menu()
 end

 if build_menu then
  draw_build_menu()
 end

 if unit_build_menu then
  draw_unit_build_menu()
 end

 -- draw cursor last so it's on top
 draw_cursor()
end

function handle_input()
 local mx,my=stat(32),stat(33)
 local mb=stat(34)

 -- handle building placement mode
 if placing_building then
  local wx,wy=screen_to_world(mx,my)
  if mb==1 then
   -- place building
   if resources>=placing_cost then
    local tmpl=building_templates[placing_type]
    if tmpl then
     add(buildings,{
      x=flr(wx),
      y=flr(wy),
      type=tmpl.type,
      hp=tmpl.hp,
      maxhp=tmpl.maxhp,
      team=1,
      w=tmpl.w,
      h=tmpl.h
     })
     resources-=placing_cost
    end
   end
   placing_building=false
   placing_type=nil
   placing_cost=0
  elseif mb==2 then
   -- cancel placement
   placing_building=false
   placing_type=nil
   placing_cost=0
  end
  return
 end

 -- check if mouse is over any menu
 local over_menu=(menu_open or build_menu or unit_build_menu)

 -- arrow key camera movement
 if btn(0) then cx-=2 end
 if btn(1) then cx+=2 end
 if btn(2) then cy-=2 end
 if btn(3) then cy+=2 end

 -- mouse edge panning (disabled over menus)
 if not over_menu then
  if mx<14 then cx-=2 end
  if mx>114 then cx+=2 end
  if my<14 then cy-=2 end
  if my>114 then cy+=2 end
 end
 
 -- keep camera within map bounds (center stays in map)
 cx=mid(0,cx,gx*8-64)
 cy=mid(0,cy,gy*8-64)
 

 -- update hover unit, building, and resource
 local wx,wy=screen_to_world(mx,my)
 hover_unit=get_unit_at(wx,wy)
 hover_building=get_building_at(wx,wy)
 hover_resource=get_resource_at(mx,my)

 -- left click - unit/building select or box select
 if mb==1 and not menu_open then
  -- check if clicking inside a menu first
  local clicked_in_menu=false

  if build_menu then
   local bm=ui_bounds.build_menu
   if mx>bm.x and mx<bm.x+bm.w and my>bm.y and my<bm.y+bm.h then
    clicked_in_menu=true
   end
  end

  if unit_build_menu then
   local ubm=ui_bounds.unit_build_menu
   if mx>ubm.x and mx<ubm.x+ubm.w and my>ubm.y and my<ubm.y+ubm.h then
    clicked_in_menu=true
   end
  end

  if not clicked_in_menu and not box_dragging then
   -- check if clicking on unit first
   local clicked_unit=get_unit_at(wx,wy)
   if clicked_unit and clicked_unit.team==1 then
    selected={clicked_unit}
    selected_building=nil
    unit_build_menu=false
    build_menu=false
   else
    -- check if clicking on building
    local clicked_building=get_building_at(wx,wy)
    if clicked_building and clicked_building.team==1 then
     selected_building=clicked_building
     selected={}
     unit_build_menu=false
     build_menu=false
     if clicked_building.type=="hq" or clicked_building.type=="barracks" then
      unit_build_menu=true
     end
    else
     -- clicking on terrain - start box drag (don't clear yet)
     box_start_x=mx
     box_start_y=my
     box_dragging=true
    end
   end
  end
 else
  -- mouse button released
  if box_dragging then
   -- finish box selection
   box_select(box_start_x,box_start_y,mx,my)
   box_dragging=false
   box_start_x=nil
   box_start_y=nil

   -- close menus and clear building selection
   selected_building=nil
   unit_build_menu=false
   build_menu=false
  end
 end


 -- right click - move/attack/mine
 if mb==2 and #selected>0 then
  local target_enemy=get_enemy_at(wx,wy)
  local target_resource=get_resource_at(mx,my)

  for u in all(selected) do
   if target_enemy then
    u.task="attack"
    u.target=target_enemy
   elseif target_resource and u.type=="drone" then
    u.task="harvest"
    u.target=target_resource
    u.carrying=0
   else
    u.task="move"
    u.target_x=wx
    u.target_y=wy
   end
  end
 end
end

function screen_to_world(sx,sy)
 -- convert screen to camera space
 local camx=sx+cx-64
 local camy=sy+cy-64

 -- inverse isometric transformation
 -- from: sx=(ix-iy)*8, sy=(ix+iy)*4
 -- solve: ix=(sx/8 + sy/4)/2, iy=(sy/4 - sx/8)/2
 local ix=(camx/8 + camy/4)/2
 local iy=(camy/4 - camx/8)/2

 return flr(ix),flr(iy)
end

function world_to_screen(wx,wy)
 local sx=(wx*8)+(wy*8)-cx+64
 local sy=(wy*4)-(wx*4)-cy+64
 return sx,sy
end

function iso_to_screen(ix,iy)
 local sx=(ix-iy)*8-cx+64
 local sy=(ix+iy)*4-cy+64
 return sx,sy
end

function draw_terrain()
 for y=0,gx do
  for x=0,gy do
   local sx,sy=iso_to_screen(x,y)
   if sx>-8 and sx<136 and sy>-8 and sy<136 then
    -- randomize color slightly
    srand(x*1000+y)
    local r=flr(rnd(3))
    local c=3
    if r==0 then c=3
    elseif r==1 then c=11
    else c=3 end

    -- draw isometric diamond tile
    -- top edge
    line(sx,sy+4,sx+8,sy,c)
    -- right edge
    line(sx+8,sy,sx+16,sy+4,c)
    -- bottom edge
    line(sx+16,sy+4,sx+8,sy+8,c)
    -- left edge
    line(sx+8,sy+8,sx,sy+4,c)

    -- fill with slightly darker pattern
    fillp(0b1010010110100101)
    local fc=c
    if c==11 then fc=3 end
    -- fill top half
    for i=0,3 do
     line(sx+4-i,sy+4+i,sx+12+i,sy+4+i,fc)
    end
    fillp()
   end
  end
 end
end

function draw_resources()
 for r in all(resources_deposits) do
  local sx,sy=iso_to_screen(r.x,r.y)

  -- draw blue crystal cluster
  circfill(sx+6,sy+4,3,12)
  circfill(sx+10,sy+3,2,12)
  circfill(sx+4,sy+5,2,12)
  -- crystal highlights
  pset(sx+6,sy+3,7)
  pset(sx+10,sy+2,7)
  pset(sx+4,sy+4,7)

  -- show amount if hovering
  if hover_building==r then
   print(r.amount,sx,sy-6,7)
  end
 end
end

function draw_buildings()
 for b in all(buildings) do
  local sx,sy=iso_to_screen(b.x,b.y)

  -- building base
  local col=8
  if b.team==1 then col=12 end

  -- highlight if selected
  if b==selected_building then col=10 end

  if b.type=="hq" then
   rectfill(sx,sy,sx+16,sy+12,col)
   rectfill(sx+2,sy-4,sx+14,sy+2,col+1)
  elseif b.type=="barracks" then
   rectfill(sx,sy,sx+12,sy+10,col)
   rectfill(sx+2,sy-3,sx+10,sy+2,col+1)
  elseif b.type=="depot" then
   rectfill(sx,sy,sx+10,sy+8,col)
   rectfill(sx+2,sy-2,sx+8,sy+2,col+1)
  end

  -- hp bar
  local pct=b.hp/b.maxhp
  rectfill(sx,sy-2,sx+10,sy-1,8)
  rectfill(sx,sy-2,sx+10*pct,sy-1,11)

  -- build progress bar
  if b.build_queue and #b.build_queue>0 then
   local prog=b.build_queue[1].progress/b.build_queue[1].maxprogress
   rectfill(sx,sy-4,sx+16,sy-3,0)
   rectfill(sx,sy-4,sx+16*prog,sy-3,10)
  end
 end
end

function draw_units()
 for u in all(units) do
  local sx,sy=iso_to_screen(u.x,u.y)

  -- unit
  local tmpl=unit_templates[u.type]
  if tmpl and tmpl.spr_h then
   -- determine movement direction and sprite based on screen coordinates
   local sprite=tmpl.spr_h -- default horizontal (left)
   local flipx=false
   local flipy=false

   if u.screen_dx and u.screen_dy and (u.screen_dx!=0 or u.screen_dy!=0) then
    if tmpl.spr_v and abs(u.screen_dx)<=abs(u.screen_dy) then
     -- vertical movement dominant on screen (if vertical sprite exists)
     sprite=tmpl.spr_v
     flipy=(u.screen_dy>0) -- flip for down
    else
     -- horizontal movement or no vertical sprite
     sprite=tmpl.spr_h
     if tmpl.flip_reverse then
      flipx=(u.screen_dx<0) -- reverse flip
     else
      flipx=(u.screen_dx>0) -- flip for right
     end
    end
   end

   -- check if selected
   local selected_unit=false
   for s in all(selected) do
    if u==s then selected_unit=true break end
   end

   -- draw with pal swap for selection
   if selected_unit then
    pal(7,10)
   end
   spr(sprite,sx,sy,1,1,flipx,flipy)
   pal()

   -- show blue pixel if carrying resources (drones only)
   if u.type=="drone" and u.carrying and u.carrying>0 then
    pset(sx+4,sy,12)
   end
  else
   -- other unit types without sprites
   local col=7
   for s in all(selected) do
    if u==s then col=10 break end
   end
   circfill(sx+4,sy+2,2,col)
  end

  -- hp bar
  local pct=u.hp/u.maxhp
  rectfill(sx,sy-2,sx+8,sy-1,8)
  rectfill(sx,sy-2,sx+8*pct,sy-1,11)

  -- draw move target
  if u.task=="move" and u.target_x then
   local tx,ty=iso_to_screen(u.target_x,u.target_y)
   circ(tx+4,ty+2,3,10)
  end
 end
end

function draw_enemies()
 for e in all(enemies) do
  local sx,sy=iso_to_screen(e.x,e.y)
  
  -- enemy
  circfill(sx+4,sy+2,2,8)
  
  -- hp bar
  local pct=e.hp/e.maxhp
  rectfill(sx,sy-2,sx+8,sy-1,8)
  rectfill(sx,sy-2,sx+8*pct,sy-1,9)
 end
end

function draw_ui()
 -- resource counter
 rectfill(0,0,40,8,0)
 print("res:"..resources,2,2,7)

 -- selected units info and build button
 if #selected>0 then
  rectfill(0,120,80,128,0)
  print("selected:"..#selected,2,122,7)

  -- check if any selected units are drones
  local has_drone=false
  for u in all(selected) do
   if u.type=="drone" then
    has_drone=true
    break
   end
  end

  -- show build button if drone selected
  if has_drone then
   local bb=ui_bounds.build_button
   rectfill(bb.x,bb.y,bb.x+bb.w,bb.y+bb.h,5)
   rect(bb.x,bb.y,bb.x+bb.w,bb.y+bb.h,7)
   print("build",bb.x+4,bb.y+2,7)

   -- check if mouse is over build button
   local mx,my=stat(32),stat(33)
   if mx>bb.x and mx<bb.x+bb.w and my>bb.y and my<bb.y+bb.h then
    rect(bb.x,bb.y,bb.x+bb.w,bb.y+bb.h,10)
    if stat(34)==1 then
     build_menu=not build_menu
    end
   end
  end
 end
end

function draw_hover_info()
 local mx,my=stat(32),stat(33)
 local hi=ui_bounds.hover_info

 if hover_unit then
  local w,h=hi.unit.w,hi.unit.h
  rectfill(mx+8,my-h-4,mx+8+w,my-4,0)
  rect(mx+8,my-h-4,mx+8+w,my-4,7)
  print(hover_unit.type,mx+10,my-h-2,7)
  print("hp:"..hover_unit.hp.."/"..hover_unit.maxhp,mx+10,my-8,11)
 elseif hover_building then
  local w,h=hi.building.w,hi.building.h
  rectfill(mx+8,my-h-4,mx+8+w,my-4,0)
  rect(mx+8,my-h-4,mx+8+w,my-4,7)
  print(hover_building.type,mx+10,my-h-2,7)
  if hover_building.hp then
   print("hp:"..hover_building.hp.."/"..hover_building.maxhp,mx+10,my-8,11)
  end
 elseif hover_resource then
  local w,h=hi.resource.w,hi.resource.h
  rectfill(mx+8,my-h-4,mx+8+w,my-4,0)
  rect(mx+8,my-h-4,mx+8+w,my-4,7)
  print("minerals",mx+10,my-h-2,7)
  print("amt:"..hover_resource.amount,mx+10,my-8,12)
 end
end

function draw_placement_preview()
 local mx,my=stat(32),stat(33)
 local wx,wy=screen_to_world(mx,my)
 local gx_pos,gy_pos=flr(wx),flr(wy)

 local tmpl=building_templates[placing_type]
 if tmpl then
  local w,h=tmpl.w,tmpl.h

  -- draw highlighted ground squares
  for dy=0,h-1 do
   for dx=0,w-1 do
    local sx,sy=iso_to_screen(gx_pos+dx,gy_pos+dy)

    -- draw isometric diamond tile with highlight
    local col=11 -- green for valid placement
    if resources<placing_cost then col=8 end -- red if can't afford

    -- draw diamond outline
    line(sx,sy+4,sx+8,sy,col)
    line(sx+8,sy,sx+16,sy+4,col)
    line(sx+16,sy+4,sx+8,sy+8,col)
    line(sx+8,sy+8,sx,sy+4,col)
   end
  end
 end
end

function draw_cursor()
 local mx,my=stat(32),stat(33)
 spr(0,mx,my)
end

function draw_menu()
 local mx,my=stat(32),stat(33)
 
 -- menu background
 rectfill(mx+4,my+4,mx+44,my+44,0)
 rect(mx+4,my+4,mx+44,my+44,7)
 
 local opts={"move","attack"}
 if selected.type=="drone" then
  add(opts,"harvest")
  add(opts,"build")
 end
 
 for i=1,#opts do
  local py=my+4+i*8
  print(opts[i],mx+6,py,7)
  
  if mx<stat(32) and stat(32)<mx+44 and
     py<stat(33) and stat(33)<py+6 then
   if btnp(5) or stat(34)==1 then
    execute_action(opts[i])
    menu_open=false
   end
  end
 end
end

function draw_build_menu()
 local bm=ui_bounds.build_menu
 local bx,by=bm.x,bm.y

 rectfill(bx,by,bx+bm.w,by+bm.h,0)
 rect(bx,by,bx+bm.w,by+bm.h,7)

 print("build",bx+2,by+2,7)

 local opts={"hq","barracks"}
 local costs={building_templates.hq.cost,building_templates.barracks.cost}

 for i=1,#opts do
  local py=by+8+i*8
  local col=7
  if resources<costs[i] then col=8 end
  print(opts[i].." ("..costs[i]..")",bx+4,py,col)

  -- check if mouse is over this option
  local mx,my=stat(32),stat(33)
  if mx>bx and mx<bx+bm.w and my>py and my<py+9 then
   rect(bx+2,py-1,bx+bm.w-2,py+7,10)
   if stat(34)==1 and resources>=costs[i] then
    -- enter building placement mode
    placing_building=true
    placing_type=opts[i]
    placing_cost=costs[i]
    build_menu=false
   end
  end
 end

 -- close on right click
 if stat(34)==2 then
  build_menu=false
 end
end

function draw_unit_build_menu()
 local ubm=ui_bounds.unit_build_menu
 local bx,by=ubm.x,ubm.y

 rectfill(bx,by,bx+ubm.w,by+ubm.h,0)
 rect(bx,by,bx+ubm.w,by+ubm.h,7)

 print("build unit",bx+2,by+2,7)

 -- determine what units to show based on building type
 local opts={}
 local costs={}

 if selected_building then
  if selected_building.type=="hq" then
   opts={"drone"}
   costs={unit_templates.drone.cost}
  elseif selected_building.type=="barracks" then
   opts={"marine"}
   costs={unit_templates.marine.cost}
  end
 end

 for i=1,#opts do
  local py=by+8+i*8
  local col=7
  if resources<costs[i] then col=8 end
  print(opts[i].." ("..costs[i]..")",bx+4,py,col)

  -- check if mouse is over this option
  local mx,my=stat(32),stat(33)
  if mx>bx and mx<bx+ubm.w and my>py and my<py+6 then
   rect(bx+2,py-1,bx+ubm.w-2,py+6,10)
   if stat(34)==1 and resources>=costs[i] then
    build_unit(opts[i],costs[i])
    unit_build_menu=false
   end
  end
 end

 -- close button
 if stat(34)==2 or btnp(4) then
  unit_build_menu=false
 end
end

function build_unit(utype,cost)
 if selected_building and (selected_building.type=="hq" or selected_building.type=="barracks") then
  if not selected_building.build_queue then
   selected_building.build_queue={}
  end

  -- check if already building
  if #selected_building.build_queue<5 then
   resources-=cost
   add(selected_building.build_queue,{
    type=utype,
    progress=0,
    maxprogress=120 -- 2 seconds at 60fps
   })
  end
 end
end

function update_buildings()
 for b in all(buildings) do
  if b.build_queue and #b.build_queue>0 then
   local current=b.build_queue[1]
   current.progress+=1

   if current.progress>=current.maxprogress then
    -- spawn unit using template
    local tmpl=unit_templates[current.type]
    if tmpl then
     add(units,{
      x=mid(0.5,b.x+1,gx-1.5),
      y=mid(0.5,b.y+1,gy-1.5),
      type=tmpl.type,
      hp=tmpl.hp,
      maxhp=tmpl.maxhp,
      team=1,
      task=nil,
      target=nil,
      path=nil
     })
    end
    del(b.build_queue,current)
   end
  end
 end
end

function get_unit_at(wx,wy)
 for u in all(units) do
  if flr(u.x)==wx and flr(u.y)==wy then
   return u
  end
 end
 return nil
end

function get_enemy_at(wx,wy)
 for e in all(enemies) do
  if flr(e.x)==wx and flr(e.y)==wy then
   return e
  end
 end
 return nil
end

function get_building_at(wx,wy)
 for b in all(buildings) do
  local bw=b.w or 1
  local bh=b.h or 1
  if wx>=b.x and wx<b.x+bw and wy>=b.y and wy<b.y+bh then
   return b
  end
 end
 return nil
end

function get_resource_at(mx,my)
 -- check resources using screen coordinates for better hitbox
 for r in all(resources_deposits) do
  local sx,sy=iso_to_screen(r.x,r.y)

  -- crystal bounds: roughly sx+4 to sx+10, sy+2 to sy+7
  local dx=mx-sx-7  -- center at sx+7
  local dy=my-sy-4  -- center at sy+4
  local dist=sqrt(dx*dx+dy*dy)

  if dist<5 then -- 5 pixel radius for easier clicking
   return r
  end
 end
 return nil
end

function box_select(x1,y1,x2,y2)
 -- normalize coords
 local minx,maxx=min(x1,x2),max(x1,x2)
 local miny,maxy=min(y1,y2),max(y1,y2)

 selected={}
 for u in all(units) do
  local sx,sy=iso_to_screen(u.x,u.y)
  if sx>=minx and sx<=maxx and sy>=miny and sy<=maxy then
   add(selected,u)
  end
 end
end

function execute_action(action)
 if action=="move" then
  selected.task="move"
 elseif action=="attack" then
  selected.task="attack"
 elseif action=="harvest" then
  selected.task="harvest"
 elseif action=="build" then
  build_menu=true
 end
end


function update_units()
 for u in all(units) do
  if u.task=="move" and u.target_x then
   local dx=abs(u.x-u.target_x)
   local dy=abs(u.y-u.target_y)
   if dx<0.2 and dy<0.2 then
    u.task=nil
    u.target_x=nil
    u.target_y=nil
   else
    move_towards(u,u.target_x,u.target_y)
   end
  elseif u.task=="harvest" then
   if not u.carrying then u.carrying=0 end
   if not u.extract_time then u.extract_time=0 end

   if u.carrying==0 then
    -- go to resource deposit
    if u.target and u.target.amount>0 then
     local dist=abs(u.target.x-u.x)+abs(u.target.y-u.y)
     if dist<1.5 then
      -- extract resources (takes time)
      u.extract_time+=1
      if u.extract_time>=30 then -- 0.5 seconds
       local gathered=min(10,u.target.amount)
       u.target.amount-=gathered
       u.carrying=gathered
       u.extract_time=0
       if u.target.amount<=0 then
        del(resources_deposits,u.target)
        u.target=nil
       end
      end
     else
      u.extract_time=0
      move_towards(u,u.target.x,u.target.y)
     end
    else
     u.task=nil
     u.extract_time=0
    end
   else
    -- return to hq
    local nearest=nil
    local dist=999
    for b in all(buildings) do
     if b.type=="hq" and b.team==1 then
      local d=abs(b.x-u.x)+abs(b.y-u.y)
      if d<dist then
       dist=d
       nearest=b
      end
     end
    end

    if nearest then
     if dist<2 then
      resources+=u.carrying
      u.carrying=0
      u.extract_time=0
     else
      move_towards(u,nearest.x,nearest.y)
     end
    end
   end
  elseif u.task=="attack" then
   local target=u.target
   -- if no specific target, find nearest enemy
   if not target or target.hp<=0 then
    local nearest=nil
    local dist=999
    for e in all(enemies) do
     local d=abs(e.x-u.x)+abs(e.y-u.y)
     if d<dist then
      dist=d
      nearest=e
     end
    end
    target=nearest
    u.target=target
   end

   if target then
    local dist=abs(target.x-u.x)+abs(target.y-u.y)
    if dist<2 then
     target.hp-=1
     if target.hp<=0 then
      del(enemies,target)
      u.task=nil
      u.target=nil
     end
    else
     move_towards(u,target.x,target.y)
    end
   end
  end
 end
end

function update_enemies()
 for e in all(enemies) do
  -- find nearest player unit/building
  local nearest=nil
  local dist=999
  
  for u in all(units) do
   local d=abs(u.x-e.x)+abs(u.y-e.y)
   if d<dist then
    dist=d
    nearest=u
   end
  end
  
  for b in all(buildings) do
   if b.team==1 then
    local d=abs(b.x-e.x)+abs(b.y-e.y)
    if d<dist then
     dist=d
     nearest=b
    end
   end
  end
  
  if nearest then
   if dist<10 then
    if dist<2 then
     e.cooldown-=1
     if e.cooldown<=0 then
      nearest.hp-=5
      e.cooldown=30
      if nearest.hp<=0 then
       del(units,nearest)
       del(buildings,nearest)
      end
     end
    else
     move_towards(e,nearest.x,nearest.y)
    end
   end
  end
 end
end

function move_towards(unit,tx,ty)
 -- track movement delta in world space
 local world_dx=0
 local world_dy=0

 if unit.x<tx then
  unit.x+=0.1
  world_dx=0.1
 end
 if unit.x>tx then
  unit.x-=0.1
  world_dx=-0.1
 end
 if unit.y<ty then
  unit.y+=0.1
  world_dy=0.1
 end
 if unit.y>ty then
  unit.y-=0.1
  world_dy=-0.1
 end

 -- convert to screen space delta for sprite direction
 -- screen: sx=(wx-wy)*8, sy=(wy+wx)*4
 unit.screen_dx=(world_dx-world_dy)*8
 unit.screen_dy=(world_dy+world_dx)*4

 -- keep within map bounds
 unit.x=mid(0.5,unit.x,gx-1.5)
 unit.y=mid(0.5,unit.y,gy-1.5)
end

function separate_drones()
 -- prevent drones from stacking
 for i=1,#units do
  for j=i+1,#units do
   local u1=units[i]
   local u2=units[j]
   local dx=u2.x-u1.x
   local dy=u2.y-u1.y
   local dist=sqrt(dx*dx+dy*dy)

   if dist<0.3 and dist>0 then
    -- push apart slightly
    local push=0.02
    local nx=dx/dist
    local ny=dy/dist
    u1.x-=nx*push
    u1.y-=ny*push
    u2.x+=nx*push
    u2.y+=ny*push

    -- keep within bounds
    u1.x=mid(0.5,u1.x,gx-1.5)
    u1.y=mid(0.5,u1.y,gy-1.5)
    u2.x=mid(0.5,u2.x,gx-1.5)
    u2.y=mid(0.5,u2.y,gy-1.5)
   end
  end
 end
end

__gfx__
77700000777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6777700077777770000000000000000000cc70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6777770076666677000077000005050000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
167700007666667700076b7000060600057666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06717000766666770666655000067600055565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0160170076666677055567900056b650006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100777777770000565000666660006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000065060000699960007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000150010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
