pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- parking puzzle
-- slide cars to free the exit!
-- inspired by rush hour

-- constants
grid_ox=20  -- grid offset x
grid_oy=20  -- grid offset y
cell=15     -- cell size in pixels
gw=6        -- grid width
gh=6        -- grid height
exit_row=3  -- exit is on row 3 (1-indexed)

-- game state
cars={}
sel=1       -- selected car index
level=1
moves=0
state="title" -- title,play,win,allclear
anim_t=0
msg_t=0
msg=""
best_moves={}
total_levels=8

-- particle system
particles={}

function make_particle(x,y,c)
  add(particles,{
    x=x,y=y,
    dx=(rnd(2)-1)*1.5,
    dy=-(rnd(2)+1),
    life=20+rnd(20),
    c=c
  })
end

function update_particles()
  for i=#particles,1,-1 do
    local p=particles[i]
    p.x+=p.dx
    p.y+=p.dy
    p.dy+=0.08
    p.life-=1
    if p.life<=0 then
      del(particles,p)
    end
  end
end

function draw_particles()
  for p in all(particles) do
    local a=p.life/40
    if a>0.5 then
      pset(p.x,p.y,p.c)
    elseif a>0.2 then
      pset(p.x,p.y,5)
    end
  end
end

-- level data: {gx,gy,len,dir,color}
-- dir: 0=horizontal, 1=vertical
-- car 1 is always the target (red)
function load_level(n)
  cars={}
  moves=0
  sel=1
  particles={}
  msg=""
  msg_t=0

  if n==1 then
    -- tutorial: simple
    add(cars,{gx=1,gy=3,len=2,dir=0,c=8})  -- red target
    add(cars,{gx=3,gy=1,len=3,dir=1,c=12}) -- blue
    add(cars,{gx=4,gy=3,len=2,dir=1,c=11}) -- green
  elseif n==2 then
    add(cars,{gx=1,gy=3,len=2,dir=0,c=8})
    add(cars,{gx=3,gy=2,len=2,dir=1,c=12})
    add(cars,{gx=4,gy=1,len=3,dir=1,c=11})
    add(cars,{gx=5,gy=3,len=2,dir=1,c=13})
  elseif n==3 then
    add(cars,{gx=2,gy=3,len=2,dir=0,c=8})
    add(cars,{gx=1,gy=1,len=2,dir=0,c=12})
    add(cars,{gx=3,gy=1,len=2,dir=1,c=11})
    add(cars,{gx=5,gy=2,len=3,dir=1,c=13})
    add(cars,{gx=4,gy=4,len=2,dir=0,c=14})
  elseif n==4 then
    add(cars,{gx=1,gy=3,len=2,dir=0,c=8})
    add(cars,{gx=3,gy=1,len=3,dir=1,c=12})
    add(cars,{gx=4,gy=2,len=2,dir=0,c=11})
    add(cars,{gx=6,gy=1,len=2,dir=1,c=13})
    add(cars,{gx=5,gy=4,len=2,dir=1,c=14})
    add(cars,{gx=1,gy=5,len=3,dir=0,c=10})
  elseif n==5 then
    add(cars,{gx=2,gy=3,len=2,dir=0,c=8})
    add(cars,{gx=1,gy=1,len=3,dir=1,c=12})
    add(cars,{gx=3,gy=1,len=2,dir=0,c=11})
    add(cars,{gx=4,gy=2,len=3,dir=1,c=13})
    add(cars,{gx=5,gy=1,len=2,dir=1,c=14})
    add(cars,{gx=2,gy=5,len=2,dir=0,c=10})
    add(cars,{gx=6,gy=4,len=3,dir=1,c=9})
  elseif n==6 then
    add(cars,{gx=1,gy=3,len=2,dir=0,c=8})
    add(cars,{gx=3,gy=1,len=2,dir=1,c=12})
    add(cars,{gx=4,gy=1,len=2,dir=0,c=11})
    add(cars,{gx=6,gy=1,len=3,dir=1,c=13})
    add(cars,{gx=3,gy=3,len=3,dir=1,c=14})
    add(cars,{gx=4,gy=4,len=2,dir=0,c=10})
    add(cars,{gx=1,gy=5,len=2,dir=1,c=9})
    add(cars,{gx=5,gy=5,len=2,dir=0,c=15})
  elseif n==7 then
    add(cars,{gx=3,gy=3,len=2,dir=0,c=8})
    add(cars,{gx=1,gy=1,len=2,dir=0,c=12})
    add(cars,{gx=3,gy=1,len=2,dir=1,c=11})
    add(cars,{gx=5,gy=1,len=3,dir=1,c=13})
    add(cars,{gx=6,gy=2,len=2,dir=1,c=14})
    add(cars,{gx=1,gy=3,len=2,dir=1,c=10})
    add(cars,{gx=2,gy=4,len=3,dir=0,c=9})
    add(cars,{gx=4,gy=5,len=2,dir=0,c=15})
    add(cars,{gx=1,gy=6,len=2,dir=0,c=4})
  elseif n==8 then
    add(cars,{gx=1,gy=3,len=2,dir=0,c=8})
    add(cars,{gx=1,gy=1,len=2,dir=1,c=12})
    add(cars,{gx=2,gy=1,len=2,dir=0,c=11})
    add(cars,{gx=4,gy=1,len=2,dir=1,c=13})
    add(cars,{gx=5,gy=1,len=3,dir=1,c=14})
    add(cars,{gx=6,gy=1,len=2,dir=1,c=15})
    add(cars,{gx=3,gy=2,len=2,dir=1,c=10})
    add(cars,{gx=3,gy=4,len=3,dir=0,c=9})
    add(cars,{gx=1,gy=5,len=2,dir=0,c=4})
    add(cars,{gx=6,gy=4,len=3,dir=1,c=2})
  end
end

-- check if a grid cell is occupied
-- skip_idx: car index to ignore
function cell_blocked(gx,gy,skip_idx)
  if gx<1 or gx>gw or gy<1 or gy>gh then
    return true
  end
  for i,car in pairs(cars) do
    if i!=skip_idx then
      for j=0,car.len-1 do
        local cx=car.gx
        local cy=car.gy
        if car.dir==0 then
          cx+=j
        else
          cy+=j
        end
        if cx==gx and cy==gy then
          return true
        end
      end
    end
  end
  return false
end

-- try to move the selected car
function try_move(di)
  local car=cars[sel]
  if car==nil then return end

  local can_move=true

  if car.dir==0 then
    -- horizontal car
    if di==-1 then
      -- move left
      if cell_blocked(car.gx-1,car.gy,sel) then
        can_move=false
      end
    elseif di==1 then
      -- move right: special exit check for target car
      local front=car.gx+car.len
      if sel==1 and car.gy==exit_row and front>gw then
        -- target car reaching exit - win!
        car.gx+=1
        moves+=1
        state="win"
        anim_t=0
        -- fireworks
        for i=1,30 do
          local px=grid_ox+car.gx*cell
          local py=grid_oy+car.gy*cell
          make_particle(px,py,8+flr(rnd(8)))
        end
        return
      end
      if cell_blocked(front,car.gy,sel) then
        can_move=false
      end
    end
    if can_move then
      car.gx+=di
      moves+=1
    end
  else
    -- vertical car
    if di==-1 then
      -- move up
      if cell_blocked(car.gx,car.gy-1,sel) then
        can_move=false
      end
    elseif di==1 then
      -- move down
      local front=car.gy+car.len
      if cell_blocked(car.gx,front,sel) then
        can_move=false
      end
    end
    if can_move then
      car.gy+=di
      moves+=1
    end
  end
end

function show_msg(txt)
  msg=txt
  msg_t=90
end

function _init()
  load_level(1)
  state="title"
  anim_t=0
end

function _update()
  anim_t+=1
  update_particles()

  if msg_t>0 then
    msg_t-=1
  end

  if state=="title" then
    if btnp(4) or btnp(5) then
      state="play"
      level=1
      load_level(level)
      show_msg("slide cars to free the exit!")
    end

  elseif state=="play" then
    -- select car with z/x or up/down when
    -- using tab selection
    if btnp(4) then
      -- z: prev car
      sel-=1
      if sel<1 then sel=#cars end
    end
    if btnp(5) then
      -- x: next car
      sel+=1
      if sel>#cars then sel=1 end
    end

    local car=cars[sel]
    if car then
      if car.dir==0 then
        -- horizontal: left/right to move
        if btnp(0) then try_move(-1) end
        if btnp(1) then try_move(1) end
        -- up/down to change selection
        if btnp(2) then
          sel-=1
          if sel<1 then sel=#cars end
        end
        if btnp(3) then
          sel+=1
          if sel>#cars then sel=1 end
        end
      else
        -- vertical: up/down to move
        if btnp(2) then try_move(-1) end
        if btnp(3) then try_move(1) end
        -- left/right to change selection
        if btnp(0) then
          sel-=1
          if sel<1 then sel=#cars end
        end
        if btnp(1) then
          sel+=1
          if sel>#cars then sel=1 end
        end
      end
    end

    -- restart level: press z+x together
    if btn(4) and btn(5) then
      load_level(level)
      show_msg("level reset!")
    end

  elseif state=="win" then
    -- spawn particles
    if anim_t%4==0 then
      make_particle(
        40+rnd(48),20+rnd(88),
        8+flr(rnd(8))
      )
    end

    if anim_t>30 and (btnp(4) or btnp(5)) then
      -- save best
      if best_moves[level]==nil or moves<best_moves[level] then
        best_moves[level]=moves
      end
      level+=1
      if level>total_levels then
        state="allclear"
        anim_t=0
      else
        load_level(level)
        state="play"
        show_msg("level "..level)
      end
    end

  elseif state=="allclear" then
    if anim_t%3==0 then
      make_particle(
        rnd(128),rnd(128),
        8+flr(rnd(8))
      )
    end
    if btnp(4) or btnp(5) then
      level=1
      load_level(level)
      state="play"
      best_moves={}
      show_msg("starting over!")
    end
  end
end

function _draw()
  cls(0)

  if state=="title" then
    draw_title()
    return
  end

  if state=="allclear" then
    draw_allclear()
    return
  end

  -- draw grid background
  draw_grid()

  -- draw exit arrow
  draw_exit()

  -- draw cars
  draw_cars()

  -- draw ui
  draw_hud()

  -- draw message
  if msg_t>0 then
    local my=116
    local a=1
    if msg_t<15 then a=msg_t/15 end
    if a>0.3 then
      local mw=#msg*4
      rectfill(64-mw/2-2,my-1,64+mw/2+1,my+6,0)
      print(msg,64-mw/2,my,7)
    end
  end

  -- win overlay
  if state=="win" then
    draw_win()
  end

  draw_particles()
end

function draw_title()
  -- background
  for i=0,15 do
    local c=1
    if (i+flr(anim_t/8))%4==0 then c=2 end
    rectfill(0,i*8,127,i*8+7,c)
  end

  -- title box
  rectfill(10,20,117,52,0)
  rect(10,20,117,52,8)
  rect(11,21,116,51,8)

  -- title text
  local tx=22
  local ty=28
  print("parking",tx,ty,8)
  print("parking",tx+1,ty,9)
  print("puzzle",tx+28,ty+10,7)

  -- car graphic on title
  local cy=65
  -- road
  rectfill(0,cy+2,127,cy+18,5)
  for i=0,7 do
    local lx=(i*18+flr(anim_t/2))%144-10
    rectfill(lx,cy+9,lx+8,cy+10,6)
  end

  -- animated car
  local carx=20+sin(anim_t*0.01)*30
  draw_car_sprite(carx,cy+4,2,0,8,true)

  -- instructions
  local blink=anim_t%40<25
  if blink then
    print("press z or x to start",18,95,7)
  end

  print("z/x: select car",20,106,6)
  print("arrows: slide car",20,113,6)
end

function draw_grid()
  -- grid bg
  rectfill(
    grid_ox,grid_oy,
    grid_ox+gw*cell-1,grid_oy+gh*cell-1,
    1
  )

  -- grid lines
  for x=0,gw do
    line(
      grid_ox+x*cell,grid_oy,
      grid_ox+x*cell,grid_oy+gh*cell,
      2
    )
  end
  for y=0,gh do
    line(
      grid_ox,grid_oy+y*cell,
      grid_ox+gw*cell,grid_oy+y*cell,
      2
    )
  end

  -- parking spots pattern
  for y=0,gh-1 do
    for x=0,gw-1 do
      local px=grid_ox+x*cell+cell/2
      local py=grid_oy+y*cell+cell/2
      pset(px,py,2)
    end
  end
end

function draw_exit()
  -- exit opening on right side
  local ex=grid_ox+gw*cell
  local ey=grid_oy+(exit_row-1)*cell
  -- clear wall for exit
  rectfill(ex,ey+1,ex+8,ey+cell-2,0)
  -- arrow
  local ax=ex+2
  local ay=ey+cell/2
  local bob=sin(anim_t*0.03)*2
  line(ax+bob,ay-3,ax+4+bob,ay,8)
  line(ax+bob,ay+3,ax+4+bob,ay,8)
  line(ax-2+bob,ay,ax+4+bob,ay,8)
  -- "exit" text
  print("exit",ex+1,ey-6,8)
end

function draw_car_sprite(px,py,len,dir,c,is_sel)
  local w,h
  if dir==0 then
    w=len*cell-2
    h=cell-2
  else
    w=cell-2
    h=len*cell-2
  end

  -- shadow
  rectfill(px+1,py+1,px+w,py+h,1)

  -- car body
  rectfill(px,py,px+w-1,py+h-1,c)

  -- highlight edge
  if dir==0 then
    line(px,py,px+w-1,py,c+1>15 and 7 or c+1)
    line(px,py,px,py+h-1,c+1>15 and 7 or c+1)
  else
    line(px,py,px+w-1,py,c+1>15 and 7 or c+1)
    line(px,py,px,py+h-1,c+1>15 and 7 or c+1)
  end

  -- dark edge
  line(px+w-1,py,px+w-1,py+h-1,c-1<1 and c or c-1)
  line(px,py+h-1,px+w-1,py+h-1,c-1<1 and c or c-1)

  -- windshield
  if dir==0 then
    -- horizontal car: front windshield
    local wx=px+w-5
    local wy=py+2
    rectfill(wx,wy,wx+2,wy+h-5,12)
    -- rear window
    rectfill(px+2,wy,px+4,wy+h-5,12)
    -- wheels
    rectfill(px+3,py-1,px+5,py,0)
    rectfill(px+3,py+h-1,px+5,py+h,0)
    rectfill(px+w-6,py-1,px+w-4,py,0)
    rectfill(px+w-6,py+h-1,px+w-4,py+h,0)
  else
    -- vertical car: windshields
    local wx=px+2
    local wy=py+2
    rectfill(wx,wy,wx+w-5,wy+2,12)
    -- rear window
    rectfill(wx,py+h-5,wx+w-5,py+h-3,12)
    -- wheels
    rectfill(px-1,py+3,px,py+5,0)
    rectfill(px+w-1,py+3,px+w,py+5,0)
    rectfill(px-1,py+h-6,px,py+h-4,0)
    rectfill(px+w-1,py+h-6,px+w,py+h-4,0)
  end

  -- selection indicator
  if is_sel then
    local blink=anim_t%20<14
    if blink then
      rect(px-1,py-1,px+w,py+h,7)
    end
  end
end

function draw_cars()
  for i,car in pairs(cars) do
    local px=grid_ox+(car.gx-1)*cell+1
    local py=grid_oy+(car.gy-1)*cell+1
    draw_car_sprite(
      px,py,
      car.len,car.dir,car.c,
      i==sel
    )

    -- label for target car
    if i==1 then
      local lx,ly
      if car.dir==0 then
        lx=px+car.len*cell/2-5
        ly=py+3
      else
        lx=px+2
        ly=py+car.len*cell/2-3
      end
      print("you",lx,ly,0)
    end
  end
end

function draw_hud()
  -- top bar
  rectfill(0,0,127,9,0)
  print("lv:"..level.."/"..total_levels,1,2,6)
  print("moves:"..moves,50,2,7)

  -- best for this level
  if best_moves[level] then
    print("best:"..best_moves[level],95,2,11)
  end

  -- bottom controls
  rectfill(0,121,127,127,0)
  print("z/x:sel  arrows:move",4,122,5)
end

function draw_win()
  -- overlay
  rectfill(20,40,107,80,0)
  rect(20,40,107,80,11)
  rect(21,41,106,79,3)

  print("level clear!",36,47,11)
  print("moves: "..moves,40,57,7)

  if best_moves[level] and moves<=best_moves[level] then
    print("new best!",42,65,10)
  end

  if anim_t>30 then
    local blink=anim_t%30<20
    if blink then
      print("press z or x",36,72,6)
    end
  end
end

function draw_allclear()
  -- fireworks bg
  cls(0)
  draw_particles()

  rectfill(14,15,113,112,0)
  rect(14,15,113,112,10)
  rect(15,16,112,111,11)

  print("all puzzles",30,22,10)
  print("cleared!",38,32,11)

  -- show scores
  local y=46
  for i=1,total_levels do
    local c=7
    print("level "..i..": ",22,y,6)
    if best_moves[i] then
      print(best_moves[i].." moves",62,y,11)
    else
      print("---",62,y,5)
    end
    y+=9
  end

  local blink=anim_t%30<20
  if blink then
    print("press z or x to replay",14,100,7)
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
