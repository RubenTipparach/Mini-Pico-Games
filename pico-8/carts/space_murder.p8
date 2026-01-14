pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- space murder mystery
-- a top-down rpg detective game

-- constants
txt_box_x=4
txt_box_y=84
txt_box_w=120
txt_box_h=40
txt_margin=6
txt_max_chars=27
txt_line_h=7

-- game states
state="title"

-- player
player={
 x=64,y=64,
 room=1,
 spd=1.2,
 dir=2,
 frame=0,
 walk_t=0
}

-- room data
rooms={
 {name="bridge",flr=1,wall=12},
 {name="medbay",flr=3,wall=11},
 {name="engine",flr=4,wall=9},
 {name="cargo",flr=5,wall=4},
 {name="quarters",flr=1,wall=13}
}

-- doors
doors={
 {r=1,x=120,y=56,w=8,h=16,to=2,sx=16,sy=64},
 {r=1,x=0,y=56,w=8,h=16,to=3,sx=108,sy=64},
 {r=2,x=0,y=56,w=8,h=16,to=1,sx=108,sy=64},
 {r=2,x=120,y=56,w=8,h=16,to=4,sx=16,sy=64},
 {r=3,x=120,y=56,w=8,h=16,to=1,sx=16,sy=64},
 {r=3,x=56,y=120,w=16,h=8,to=5,sx=64,sy=24},
 {r=4,x=0,y=56,w=8,h=16,to=2,sx=108,sy=64},
 {r=4,x=56,y=120,w=16,h=8,to=5,sx=64,sy=24},
 {r=5,x=24,y=0,w=16,h=8,to=3,sx=64,sy=100},
 {r=5,x=88,y=0,w=16,h=8,to=4,sx=64,sy=100}
}

-- suspects
suspects={
 {
  name="dr.nova",
  role="doctor",
  room=2,x=80,y=48,
  spr=32,col=11,
  motive="theft of meds",
  alibi="treating patient",
  guilty=false,
  asked=false,
  lines={
   "captain was alive earlier.",
   "heard noise from bridge.",
   "check cargo bay."
  }
 },
 {
  name="eng.vex",
  role="engineer",
  room=3,x=40,y=80,
  spr=34,col=9,
  motive="demotion threat",
  alibi="fixing conduit",
  guilty=true,
  asked=false,
  lines={
   "i was busy all shift.",
   "captain was harsh but...",
   "my wrench is missing!"
  }
 },
 {
  name="lt.orion",
  role="security",
  room=4,x=90,y=70,
  spr=36,col=8,
  motive="smuggling found",
  alibi="cargo inspection",
  guilty=false,
  asked=false,
  lines={
   "i found the body.",
   "no forced entry.",
   "crew all had motive."
  }
 },
 {
  name="nav.stella",
  role="navigator",
  room=5,x=64,y=80,
  spr=38,col=14,
  motive="transfer denied",
  alibi="reviewing charts",
  guilty=false,
  asked=false,
  lines={
   "we disagreed, yes.",
   "but never violence!",
   "heard clanging in eng."
  }
 }
}

-- clues
clues={
 {
  name="bloody wrench",
  room=1,x=96,y=80,
  spr=48,found=false,
  desc="murder weapon with blood"
 },
 {
  name="oil trail",
  room=1,x=48,y=90,
  spr=49,found=false,
  desc="engine oil leads to eng"
 },
 {
  name="torn badge",
  room=3,x=100,y=50,
  spr=50,found=false,
  desc="piece of vex's id badge"
 },
 {
  name="med log",
  room=2,x=30,y=70,
  spr=51,found=false,
  desc="nova was busy w/ patient"
 },
 {
  name="cargo log",
  room=4,x=50,y=45,
  spr=52,found=false,
  desc="orion in cargo all day"
 }
}

-- victim
victim={room=1,x=64,y=64,seen=false}

-- dialogue state
dlg={
 active=false,
 npc=nil,
 step=1,
 txt="",
 lines={}
}

-- found clues
found={}
gtime=0
cursor=1

function _init()
 state="title"
 player.x=64
 player.y=90
 player.room=1
 gtime=0
end

function _update60()
 gtime+=1
 if state=="title" then
  if btnp(4) or btnp(5) then
   state="playing"
   set_msg("captain reed is dead! investigate the crime scene.")
  end
 elseif state=="playing" then
  move_player()
  check_doors()
  check_interact()
 elseif state=="dialogue" then
  upd_dialogue()
 elseif state=="message" then
  if btnp(4) or btnp(5) then
   state="playing"
  end
 elseif state=="accuse" then
  upd_accuse()
 elseif state=="win" or state=="lose" then
  if btnp(4) or btnp(5) then
   _init()
  end
 end
end

function move_player()
 local nx,ny=player.x,player.y
 local moving=false

 if btn(0) then
  nx-=player.spd
  player.dir=3
  moving=true
 end
 if btn(1) then
  nx+=player.spd
  player.dir=1
  moving=true
 end
 if btn(2) then
  ny-=player.spd
  player.dir=0
  moving=true
 end
 if btn(3) then
  ny+=player.spd
  player.dir=2
  moving=true
 end

 nx=mid(12,nx,116)
 ny=mid(20,ny,108)
 player.x=nx
 player.y=ny

 if moving then
  player.walk_t+=0.15
  player.frame=flr(player.walk_t)%4
 else
  player.frame=0
 end
end

function check_doors()
 for d in all(doors) do
  if d.r==player.room then
   if player.x>d.x-4 and player.x<d.x+d.w+4 and
      player.y>d.y-4 and player.y<d.y+d.h+4 then
    player.room=d.to
    player.x=d.sx
    player.y=d.sy
    sfx(0)
    return
   end
  end
 end
end

function check_interact()
 if not btnp(4) then return end

 -- npcs
 for s in all(suspects) do
  if s.room==player.room then
   if dist(player.x,player.y,s.x,s.y)<20 then
    start_dlg(s)
    return
   end
  end
 end

 -- clues
 for c in all(clues) do
  if not c.found and c.room==player.room then
   if dist(player.x,player.y,c.x,c.y)<16 then
    c.found=true
    add(found,c)
    set_msg("found: "..c.name.."! "..c.desc)
    sfx(1)
    return
   end
  end
 end

 -- victim
 if player.room==1 and not victim.seen then
  if dist(player.x,player.y,victim.x,victim.y)<20 then
   victim.seen=true
   set_msg("captain reed. blunt trauma to head. dead 2 hours.")
   return
  end
 end

 -- console for accusation
 if player.room==1 and player.y<30 and
    player.x>40 and player.x<88 then
  if #found>=3 then
   state="accuse"
   cursor=1
  else
   set_msg("need more clues first! find at least 3.")
  end
 end
end

function dist(x1,y1,x2,y2)
 return abs(x1-x2)+abs(y1-y2)
end

function start_dlg(npc)
 state="dialogue"
 dlg.npc=npc
 dlg.step=1
 dlg.txt=npc.lines[1]
 dlg.lines=wrap_text(dlg.txt,txt_max_chars)
 npc.asked=true
end

function upd_dialogue()
 if btnp(4) or btnp(5) then
  dlg.step+=1
  local npc=dlg.npc
  local total=#npc.lines

  if dlg.step<=total then
   dlg.txt=npc.lines[dlg.step]
  elseif dlg.step==total+1 then
   dlg.txt="motive: "..npc.motive
  elseif dlg.step==total+2 then
   dlg.txt="alibi: "..npc.alibi
  else
   state="playing"
   dlg.npc=nil
   return
  end
  dlg.lines=wrap_text(dlg.txt,txt_max_chars)
 end
end

function set_msg(txt)
 state="message"
 dlg.txt=txt
 dlg.lines=wrap_text(txt,txt_max_chars)
 dlg.npc=nil
end

-- text wrapping function
function wrap_text(txt,maxw)
 local lines={}
 local line=""
 local word=""

 for i=1,#txt do
  local c=sub(txt,i,i)
  if c==" " or c=="\n" then
   if #line+#word+1>maxw then
    if #line>0 then
     add(lines,line)
    end
    line=word
   else
    if #line>0 then
     line=line.." "..word
    else
     line=word
    end
   end
   word=""
   if c=="\n" and #line>0 then
    add(lines,line)
    line=""
   end
  else
   word=word..c
  end
 end

 -- last word
 if #word>0 then
  if #line+#word+1>maxw then
   if #line>0 then
    add(lines,line)
   end
   line=word
  else
   if #line>0 then
    line=line.." "..word
   else
    line=word
   end
  end
 end
 if #line>0 then
  add(lines,line)
 end

 return lines
end

function upd_accuse()
 if btnp(2) then cursor=max(1,cursor-1) end
 if btnp(3) then cursor=min(4,cursor+1) end

 if btnp(4) then
  if suspects[cursor].guilty then
   state="win"
  else
   state="lose"
  end
 end

 if btnp(5) then
  state="playing"
 end
end

function _draw()
 cls(0)

 if state=="title" then
  draw_title()
 elseif state=="win" then
  draw_win()
 elseif state=="lose" then
  draw_lose()
 else
  draw_room()
  draw_furniture()
  draw_clues()
  draw_victim()
  draw_npcs()
  draw_player()
  draw_ui()

  if state=="dialogue" or state=="message" then
   draw_dlg_box()
  elseif state=="accuse" then
   draw_accuse()
  end
 end
end

function draw_title()
 -- stars
 for i=0,40 do
  local sx=(i*17+gtime/3)%128
  local sy=(i*23+sin(i)*8)%128
  local c=6
  if i%5==0 then c=7 end
  pset(sx,sy,c)
 end

 -- ship silhouette
 spr(56,48,50,4,2)

 -- title text box
 rectfill(16,22,112,52,1)
 rect(16,22,112,52,12)
 rect(17,23,111,51,5)

 print("space murder",32,28,12)
 print("mystery",44,38,8)

 -- subtitle
 print("a detective rpg",28,68,6)

 -- prompt
 if (gtime/30)%2<1 then
  print("press \151 to start",28,100,7)
 end

 -- credits
 print("by claude code",32,118,5)
end

function draw_room()
 local rm=rooms[player.room]

 -- floor tiles
 for ty=0,15 do
  for tx=0,15 do
   spr(rm.flr,tx*8,ty*8)
  end
 end

 -- walls top
 for tx=0,15 do
  spr(16+rm.wall%4,tx*8,0)
  spr(16+rm.wall%4,tx*8,8)
 end

 -- walls left/right
 for ty=2,14 do
  spr(20,0,ty*8)
  spr(21,120,ty*8)
 end

 -- wall bottom
 for tx=0,15 do
  spr(22,tx*8,112)
  spr(22,tx*8,120)
 end

 -- doors
 for d in all(doors) do
  if d.r==player.room then
   -- door sprite
   if d.h>d.w then
    -- vertical door
    spr(24,d.x,d.y)
    spr(24,d.x,d.y+8)
   else
    -- horizontal door
    spr(25,d.x,d.y)
    spr(25,d.x+8,d.y)
   end
  end
 end

 -- room label
 local nm=rm.name
 local nw=#nm*4
 rectfill(64-nw/2-2,2,64+nw/2+1,10,0)
 print(nm,64-nw/2,4,7)
end

function draw_furniture()
 local r=player.room

 if r==1 then
  -- bridge console
  spr(64,40,16,6,2)
  -- chairs
  spr(80,32,40)
  spr(80,88,40)
 elseif r==2 then
  -- med beds
  spr(72,20,32,2,2)
  spr(72,72,32,2,2)
  -- med cabinet
  spr(82,100,24)
 elseif r==3 then
  -- reactor core
  spr(96,32,32,4,4)
  -- pipes
  spr(84,16,24)
  spr(84,16,80)
  spr(84,104,24)
 elseif r==4 then
  -- crates
  spr(88,24,28,2,2)
  spr(88,64,28,2,2)
  spr(88,24,72,2,2)
  spr(88,64,72,2,2)
  spr(90,100,50)
 elseif r==5 then
  -- bunks
  spr(112,16,36,2,4)
  spr(112,88,36,2,4)
  -- table
  spr(81,52,64,3,2)
 end
end

function draw_clues()
 for c in all(clues) do
  if not c.found and c.room==player.room then
   -- sparkle
   local sp=flr(gtime/8)%4
   spr(c.spr,c.x-4,c.y-4)
   if sp<2 then
    pset(c.x-4,c.y-4,7)
    pset(c.x+3,c.y+3,7)
   else
    pset(c.x+3,c.y-4,7)
    pset(c.x-4,c.y+3,7)
   end
  end
 end
end

function draw_victim()
 if player.room~=1 then return end

 -- body
 spr(44,victim.x-8,victim.y-8,2,2)

 if not victim.seen then
  -- question mark
  print("?",victim.x-2,victim.y-16,7)
 end
end

function draw_npcs()
 for s in all(suspects) do
  if s.room==player.room then
   -- npc sprite (2x2)
   local fr=0
   if (gtime/30)%2<1 then fr=2 end
   spr(s.spr+fr,s.x-8,s.y-8,2,2)

   -- name above
   local nw=#s.name*4
   print(s.name,s.x-nw/2,s.y-16,7)

   -- ? if not talked
   if not s.asked then
    print("?",s.x+10,s.y-12,11)
   end
  end
 end
end

function draw_player()
 local px,py=player.x,player.y

 -- sprite based on direction
 local sp=0
 if player.dir==0 then sp=4 --up
 elseif player.dir==1 then sp=2 --right
 elseif player.dir==2 then sp=0 --down
 elseif player.dir==3 then sp=6 --left
 end

 -- walk animation
 if player.frame%2==1 then
  sp+=8
 end

 spr(sp,px-8,py-8,2,2)
end

function draw_ui()
 -- bottom bar
 rectfill(0,120,127,127,0)

 -- clue count
 spr(48,2,120)
 print(#found.."/5",12,121,7)

 -- room indicator
 print(rooms[player.room].name,40,121,6)

 -- help
 print("\151:talk",96,121,5)
end

function draw_dlg_box()
 -- box background
 rectfill(txt_box_x,txt_box_y,
          txt_box_x+txt_box_w,
          txt_box_y+txt_box_h,0)
 -- border
 rect(txt_box_x,txt_box_y,
      txt_box_x+txt_box_w,
      txt_box_y+txt_box_h,7)
 rect(txt_box_x+1,txt_box_y+1,
      txt_box_x+txt_box_w-1,
      txt_box_y+txt_box_h-1,5)

 local ty=txt_box_y+txt_margin

 -- speaker name
 if dlg.npc then
  print(dlg.npc.name,txt_box_x+txt_margin,ty,dlg.npc.col)
  ty+=txt_line_h+2
  line(txt_box_x+4,ty-1,txt_box_x+txt_box_w-4,ty-1,5)
  ty+=2
 end

 -- text lines (pre-wrapped)
 local max_lines=3
 if dlg.npc then max_lines=2 end

 for i=1,min(#dlg.lines,max_lines) do
  print(dlg.lines[i],txt_box_x+txt_margin,ty,7)
  ty+=txt_line_h
 end

 -- continue indicator
 if (gtime/15)%2<1 then
  print("\142",txt_box_x+txt_box_w-10,
        txt_box_y+txt_box_h-10,11)
 end
end

function draw_accuse()
 -- box
 rectfill(12,18,116,110,0)
 rect(12,18,116,110,8)
 rect(13,19,115,109,5)

 -- title
 print("make accusation",30,24,8)
 line(20,33,108,33,5)

 print("who killed reed?",28,38,7)

 -- suspects list
 for i=1,4 do
  local s=suspects[i]
  local y=46+i*14
  local c=6

  if i==cursor then
   c=11
   print("\145",18,y,11)
  end

  print(s.name,28,y,c)
  print(s.role,70,y,5)
 end

 -- help
 print("\151:accuse \142:cancel",22,100,6)
end

function draw_win()
 -- stars
 for i=0,30 do
  pset((i*17)%128,(i*23)%128,7)
 end

 -- box
 rectfill(16,28,112,72,1)
 rect(16,28,112,72,11)

 print("case closed!",38,34,11)
 print("engineer vex",36,46,9)
 print("is guilty!",42,56,8)

 print("great work,",40,82,10)
 print("detective!",42,92,10)

 if (gtime/30)%2<1 then
  print("press \151 to retry",24,112,6)
 end
end

function draw_lose()
 -- stars
 for i=0,30 do
  pset((i*17)%128,(i*23)%128,5)
 end

 -- box
 rectfill(16,28,112,72,1)
 rect(16,28,112,72,8)

 print("wrong!",52,34,8)
 print("the killer was",32,46,7)
 print("engineer vex",36,56,9)

 print("he escaped...",36,82,8)

 if (gtime/30)%2<1 then
  print("press \151 to retry",24,112,6)
 end
end

__gfx__
00000000005550000055500000555000005550000011100000111000001110000011100000000000000000000000000000000000000000000000000000000000
000cc0000055c5000055c500005c5500005c55000011c1000011c100001c1100001c110000cccc0000cccc0000cccc0000cccc0000000000000000000000000000
00cccc0000ccc50000ccc5000005ccc0005ccc000c1111000c11110000111c0001111c0000c77c0000c77c0000c77c0000c77c0000000000000000000000000000
00c77c00005cc500005cc500005cc500005cc50001cc1000001cc100001cc1000001cc10007cc7000077cc000077cc00007cc70000000000000000000000000000
007cc700007007000070070000700700007007000170170001701700017017000170170000700700007007000070070000700700000c0c00000c0c0000000000c0
0c0770c0007007000070070000700700007007000170170001701700017017000170170000c00c0000c00c0000c00c0000c00c00000c0c00000c0c000000000c00
0c0000c0000770000077000000007700000077000017710000177100001771000017710000077000007700000000770000007700000ccc00000ccc00000000c000
000000000007700000770000000077000000770000177100001771000017710000177100000770000077000000007700000077000000c000000c0c0000000c0000
1111111151111115555555556666666655555555666666660000000000000000000000000000000000000000000000000000000000000000111111111ddddddd
1515151551111115555995556669966655995955669669660000000000000000000000000000000000000000000000000000000000000000111111111ddddddd
11111111515115155559955566699665559559556696696600000000000000000000000000000000000000000000000000000000000000001111111111111111
1515151551511515555555556666666655555555666666660000000000000000000000000000000000000000000000000000000000000000111111111ddddddd
1111111151511515555555556666666655555555666666660000000000000000000000000000000000000000000000000000000000000000111111111ddddddd
1515151551511515555995556669966655599555666996660000000000000000000000000000000000000000000000000000000000000000111111111ddddddd
1111111151111115555995556669966655955955669699660000000000000000000000000000000000000000000000000000000000000000111111111ddddddd
1515151551515155555555556666666655555555666666660000000000000000000000000000000000000000000000000000000000000000111111111ddddddd
00bbb000000b0b00009990000099900000888000008880000000e0000000e0000088888808888880099aa99009aaaa9000000000000000005555555500000000
00b1bb000bbbbb00009b990009999000008b880008888000000eee00000eee000878787808888880099aa99009aaaa9000000000000000005555555500000000
0bb11b000b1b1b0000999900009b990000888800008b88000e0e0e0000e0e0e008888880888888809aa99aa09a99a9a000000000000000005599995500000000
0b111b000bbbbb00009999000099990000888800008888000eeeee0000eeeee00fffffff0fffffff0aa99aa00a99a9a000000000000000005599995500000000
0b1b1b0000b0b000009999000099990000888800008888000e0e0e0000e0e0e00f1f1f100f1f1f1009aa99aa09a99a9a000000000000000005599995500000000
00bbb000000b0b00009999000099990000888800008888000eeeee0000eeeee00ffffff00ffffff0099aa99009aaaa9a000000000000000005599995500000000
0b000b000b000b00090009000900090008000800080008000e000e0000e000e00f0000f00f0000f0099aa99009aaaa9a000000000000000005555555500000000
0b000b000b000b000900090009000900080008000800080000e00e00000e00e000f00f0000f00f00090009000900090a000000000000000005555555500000000
08888000099990008888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08f8f000097970008787878788880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088880000999900088888888888f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f88f0000f99f000ffffffff88880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088000000990000f1f1f1f188880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088000000990000ffffffff88880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088000000990000f0000f00000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088000000990000f00f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000044440000000000000000000000000055555555666666664444444455050505888888880000000000000000000000000000000000000000
00007770000000000045540000000000000000000000000055555555666666664545454450505050888888880000000000000000000000000000000000000000
00078870000000000045540000000000000000000000000055555555666666664444444455050505888888880000000000000000000000000000000000000000
00788887000000000045540000000000000000000000000055555555666666664545454450505050888888880000000000000000000000000000000000000000
0c788887000000000045540000000000000000000000000055555555666666664444444455050505888888880000000000000000000000000000000000000000
00788887000000000045540000000000000000000000000055555555666666664545454450505050888888880000000000000000000000000000000000000000
00078870000000000045540000000000000000000000000055555555666666664444444455050505888888880000000000000000000000000000000000000000
00007770000000000044440000000000000000000000000055555555666666664545454450505050888888880000000000000000000000000000000000000000
0555555555555555555555555555555055555550000000000000000000000000666666666666666600000000000000001111111100000000dddddddd11111111
05aaaa5555555555555555555aaaa5055aaaa550000000000000000000000000666966696669666600000000000000001111111100000000dddddddd11111111
05a66a555555555555555555556aa5055a66a550000000000000000000000000669669666696696600000000000000001111111100000000dd1ddddd111d1111
05a66a555555555555555555556aa5055a66a550000000000000000000000000666666666666666600000000000000001111111100000000dddddddd11111111
05aaaa555555555555555555556665055666a550000000000000000000000000666666666666666600000000000000001111111100000000dddddddd11111111
0555555555555555555555555555550555555550000000000000000000000000669966696669966600000000000000001111111100000000dddddddd11111111
05777775555555555555555557777505577775500000000000000000000000006699666966699666000000000000000011d1111100000000dddddddd1d111111
05555555555555555555555555555505555555500000000000000000000000006666666666666666000000000000000011111111000000001ddddddd11111111
0666666666666666666666666666660666666666666666600000000000000000000000000000000000000000000000000000000000000000000000001d1ddddd
06aaaa66666666666666666666aa606666666666aaaa6660000000000000000000000000000000000000000000000000000000000000000000000000dddd1ddd
06a77a6666666666666666666677606666666666a77a6660000000000000000000000000000000000000000000000000000000000000000000000000d1dddddd
06a77a6666666666666666666677606666666666a77a6660000000000000000000000000000000000000000000000000000000000000000000000000dddddddd
06aaaa66666666666666666666666066666666666666a660000000000000000000000000000000000000000000000000000000000000000000000000dddddddd
0666666666666666666666666666606666666666666666600000000000000000000000000000000000000000000000000000000000000000000000001ddddddd
0677777666666666666666666777706666666666777776600000000000000000000000000000000000000000000000000000000000000000000000001ddddddd
0666666666666666666666666666606666666666666666600000000000000000000000000000000000000000000000000000000000000000000000001dd1dddd
__sfx__
000100001505015050150401503015020150101500015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002465024650216501d6501a6501765014650116500060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
