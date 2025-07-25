pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- rocket staging game - v0.2

-- constants
gravity = 0.01
unit_mass = 0.1
dry_mass_per_part = 1

-- rocket parts: bottom to top
rocket = {
  {type="engine", thrust=.05, fuel=300, active=true},
  {type="fuel", fuel=20},
  {type="engine", thrust=.1, fuel=400, active=false},
}

particles = {}
y = 120
vy = 0
altitude = 0
cam_y = 0
thrusting = false
stars = {}
max_star_y = 0

function generate_stars()
  if altitude < 1000 then return end -- not in space yet

  local buffer = 200

  while max_star_y < altitude + 128 + buffer do
    for i=1, 3 do
      add(stars, {
        x = rnd(128),
        y = max_star_y + rnd(8),
        z = 0.2 + rnd(0.3),
        c = 7
      })
    end
    max_star_y += 8
  end
end

function _update()
  vy -= gravity
  thrusting = false
generate_stars()
  for part in all(rocket) do
    if part.type == "engine" and part.active and part.fuel > 0 then
      if btn(4) then -- Z key
        vy += part.thrust
        part.fuel -= 1
        thrusting = true

        -- emit flame particles
        for i=1,3 do
        local px = 64 + rnd(2) - 1
        local py = y + 2
        local pdx = rnd(1) - 0.5
        local pdy = 0.5 + rnd(0.5)

        -- flame color varies from red (8), orange (9), yellow (10), white (7)
        local flame_colors = {8, 9, 10, 7}
        local pcolor = flame_colors[flr(rnd(#flame_colors)) + 1]

        add(particles, {
            x=px,
            y=py,
            dx=pdx,
            dy=pdy,
            life=8 + flr(rnd(5)), -- 8–12
            color=pcolor
        })
        end
      end
    end
  end

  -- ground collision
    y -= vy

    if y > 120 then
    y = 120
    if vy > 0 then
        vy = 0
    end
    end
  altitude = max(0, 120 - y)
  cam_y = y - 64

  if btnp(5) then -- X key to stage
    activate_next_stage()
  end

  update_particles()
end


function activate_next_stage()
  for part in all(rocket) do
    if part.type == "engine" and not part.active then
      part.active = true
      break
    end
  end
end

function update_particles()
  for p in all(particles) do
    p.x += p.dx
    p.y += p.dy
    p.life -= 1
    if p.life <= 0 then
      del(particles, p)
    end
  end
end

function draw_particles()
  for p in all(particles) do
    pset(p.x, p.y - cam_y, p.color)
  end
end

function get_mass()
  local mass = 0
  for part in all(rocket) do
    mass += dry_mass_per_part
    if part.fuel then
      mass += part.fuel * unit_mass
    end
  end
  return mass
end

function get_total_thrust()
  local thrust = 0
  for part in all(rocket) do
    if part.type == "engine" and part.active and part.fuel > 0 then
      thrust += part.thrust
    end
  end
  return thrust
end

function get_total_isp()
  local total_thrust = 0
  local total_consumption = 0
  for part in all(rocket) do
    if part.type == "engine" and part.active and part.fuel > 0 then
      total_thrust += part.thrust
      total_consumption += 1 -- 1 fuel unit per frame
    end
  end
  if total_consumption == 0 then return 0 end
  return total_thrust / total_consumption
end

function get_total_fuel()
  local fuel = 0
  for part in all(rocket) do
    if part.fuel then fuel += part.fuel end
  end
  return fuel
end

function draw_stars()
  for s in all(stars) do
    -- parallax: stars move slowly relative to camera
    local sy =  (altitude * s.z) - s.y 
    if sy >= 0 and sy < 128 then
      pset(s.x, flr(sy), s.c)
    end
  end
end

function draw_sky()
  for i=0,127 do
    local screen_alt = altitude + i

    local c1, c2, t

    if screen_alt < 600 then
      c1 = 12 -- blue
      c2 = 5  -- gray
      t = screen_alt / 600
    elseif screen_alt < 1000 then
      c1 = 5  -- gray
      c2 = 0  -- black
      t = (screen_alt - 600) / 400
    else
      c1 = 0
      c2 = 0
      t = 1
    end

    local dither = ((i % 4) + ((i \ 4) % 4)) / 7
    local c = (dither < t) and c2 or c1

    line(0, i, 127, i, c)
  end
end




function _draw()
  cls()

  -- sky background
    draw_sky()
    draw_stars()

  -- ground
  rectfill(0, 120 - cam_y, 127, 127 - cam_y, 3)

  -- draw particles
  draw_particles()

  -- draw rocket
  local ry = y
  for part in all(rocket) do
    rectfill(60, ry - cam_y, 68, ry - 5 - cam_y, 7)
    ry -= 6
  end

  -- display UI
  local thrust = get_total_thrust()
  local mass = get_mass()
  local twr = thrust / (mass * gravity)
  local isp = get_total_isp()
  local fuel = get_total_fuel()

  print("alt: "..flr(altitude), 2, 2, 7)
  print("fuel: "..fuel, 2, 10, 11)
  print("twr: "..flr(twr*100)/100, 2, 18, 9)
  print("isp: "..flr(isp*100)/100, 2, 26, 10)
end




__gfx__
00000000000000000000000067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000dddd000670000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000dc7d006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000dccd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000d0000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000f650166501365010650126501765017650176501b6500f6500f6500f65015650106500e6501065014650156500d650146500d65014650106500e650106500e6500e6500e6500e6500f6501065014650
__music__
00 01424344

