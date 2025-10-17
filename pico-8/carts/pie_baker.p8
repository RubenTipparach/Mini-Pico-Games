pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- pie baker game
-- collect fruits and bake pies!

-- game states
local state_menu = 0
local state_game = 1
local state_baking = 2
local state_pie_show = 3
local state_gameover = 4
local game_state = state_menu

-- player
local player = {
  x = 64,
  y = 64,
  speed = 1.5
}

-- fruits
local fruits = {}
local fruit_types = {
  {name="apple", color=8, points=10},
  {name="cherry", color=12, points=15},
  {name="orange", color=9, points=12},
  {name="berry", color=2, points=8}
}

-- inventory
local inventory = {
  apple = 0,
  cherry = 0,
  orange = 0,
  berry = 0
}

-- pie recipes
local recipes = {
  {name="apple pie", apple=3, points=100},
  {name="cherry pie", cherry=3, points=150},
  {name="mixed berry", berry=4, points=120},
  {name="fruit medley", apple=1, cherry=1, orange=1, berry=1, points=200}
}

-- game vars
local score = 0
local pies_baked = 0
local timer = 3600  -- 60 seconds
local spawn_timer = 0
local selected_recipe = 1
local pie_show_timer = 0
local current_pie = nil

function _init()
  spawn_fruits()
end

function _update()
  if game_state == state_menu then
    update_menu()
  elseif game_state == state_game then
    update_game()
  elseif game_state == state_baking then
    update_baking()
  elseif game_state == state_pie_show then
    update_pie_show()
  elseif game_state == state_gameover then
    update_gameover()
  end
end

function _draw()
  cls(3)  -- green background
  
  if game_state == state_menu then
    draw_menu()
  elseif game_state == state_game then
    draw_game()
  elseif game_state == state_baking then
    draw_baking()
  elseif game_state == state_pie_show then
    draw_pie_show()
  elseif game_state == state_gameover then
    draw_gameover()
  end
end

function update_menu()
  if btnp(4) or btnp(5) then  -- z or x
    game_state = state_game
    reset_game()
  end
end

function update_game()
  -- update timer
  timer -= 1
  if timer <= 0 then
    game_state = state_gameover
    return
  end
  
  -- player movement
  if btn(0) then player.x -= player.speed end
  if btn(1) then player.x += player.speed end
  if btn(2) then player.y -= player.speed end
  if btn(3) then player.y += player.speed end
  
  -- keep player on screen
  player.x = mid(4, player.x, 124)
  player.y = mid(4, player.y, 124)
  
  -- fruit spawning
  spawn_timer -= 1
  if spawn_timer <= 0 then
    spawn_fruit()
    spawn_timer = 60 + rnd(60)  -- 1-2 seconds
  end
  
  -- fruit collection
  for i = #fruits, 1, -1 do
    local fruit = fruits[i]
    if abs(player.x - fruit.x) < 6 and abs(player.y - fruit.y) < 6 then
      -- collect fruit
      inventory[fruit.type.name] += 1
      score += fruit.type.points
      sfx(0)  -- collect sound
      del(fruits, fruit)
    end
  end
  
  -- baking mode
  if btnp(4) then  -- z key
    game_state = state_baking
  end
end

function update_baking()
  if btnp(5) then  -- x to go back
    game_state = state_game
  end
  
  -- recipe selection with arrows
  if btnp(2) then  -- up arrow
    selected_recipe -= 1
    if selected_recipe < 1 then
      selected_recipe = #recipes
    end
  elseif btnp(3) then  -- down arrow
    selected_recipe += 1
    if selected_recipe > #recipes then
      selected_recipe = 1
    end
  end
  
  -- bake with z key
  if btnp(4) and can_bake_recipe(selected_recipe) then  -- z key
    bake_pie(selected_recipe)
  end
end

function update_gameover()
  if btnp(4) or btnp(5) then
    game_state = state_menu
  end
end

function draw_menu()
  print("pie baker", 42, 30, 7)
  print("collect fruits", 32, 50, 6)
  print("and bake pies!", 32, 58, 6)
  print("press z to start", 28, 80, 7)
  print("z=baking mode", 32, 100, 5)
  print("arrows=move", 36, 108, 5)
end

function draw_game()
  -- draw player
  circfill(player.x, player.y, 3, 7)
  circfill(player.x, player.y-1, 2, 15)  -- chef hat
  
  -- draw fruits
  for fruit in all(fruits) do
    circfill(fruit.x, fruit.y, 2, fruit.type.color)
  end
  
  -- draw hud
  draw_hud()
end

function draw_baking()
  print("baking mode", 40, 10, 7)
  print("recipes:", 10, 25, 6)
  
  for i, recipe in ipairs(recipes) do
    local y = 30 + i * 15
    local can_bake = can_bake_recipe(i)
    local color = can_bake and 7 or 5
    
    -- draw selection cursor
    if i == selected_recipe then
      print("> ", 2, y, 11)  -- yellow arrow
    end
    
    print(recipe.name, 10, y, color)
    print("pts:" .. recipe.points, 80, y, color)
    
    -- show ingredients
    local ing_text = ""
    for ingredient, amount in pairs(recipe) do
      if ingredient ~= "name" and ingredient ~= "points" then
        ing_text = ing_text .. ingredient .. ":" .. amount .. " "
      end
    end
    print(ing_text, 10, y + 6, 5)
  end
  
  print("arrows=select", 30, 100, 6)
  print("z=bake, x=return", 24, 108, 6)
end

function draw_gameover()
  print("game over!", 40, 40, 7)
  print("score: " .. score, 42, 55, 6)
  print("pies baked: " .. pies_baked, 28, 65, 6)
  print("press z to menu", 28, 85, 7)
end

function draw_hud()
  -- timer
  local time_left = flr(timer / 60)
  print("time: " .. time_left, 5, 5, 7)
  
  -- score
  print("score: " .. score, 5, 13, 7)
  
  -- inventory
  print("fruits:", 5, 25, 6)
  local y_offset = 33
  for name, count in pairs(inventory) do
    if count > 0 then
      print(name .. ": " .. count, 5, y_offset, 7)
      y_offset += 8
    end
  end
  
  -- instructions
  print("z=bake", 90, 115, 5)
end

function spawn_fruits()
  fruits = {}
  for i = 1, 5 do
    spawn_fruit()
  end
end

function spawn_fruit()
  local fruit = {
    x = 10 + rnd(108),
    y = 10 + rnd(108),
    type = fruit_types[flr(rnd(#fruit_types)) + 1]
  }
  add(fruits, fruit)
end

function can_bake_recipe(recipe_index)
  local recipe = recipes[recipe_index]
  
  for ingredient, amount in pairs(recipe) do
    if ingredient ~= "name" and ingredient ~= "points" then
      if inventory[ingredient] < amount then
        return false
      end
    end
  end
  
  return true
end

function bake_pie(recipe_index)
  local recipe = recipes[recipe_index]
  
  -- consume ingredients
  for ingredient, amount in pairs(recipe) do
    if ingredient ~= "name" and ingredient ~= "points" then
      inventory[ingredient] -= amount
    end
  end
  
  -- add score and increment pies
  score += recipe.points
  pies_baked += 1
  
  -- show the pie
  current_pie = recipe
  pie_show_timer = 120  -- 2 seconds
  game_state = state_pie_show
  
  sfx(1)  -- baking sound
end

function update_pie_show()
  pie_show_timer -= 1
  if pie_show_timer <= 0 or btnp(4) or btnp(5) then
    game_state = state_game
  end
end

function draw_pie_show()
  -- draw background
  cls(1)  -- dark blue background
  
  -- draw pie
  local pie_x = 64
  local pie_y = 50
  
  -- pie crust (brown circle)
  circfill(pie_x, pie_y, 20, 4)  -- brown
  circfill(pie_x, pie_y, 18, 15) -- tan filling
  
  -- pie filling based on type
  local fill_color = 15
  if current_pie.name == "apple pie" then
    fill_color = 8  -- red
  elseif current_pie.name == "cherry pie" then
    fill_color = 12 -- light red
  elseif current_pie.name == "mixed berry" then
    fill_color = 2  -- purple
  elseif current_pie.name == "fruit medley" then
    -- multicolored filling
    circfill(pie_x-5, pie_y-5, 3, 8)  -- apple
    circfill(pie_x+5, pie_y-5, 3, 12) -- cherry
    circfill(pie_x-5, pie_y+5, 3, 9)  -- orange
    circfill(pie_x+5, pie_y+5, 3, 2)  -- berry
    fill_color = 15
  end
  
  if current_pie.name ~= "fruit medley" then
    circfill(pie_x, pie_y, 15, fill_color)
  end
  
  -- pie crust details
  for i = 0, 7 do
    local angle = i * 0.785  -- 45 degree increments
    local x = pie_x + cos(angle) * 17
    local y = pie_y + sin(angle) * 17
    pset(x, y, 4)  -- brown crust edge
  end
  
  -- text
  local title_x = 64 - #current_pie.name * 2
  print(current_pie.name, title_x, 20, 7)
  print("+" .. current_pie.points .. " points!", 48, 85, 11)
  print("delicious!", 46, 100, 6)
  
  -- continue prompt
  print("press any key", 42, 115, 5)
end

function reset_game()
  player.x = 64
  player.y = 64
  score = 0
  pies_baked = 0
  timer = 3600
  spawn_timer = 60
  selected_recipe = 1
  pie_show_timer = 0
  current_pie = nil
  
  -- reset inventory
  for name, _ in pairs(inventory) do
    inventory[name] = 0
  end
  
  spawn_fruits()
end

__gfx__
-- sprites not needed for this simple game

__sfx__
001000000f0500e0500d0500c0500b0500a0500905007050060500505003050020500105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001705017050160501505014050130501205011050100500f0500e0500d0500c0500b0500a050090500805007050060500505004050030500205001050000000000000000000000000000000000000