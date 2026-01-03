pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- space murder mystery
-- a top-down rpg detective game

-- game states
state = "title"
-- title, playing, dialogue, clue, accusation, win, lose

-- player
player = {
  x = 64, y = 64,
  room = 1,
  speed = 1.5,
  dir = 2, -- 0=up,1=right,2=down,3=left
  anim = 0
}

-- rooms: 1=bridge, 2=medbay, 3=engine, 4=cargo, 5=quarters
rooms = {
  {name="bridge", col=12},
  {name="medbay", col=11},
  {name="engine room", col=9},
  {name="cargo bay", col=4},
  {name="crew quarters", col=13}
}

-- doors between rooms (x,y,to_room,spawn_x,spawn_y)
doors = {
  -- bridge doors
  {room=1, x=120, y=56, w=8, h=16, to=2, sx=16, sy=64},
  {room=1, x=0, y=56, w=8, h=16, to=3, sx=112, sy=64},
  -- medbay doors
  {room=2, x=0, y=56, w=8, h=16, to=1, sx=112, sy=64},
  {room=2, x=120, y=56, w=8, h=16, to=4, sx=16, sy=64},
  -- engine doors
  {room=3, x=120, y=56, w=8, h=16, to=1, sx=16, sy=64},
  {room=3, x=64, y=120, w=16, h=8, to=5, sx=64, sy=16},
  -- cargo doors
  {room=4, x=0, y=56, w=8, h=16, to=2, sx=112, sy=64},
  {room=4, x=64, y=120, w=16, h=8, to=5, sx=64, sy=16},
  -- quarters doors
  {room=5, x=32, y=0, w=16, h=8, to=3, sx=64, sy=104},
  {room=5, x=80, y=0, w=16, h=8, to=4, sx=64, sy=104}
}

-- suspects (npcs)
suspects = {
  {
    name="dr. nova",
    role="ship doctor",
    room=2, x=80, y=40,
    col=11,
    motive="captain threatened to report her for stealing medical supplies",
    alibi="was in medbay treating a patient",
    guilty=false,
    questioned=false,
    lines={
      "the captain was alive when i last saw him.",
      "i heard a loud noise from the bridge.",
      "check the cargo bay... i saw something odd there."
    }
  },
  {
    name="engineer vex",
    role="chief engineer",
    room=3, x=40, y=80,
    col=9,
    motive="captain was going to demote him for the engine failures",
    alibi="was fixing a plasma conduit in engineering",
    guilty=true, -- the killer!
    questioned=false,
    lines={
      "i was busy with repairs all shift.",
      "the captain was harsh... but i didn't...",
      "my wrench is missing. someone took it!"
    }
  },
  {
    name="lt. orion",
    role="security chief",
    room=4, x=90, y=70,
    col=8,
    motive="captain discovered his smuggling operation",
    alibi="was doing cargo inspection",
    guilty=false,
    questioned=false,
    lines={
      "i found the body on my patrol.",
      "no forced entry. must be crew.",
      "everyone had reasons to hate the captain."
    }
  },
  {
    name="nav. stella",
    role="navigator",
    room=5, x=64, y=80,
    col=14,
    motive="captain rejected her transfer request",
    alibi="was in quarters reviewing star charts",
    guilty=false,
    questioned=false,
    lines={
      "the captain and i disagreed, yes.",
      "but i would never resort to violence!",
      "check engineering... i heard clanging."
    }
  }
}

-- clues to find
clues = {
  {
    name="bloody wrench",
    room=1, x=96, y=80,
    found=false,
    desc="a wrench with blood stains. the murder weapon!"
  },
  {
    name="oil stains",
    room=1, x=48, y=90,
    found=false,
    desc="engine oil on the floor. leads to engineering."
  },
  {
    name="torn badge",
    room=3, x=100, y=50,
    found=false,
    desc="a piece of engineer vex's id badge."
  },
  {
    name="schedule log",
    room=2, x=30, y=60,
    found=false,
    desc="shows dr. nova was busy with a patient."
  },
  {
    name="cargo manifest",
    room=4, x=50, y=40,
    found=false,
    desc="proves lt. orion was in cargo bay."
  }
}

-- victim (captain's body)
victim = {
  room=1, x=64, y=64,
  examined=false
}

-- dialogue system
dialogue = {
  active=false,
  npc=nil,
  line=1,
  text="",
  choices={}
}

-- found clues list
found_clues = {}

-- game timer
game_time = 0

function _init()
  state = "title"
  player.x = 64
  player.y = 90
  player.room = 1
end

function _update60()
  if state == "title" then
    if btnp(4) or btnp(5) then
      state = "playing"
      -- show intro
      show_message("captain reed is dead!\ninvestigate the crime scene.")
    end
  elseif state == "playing" then
    update_player()
    check_doors()
    check_interactions()
    game_time += 1
  elseif state == "dialogue" then
    update_dialogue()
  elseif state == "message" then
    if btnp(4) or btnp(5) then
      state = "playing"
    end
  elseif state == "accusation" then
    update_accusation()
  elseif state == "win" or state == "lose" then
    if btnp(4) or btnp(5) then
      _init()
    end
  end
end

function update_player()
  local nx, ny = player.x, player.y

  if btn(0) then
    nx -= player.speed
    player.dir = 3
  end
  if btn(1) then
    nx += player.speed
    player.dir = 1
  end
  if btn(2) then
    ny -= player.speed
    player.dir = 0
  end
  if btn(3) then
    ny += player.speed
    player.dir = 2
  end

  -- boundary check
  nx = mid(8, nx, 120)
  ny = mid(16, ny, 112)

  -- simple collision with furniture would go here
  player.x = nx
  player.y = ny

  -- animation
  if btn(0) or btn(1) or btn(2) or btn(3) then
    player.anim = (player.anim + 0.2) % 4
  end
end

function check_doors()
  for d in all(doors) do
    if d.room == player.room then
      if player.x > d.x and player.x < d.x + d.w and
         player.y > d.y and player.y < d.y + d.h then
        player.room = d.to
        player.x = d.sx
        player.y = d.sy
        sfx(0)
        return
      end
    end
  end
end

function check_interactions()
  if not btnp(4) then return end

  -- check npcs
  for s in all(suspects) do
    if s.room == player.room then
      local dist = abs(player.x - s.x) + abs(player.y - s.y)
      if dist < 20 then
        start_dialogue(s)
        return
      end
    end
  end

  -- check clues
  for c in all(clues) do
    if not c.found and c.room == player.room then
      local dist = abs(player.x - c.x) + abs(player.y - c.y)
      if dist < 16 then
        c.found = true
        add(found_clues, c)
        show_message("found: " .. c.name .. "\n" .. c.desc)
        sfx(1)
        return
      end
    end
  end

  -- check victim
  if player.room == 1 and not victim.examined then
    local dist = abs(player.x - victim.x) + abs(player.y - victim.y)
    if dist < 20 then
      victim.examined = true
      show_message("captain reed's body.\nblunt force trauma to head.\ntime of death: 2 hours ago.")
      return
    end
  end

  -- accusation mode (press x near bridge console)
  if player.room == 1 and player.x > 50 and player.x < 78 and player.y < 30 then
    if #found_clues >= 3 then
      start_accusation()
    else
      show_message("need more evidence before\nmaking an accusation.\nfind more clues!")
    end
  end
end

function start_dialogue(npc)
  state = "dialogue"
  dialogue.npc = npc
  dialogue.line = 1
  dialogue.text = npc.lines[1]
  npc.questioned = true
end

function update_dialogue()
  if btnp(4) or btnp(5) then
    dialogue.line += 1
    if dialogue.line > #dialogue.npc.lines then
      -- show motive and alibi
      if dialogue.line == #dialogue.npc.lines + 1 then
        dialogue.text = "motive: " .. dialogue.npc.motive
      elseif dialogue.line == #dialogue.npc.lines + 2 then
        dialogue.text = "alibi: " .. dialogue.npc.alibi
      else
        state = "playing"
        dialogue.npc = nil
      end
    else
      dialogue.text = dialogue.npc.lines[dialogue.line]
    end
  end
end

function show_message(txt)
  state = "message"
  dialogue.text = txt
end

-- accusation system
accuse_cursor = 1

function start_accusation()
  state = "accusation"
  accuse_cursor = 1
end

function update_accusation()
  if btnp(2) then accuse_cursor = max(1, accuse_cursor - 1) end
  if btnp(3) then accuse_cursor = min(4, accuse_cursor + 1) end

  if btnp(4) then
    local accused = suspects[accuse_cursor]
    if accused.guilty then
      state = "win"
    else
      state = "lose"
    end
  end

  if btnp(5) then
    state = "playing"
  end
end

function _draw()
  cls(0)

  if state == "title" then
    draw_title()
  elseif state == "win" then
    draw_win()
  elseif state == "lose" then
    draw_lose()
  else
    draw_room()
    draw_objects()
    draw_npcs()
    draw_player()
    draw_ui()

    if state == "dialogue" or state == "message" then
      draw_dialogue()
    elseif state == "accusation" then
      draw_accusation()
    end
  end
end

function draw_title()
  -- starfield
  for i=0,50 do
    local sx = (i*17+game_time/2) % 128
    local sy = (i*23) % 128
    pset(sx, sy, 7)
  end
  game_time += 1

  -- title
  local tx = 20
  print("~~~~~~~~~~~~~~~~~", tx, 20, 1)
  print("~~~~~~~~~~~~~~~~~", tx, 21, 5)

  print("space murder", tx+10, 35, 12)
  print("mystery", tx+30, 45, 11)

  print("~~~~~~~~~~~~~~~~~", tx, 60, 5)
  print("~~~~~~~~~~~~~~~~~", tx, 61, 1)

  print("a detective rpg", tx+8, 80, 6)

  if (game_time/30) % 2 < 1 then
    print("press z to start", tx+4, 100, 7)
  end
end

function draw_room()
  local room = rooms[player.room]

  -- floor
  rectfill(0, 0, 127, 127, 1)

  -- grid pattern for floor
  for x=0,127,8 do
    line(x, 0, x, 127, 0)
  end
  for y=0,127,8 do
    line(0, y, 127, y, 0)
  end

  -- walls
  rectfill(0, 0, 127, 12, room.col)
  rectfill(0, 0, 6, 127, room.col)
  rectfill(121, 0, 127, 127, room.col)
  rectfill(0, 115, 127, 127, room.col)

  -- room name
  print(room.name, 48, 3, 0)

  -- draw doors
  for d in all(doors) do
    if d.room == player.room then
      rectfill(d.x, d.y, d.x+d.w, d.y+d.h, 10)
    end
  end

  -- room-specific decorations
  if player.room == 1 then
    -- bridge: console at top
    rectfill(40, 16, 88, 28, 5)
    rectfill(42, 18, 86, 26, 0)
    -- blinking lights
    for i=0,4 do
      pset(44+i*10, 22, 8+((game_time/10+i)%4))
    end
    print("console", 52, 20, 11)
  elseif player.room == 2 then
    -- medbay: beds
    rectfill(20, 30, 50, 50, 6)
    rectfill(70, 30, 100, 50, 6)
    print("bed", 30, 38, 7)
    print("bed", 80, 38, 7)
  elseif player.room == 3 then
    -- engine: machinery
    rectfill(20, 20, 60, 60, 5)
    for i=0,3 do
      circ(40, 40, 8+i*4, 8+i)
    end
    print("reactor", 26, 65, 9)
  elseif player.room == 4 then
    -- cargo: crates
    for i=0,2 do
      for j=0,1 do
        rectfill(20+i*35, 25+j*50, 40+i*35, 45+j*50, 4)
        rect(20+i*35, 25+j*50, 40+i*35, 45+j*50, 5)
      end
    end
  elseif player.room == 5 then
    -- quarters: bunks
    rectfill(20, 40, 45, 100, 13)
    rectfill(80, 40, 105, 100, 13)
    print("bunk", 26, 68, 7)
    print("bunk", 86, 68, 7)
  end
end

function draw_objects()
  -- draw clues
  for c in all(clues) do
    if not c.found and c.room == player.room then
      -- sparkle effect
      local sparkle = (game_time/8) % 4
      circfill(c.x, c.y, 3, 10)
      if sparkle < 2 then
        pset(c.x-2, c.y-2, 7)
        pset(c.x+2, c.y+2, 7)
      else
        pset(c.x+2, c.y-2, 7)
        pset(c.x-2, c.y+2, 7)
      end
    end
  end

  -- draw victim
  if player.room == 1 then
    -- body outline
    rectfill(victim.x-8, victim.y-4, victim.x+8, victim.y+4, 8)
    -- x eyes
    print("x x", victim.x-6, victim.y-2, 0)
    if not victim.examined then
      print("?", victim.x-2, victim.y-12, 7)
    end
  end
end

function draw_npcs()
  for s in all(suspects) do
    if s.room == player.room then
      -- body
      circfill(s.x, s.y, 6, s.col)
      -- face
      circfill(s.x, s.y-2, 4, 15)
      -- eyes
      pset(s.x-1, s.y-3, 0)
      pset(s.x+1, s.y-3, 0)
      -- name tag
      local tw = #s.name * 2
      print(s.name, s.x - tw, s.y - 14, 7)

      -- question mark if not questioned
      if not s.questioned then
        print("?", s.x + 8, s.y - 8, 11)
      end
    end
  end
end

function draw_player()
  local px, py = player.x, player.y

  -- body
  circfill(px, py, 5, 12)

  -- face direction indicator
  local fx, fy = 0, 0
  if player.dir == 0 then fy = -3
  elseif player.dir == 1 then fx = 3
  elseif player.dir == 2 then fy = 3
  elseif player.dir == 3 then fx = -3
  end

  -- head
  circfill(px, py-2, 4, 15)

  -- eyes
  pset(px-1+fx/2, py-3+fy/2, 0)
  pset(px+1+fx/2, py-3+fy/2, 0)

  -- detective hat
  rectfill(px-4, py-8, px+4, py-6, 5)
  rectfill(px-2, py-10, px+2, py-8, 5)

  -- walking animation
  if btn(0) or btn(1) or btn(2) or btn(3) then
    local legoff = sin(player.anim) * 2
    pset(px-2, py+5+legoff, 0)
    pset(px+2, py+5-legoff, 0)
  end
end

function draw_ui()
  -- clue counter
  rectfill(0, 120, 50, 127, 0)
  print("clues:"..#found_clues.."/5", 2, 121, 7)

  -- help text
  print("z:interact", 70, 121, 6)
end

function draw_dialogue()
  -- dialogue box
  rectfill(4, 80, 124, 124, 0)
  rect(4, 80, 124, 124, 7)
  rect(5, 81, 123, 123, 6)

  if dialogue.npc then
    -- speaker name
    print(dialogue.npc.name, 10, 84, dialogue.npc.col)
    line(8, 92, 120, 92, 6)
  end

  -- text with word wrap
  local txt = dialogue.text
  local y = 96
  local line = ""
  for word in all(split(txt, " ")) do
    if #line + #word > 26 then
      print(line, 10, y, 7)
      y += 8
      line = word .. " "
    else
      line = line .. word .. " "
    end
  end
  print(line, 10, y, 7)

  -- continue prompt
  if (game_time/20) % 2 < 1 then
    print("z", 116, 116, 11)
  end
end

function draw_accusation()
  -- accusation menu
  rectfill(10, 20, 118, 108, 0)
  rect(10, 20, 118, 108, 8)
  rect(11, 21, 117, 107, 5)

  print("make accusation", 28, 26, 8)
  line(20, 35, 108, 35, 5)

  print("who killed captain reed?", 16, 40, 7)

  for i=1,4 do
    local s = suspects[i]
    local col = 6
    if i == accuse_cursor then
      col = 11
      print(">", 18, 48+i*12, 11)
    end
    print(s.name, 28, 48+i*12, col)
    print("("..s.role..")", 70, 48+i*12, 5)
  end

  print("z:accuse  x:cancel", 24, 100, 6)
end

function draw_win()
  cls(0)
  -- stars
  for i=0,30 do
    pset((i*17)%128, (i*23)%128, 7)
  end

  print("case closed!", 36, 30, 11)

  rectfill(20, 45, 108, 90, 5)
  rect(20, 45, 108, 90, 6)

  print("engineer vex", 38, 52, 9)
  print("is guilty!", 42, 62, 8)

  print("the evidence proved", 22, 75, 7)
  print("beyond doubt.", 36, 83, 7)

  print("great detective work!", 18, 100, 10)

  if (game_time/30)%2<1 then
    print("press z to restart", 20, 115, 6)
  end
  game_time += 1
end

function draw_lose()
  cls(0)

  print("wrong accusation!", 28, 30, 8)

  rectfill(20, 45, 108, 85, 1)
  rect(20, 45, 108, 85, 2)

  print("the real killer", 30, 52, 7)
  print("was engineer vex!", 26, 62, 9)

  print("he escapes...", 36, 75, 8)

  print("review the evidence", 22, 95, 6)
  print("more carefully!", 32, 105, 6)

  if (game_time/30)%2<1 then
    print("press z to retry", 24, 118, 5)
  end
  game_time += 1
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001505015050150401503015020150101500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002465024650216501d6501a650176501465011650006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
