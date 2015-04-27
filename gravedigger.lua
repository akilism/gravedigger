--grave digger
--z:fire tongue / x:dig

--t
--0=grass
--1=wall
--2=grave
--3=plot

spawn={x=1,y=14}
lvl=1
plothp=12
gravity={x=0,y=0.01}
dx=0
dy=0
toff=15
debug=false
plr={ pts=0 }
gamestates = {
  playing=0,
  gameover=1,
  lvlswitch=2
}

function _init()
 loadlvl(lvl)
end

function loadlvl(lvl)
 rset()
 newboard()
 spawnenemies(3*lvl)
 if lvl%2==0 then
  music(0,150)
 else
   music(1,150)
 end
end

function rset()
 gamestate=gamestates.playing
 board={}
 plr={hp=100,pts=plr.pts,
  klde=0, fndt=0,
 pos=spawn,spr=58,
 tpf=4,t=0,
 f=0,fm=0,
 vel={x=0,y=0},dir={x=0,y=0}}
 plots={}
 enemies={}
 particles={}
 treasures={}
 tongue = {}
 endp={}
 grabbed={grabbed=false}
 showscore=false
 ttle=0
 ttlt=0
 pause=0
end

function newboard()
 for y=0,15 do
  for x=0,15 do
   if x==0 or x==15 or y==0 or y==15 then
    --draw wall
    add(board, {t=1, mx=0,my=2})
   else
    --populate board
    cell = getcell(x,y)
    if cell.t==3 then
     add(plots,spawnplot(x,y))
    end
    add(board, cell)
   end
  end
 end
end

function getidx(x,y)
 return (16*y)+x+1
end

function getcell(x, y)
 r=rnd(1)
 i=getidx(x,y-1)
 tabove=board[i].t
 if tabove==2 then
  return {t=3, mx=rndrngi(1,7),my=1}
 elseif x==1 or x==14 or y==1 or y==14 then
  return {t=0, mx=0,my=1}
 elseif r>0.85 then
  return {t=2, mx=rndrngi(0, 6), my=0}
 else
  return {t=0, mx=0,my=1}
 end
end

function spawnenemies(count)
 ttle=count
 for i=1,count do
  add(enemies, newenemy(false))
 end
end

function newenemy(isboss)
 e={pos=getspawnpos(),
 tpf=10, t=0, f=0,
 vel=getrndvel()}
 if isboss then
  e.hp=lvl * rndrngi(30,40)
  e.spr=38
  e.spd=2
 else
  e.hp=rndrngi(10,21)
  e.p=150
  if rnd() > 0.5 then e.spr=22 else e.spr=6 end
  e.spd=1
 end
 return e
end

function getspawnpos()
 sx = rndrngi(1,16)
 sy = rndrngi(1,16)
 if validpos(sx, sy) then
  return {x=sx, y=sy}
 else
  return getspawnpos()
 end
end

function validpos(x, y)
 i=getidx(x,y)
 t=board[i]
 mv=mget(t.mx, t.my)
 return fget(mv,0) or fget(mv,2)
end

function getrndvel()
 if rnd(1)>0.5 then rx=0 else rx=dir() end
 if rnd(1)>0.5 and rx!=0 then ry=0 else ry=dir() end
 return {x=rx, y=ry}
end

function spawnplot(px, py)
 return {x=px,y=py,hp=plothp,i=getitem(), live=true}
end

function getitem()
 if rnd(1) > 0.25 then
  if rnd(1) > 0.65 then
   --random treasure
   t=rndi(4)
   sp=54 + t
   ttlt+=1
   if t==0 or t==1 then
    return {s=sp,p=50,ttl=360}
   elseif t==2 then
    return {s=sp,p=100,ttl=180}
   else
    return {s=sp,p=250,ttl=120}
   end
  else
   --bone
   ttlt+=1
   return {s=53,p=5,ttl=360}
  end
 end
 return false
end

function _update()
 if gamestate==gamestates.lvlswitch or gamestate==gamestates.gameover then
  nextlvl()
  return
 end

 foreach(enemies,updtenemy)
 updtplr()
 if isdead() then
  gamestate = gamestates.gameover
  return
 end

 foreach(particles,updtpat)
 foreach(treasures,updttrs)
 foreach(tongue,updttng)
 for p in all(particles) do
  if p.c==0 and p.ttl==0 then
   del(particles,p)
  end
 end

 for t in all(treasures) do
  if t.ttl==0 then
   del(treasures,t)
  end
 end

 for t in all(tongue) do
  if not plr.fire and not grabbed.grabbed then
   t.rev=true
  end
  if t.rem then
   if grabbed.grabbed then
    addpoints(grabbed.p)
    grabbed={grabbed=false}
    if plr.klde==ttle then
     gamestate=gamestates.lvlswitch
    end
   end
   del(tongue,t)
  end
 end
end

function isdead()
  for e in all(enemies) do
    if e.pos.x==plr.pos.x and e.pos.y==plr.pos.y then
      return true
    end
  end

  return false
end

function nextlvl()
  if showscore and btn(4) and pause>60 then
    if gamestate==gamestates.gameover then lvl=1 else lvl+=1 end
    loadlvl(lvl)
  end
  showscore=true
  pause+=1
end

function addpoints(pts)
  sfx(-1,3)
  sfx(7,3)
 plr.pts+=pts
end

function updtenemy(e)
 e.t+=1

 if e.t > e.tpf then
  e.t = 0
  if e.f > 0 then e.f=0 else e.f=1 end
  e.pos, e.vel = getnewpos(e.pos, e.vel)
 end
end

function updtplr()
 if btn(4) then
  dofire()
  plr.fire=true
 else
  plr.fire=false
 end
 if btn(5) then
  dig=true
  dodig()
 else
  dig=false
 end

 plr.t+=1
 if plr.t > plr.tpf then
  plr.t=0
  if plr.f<=1 then plr.f=2+plr.fm else plr.f=0+plr.fm end

  x = plr.pos.x
  y = plr.pos.y
  if btn(0) then x -= 1 end
  if btn(1) then x += 1 end
  if btn(2) then y -= 1 end
  if btn(3) then y += 1 end

  if validpos(x,y) and (plr.pos.x!=x or plr.pos.y!=y) then
   if x<plr.pos.x then
    plr.dir.x=-1
   elseif x>plr.pos.x then
    plr.dir.x=1
   else
    plr.dir.x=0
   end

    if y<plr.pos.y then
     plr.dir.y=-1
    elseif y>plr.pos.y then
     plr.dir.y=1
    else
     plr.dir.y=0
    end

     if plr.fm==0 then plr.fm=1 else plr.fm=0 end
     if not dig and not plr.fire then
      plr.pos.x = x
      plr.pos.y = y
     end
    end
 end
end

function dofire()
 if not plr.fire and count(tongue)==0 then
  add(tongue, newtongue())
  sfx(-1,3)
  sfx(2,3)
 end
end

function newtongue()
 ppos = multv(plr.pos,8)
 return {
  strtp=ppos,
  endp=addv(ppos,plr.dir),
  endp=addv(ppos,plr.dir),
  dir=multv(plr.dir,1),
  len=40, rev=false, rem=false}
end

function dodig()
 px = (plr.pos.x*8) + (plr.dir.x*8)+4
 py = (plr.pos.y*8) + (plr.dir.y*8)+4
 dx = (plr.pos.x) + (plr.dir.x)
 dy = (plr.pos.y) + (plr.dir.y)
 poof(px,py)
 sfx(-1,3)
  sfx(0,3)
 foreach(plots, checkplot)
end

function poof(x,y)
 for i=0,15 do
  add(particles, newpat(x,y))
 end
end

function newpat(sx,sy)
 pdx=dir()
 pdy=dir()
 return { acc={x=0, y=0},
 vel={x=pdx*rnd(1),y=pdy*rnd(1)},
 pos={x=sx, y=sy},
 mass=max(0.5, rnd(1)),
 ttl=rndi(5),
 c=5}
end

function updttrs(t)
 local ply=0
 t=addforce(gravity,t)
 t=updtt(t)
 t=chkbnd(t)
 x,y=getmappos(t.pos)
 i=getidx(x,y)
 if board[i].t == 2 then --gravestone
  if rnd(1) > 0.75 then
   t.vel.x*=-1
   ply=1
  end
  if rnd(1) > 0.55 then
   t.vel.y*=-1
   ply=1
  end
 end
 if ply==1 then
  sfx(-1,3)
  sfx(3,3)
 end
 t.ttl-=1
end

function updttng(t)
 if not grabbed.grabbed then
  endp = addv(t.endp, multv(t.dir,8))
  foreach(treasures, checkgrab)
 end

 if not grabbed.grabbed then
  foreach(enemies, checkgrab)
 end

 if grabbed.grabbed or t.rev then
  if not t.revd then
   t.dir=multv(t.dir, -1)
   t.revd=true
  end
  ppos=multv(plr.pos,8)
  v=multv(normlv(subv(ppos,t.endp)),0.5)
  t.endp=addv(t.endp,v)
  t.strtp=ppos
  if grabbed.grabbed then
    if grabbed.hp then
      grabbed.pos=divv(t.endp,8)
    else
      grabbed.pos=t.endp
    end
  end
  if t.endp.x<=ppos.x+4 and
   t.endp.x>=ppos.x-4 and
   t.endp.y<=ppos.y+4 and
   t.endp.y>=ppos.y-4 then
    t.rem=true
    sfx(-1,3)
    sfx(2,3)
  end
 else
  t.endp = addv(t.endp, multv(t.dir,8))
 end
end

function checkgrab(t)
 chk=endp
 if t.hp then
  chk=multv(t.pos,8)
  off=2
 else
  chk=multv(t.pos,1)
  off=2
 end
 if endp.x>=chk.x-off and endp.x<=chk.x+off and
  endp.y>=chk.y-off and endp.y<=chk.y+off then
  if t.hp then
    del(enemies,t)
    plr.klde+=1
  else
    del(treasures,t)
    plr.fndt+=1
  end
  grabbed=t
  grabbed.grabbed=true
 end
end

function updtt(t)
 if t.ttl<=0 then
  t.c=0
  t.ttl=0
 else
  t.vel=addv(t.vel, t.acc)
  t.pos=addv(t.pos, t.vel)
  t.acc=multv(t.acc, 0)
 end
 return t
end

function updtpat(pat)
 pat=addforce(gravity, pat)
 pat=updatepat(pat)
end

function updatepat(pat)
 if pat.ttl<=0 then
  pat.c=0
  pat.ttl=0
 else
  pat.vel=addv(pat.vel, pat.acc)
  pat.pos=addv(pat.pos, pat.vel)
  if pat.ttl>30 then pat.ttl=30 end
  pat.ttl-=1
  pat.acc=multv(pat.acc, 0)
  return pat
 end
end

function chkbnd(t)
 local ply=0
 if t.pos.x > 111 then
  t.vel.x*=-1
  t.pos.x=111
  ply=1
 elseif t.pos.x < 8 then
  t.vel.x*=-1
  t.pos.x=8
  ply=1
 end
 if t.pos.y > 114 then
  t.vel.y*=-1
  t.pos.y=114
  ply=1
 elseif t.pos.y < 8 then
  t.vel.y*=-1
  t.pos.y=8
  ply=1
 end
 if ply==1 then
  sfx(3)
 end
 return t
end

function addforce(force, p)
 p.acc.x += force.x/p.mass
 p.acc.y += force.y/p.mass
 return p
end

function getnewpos(pos, vel)
 newpos = addv(pos, vel)
 if rnd(1)>0.85 then
  return getnewpos(pos, getrndvel())
 elseif validpos(newpos.x, newpos.y) then
  return newpos, vel
 else
  return getnewpos(pos, getrndvel())
 end
end

function getmappos(pos)
 return flr(pos.x/8), flr(pos.y/8)
end

function checkplot(p)
 if p.x==dx and p.y==dy and p.live then
  p.hp-=1
  if p.hp>plothp/0.75 then
   p.s=48
  elseif p.hp>plothp/0.5 then
   p.s=49
  elseif p.hp>plothp/0.25 then
   p.s=50
  else
   p.s=51
  end
  if p.hp==0 then
   if p.i then
    spawntrs(p.i)
   end
   p.live=false
  end
 end
end

function spawntrs(t)
 t.acc={x=dir(),y=-1}
 t.vel={x=0,y=0}
 t.pos={x=px,y=py}
 t.mass=0.25
 add(treasures,t)
end

function _draw()
 rectfill(0,0,127,127,0)
 drawboard()
 drawscore()
 foreach(plots, drawplot)
 foreach(treasures, drawtreasure)
 drawplr()
 foreach(enemies, drawenemy)
 foreach(particles, drawpat)
 foreach(tongue, drawtongue)

 if grabbed.grabbed then
  if grabbed.hp then drawenemy(grabbed) else drawtreasure(grabbed) end
 end

 if gamestate==gamestates.lvlswitch or gamestate==gamestates.gameover then drawscoreboard() end

 if debug then
  for t in all(tongue) do
   print("t "..t.endp.x..","..t.endp.y,0,9,0)
   print("p "..plr.pos.x..","..plr.pos.y,0,18,0)
   print("tdir "..t.dir.x..","..t.dir.y,0,27,0)
  end
 end
end

function drawscoreboard()
 rectfill(15,30,112,80,0)
 c=10
 print(plr.klde.."/"..ttle.." enemies",24,44,c)
 print(plr.fndt.."/"..ttlt.." treasures",24,53,c)
 print(plr.pts.." points",24,62,c)
 if gamestate==gamestates.gameover then
  print("game over!!",44,35,c)
  print("press z to play again.",24,71,c)
 else
  print("level complete!!",34,35,c)
  print("press z for next level.",19,71,c)
 end
end

function drawscore()
 print("score:"..plr.pts,0,1,0)
 print("score:"..plr.pts,0,0,9)
end

function drawboard()
 for i=1,count(board) do
  y=flr((i-1)/16)
  x=(i-1)-(16*y)
  mapdraw(board[i].mx, board[i].my,x*8,y*8,1,1)
 end
end

function drawgrabbed(g)
 spr(g.spr, g.pos.x, g.pos.y)
end

function drawenemy(e)
 spr(e.spr+e.f, e.pos.x*8, e.pos.y*8 )
end

function drawplr()
 if plr.dir.x == -1 then flp = true else flp = false end
 spr(plr.spr+plr.f, plr.pos.x*8,plr.pos.y*8,1,1,flp)
end

function drawpat(p)
 pset(p.pos.x, p.pos.y, p.c)
end

function drawplot(p)
 if p.hp != plothp then
  spr(p.s,p.x*8,p.y*8)
 end
end

function drawtreasure(t)
 spr(t.s,t.pos.x,t.pos.y)
end

function drawtongue(t)
 off = addv({x=4,y=4}, t.dir)
 line(t.strtp.x+off.x,t.strtp.y+off.y,t.endp.x+off.x,t.endp.y+off.y,11)
 if debug then
  circfill(t.endp.x*8, t.endp.y*8, 3, 12)
  circfill(t.strtp.x*8, t.strtp.y*8, 3, 10)
 end
end

function rndi(x)
 return flr(rnd(x))
end

function dir()
 if rndi(2) == 1 then return 1 else return -1 end
end

function rndrngf(mn, mx)
 return rnd(mx - mn) + mn
end

function rndrngi(mn, mx)
 return rndi(mx - mn) + mn
end

function addv(v1, v2)
 return {x=v1.x+v2.x, y=v1.y+v2.y}
end

function subv(v1,v2)
 return {x=v1.x-v2.x, y=v1.y-v2.y}
end

function multv(v,n)
 return {x=v.x*n, y=v.y*n}
end

function divv(v, n)
 return {x=v.x/n, y=v.y/n}
end

function magsqrv(v)
 return (v.x*v.x)+(v.y*v.y)
end

function distsqrv(v1, v2)
 return (v1.x-v2.x) * (v1.x-v2.x) + (v1.y-v2.y) * (v1.y-v2.y)
end

function normlv(v)
 mag = magsqrv(v)^0.5
 if mag>0 then return divv(v,mag) else return v end
end

