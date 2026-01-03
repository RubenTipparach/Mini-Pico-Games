pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- space blaster 3d
-- epic space shooter

-- globals
player=nil
bullets={}
enemies={}
particles={}
powerups={}
stars={}
shake=0
score=0
wave=1
wave_timer=0
boss=nil
game_state="title"
flash=0
combo=0
combo_timer=0
hi_score=0

-- 3d ship rendering data
-- ship vertices for pseudo-3d
ship_verts={
 {-4,0},{0,-6},{4,0},{0,2}
}

function _init()
 -- init stars
 for i=1,50 do
  add(stars,{
   x=rnd(128),
   y=rnd(128),
   spd=rnd(2)+0.5,
   c=rnd()>0.7 and 7 or 6
  })
 end
 hi_score=dget(0)
end

function new_game()
 player={
  x=64,y=100,
  vx=0,vy=0,
  bank=0,-- banking angle
  hp=5,max_hp=5,
  power=1,
  shield=0,
  fire_rate=8,
  fire_timer=0,
  spread=1,
  invuln=60,
  magnet=0
 }
 bullets={}
 enemies={}
 particles={}
 powerups={}
 boss=nil
 score=0
 wave=1
 wave_timer=180
 combo=0
 combo_timer=0
 game_state="play"
end

function _update60()
 if game_state=="title" then
  update_title()
 elseif game_state=="play" then
  update_game()
 elseif game_state=="gameover" then
  update_gameover()
 end
end

function update_title()
 update_stars()
 if btnp(4) or btnp(5) then
  new_game()
  sfx(0)
 end
end

function update_gameover()
 update_stars()
 update_particles()
 if btnp(4) or btnp(5) then
  game_state="title"
 end
end

function update_game()
 if flash>0 then flash-=1 end
 if shake>0 then shake-=0.5 end
 if combo_timer>0 then
  combo_timer-=1
 else
  combo=0
 end

 update_stars()
 update_player()
 update_bullets()
 update_enemies()
 update_boss()
 update_powerups()
 update_particles()
 spawn_waves()

 if player.hp<=0 then
  game_over()
 end
end

function update_stars()
 for s in all(stars) do
  s.y+=s.spd
  if s.y>128 then
   s.y=0
   s.x=rnd(128)
  end
 end
end

function update_player()
 local p=player
 if p.invuln>0 then p.invuln-=1 end
 if p.shield>0 then p.shield-=1 end

 -- movement with momentum
 local acc=0.5
 local fric=0.85
 local max_spd=3

 if btn(0) then p.vx-=acc end
 if btn(1) then p.vx+=acc end
 if btn(2) then p.vy-=acc end
 if btn(3) then p.vy+=acc end

 -- banking based on horizontal velocity
 p.bank=p.vx*0.3
 p.bank=mid(-1,p.bank,1)

 p.vx*=fric
 p.vy*=fric
 p.vx=mid(-max_spd,p.vx,max_spd)
 p.vy=mid(-max_spd,p.vy,max_spd)

 p.x+=p.vx
 p.y+=p.vy
 p.x=mid(8,p.x,120)
 p.y=mid(16,p.y,120)

 -- shooting
 p.fire_timer-=1
 if btn(4) and p.fire_timer<=0 then
  fire_player_bullet()
  p.fire_timer=p.fire_rate
 end

 -- engine particles
 if rnd()<0.5 then
  spawn_particle(
   p.x+rnd(4)-2,
   p.y+4,
   rnd(1)-0.5,
   rnd(2)+1,
   {10,9,8,2},
   10+rnd(5)
  )
 end
end

function fire_player_bullet()
 local p=player
 sfx(1)

 local spread=p.spread
 local pw=p.power

 if spread>=1 then
  add(bullets,{
   x=p.x,y=p.y-6,
   vx=0,vy=-6,
   dmg=pw,player=true,
   c=10
  })
 end

 if spread>=2 then
  add(bullets,{
   x=p.x-4,y=p.y-4,
   vx=-0.5,vy=-5.5,
   dmg=pw,player=true,c=10
  })
  add(bullets,{
   x=p.x+4,y=p.y-4,
   vx=0.5,vy=-5.5,
   dmg=pw,player=true,c=10
  })
 end

 if spread>=3 then
  add(bullets,{
   x=p.x-6,y=p.y-2,
   vx=-1,vy=-5,
   dmg=pw,player=true,c=9
  })
  add(bullets,{
   x=p.x+6,y=p.y-2,
   vx=1,vy=-5,
   dmg=pw,player=true,c=9
  })
 end
end

function update_bullets()
 for b in all(bullets) do
  b.x+=b.vx
  b.y+=b.vy

  if b.x<-8 or b.x>136 or
     b.y<-8 or b.y>136 then
   del(bullets,b)
  end

  -- player bullets hit enemies
  if b.player then
   for e in all(enemies) do
    if dist(b.x,b.y,e.x,e.y)<e.r then
     e.hp-=b.dmg
     del(bullets,b)
     spawn_hit_effect(b.x,b.y)
     if e.hp<=0 then
      kill_enemy(e)
     end
     break
    end
   end
   -- hit boss
   if boss and dist(b.x,b.y,boss.x,boss.y)<boss.r then
    boss.hp-=b.dmg
    del(bullets,b)
    spawn_hit_effect(b.x,b.y)
    boss.hit_flash=5
    if boss.hp<=0 then
     kill_boss()
    end
   end
  else
   -- enemy bullets hit player
   if player.invuln<=0 and
      player.shield<=0 and
      dist(b.x,b.y,player.x,player.y)<6 then
    player.hp-=1
    player.invuln=60
    del(bullets,b)
    shake=10
    sfx(3)
   end
  end
 end
end

function update_enemies()
 for e in all(enemies) do
  -- update pattern
  e.t+=1
  local pt=e.pattern

  if pt=="dive" then
   e.y+=e.spd
   e.x+=sin(e.t*0.02)*2
   e.bank=cos(e.t*0.02)*0.5
  elseif pt=="sine" then
   e.y+=e.spd*0.5
   e.x=e.ox+sin(e.t*0.03)*40
   e.bank=cos(e.t*0.03)*0.8
  elseif pt=="circle" then
   e.angle+=0.02
   e.x=e.cx+cos(e.angle)*e.rad
   e.y=e.cy+sin(e.angle)*e.rad+e.spd*e.t*0.1
   e.bank=sin(e.angle)*0.6
  elseif pt=="swoop" then
   if e.phase==0 then
    e.y+=e.spd
    if e.y>60 then e.phase=1 end
   else
    e.y+=e.spd*0.3
    e.x+=e.dir*2
    e.bank=e.dir*0.7
   end
  elseif pt=="zigzag" then
   e.y+=e.spd
   e.zig_t+=1
   if e.zig_t>30 then
    e.dir=-e.dir
    e.zig_t=0
   end
   e.x+=e.dir*2
   e.bank=e.dir*0.6
  elseif pt=="kamikaze" then
   local dx=player.x-e.x
   local dy=player.y-e.y
   local d=sqrt(dx*dx+dy*dy)
   if d>0 then
    e.x+=dx/d*e.spd
    e.y+=dy/d*e.spd
    e.bank=dx/d*0.8
   end
  end

  -- shooting
  e.fire_t-=1
  if e.fire_t<=0 and e.y>0 and e.y<120 then
   if e.shoot_type=="aimed" then
    fire_aimed(e)
   elseif e.shoot_type=="spread" then
    fire_spread(e)
   elseif e.shoot_type=="burst" then
    fire_burst(e)
   end
   e.fire_t=e.fire_rate
  end

  -- remove if off screen
  if e.y>140 or e.y<-50 or
     e.x<-30 or e.x>158 then
   del(enemies,e)
  end

  -- collision with player
  if player.invuln<=0 and
     player.shield<=0 and
     dist(e.x,e.y,player.x,player.y)<e.r+4 then
   player.hp-=1
   player.invuln=60
   e.hp-=2
   shake=8
   sfx(3)
   if e.hp<=0 then
    kill_enemy(e)
   end
  end
 end
end

function fire_aimed(e)
 local dx=player.x-e.x
 local dy=player.y-e.y
 local d=sqrt(dx*dx+dy*dy)
 if d>0 then
  add(bullets,{
   x=e.x,y=e.y,
   vx=dx/d*3,vy=dy/d*3,
   player=false,c=8
  })
  sfx(2)
 end
end

function fire_spread(e)
 for i=-1,1 do
  add(bullets,{
   x=e.x,y=e.y,
   vx=i*1.5,vy=3,
   player=false,c=8
  })
 end
 sfx(2)
end

function fire_burst(e)
 for i=0,5 do
  local a=i/6
  add(bullets,{
   x=e.x,y=e.y,
   vx=cos(a)*2,vy=sin(a)*2,
   player=false,c=8
  })
 end
 sfx(2)
end

function kill_enemy(e)
 del(enemies,e)
 spawn_explosion(e.x,e.y,e.r)
 score+=e.score*(1+combo*0.1)
 combo+=1
 combo_timer=120
 sfx(4)

 -- drop powerup
 if rnd()<0.25 then
  spawn_powerup(e.x,e.y)
 end
end

function spawn_explosion(x,y,r)
 for i=1,r*3 do
  spawn_particle(
   x,y,
   rnd(4)-2,rnd(4)-2,
   {10,9,8,5,1},
   15+rnd(15)
  )
 end
 shake=max(shake,r)
end

function spawn_hit_effect(x,y)
 for i=1,3 do
  spawn_particle(
   x,y,
   rnd(2)-1,rnd(2)-1,
   {7,10,9},
   5+rnd(5)
  )
 end
end

function spawn_particle(x,y,vx,vy,colors,life)
 add(particles,{
  x=x,y=y,vx=vx,vy=vy,
  colors=colors,
  life=life,max_life=life
 })
end

function update_particles()
 for p in all(particles) do
  p.x+=p.vx
  p.y+=p.vy
  p.vx*=0.95
  p.vy*=0.95
  p.life-=1
  if p.life<=0 then
   del(particles,p)
  end
 end
end

function spawn_powerup(x,y)
 local types={"power","spread","heal","shield","rapid","magnet"}
 local t=types[flr(rnd(#types))+1]
 add(powerups,{
  x=x,y=y,
  vy=0.5,
  type=t,
  t=0
 })
end

function update_powerups()
 for pw in all(powerups) do
  pw.t+=1
  pw.y+=pw.vy

  -- magnet effect
  if player.magnet>0 then
   local dx=player.x-pw.x
   local dy=player.y-pw.y
   local d=dist(pw.x,pw.y,player.x,player.y)
   if d<50 then
    pw.x+=dx/d*2
    pw.y+=dy/d*2
   end
  end

  -- collect
  if dist(pw.x,pw.y,player.x,player.y)<12 then
   collect_powerup(pw)
   del(powerups,pw)
  elseif pw.y>135 then
   del(powerups,pw)
  end
 end
end

function collect_powerup(pw)
 sfx(5)
 flash=10
 local t=pw.type

 if t=="power" then
  player.power=min(player.power+1,5)
 elseif t=="spread" then
  player.spread=min(player.spread+1,3)
 elseif t=="heal" then
  player.hp=min(player.hp+2,player.max_hp)
 elseif t=="shield" then
  player.shield=180
 elseif t=="rapid" then
  player.fire_rate=max(player.fire_rate-1,3)
 elseif t=="magnet" then
  player.magnet=300
 end

 -- visual feedback
 for i=1,8 do
  spawn_particle(
   pw.x,pw.y,
   cos(i/8)*2,sin(i/8)*2,
   {7,11,3},
   15
  )
 end
end

function spawn_waves()
 wave_timer-=1
 if wave_timer<=0 and not boss then
  if wave%5==0 then
   spawn_boss()
  else
   spawn_wave()
  end
  wave_timer=300+wave*20
  wave+=1
 end
end

function spawn_wave()
 local formations={
  "v_formation",
  "line",
  "circle_in",
  "pincer",
  "random"
 }
 local fm=formations[flr(rnd(#formations))+1]
 local patterns={"dive","sine","circle","swoop","zigzag","kamikaze"}
 local pt=patterns[flr(rnd(#patterns))+1]
 local count=4+flr(wave/2)
 count=min(count,12)

 local shoot_types={"aimed","spread","none"}
 local st=shoot_types[flr(rnd(#shoot_types))+1]
 if wave>3 and rnd()<0.3 then
  st="burst"
 end

 for i=1,count do
  local e={
   hp=1+flr(wave/3),
   r=6,
   t=0,
   pattern=pt,
   spd=1+wave*0.1,
   fire_t=60+rnd(60),
   fire_rate=90-wave*2,
   shoot_type=st,
   score=100+wave*10,
   bank=0,
   ship_type=flr(rnd(3))+1
  }

  -- formation positioning
  if fm=="v_formation" then
   local ox=64
   e.x=ox+(i-count/2)*12
   e.y=-10-abs(i-count/2)*8
  elseif fm=="line" then
   e.x=20+i*(88/count)
   e.y=-10-i*5
  elseif fm=="circle_in" then
   local a=i/count
   e.x=64+cos(a)*50
   e.y=-10
  elseif fm=="pincer" then
   if i<=count/2 then
    e.x=-10
    e.y=10+i*10
    e.dir=1
   else
    e.x=138
    e.y=10+(i-count/2)*10
    e.dir=-1
   end
   e.pattern="swoop"
   e.phase=0
  else
   e.x=rnd(100)+14
   e.y=-10-rnd(50)
  end

  -- pattern specific init
  e.ox=e.x
  e.cx=e.x
  e.cy=30
  e.rad=30
  e.angle=rnd(1)
  e.dir=rnd()>0.5 and 1 or -1
  e.zig_t=0
  e.phase=0

  add(enemies,e)
 end
end

function spawn_boss()
 local hp=50+wave*20
 boss={
  x=64,y=-40,
  tx=64,ty=40,
  hp=hp,max_hp=hp,
  r=24,
  phase=1,
  t=0,
  attack_t=0,
  attack="none",
  hit_flash=0,
  parts={}
 }
 -- boss parts/turrets
 for i=1,2 do
  add(boss.parts,{
   ox=(i==1) and -20 or 20,
   oy=10,
   hp=20+wave*5,
   alive=true
  })
 end
end

function update_boss()
 if not boss then return end
 local b=boss
 b.t+=1
 if b.hit_flash>0 then b.hit_flash-=1 end

 -- movement
 if b.y<b.ty then
  b.y+=1
 else
  -- oscillate
  b.x=64+sin(b.t*0.01)*40
 end

 -- attack patterns
 b.attack_t-=1
 if b.attack_t<=0 then
  local attacks={"spiral","aimed","sweep","spawn"}
  b.attack=attacks[flr(rnd(#attacks))+1]
  b.attack_t=120
  b.attack_phase=0
 end

 -- execute attack
 if b.attack=="spiral" then
  if b.t%4==0 then
   local a=b.t*0.1
   add(bullets,{
    x=b.x,y=b.y+10,
    vx=cos(a)*3,vy=sin(a)*3+1,
    player=false,c=8
   })
   sfx(2)
  end
 elseif b.attack=="aimed" then
  if b.t%20==0 then
   for i=-1,1 do
    local dx=player.x-b.x+i*20
    local dy=player.y-b.y
    local d=sqrt(dx*dx+dy*dy)
    add(bullets,{
     x=b.x,y=b.y+15,
     vx=dx/d*4,vy=dy/d*4,
     player=false,c=14
    })
   end
   sfx(2)
  end
 elseif b.attack=="sweep" then
  if b.t%3==0 then
   local a=sin(b.t*0.05)*0.3+0.25
   add(bullets,{
    x=b.x,y=b.y+15,
    vx=cos(a)*4,vy=sin(a)*4,
    player=false,c=9
   })
   sfx(2)
  end
 elseif b.attack=="spawn" then
  if b.attack_phase==0 then
   -- spawn mini enemies
   for i=1,3 do
    add(enemies,{
     x=b.x+(i-2)*20,
     y=b.y+20,
     hp=2,r=4,t=0,
     pattern="kamikaze",
     spd=2,fire_t=999,
     fire_rate=999,
     shoot_type="none",
     score=50,bank=0,
     ship_type=1,
     ox=b.x,cx=b.x,cy=b.y,
     rad=20,angle=0,dir=1,
     zig_t=0,phase=0
    })
   end
   b.attack_phase=1
  end
 end

 -- turrets shoot
 for p in all(b.parts) do
  if p.alive and b.t%40==0 then
   local px=b.x+p.ox
   local py=b.y+p.oy
   local dx=player.x-px
   local dy=player.y-py
   local d=sqrt(dx*dx+dy*dy)
   add(bullets,{
    x=px,y=py,
    vx=dx/d*2.5,vy=dy/d*2.5,
    player=false,c=12
   })
  end
 end

 -- turret hit detection
 for p in all(b.parts) do
  if p.alive then
   local px=b.x+p.ox
   local py=b.y+p.oy
   for bul in all(bullets) do
    if bul.player and dist(bul.x,bul.y,px,py)<8 then
     p.hp-=bul.dmg
     del(bullets,bul)
     spawn_hit_effect(bul.x,bul.y)
     if p.hp<=0 then
      p.alive=false
      spawn_explosion(px,py,10)
      score+=500
     end
    end
   end
  end
 end
end

function kill_boss()
 spawn_explosion(boss.x,boss.y,30)
 for i=1,5 do
  spawn_powerup(
   boss.x+rnd(40)-20,
   boss.y+rnd(40)-20
  )
 end
 score+=5000+wave*1000
 boss=nil
 shake=20
 sfx(6)
end

function game_over()
 game_state="gameover"
 if score>hi_score then
  hi_score=score
  dset(0,hi_score)
 end
 sfx(7)
end

function dist(x1,y1,x2,y2)
 local dx=x2-x1
 local dy=y2-y1
 return sqrt(dx*dx+dy*dy)
end

-- 3d ship rendering
function draw_ship_3d(x,y,bank,c1,c2,scl)
 scl=scl or 1
 -- bank affects width (-1 to 1)
 local w_mult=1-abs(bank)*0.6

 -- ship body vertices
 local pts={}
 for i,v in pairs(ship_verts) do
  pts[i]={
   x=x+v[1]*w_mult*scl,
   y=y+v[2]*scl
  }
 end

 -- banking visual: offset wing
 local wing_off=bank*3*scl

 -- draw shadow/depth
 local shade=c2
 if bank<0 then
  -- left wing forward
  line(pts[1].x,pts[1].y,pts[2].x-wing_off,pts[2].y,shade)
  line(pts[1].x,pts[1].y,pts[4].x,pts[4].y,shade)
 else
  -- right wing forward
  line(pts[3].x,pts[3].y,pts[2].x-wing_off,pts[2].y,shade)
  line(pts[3].x,pts[3].y,pts[4].x,pts[4].y,shade)
 end

 -- main body
 line(pts[1].x,pts[1].y,pts[2].x-wing_off,pts[2].y,c1)
 line(pts[2].x-wing_off,pts[2].y,pts[3].x,pts[3].y,c1)
 line(pts[3].x,pts[3].y,pts[4].x,pts[4].y,c1)
 line(pts[4].x,pts[4].y,pts[1].x,pts[1].y,c1)

 -- cockpit
 pset(x,y-2*scl,c2)

 -- engine glow
 local eng_c=8+flr(rnd(3))
 if scl>=1 then
  pset(x,y+3*scl,eng_c)
 end
end

function draw_enemy_ship(x,y,bank,ship_type)
 local c1,c2=8,2
 if ship_type==2 then c1,c2=11,3 end
 if ship_type==3 then c1,c2=14,4 end

 draw_ship_3d(x,y+6,-bank,c1,c2,0.8)
end

function _draw()
 cls(0)

 local sx,sy=0,0
 if shake>0 then
  sx=rnd(shake)-shake/2
  sy=rnd(shake)-shake/2
 end
 camera(sx,sy)

 -- stars
 for s in all(stars) do
  pset(s.x,s.y,s.c)
 end

 if game_state=="title" then
  draw_title()
 elseif game_state=="play" then
  draw_game()
 elseif game_state=="gameover" then
  draw_gameover()
 end

 camera()
end

function draw_title()
 -- title with glow effect
 local t=time()
 for i=0,2 do
  local c=1+i
  print("space blaster",28+i/2,30-i,c)
 end
 print("space blaster",28,30,10)
 print("3d",74,30,9)

 -- subtitle pulse
 local pc=7+flr(sin(t*2)*2)
 print("press ❎ to start",24,60,pc)

 print("hi-score: "..hi_score,28,80,6)

 -- animated ships
 local bk=sin(t*3)*0.8
 draw_ship_3d(64,100,bk,10,9,1.5)

 for i=1,3 do
  local ex=30+i*25
  local ey=115+sin(t*2+i)*5
  draw_enemy_ship(ex,ey,sin(t*2+i)*0.5,i)
 end
end

function draw_game()
 -- enemies
 for e in all(enemies) do
  draw_enemy_ship(e.x,e.y,e.bank,e.ship_type)
 end

 -- boss
 if boss then
  draw_boss()
 end

 -- player
 if player.invuln%4<2 then
  local c1,c2=10,9
  if player.shield>0 then
   c1=12 c2=1
   -- shield bubble
   circ(player.x,player.y,10,12)
  end
  draw_ship_3d(player.x,player.y,player.bank,c1,c2,1)
 end

 -- bullets
 for b in all(bullets) do
  if b.player then
   local c=b.c or 10
   line(b.x,b.y,b.x,b.y-4,c)
   pset(b.x,b.y-5,7)
  else
   circfill(b.x,b.y,2,b.c or 8)
   pset(b.x,b.y,7)
  end
 end

 -- powerups
 for pw in all(powerups) do
  local bob=sin(pw.t*0.1)*2
  local c=11
  local ic=""
  if pw.type=="power" then c=9 ic="p"
  elseif pw.type=="spread" then c=12 ic="s"
  elseif pw.type=="heal" then c=11 ic="+"
  elseif pw.type=="shield" then c=14 ic="o"
  elseif pw.type=="rapid" then c=10 ic="r"
  elseif pw.type=="magnet" then c=13 ic="m"
  end
  circfill(pw.x,pw.y+bob,5,c)
  print(ic,pw.x-2,pw.y+bob-2,7)
 end

 -- particles
 for p in all(particles) do
  local ci=flr((1-p.life/p.max_life)*#p.colors)+1
  ci=min(ci,#p.colors)
  pset(p.x,p.y,p.colors[ci])
 end

 -- ui
 draw_ui()

 -- flash effect
 if flash>0 then
  for i=0,127,4 do
   line(i,0,i,127,7)
  end
 end
end

function draw_boss()
 local b=boss
 local c=b.hit_flash>0 and 7 or 8

 -- main body
 rectfill(b.x-20,b.y-15,b.x+20,b.y+15,c)
 rectfill(b.x-24,b.y-10,b.x+24,b.y+10,c)
 rect(b.x-20,b.y-15,b.x+20,b.y+15,2)

 -- details
 rectfill(b.x-8,b.y-12,b.x+8,b.y-8,2)
 for i=-1,1,2 do
  line(b.x+i*15,b.y-15,b.x+i*18,b.y-20,c)
  line(b.x+i*15,b.y+15,b.x+i*18,b.y+20,c)
 end

 -- turrets
 for p in all(b.parts) do
  if p.alive then
   local px=b.x+p.ox
   local py=b.y+p.oy
   circfill(px,py,6,11)
   circ(px,py,6,3)
   circfill(px,py,2,14)
  end
 end

 -- core
 local cc=8+flr(sin(b.t*0.1)*3)
 circfill(b.x,b.y,8,cc)
 circ(b.x,b.y,8,7)

 -- health bar
 local hw=40
 local hp_pct=b.hp/b.max_hp
 rectfill(b.x-hw/2,b.y-25,b.x+hw/2,b.y-22,5)
 rectfill(b.x-hw/2,b.y-25,b.x-hw/2+hw*hp_pct,b.y-22,8)
 rect(b.x-hw/2,b.y-25,b.x+hw/2,b.y-22,7)
end

function draw_ui()
 camera()

 -- health
 print("hp",2,2,7)
 for i=1,player.max_hp do
  local c=i<=player.hp and 8 or 5
  rectfill(12+(i-1)*6,2,16+(i-1)*6,6,c)
 end

 -- power level
 print("pow:"..player.power,2,10,9)

 -- spread
 print("spr:"..player.spread,40,10,12)

 -- shield timer
 if player.shield>0 then
  print("shield:"..flr(player.shield/60),70,10,14)
 end

 -- score
 print("score:"..flr(score),70,2,7)

 -- wave
 print("wave:"..wave,2,120,6)

 -- combo
 if combo>1 then
  local cc=7+flr(sin(time()*8)*2)
  print(combo.."x combo!",50,60,cc)
 end

 -- boss warning
 if wave%5==4 and wave_timer<120 and wave_timer%20<10 then
  print("⚠ boss incoming ⚠",25,50,8)
 end
end

function draw_gameover()
 -- particles continue
 for p in all(particles) do
  local ci=flr((1-p.life/p.max_life)*#p.colors)+1
  ci=min(ci,#p.colors)
  pset(p.x,p.y,p.colors[ci])
 end

 rectfill(20,40,108,88,1)
 rect(20,40,108,88,7)

 print("game over",42,46,8)
 print("score: "..flr(score),38,58,7)
 print("wave: "..wave,46,66,6)

 if score>=hi_score then
  print("new high score!",32,76,11)
 else
  print("press ❎",48,76,6)
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000c0500c0500c0500c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001805018050180501805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000c0300c0300c0300c030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001f0501f0501a050150501005005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002405024050200501c05018050140500f0500a050050500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001005010050130501805020050280502f0503405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002c0502c0502805024050200501c0501805014050100500c05008050040500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c0500c0500a050080500605004050020500105000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
