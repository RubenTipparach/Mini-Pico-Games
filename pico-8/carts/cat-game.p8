pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- rainbow cat chase
-- by claude code

-- game states
gamestate = "playing"
win_timer = 0

-- camera system
cam = {
  x = 0,
  y = 0,
  follow_margin = 32
}

-- maze dimensions
mazew = 512
mazeh = 512
maze_grid_w = 24
maze_grid_h = 24
cell_size = 12  -- 2x cat size (6x2=12) for tighter gameplay

-- cat player
cat = {
  x = 0,
  y = 0,
  w = 6,
  h = 6,
  speed = 2,
  color_cycle = 0,
  last_dir_x = 1,
  last_dir_y = 0,
  anim_frame = 0,
  anim_timer = 0,
  is_moving = false,
  idle_timer = 0
}

-- mice enemies (multiple mice now)
mice = {}

-- hairballs
hairballs = {}

-- cheese pieces
cheese = {}

-- maze grid (1=wall, 0=path)
maze_grid = {}

function generate_maze()
  -- initialize grid with all walls
  for y=1,maze_grid_h do
    maze_grid[y] = {}
    for x=1,maze_grid_w do
      maze_grid[y][x] = 1
    end
  end
  
  -- create paths using simple maze algorithm
  local function carve_path(x, y)
    maze_grid[y][x] = 0
    
    local directions = {{0,2},{2,0},{0,-2},{-2,0}}
    -- shuffle directions
    for i=#directions,2,-1 do
      local j = flr(rnd(i))+1
      directions[i], directions[j] = directions[j], directions[i]
    end
    
    for dir in all(directions) do
      local nx, ny = x + dir[1], y + dir[2]
      if nx > 0 and nx <= maze_grid_w and ny > 0 and ny <= maze_grid_h then
        if maze_grid[ny][nx] == 1 then
          maze_grid[y + dir[2]/2][x + dir[1]/2] = 0
          carve_path(nx, ny)
        end
      end
    end
  end
  
  -- start carving from top-left corner (make sure it's odd coordinates for proper maze)
  carve_path(1, 1)
  
  -- ensure start and end are open
  maze_grid[1][1] = 0
  maze_grid[maze_grid_h][maze_grid_w] = 0
  
  -- add some extra connections to make it less linear
  for i=1,15 do
    local x = flr(rnd(maze_grid_w-2))+2
    local y = flr(rnd(maze_grid_h-2))+2
    if (x % 2 == 0 or y % 2 == 0) then
      maze_grid[y][x] = 0
    end
  end
end

function find_open_cell()
  -- find a random open cell (path, not wall)
  local attempts = 0
  while attempts < 100 do
    local x = flr(rnd(maze_grid_w)) + 1
    local y = flr(rnd(maze_grid_h)) + 1
    if maze_grid[y][x] == 0 then
      return x, y
    end
    attempts += 1
  end
  -- fallback to first open cell
  for y=1,maze_grid_h do
    for x=1,maze_grid_w do
      if maze_grid[y][x] == 0 then
        return x, y
      end
    end
  end
  return 1, 1 -- emergency fallback
end

function _init()
  -- generate the maze
  generate_maze()
  
  -- place cat in first open cell
  local cat_grid_x, cat_grid_y = find_open_cell()
  cat.x = (cat_grid_x - 1) * cell_size + cell_size/2 - cat.w/2
  cat.y = (cat_grid_y - 1) * cell_size + cell_size/2 - cat.h/2
  
  -- create multiple mice
  mice = {}
  for i=1,3 do
    local mouse_grid_x, mouse_grid_y = find_open_cell()
    local mouse = {
      x = (mouse_grid_x - 1) * cell_size + cell_size/2 - 2.5,
      y = (mouse_grid_y - 1) * cell_size + cell_size/2 - 2.5,
      w = 5,
      h = 5,
      speed = 0.8,
      stunned = 0,
      cheese_collected = 0,
      dir_x = 0,
      dir_y = 0,
      change_dir_timer = 0,
      target_cheese = nil,
      flee_timer = 0
    }
    add(mice, mouse)
  end
  
  -- place more cheese pieces in open cells
  for i=1,8 do
    local cheese_grid_x, cheese_grid_y = find_open_cell()
    local cheese_x = (cheese_grid_x - 1) * cell_size + cell_size/2 - 3
    local cheese_y = (cheese_grid_y - 1) * cell_size + cell_size/2 - 3
    add(cheese, {x=cheese_x, y=cheese_y, collected=false})
  end
end

function _update()
  if gamestate == "playing" then
    update_cat()
    update_camera()
    update_mice()
    update_hairballs()
    check_collisions()
    check_win_conditions()
  elseif gamestate == "win" or gamestate == "lose" then
    win_timer += 1
    if btnp(5) then -- restart with x
      restart_game()
    end
  end
end

function _draw()
  cls(1) -- dark blue background
  
  draw_maze()
  draw_cheese()
  draw_cat()
  draw_mice()
  draw_hairballs()
  draw_ui()
  
  if gamestate == "win" then
    print("cat wins! press x to restart", 16, 64, 7)
  elseif gamestate == "lose" then
    print("mouse escapes! press x to restart", 8, 64, 7)
  end
end

function update_cat()
  local new_x = cat.x
  local new_y = cat.y
  local moved = false
  
  if btn(0) then 
    new_x -= cat.speed
    cat.last_dir_x = -1
    cat.last_dir_y = 0
    moved = true
  end -- left
  if btn(1) then 
    new_x += cat.speed
    cat.last_dir_x = 1
    cat.last_dir_y = 0
    moved = true
  end -- right
  if btn(2) then 
    new_y -= cat.speed
    cat.last_dir_x = 0
    cat.last_dir_y = -1
    moved = true
  end -- up
  if btn(3) then 
    new_y += cat.speed
    cat.last_dir_x = 0
    cat.last_dir_y = 1
    moved = true
  end -- down
  
  -- check wall collision
  if not check_wall_collision(new_x, new_y, cat.w, cat.h) then
    cat.x = new_x
    cat.y = new_y
  end
  
  -- update animation
  cat.is_moving = moved
  if moved then
    cat.anim_timer += 1
    cat.idle_timer = 0
    if cat.anim_timer >= 8 then
      cat.anim_frame = (cat.anim_frame + 1) % 4
      cat.anim_timer = 0
    end
  else
    cat.idle_timer += 1
    cat.anim_timer = 0
    if cat.idle_timer >= 30 then
      cat.anim_frame = (cat.anim_frame + 1) % 2
      cat.idle_timer = 0
    end
  end
  
  -- shoot hairball
  if btnp(4) then -- z key
    add(hairballs, {
      x = cat.x + 4,
      y = cat.y + 4,
      dx = cat.last_dir_x * 3,
      dy = cat.last_dir_y * 3,
      speed = 3
    })
  end
  
  -- rainbow color cycle
  cat.color_cycle = (cat.color_cycle + 0.1) % 1
end

function update_mice()
  for mouse in all(mice) do
    if mouse.stunned > 0 then
      mouse.stunned -= 1
    else
      -- smart ai: find nearest cheese or flee from cat
      local cat_dist = abs(mouse.x - cat.x) + abs(mouse.y - cat.y)
      
      if cat_dist < 40 then -- cat is close, flee!
        mouse.flee_timer = 60
        mouse.target_cheese = nil
        local flee_x = mouse.x - cat.x
        local flee_y = mouse.y - cat.y
        if abs(flee_x) > abs(flee_y) then
          mouse.dir_x = sgn(flee_x)
          mouse.dir_y = 0
        else
          mouse.dir_x = 0
          mouse.dir_y = sgn(flee_y)
        end
      elseif mouse.flee_timer > 0 then
        mouse.flee_timer -= 1
        -- keep fleeing
      else
        -- look for cheese
        if not mouse.target_cheese then
          local closest_cheese = nil
          local closest_dist = 999
          for c in all(cheese) do
            if not c.collected then
              local dist = abs(mouse.x - c.x) + abs(mouse.y - c.y)
              if dist < closest_dist then
                closest_dist = dist
                closest_cheese = c
              end
            end
          end
          mouse.target_cheese = closest_cheese
        end
        
        -- move toward target cheese
        if mouse.target_cheese and not mouse.target_cheese.collected then
          local dx = mouse.target_cheese.x - mouse.x
          local dy = mouse.target_cheese.y - mouse.y
          if abs(dx) > abs(dy) then
            mouse.dir_x = sgn(dx) * 0.8
            mouse.dir_y = 0
          else
            mouse.dir_x = 0
            mouse.dir_y = sgn(dy) * 0.8
          end
        else
          mouse.target_cheese = nil
          -- random movement
          mouse.change_dir_timer -= 1
          if mouse.change_dir_timer <= 0 then
            mouse.dir_x = (rnd(3) - 1) * 0.8
            mouse.dir_y = (rnd(3) - 1) * 0.8
            mouse.change_dir_timer = 30 + rnd(30)
          end
        end
      end
      
      -- move mouse
      local new_x = mouse.x + mouse.dir_x * mouse.speed
      local new_y = mouse.y + mouse.dir_y * mouse.speed
      
      -- check boundaries and walls
      if not check_wall_collision(new_x, new_y, mouse.w, mouse.h) then
        mouse.x = new_x
        mouse.y = new_y
      else
        -- change direction if hit wall
        mouse.change_dir_timer = 0
        mouse.target_cheese = nil
      end
    end
  end
end

function update_hairballs()
  for i=#hairballs,1,-1 do
    local hb = hairballs[i]
    hb.x += hb.dx
    hb.y += hb.dy
    
    -- remove if out of bounds or hit wall
    if hb.x < 0 or hb.x > mazew or hb.y < 0 or hb.y > mazeh or
       check_wall_collision(hb.x, hb.y, 2, 2) then
      del(hairballs, hb)
    end
  end
end

function check_wall_collision(x, y, w, h)
  -- check collision with maze grid
  local left_cell = flr(x / cell_size) + 1
  local right_cell = flr((x + w - 1) / cell_size) + 1
  local top_cell = flr(y / cell_size) + 1
  local bottom_cell = flr((y + h - 1) / cell_size) + 1
  
  -- clamp to grid bounds
  left_cell = max(1, min(left_cell, maze_grid_w))
  right_cell = max(1, min(right_cell, maze_grid_w))
  top_cell = max(1, min(top_cell, maze_grid_h))
  bottom_cell = max(1, min(bottom_cell, maze_grid_h))
  
  for grid_y = top_cell, bottom_cell do
    for grid_x = left_cell, right_cell do
      if maze_grid[grid_y][grid_x] == 1 then
        return true
      end
    end
  end
  
  return false
end

function check_collisions()
  -- cat catches any mouse
  for mouse in all(mice) do
    if abs(cat.x - mouse.x) < 6 and abs(cat.y - mouse.y) < 6 then
      gamestate = "win"
      return
    end
  end
  
  -- hairball hits mice
  for hb in all(hairballs) do
    for mouse in all(mice) do
      if abs(hb.x - mouse.x) < 6 and abs(hb.y - mouse.y) < 6 then
        mouse.stunned = 90 -- 3 seconds
        mouse.target_cheese = nil
        del(hairballs, hb)
        break
      end
    end
  end
  
  -- mice collect cheese
  for mouse in all(mice) do
    for c in all(cheese) do
      if not c.collected and abs(mouse.x - c.x) < 6 and abs(mouse.y - c.y) < 6 then
        c.collected = true
        mouse.cheese_collected += 1
        mouse.target_cheese = nil
      end
    end
  end
end

function update_camera()
  local screen_w = 128
  local screen_h = 128
  local margin = cam.follow_margin
  
  -- calculate target camera position
  local target_x = cat.x - screen_w/2
  local target_y = cat.y - screen_h/2
  
  -- clamp camera to maze bounds
  target_x = max(0, min(target_x, mazew - screen_w))
  target_y = max(0, min(target_y, mazeh - screen_h))
  
  -- smooth camera movement
  cam.x += (target_x - cam.x) * 0.1
  cam.y += (target_y - cam.y) * 0.1
end

function check_win_conditions()
  -- mice win if any mouse has collected all cheese and reaches edge
  local total_cheese = 0
  for c in all(cheese) do
    if c.collected then total_cheese += 1 end
  end
  
  if total_cheese >= 8 then -- all cheese collected
    for mouse in all(mice) do
      if mouse.x <= 12 or mouse.x >= mazew-12 or mouse.y <= 12 or mouse.y >= mazeh-12 then
        gamestate = "lose"
        return
      end
    end
  end
end

function draw_maze()
  -- draw maze from grid
  for y=1,maze_grid_h do
    for x=1,maze_grid_w do
      if maze_grid[y][x] == 1 then
        local wall_x = (x-1) * cell_size
        local wall_y = (y-1) * cell_size
        rectfill(wall_x - cam.x, wall_y - cam.y, wall_x + cell_size - 1 - cam.x, wall_y + cell_size - 1 - cam.y, 5)
      end
    end
  end
end

function draw_cat()
  local screen_x = cat.x - cam.x
  local screen_y = cat.y - cam.y
  
  -- draw cat body with rainbow stripes
  for i=0,cat.h-1 do
    local colors = {8, 9, 10, 11, 12, 13, 14, 15}
    local color = colors[(i % #colors) + 1]
    line(screen_x, screen_y + i, screen_x + cat.w - 1, screen_y + i, color)
  end
  
  -- cat ears (rainbow and animated)
  local ear_offset = 0
  if cat.is_moving and cat.anim_frame % 2 == 1 then
    ear_offset = 1
  end
  pset(screen_x + 1 + ear_offset, screen_y - 1, 8)
  pset(screen_x + 6 - ear_offset, screen_y - 1, 12)
  
  -- animated eyes
  local eye_y_offset = 0
  if not cat.is_moving and cat.anim_frame == 1 then
    eye_y_offset = 1 -- blink
  end
  
  if eye_y_offset == 0 then
    pset(screen_x + 2, screen_y + 2, 0)
    pset(screen_x + 5, screen_y + 2, 0)
  end
  
  -- animated legs/paws when running
  if cat.is_moving then
    local leg_offset = cat.anim_frame % 2
    -- front paws
    pset(screen_x + 1 + leg_offset, screen_y + cat.h, 0)
    pset(screen_x + 6 - leg_offset, screen_y + cat.h, 0)
    -- back paws
    pset(screen_x + 2 - leg_offset, screen_y + cat.h, 0)
    pset(screen_x + 5 + leg_offset, screen_y + cat.h, 0)
  end
  
  -- tail animation
  local tail_x = screen_x + cat.w
  local tail_y = screen_y + 3
  local tail_curve = 0
  
  if cat.is_moving then
    tail_curve = sgn(sin(cat.anim_frame * 0.5)) * 2
  else
    tail_curve = sgn(sin(cat.idle_timer * 0.1)) * 1
  end
  
  -- draw curved tail
  line(tail_x, tail_y, tail_x + 2, tail_y - 1 + tail_curve, 8)
  line(tail_x + 2, tail_y - 1 + tail_curve, tail_x + 4, tail_y + 1 - tail_curve, 9)
  
  -- whiskers
  pset(screen_x - 1, screen_y + 3, 7)
  pset(screen_x + cat.w, screen_y + 3, 7)
end

function draw_mice()
  for mouse in all(mice) do
    local color = mouse.stunned > 0 and 6 or 13 -- flash when stunned
    rectfill(mouse.x - cam.x, mouse.y - cam.y, mouse.x + mouse.w - 1 - cam.x, mouse.y + mouse.h - 1 - cam.y, color)
    -- mouse tail
    line(mouse.x + 5 - cam.x, mouse.y + 2 - cam.y, mouse.x + 8 - cam.x, mouse.y + 1 - cam.y, color)
    -- eyes
    pset(mouse.x + 1 - cam.x, mouse.y + 1 - cam.y, 0)
    pset(mouse.x + 3 - cam.x, mouse.y + 1 - cam.y, 0)
  end
end

function draw_cheese()
  for c in all(cheese) do
    if not c.collected then
      rectfill(c.x - cam.x, c.y - cam.y, c.x + 6 - cam.x, c.y + 6 - cam.y, 10) -- yellow
      pset(c.x + 2 - cam.x, c.y + 2 - cam.y, 9) -- orange dot
      pset(c.x + 4 - cam.x, c.y + 4 - cam.y, 9)
    end
  end
end

function draw_hairballs()
  for hb in all(hairballs) do
    circfill(hb.x - cam.x, hb.y - cam.y, 1, 4) -- brown
  end
end

function draw_ui()
  local total_cheese = 0
  local total_collected = 0
  for c in all(cheese) do
    total_cheese += 1
    if c.collected then total_collected += 1 end
  end
  
  print("cheese: " .. total_collected .. "/" .. total_cheese, 2, 2, 7)
  print("mice: " .. #mice, 2, 10, 7)
  
  local stunned_count = 0
  for mouse in all(mice) do
    if mouse.stunned > 0 then stunned_count += 1 end
  end
  
  if stunned_count > 0 then
    print("stunned: " .. stunned_count, 90, 2, 8)
  end
end

function restart_game()
  gamestate = "playing"
  win_timer = 0
  
  -- reset cat to an open cell
  local cat_grid_x, cat_grid_y = find_open_cell()
  cat.x = (cat_grid_x - 1) * cell_size + cell_size/2 - cat.w/2
  cat.y = (cat_grid_y - 1) * cell_size + cell_size/2 - cat.h/2
  cat.last_dir_x = 1
  cat.last_dir_y = 0
  cat.anim_frame = 0
  cat.anim_timer = 0
  cat.is_moving = false
  cat.idle_timer = 0
  
  -- reset mouse to an open cell  
  local mouse_grid_x, mouse_grid_y = find_open_cell()
  mouse.x = (mouse_grid_x - 1) * cell_size + cell_size/2 - mouse.w/2
  mouse.y = (mouse_grid_y - 1) * cell_size + cell_size/2 - mouse.h/2
  mouse.stunned = 0
  mouse.cheese_collected = 0
  mouse.dir_x = 0
  mouse.dir_y = 0
  
  -- clear hairballs
  hairballs = {}
  
  -- reset cheese
  for c in all(cheese) do
    c.collected = false
  end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
