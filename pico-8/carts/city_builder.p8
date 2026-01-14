pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- city builder incremental
-- build from house to ecumenopolis!
-- controls: arrows=menu, z=select
-- x=back/save

-- ===== game state =====
money=100
pop=0
workers=0
happiness=50
tax_rate=10
tick=0
tier=1
research_pts=0
total_earned=0
buildings_built=0
game_time=0

-- tier names and thresholds
tiers={"hamlet","village","town","city","megacity","ecumenopolis"}
tier_req={0,10,100,500,2000,10000}

-- ===== buildings data =====
-- {name,cost,income,pop_add,workers_req,spr,unlocked,tier_req}
b_types={
 {n="shack",c=10,i=1,p=2,w=0,s=1,u=true,t=1},
 {n="house",c=50,i=3,p=5,w=0,s=2,u=true,t=1},
 {n="apartment",c=200,i=8,p=15,w=2,s=3,u=false,t=2},
 {n="condo",c=800,i=20,p=40,w=5,s=4,u=false,t=3},
 {n="tower",c=3000,i=60,p=120,w=15,s=5,u=false,t=4},
 {n="arcology",c=15000,i=200,p=500,w=50,s=6,u=false,t=5},
 {n="megaplex",c=80000,i=800,p=2000,w=200,s=7,u=false,t=6},
}
-- services
s_types={
 {n="well",c=30,h=5,w=1,s=8,u=true,t=1},
 {n="school",c=150,h=10,w=5,s=9,u=false,t=2},
 {n="clinic",c=300,h=15,w=8,s=10,u=false,t=2},
 {n="park",c=100,h=8,w=0,s=11,u=true,t=1},
 {n="mall",c=1000,h=20,w=15,s=12,u=false,t=3},
 {n="hospital",c=2500,h=30,w=25,s=13,u=false,t=3},
 {n="stadium",c=8000,h=50,w=40,s=14,u=false,t=4},
 {n="univ",c=5000,h=40,w=30,s=15,u=false,t=4},
 {n="spaceport",c=50000,h=100,w=100,s=16,u=false,t=5},
}
-- industry
i_types={
 {n="workshop",c=80,i=5,w=3,s=17,u=true,t=1},
 {n="factory",c=400,i=15,w=10,s=18,u=false,t=2},
 {n="office",c=600,i=20,w=12,s=19,u=false,t=3},
 {n="tech hub",c=2000,i=50,w=30,s=20,u=false,t=4},
 {n="lab",c=5000,i=80,w=50,s=21,u=false,t=4},
 {n="fusion",c=25000,i=200,w=80,s=22,u=false,t=5},
}
-- tech tree
techs={
 {n="plumbing",c=100,desc="unlock apartments",done=false},
 {n="medicine",c=200,desc="unlock clinic",done=false},
 {n="education",c=300,desc="unlock school",done=false},
 {n="commerce",c=500,desc="unlock mall,office",done=false},
 {n="industry",c=400,desc="unlock factory",done=false},
 {n="healthcare",c=800,desc="unlock hospital",done=false},
 {n="urban plan",c=1200,desc="unlock condo",done=false},
 {n="entertain",c=1500,desc="unlock stadium",done=false},
 {n="higher ed",c=2000,desc="unlock university",done=false},
 {n="skyscraper",c=3000,desc="unlock tower",done=false},
 {n="computing",c=2500,desc="unlock tech hub",done=false},
 {n="research",c=4000,desc="unlock lab",done=false},
 {n="energy",c=8000,desc="unlock fusion",done=false},
 {n="space age",c=15000,desc="unlock spaceport",done=false},
 {n="biodome",c=25000,desc="unlock arcology",done=false},
 {n="planetary",c=50000,desc="unlock megaplex",done=false},
}

-- owned buildings
buildings={}
services={}
industries={}

-- achievements
achievements={
 {n="first home",d="build first house",done=false},
 {n="neighborhood",d="reach 50 pop",done=false},
 {n="small town",d="reach village tier",done=false},
 {n="urbanite",d="reach city tier",done=false},
 {n="mogul",d="earn $10000 total",done=false},
 {n="researcher",d="complete 5 techs",done=false},
 {n="metropolis",d="reach megacity",done=false},
 {n="planetary",d="reach ecumenopolis",done=false},
}

-- ui state
menu=1 -- 1=build,2=service,3=industry,4=research,5=tax,6=stats
sub_sel=1
scroll=0
msg=""
msg_t=0
anim_t=0
show_help=true

-- particle effects
particles={}

-- multipliers
income_mult=1
growth_mult=1

-- ===== helpers =====
function clamp(x,a,b) return max(a,min(b,x)) end

function say(s)
 msg=s msg_t=120
end

function add_particle(x,y,c,txt)
 add(particles,{x=x,y=y,c=c,t=txt,life=60,vy=-0.5})
end

-- ===== core mechanics =====
function calc_income()
 local inc=0
 for b in all(buildings) do
  inc+=b_types[b.t].i*b.lvl
 end
 for i in all(industries) do
  if workers>=i_types[i.t].w*i.lvl then
   inc+=i_types[i.t].i*i.lvl
  end
 end
 -- tax income from population
 inc+=flr(pop*tax_rate/100)
 -- apply multiplier
 inc=flr(inc*income_mult)
 return inc
end

function calc_expenses()
 local exp=0
 for s in all(services) do
  exp+=flr(s_types[s.t].c*0.01)*s.lvl
 end
 return exp
end

function calc_happiness()
 local h=50
 -- services boost
 for s in all(services) do
  h+=s_types[s.t].h*s.lvl/2
 end
 -- tax penalty
 if tax_rate>20 then h-=(tax_rate-20)*2 end
 if tax_rate>40 then h-=(tax_rate-40)*3 end
 -- overcrowding
 local cap=0
 for s in all(services) do cap+=s_types[s.t].h*s.lvl*2 end
 if pop>cap+50 then h-=flr((pop-cap)/20) end
 return clamp(flr(h),0,100)
end

function calc_workers()
 -- workers = pop * happiness factor
 local factor=happiness/100
 return flr(pop*factor*0.6)
end

function calc_pop_growth()
 local growth=0
 if happiness>=60 then
  growth=flr(happiness/20)
 elseif happiness>=40 then
  growth=1
 elseif happiness<30 then
  growth=-flr((30-happiness)/10)
 end
 -- tax affects growth
 if tax_rate>30 then growth-=1 end
 if tax_rate>50 then growth-=2 end
 if tax_rate<10 then growth+=1 end
 return growth
end

function check_tier()
 for i=6,1,-1 do
  if pop>=tier_req[i] then
   if tier<i then
    tier=i
    say("upgraded to "..tiers[i].."!")
    add_particle(64,60,11,"+"..tiers[i])
    unlock_tier(i)
   end
   return
  end
 end
end

function unlock_tier(t)
 for b in all(b_types) do
  if b.t<=t then b.u=true end
 end
 for s in all(s_types) do
  if s.t<=t then s.u=true end
 end
 for i in all(i_types) do
  if i.t<=t then i.u=true end
 end
end

function unlock_tech(tech)
 local n=tech.n
 if n=="plumbing" then b_types[3].u=true end
 if n=="medicine" then s_types[3].u=true end
 if n=="education" then s_types[2].u=true end
 if n=="commerce" then s_types[5].u=true i_types[3].u=true end
 if n=="industry" then i_types[2].u=true end
 if n=="healthcare" then s_types[6].u=true end
 if n=="urban plan" then b_types[4].u=true end
 if n=="entertain" then s_types[7].u=true end
 if n=="higher ed" then s_types[8].u=true end
 if n=="skyscraper" then b_types[5].u=true end
 if n=="computing" then i_types[4].u=true end
 if n=="research" then i_types[5].u=true end
 if n=="energy" then i_types[6].u=true end
 if n=="space age" then s_types[9].u=true end
 if n=="biodome" then b_types[6].u=true end
 if n=="planetary" then b_types[7].u=true end
end

function check_achievements()
 -- first home
 if #buildings>0 and not achievements[1].done then
  achievements[1].done=true
  say("🏆 first home!")
  add_particle(64,60,11,"achievement!")
 end
 -- 50 pop
 if pop>=50 and not achievements[2].done then
  achievements[2].done=true
  say("🏆 neighborhood!")
 end
 -- village
 if tier>=2 and not achievements[3].done then
  achievements[3].done=true
  say("🏆 small town!")
 end
 -- city
 if tier>=4 and not achievements[4].done then
  achievements[4].done=true
  say("🏆 urbanite!")
  income_mult+=0.1
 end
 -- mogul
 if total_earned>=10000 and not achievements[5].done then
  achievements[5].done=true
  say("🏆 mogul! +10% income")
  income_mult+=0.1
 end
 -- researcher
 local tc=0
 for t in all(techs) do if t.done then tc+=1 end end
 if tc>=5 and not achievements[6].done then
  achievements[6].done=true
  say("🏆 researcher!")
 end
 -- megacity
 if tier>=5 and not achievements[7].done then
  achievements[7].done=true
  say("🏆 metropolis! +20% income")
  income_mult+=0.2
 end
 -- ecumenopolis
 if tier>=6 and not achievements[8].done then
  achievements[8].done=true
  say("🏆 PLANETARY! you win!")
 end
end

-- ===== save/load =====
function save_game()
 -- pack data into cartdata
 dset(0,money)
 dset(1,pop)
 dset(2,tax_rate)
 dset(3,research_pts)
 dset(4,total_earned)
 dset(5,#buildings)
 dset(6,#services)
 dset(7,#industries)
 -- pack buildings
 local idx=10
 for b in all(buildings) do
  dset(idx,b.t) dset(idx+1,b.lvl)
  idx+=2
 end
 -- pack services
 idx=30
 for s in all(services) do
  dset(idx,s.t) dset(idx+1,s.lvl)
  idx+=2
 end
 -- pack industries
 idx=50
 for i in all(industries) do
  dset(idx,i.t) dset(idx+1,i.lvl)
  idx+=2
 end
 say("game saved!")
end

function load_game()
 if dget(0)==0 then return false end
 money=dget(0)
 pop=dget(1)
 tax_rate=dget(2)
 research_pts=dget(3)
 total_earned=dget(4)
 local nb=dget(5)
 local ns=dget(6)
 local ni=dget(7)
 -- load buildings
 buildings={}
 local idx=10
 for i=1,nb do
  add(buildings,{t=dget(idx),lvl=dget(idx+1)})
  idx+=2
 end
 -- load services
 services={}
 idx=30
 for i=1,ns do
  add(services,{t=dget(idx),lvl=dget(idx+1)})
  idx+=2
 end
 -- load industries
 industries={}
 idx=50
 for i=1,ni do
  add(industries,{t=dget(idx),lvl=dget(idx+1)})
  idx+=2
 end
 check_tier()
 say("game loaded!")
 return true
end

-- ===== building functions =====
function buy_building(idx)
 local bt=b_types[idx]
 if not bt.u then say("locked!") return end
 if money<bt.c then say("need $"..bt.c) return end
 money-=bt.c
 -- check if already owned
 for b in all(buildings) do
  if b.t==idx then
   b.lvl+=1
   pop+=bt.p
   say("+"..bt.n.." lvl"..b.lvl)
   add_particle(64,40,11,"+"..bt.p.." pop")
   return
  end
 end
 add(buildings,{t=idx,lvl=1})
 pop+=bt.p
 say("built "..bt.n)
 add_particle(64,40,11,"+"..bt.p.." pop")
end

function buy_service(idx)
 local st=s_types[idx]
 if not st.u then say("locked!") return end
 if money<st.c then say("need $"..st.c) return end
 if workers<st.w then say("need "..st.w.." workers") return end
 money-=st.c
 for s in all(services) do
  if s.t==idx then
   s.lvl+=1
   say("+"..st.n.." lvl"..s.lvl)
   add_particle(64,40,10,"+"..st.h.." happy")
   return
  end
 end
 add(services,{t=idx,lvl=1})
 say("built "..st.n)
 add_particle(64,40,10,"+"..st.h.." happy")
end

function buy_industry(idx)
 local it=i_types[idx]
 if not it.u then say("locked!") return end
 if money<it.c then say("need $"..it.c) return end
 if workers<it.w then say("need "..it.w.." workers") return end
 money-=it.c
 for i in all(industries) do
  if i.t==idx then
   i.lvl+=1
   say("+"..it.n.." lvl"..i.lvl)
   add_particle(64,40,9,"+"..it.i.."/s")
   return
  end
 end
 add(industries,{t=idx,lvl=1})
 say("built "..it.n)
 add_particle(64,40,9,"+"..it.i.."/s")
end

function buy_tech(idx)
 local tech=techs[idx]
 if tech.done then say("already done") return end
 if research_pts<tech.c then say("need "..tech.c.." rp") return end
 research_pts-=tech.c
 tech.done=true
 unlock_tech(tech)
 say("researched "..tech.n.."!")
 add_particle(64,40,12,"unlocked!")
end

-- ===== game loop =====
function _init()
 cartdata("city_builder_v1")
 if not load_game() then
  -- new game: start with 1 shack
  buy_building(1)
 end
end

function _update60()
 tick+=1
 anim_t+=1
 game_time+=1

 -- income every second
 if tick%60==0 then
  local inc=calc_income()-calc_expenses()
  money+=inc
  if inc>0 then
   total_earned+=inc
   add_particle(10,12,11,"+"..inc)
  elseif inc<0 then
   add_particle(10,12,8,inc)
  end

  -- research points from labs & universities
  for i in all(industries) do
   if i_types[i.t].n=="lab" then
    research_pts+=5*i.lvl
   end
  end
  for s in all(services) do
   if s_types[s.t].n=="univ" then
    research_pts+=2*s.lvl
   end
  end

  -- auto save every 30 seconds
  if tick%1800==0 then
   save_game()
  end
 end

 -- pop growth every 3 sec
 if tick%180==0 then
  local g=calc_pop_growth()
  g=flr(g*growth_mult)
  if g~=0 and pop>0 then
   pop=max(0,pop+g)
   if g>0 then
    add_particle(64,20,11,"+"..g.." pop")
   else
    add_particle(64,20,8,g.." pop")
   end
  end
 end

 -- update stats
 happiness=calc_happiness()
 workers=calc_workers()
 check_tier()
 check_achievements()

 -- update particles
 for p in all(particles) do
  p.y+=p.vy
  p.life-=1
  if p.life<=0 then del(particles,p) end
 end

 -- message timer
 if msg_t>0 then msg_t-=1 end

 -- dismiss help after first input
 if show_help and (btn()>0) then show_help=false end

 -- input
 handle_input()
end

function handle_input()
 -- menu tabs
 if btnp(0) then menu=max(1,menu-1) sub_sel=1 scroll=0 end
 if btnp(1) then menu=min(6,menu+1) sub_sel=1 scroll=0 end

 -- list navigation
 local list_len=get_list_len()
 if menu~=5 and menu~=6 then
  if btnp(2) then sub_sel=max(1,sub_sel-1) end
  if btnp(3) then sub_sel=min(list_len,sub_sel+1) end
 end

 -- scroll
 if sub_sel>scroll+5 then scroll=sub_sel-5 end
 if sub_sel<=scroll then scroll=max(0,sub_sel-1) end

 -- select (z button)
 if btnp(4) then
  if menu==1 then buy_building(sub_sel)
  elseif menu==2 then buy_service(sub_sel)
  elseif menu==3 then buy_industry(sub_sel)
  elseif menu==4 then buy_tech(sub_sel)
  end
 end

 -- x button = save
 if btnp(5) then
  save_game()
 end

 -- tax controls in tax menu
 if menu==5 then
  if btnp(2) then tax_rate=min(100,tax_rate+5) say("tax: "..tax_rate.."%") end
  if btnp(3) then tax_rate=max(0,tax_rate-5) say("tax: "..tax_rate.."%") end
 end
end

function get_list_len()
 if menu==1 then return #b_types
 elseif menu==2 then return #s_types
 elseif menu==3 then return #i_types
 elseif menu==4 then return #techs
 else return 1 end
end

-- ===== drawing =====
function _draw()
 cls(1)

 draw_header()
 draw_city_view()
 draw_menu()
 draw_particles()

 -- message
 if msg_t>0 then
  rectfill(0,118,127,127,0)
  print(msg,64-#msg*2,120,7)
 end

 -- help overlay
 if show_help then
  rectfill(10,30,117,95,0)
  rect(10,30,117,95,7)
  print("city builder",38,33,11)
  print("",20,42,6)
  print("⬅️➡️ switch tabs",20,45,7)
  print("⬆️⬇️ select/adjust",20,53,7)
  print("🅾️ buy/build",20,61,7)
  print("❎ save game",20,69,7)
  print("",20,77,6)
  print("goal: ecumenopolis!",24,80,10)
  print("press any key...",28,88,6)
 end
end

function draw_header()
 -- top bar
 rectfill(0,0,127,18,0)

 -- tier with glow
 local tc=11
 if tier>=4 then tc=10 end
 if tier>=5 then tc=9 end
 if tier>=6 then tc=8 end
 print(tiers[tier],1,1,tc)

 -- stats
 print("$"..format_num(money),1,8,11)
 print("pop:"..format_num(pop),40,8,12)
 print("👨:"..workers,82,8,7)

 -- happiness bar
 local hc=11
 if happiness<40 then hc=8 end
 if happiness<25 then hc=2 end
 rectfill(1,15,1+happiness/2,17,hc)
 rect(1,15,51,17,6)
 print(happiness.."%",54,15,hc)

 -- income/expense
 local inc=calc_income()-calc_expenses()
 local ic=11 if inc<0 then ic=8 end
 print((inc>=0 and "+" or "")..inc.."/s",90,15,ic)

 -- research pts
 print("rp:"..research_pts,90,1,12)
end

function draw_city_view()
 -- city visualization area
 rectfill(0,19,63,75,1)
 rect(0,19,63,75,6)

 -- draw ground
 rectfill(1,65,62,74,3)

 -- draw buildings based on owned
 local bx=4
 for b in all(buildings) do
  local bt=b_types[b.t]
  draw_building(bx,64,b.t,b.lvl)
  bx+=10
  if bx>55 then bx=4 end
 end

 -- draw services
 local sx=4
 for s in all(services) do
  draw_service(sx,50,s.t)
  sx+=8
  if sx>55 then sx=4 end
 end

 -- animated elements
 if anim_t%30<15 then
  -- blinking lights on tall buildings
  for b in all(buildings) do
   if b.t>=5 then
    pset(8+rnd(50),25+rnd(20),rnd()>0.5 and 10 or 8)
   end
  end
 end

 -- clouds
 local cx=(anim_t/4)%80-10
 spr(32,cx,22)
 spr(32,cx+40,28)
end

function draw_building(x,y,t,lvl)
 -- different buildings by type
 local h=8+t*4+lvl*2
 h=min(h,40)
 local w=6+t
 w=min(w,10)

 local c1=6 local c2=5
 if t==1 then c1=4 c2=2 end --shack brown
 if t==2 then c1=6 c2=13 end --house gray
 if t==3 then c1=12 c2=1 end --apt blue
 if t==4 then c1=7 c2=6 end --condo white
 if t==5 then c1=10 c2=9 end --tower yellow
 if t==6 then c1=11 c2=3 end --arcology green
 if t==7 then c1=8 c2=14 end --megaplex red

 rectfill(x,y-h,x+w,y,c1)
 rect(x,y-h,x+w,y,c2)

 -- windows
 for wy=y-h+2,y-2,4 do
  for wx=x+1,x+w-1,2 do
   local wc=0
   if (anim_t+wx+wy)%60<30 then wc=10 end
   pset(wx,wy,wc)
  end
 end

 -- level indicator
 if lvl>1 then
  print(lvl,x,y-h-6,7)
 end
end

function draw_service(x,y,t)
 local st=s_types[t]
 local c=11
 if t<=2 then c=12 end
 if t>=5 then c=10 end
 if t>=8 then c=9 end

 -- simple service icon
 circfill(x+3,y+3,3,c)
 print(sub(st.n,1,1),x+1,y+1,0)
end

function draw_menu()
 -- menu area right side
 rectfill(64,19,127,117,0)
 rect(64,19,127,117,6)

 -- tabs
 local tabs={"bld","svc","ind","tec","tax","sta"}
 for i=1,6 do
  local tx=64+(i-1)*11
  local tc=5
  if menu==i then tc=7 rectfill(tx,19,tx+9,25,1) end
  print(sub(tabs[i],1,3),tx+1,20,tc)
 end

 line(64,26,127,26,6)

 -- list content
 local y=28
 if menu==1 then
  print("housing",68,y,12) y+=8
  for i=1,#b_types do
   if i>scroll and i<=scroll+5 then
    draw_item(i,b_types[i],y,i==sub_sel,"b")
    y+=14
   end
  end
 elseif menu==2 then
  print("services",68,y,12) y+=8
  for i=1,#s_types do
   if i>scroll and i<=scroll+5 then
    draw_item(i,s_types[i],y,i==sub_sel,"s")
    y+=14
   end
  end
 elseif menu==3 then
  print("industry",68,y,12) y+=8
  for i=1,#i_types do
   if i>scroll and i<=scroll+5 then
    draw_item(i,i_types[i],y,i==sub_sel,"i")
    y+=14
   end
  end
 elseif menu==4 then
  print("research",68,y,12) y+=8
  for i=1,#techs do
   if i>scroll and i<=scroll+5 then
    draw_tech(i,techs[i],y,i==sub_sel)
    y+=14
   end
  end
 elseif menu==5 then
  print("tax rate",68,y,12) y+=10
  print("⬆️⬇️ adjust",70,y,6) y+=10

  -- big tax display
  local tc=11
  if tax_rate>30 then tc=10 end
  if tax_rate>50 then tc=8 end
  print(tax_rate.."%",85,y+5,tc)
  y+=20

  -- effects preview
  print("effects:",68,y,6) y+=8
  if tax_rate<10 then
   print("+growth",70,y,11) y+=7
   print("-income",70,y,8)
  elseif tax_rate<=20 then
   print("balanced",70,y,11)
  elseif tax_rate<=40 then
   print("+income",70,y,11) y+=7
   print("-growth",70,y,8) y+=7
   print("-happy",70,y,8)
  else
   print("++income",70,y,11) y+=7
   print("--growth",70,y,8) y+=7
   print("--happy",70,y,8) y+=7
   print("exodus!",70,y,8)
  end
 elseif menu==6 then
  print("statistics",68,y,12) y+=10
  print("earned:$"..format_num(total_earned),68,y,11) y+=8
  print("buildings:"..#buildings,68,y,7) y+=8
  print("services:"..#services,68,y,7) y+=8
  print("industry:"..#industries,68,y,7) y+=8
  local mins=flr(game_time/3600)
  print("time:"..mins.."m",68,y,6) y+=12

  -- achievements
  print("achievements:",68,y,12) y+=8
  for a in all(achievements) do
   local ac=5
   if a.done then ac=11 end
   print((a.done and "✓" or "○").." "..a.n,68,y,ac)
   y+=7
   if y>110 then break end
  end
 end

 -- scroll indicator
 if get_list_len()>5 then
  local sh=50/get_list_len()*5
  local sy=28+scroll*50/get_list_len()
  rectfill(125,sy,126,sy+sh,6)
 end
end

function draw_item(i,item,y,sel,typ)
 local c=5
 if sel then c=7 rectfill(65,y-1,126,y+12,1) end
 if not item.u then c=2 end

 print(item.n,67,y,c)

 -- cost/stats
 if item.u then
  print("$"..format_num(item.c),67,y+6,11)
  if typ=="b" then
   print("+"..item.p,95,y+6,12)
  elseif typ=="s" then
   print("h+"..item.h,95,y+6,10)
  elseif typ=="i" then
   print("+"..item.i,95,y+6,9)
  end
  if item.w and item.w>0 then
   print("w"..item.w,110,y+6,6)
  end
 else
  print("🔒",110,y+3,8)
 end

 -- owned count
 local owned=get_owned(i,typ)
 if owned>0 then
  print("x"..owned,118,y,11)
 end
end

function draw_tech(i,tech,y,sel)
 local c=5
 if sel then c=7 rectfill(65,y-1,126,y+12,1) end
 if tech.done then c=11 end

 print(tech.n,67,y,c)
 if tech.done then
  print("✅",118,y,11)
 else
  print(tech.c.."rp",67,y+6,12)
 end
end

function get_owned(i,typ)
 if typ=="b" then
  for b in all(buildings) do if b.t==i then return b.lvl end end
 elseif typ=="s" then
  for s in all(services) do if s.t==i then return s.lvl end end
 elseif typ=="i" then
  for ind in all(industries) do if ind.t==i then return ind.lvl end end
 end
 return 0
end

function draw_particles()
 for p in all(particles) do
  local a=p.life/60
  print(p.t,p.x,p.y,p.c)
 end
end

function format_num(n)
 if n>=1000000 then return flr(n/100000)/10 .."m"
 elseif n>=1000 then return flr(n/100)/10 .."k"
 else return ""..n end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044440000666600009999000088880000bbb00000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000
00000000424424006766760099a99900888888000bbb00000ccc0000077777000000000000000000000000000000000000000000000000000000000000000000
000000004444440067676600999999908f8f8f800bfb00000cfc0000777777700000000000000000000000000000000000000000000000000000000000000000
00000000424424006766760099a99900888888000bbb00000ccc0000077777000000000000000000000000000000000000000000000000000000000000000000
00000000444444006767660099999990888888000bbb00000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000
0000000044004400670067009900990088008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555005555550055555500555555005555555055555550000000000000000000000000000000000000000000000000000000000000000000000000
0033300003b3b000055550000aaa000000e000000c0c0c0000880000099990000000000000000000000000000000000000000000000000000000000000000000
033333000bbbbb0005665000aa8aa00000e0e0000ccccc0008ff80009aaaa9000000000000000000000000000000000000000000000000000000000000000000
0333330003b3b00056665000aaa8a000eeeee000c0c0c0c008ff8000999999000000000000000000000000000000000000000000000000000000000000000000
03c3c30003b3b00056665000aa8aa00000e0e00000ccc0000088000099aa99000000000000000000000000000000000000000000000000000000000000000000
003330000333300055555000aaaaa00000e00000000c00000000000099999900
00000000055550000000000005550000000000000000000000000000099990000000000000000000000000000000000000000000000000000000000000000000
00000000555555000000000055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066600007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006666660077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006656660077577000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000666000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07767770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00000000
