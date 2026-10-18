-- Concept 08, drawn directly in Aseprite on a 32x32 pixel grid.
-- Run: Aseprite --batch --script this-file.lua
local out = 'D:/Simon/Dev/ARPGgame/GodotStarter/Art/Characters/Hero32Concept8/'
app.fs.makeAllDirectories(out)
local hex = {
 O='262637', D='574439', m='997044', h='d5a65c', H='f4cf7b', L='ffe6a3',
 s='ce8c6d', S='efb58b', F='ffdab0', e='263953', E='548cba',
 B='20375b', b='315489', C='477db5', c='79abcf',
 v='aaa797', i='dad5ba', I='fff0d0',
 g='a77335', G='e0b65b', Y='ffe29a',
 t='4b3530', T='78503b', q='ac7950', a='35a2b5', A='8ce1dc'
}
local color = {}
for k,v in pairs(hex) do
 color[k] = app.pixelColor.rgba(tonumber(v:sub(1,2),16),tonumber(v:sub(3,4),16),tonumber(v:sub(5,6),16),255)
end
local layerNames = {'Cloak','Dress and boots','Hair and face','Gold and accessories'}
local parts, img
local function selectPart(n) img=parts[n] end
local function dot(x,y,k)
 assert(x>=0 and x<32 and y>=0 and y<32,'Pixel outside 32x32 canvas')
 img:drawPixel(x,y,color[k])
end
local function row(y,x,s)
 for j=1,#s do local k=s:sub(j,j); if color[k] then dot(x+j-1,y,k) end end
end
local function rows(r) for _,v in ipairs(r) do row(v[1],v[2],v[3]) end end
local function rect(x,y,w,h,k) for yy=y,y+h-1 do for xx=x,x+w-1 do dot(xx,yy,k) end end end
local function line(x,y,xx,yy,k)
 local dx,dy=math.abs(xx-x),-math.abs(yy-y)
 local sx,sy=x<xx and 1 or -1,y<yy and 1 or -1
 local err=dx+dy
 while true do dot(x,y,k); if x==xx and y==yy then break end
  local e=2*err; if e>=dy then err=err+dy;x=x+sx end
  if e<=dx then err=err+dx;y=y+sy end
 end
end
local function poly(p,k,outline)
 local inside={}
 for y=0,31 do for x=0,31 do
  local hit=false;local j=#p
  for i=1,#p do
   local a,b=p[i],p[j]
   if (a[2]>y+.5)~=(b[2]>y+.5) and x+.5<(b[1]-a[1])*(y+.5-a[2])/(b[2]-a[2])+a[1] then hit=not hit end
   j=i
  end
  if hit then inside[#inside+1]={x,y} end
 end end
 if outline~=false then for _,p in ipairs(inside) do
  for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
   local x,y=p[1]+d[1],p[2]+d[2]
   if x>=0 and x<32 and y>=0 and y<32 then dot(x,y,'O') end
  end
 end end
 for _,p in ipairs(inside) do dot(p[1],p[2],k) end
end
local function frontCloak()
 selectPart(1)
 poly({{11,13},{20,13},{24,16},{25,21},{27,26},{24,28},{20,27},{18,23},{11,25},{7,28},{4,26},{5,21},{7,16}},'b')
 poly({{8,16},{11,14},{12,19},{9,23},{8,27},{5,25},{7,20}},'C',false)
 poly({{20,15},{23,16},{24,22},{26,26},{24,27},{21,26}},'C',false)
 line(5,25,7,27,'G');line(7,27,10,24,'G')
 line(23,27,26,25,'G');line(20,25,23,27,'g')
 line(7,18,6,22,'c');line(24,21,25,24,'b')
end
local function frontBody(back)
 selectPart(2)
 rows({{27,12,'OttO.OttO'},{28,12,'OTqO.OTqO'},{29,11,'OTTO..OTTTO'},{30,11,'OOOO..OOOOO'}})
 if back then
  rect(12,26,8,2,'i');rect(14,26,3,1,'I')
 else
  poly({{13,13},{19,13},{20,20},{21,27},{18,28},{15,27},{12,28},{11,26},{12,20}},'i')
  poly({{14,15},{17,15},{17,20},{18,27},{15,26},{13,27},{13,22}},'I',false)
  line(19,22,20,26,'v');line(12,24,12,26,'v')
 end
 row(27,13,'GYYGGG')
 if not back then
  poly({{8,16},{11,17},{11,20},{9,24},{5,22},{6,18}},'i')
  poly({{8,17},{10,18},{9,21},{7,23},{6,21}},'I',false)
  line(5,22,8,24,'G')
  poly({{21,17},{24,16},{26,18},{25,22},{22,22},{21,20}},'i')
  poly({{23,17},{25,18},{24,21},{22,21}},'I',false)
  row(23,7,'OSS');row(24,7,'OSO')
  row(21,24,'OSFO');row(22,24,'OSSO')
  row(17,12,'TqO');row(18,12,'TqO')
  row(19,12,'tTTGGTt');row(20,12,'OtGYO')
  row(21,11,'OtqTO');row(22,11,'OTqTO');row(23,11,'OTTtO')
 end
end
local function frontHead()
 selectPart(3)
 -- Long swept hair stays behind the sleeve; individual clusters read at 1x.
 rows({{3,12,'OmHHHHhmO'},{4,10,'OmhHLLLLHhmO'},
 {5,9,'OmhHLLLHHHhmO'},{6,9,'OhHLLHHHHHhhO'},
 {7,8,'OmHLHHHhhHHhhO'},{8,8,'OhHLHHhhSSShhO'},
 {9,8,'OhHhHhSFFFFShO'},{10,8,'OhHhhSFFFFFShO'},
 {11,7,'OmHHhSFFFFFSmO'},{12,7,'OhHhhOSFFFSmO'},
 {13,6,'OmHHhOOSSSOhO'},{14,6,'OhHhhO..OSmhO'},
 {15,5,'OmHHhO....OhO'},{16,5,'OhHhhO....OmO'},
 {17,5,'OhHHmO'},{18,5,'OmHhmO'},{19,5,'OhhmO'},
 {20,6,'OmmO'}})
 row(10,14,'eEF.eEF');dot(17,12,'S')
 selectPart(4)
 line(11,6,15,3,'b');dot(10,7,'B');dot(11,7,'G');dot(12,7,'Y')
 row(14,14,'bGIGb');dot(16,15,'Y')
 line(12,15,12,18,'G');line(20,15,20,19,'G')
 dot(26,23,'g');dot(26,24,'G')
 row(25,25,'OgO');row(26,25,'BaB');row(27,25,'aAa');row(28,25,'OBO')
end
local function back()
 frontCloak();frontBody(true)
 selectPart(1)
 poly({{10,14},{20,14},{22,22},{23,26},{19,28},{15,26},{11,28},{8,25}},'b')
 poly({{17,18},{20,15},{21,22},{22,26},{19,27},{17,24}},'C',false)
 line(10,26,11,27,'G');line(11,27,15,25,'G')
 line(16,26,19,27,'G');line(19,27,22,25,'G')
 line(13,22,12,25,'B');line(18,22,19,25,'c')
 selectPart(3)
 rows({{3,12,'OmHHHHhmO'},{4,10,'OmhHLLLLHhmO'},
 {5,9,'OmhHLLLHHHhmO'},{6,9,'OhHLLHHHHHhhO'},
 {7,8,'OmHLHHHhhHHhhO'},{8,8,'OhHLHHHhHHHhhO'},
 {9,8,'OhHLHHHhHHHhmO'},{10,8,'OhHHHHHhHHHhmO'},
 {11,7,'OmHHHHHhHHhhmO'},{12,7,'OhHLHHhhHHhhmO'},
 {13,6,'OmHLHHhhHhhhmO'},{14,6,'OhHLHHhhHhhmmO'},
 {15,5,'OmHLHHhhHhmmO'},{16,5,'OhHLHHhhHhmmO'},
 {17,5,'OhHHHhhHhmmO'},{18,5,'OmHHhhHhmmO'},
 {19,5,'OhHHhHhmmO'},{20,6,'OhhhmmO'},{21,7,'OmmOO'}})
 selectPart(4)
 line(11,6,15,3,'b');dot(10,7,'B');dot(11,7,'G')
 row(21,24,'OSFO');row(22,24,'OSSO')
 dot(26,23,'g');dot(26,24,'G');row(25,25,'OgO');row(26,25,'BaB');row(27,25,'aAa');row(28,25,'OBO')
end
local function side()
 selectPart(1)
 poly({{14,13},{21,14},{22,19},{23,24},{25,27},{21,28},{17,26},{14,22}},'b')
 poly({{18,15},{20,16},{21,22},{23,27},{20,26},{18,22}},'C',false)
 line(19,26,22,28,'G');line(22,28,24,27,'Y')
 line(21,20,22,24,'c');line(16,20,17,24,'B')
 selectPart(2)
 rows({{27,11,'OttO.OttO'},{28,11,'OTqO.OTqO'},{29,10,'OTTO..OTTTO'},{30,10,'OOOO..OOOOO'}})
 poly({{12,14},{17,14},{18,20},{19,27},{16,28},{12,27},{11,24}},'i')
 poly({{12,17},{14,17},{14,22},{16,27},{12,26}},'I',false)
 line(17,22,18,26,'v');row(27,12,'GYYGG')
 poly({{12,14},{15,14},{17,17},{15,19},{10,18}},'C')
 line(10,17,14,19,'G');dot(12,15,'c')
 poly({{11,18},{14,19},{13,22},{10,24},{7,22},{8,19}},'i')
 poly({{9,19},{12,20},{11,23},{8,22}},'I',false)
 line(7,22,9,24,'G');row(24,9,'OSS');row(25,9,'OSO')
 row(19,14,'tTGGO');row(20,14,'OtGYO');row(21,14,'OTqTO');row(22,14,'OTqTO');row(23,14,'OTTtO')
 selectPart(3)
 rows({{3,12,'OmHHHhmO'},{4,11,'OhHLLLLHhO'},
 {5,10,'OhHLLHHHHhO'},{6,10,'OhHLHHHHhhO'},
 {7,9,'OhhHhHHHhhmO'},{8,9,'OSShhHHHhhmO'},
 {9,8,'OSFShHHHHhmO'},{10,8,'OSFSSOhHHhmO'},
 {11,8,'OSFFFShHHhmO'},{12,9,'OSFFSOmHhhmO'},
 {13,10,'OSSOmmHHhhmO'},{14,13,'OmHHHhhmO'},
 {15,13,'OhHLHhhmO'},{16,14,'OhHLHhmO'},
 {17,14,'OhHHhhmO'},{18,14,'OmHHhmmO'},
 {19,15,'OhhhmO'},{20,16,'OmmO'}})
 row(10,9,'eEF')
 selectPart(4)
 line(10,7,14,4,'b');dot(10,8,'G');dot(11,8,'Y')
end
local frames={}
local directions={'up','down','left','right'}
for n,name in ipairs(directions) do
 parts={}
 for i=1,4 do parts[i]=Image(32,32,ColorMode.RGB) end
 if name=='up' then back() elseif name=='down' then frontCloak();frontBody(false);frontHead() else side() end
 if name=='right' then
  for i=1,4 do
   local mirrored=Image(32,32,ColorMode.RGB)
   for y=0,31 do for x=0,31 do mirrored:drawPixel(31-x,y,parts[i]:getPixel(x,y)) end end
   parts[i]=mirrored
  end
  selectPart(4)
  dot(21,25,'g');dot(21,26,'G');row(27,20,'OgO');row(28,20,'aAa');row(29,20,'OBO')
 end
 frames[n]=parts
end
local sprite=Sprite(32,32,ColorMode.RGB)
sprite.layers[1].name=layerNames[1]
local layers={sprite.layers[1]}
for i=2,4 do layers[i]=sprite:newLayer();layers[i].name=layerNames[i] end
for n,name in ipairs(directions) do
 if n>1 then sprite:newEmptyFrame() end
 sprite.frames[n].duration=0.25
 for i=1,4 do sprite:newCel(layers[i],n,frames[n][i],Point(0,0)) end
 local tag=sprite:newTag(n,n);tag.name=name
 tag.color=Color{r=71,g=125,b=181,a=255}
end
local palette=Palette(27)
palette:setColor(0,Color{r=0,g=0,b=0,a=0})
local order={'O','D','m','h','H','L','s','S','F','e','E','B','b','C','c','v','i','I','g','G','Y','t','T','q','a','A'}
for i,k in ipairs(order) do local v=hex[k];palette:setColor(i,Color{r=tonumber(v:sub(1,2),16),g=tonumber(v:sub(3,4),16),b=tonumber(v:sub(5,6),16),a=255}) end
sprite:setPalette(palette)
sprite.gridBounds=Rectangle(0,0,1,1)
sprite.data='Concept 8 from female-hero-concepts-10.png. Original Aseprite pixel drawing. Four static 32x32 facings: up, down, left, right. Four editable material layers. No walk animation.'
local slice=sprite:newSlice(Rectangle(0,0,32,32));slice.name='hero';slice.pivot=Point(16,30)
sprite:saveAs(out..'concept-08-blonde-32x32.aseprite')
local sheet=Sprite(128,32,ColorMode.RGB)
sheet:setPalette(palette);sheet.gridBounds=Rectangle(0,0,32,32)
local sheetImage=Image(128,32,ColorMode.RGB)
for n,name in ipairs(directions) do
 local flat=Image(32,32,ColorMode.RGB)
 flat:drawSprite(sprite,n)
 flat:saveAs(out..'concept-08-'..name..'.png')
 sheetImage:drawImage(flat,Point((n-1)*32,0))
 local s=sheet:newSlice(Rectangle((n-1)*32,0,32,32));s.name=name;s.pivot=Point(16,30)
end
sheet:newCel(sheet.layers[1],1,sheetImage,Point(0,0))
sheet.layers[1].name='up / down / left / right'
sheet:saveAs(out..'concept-08-four-directions.aseprite')
sheet:saveCopyAs(out..'concept-08-four-directions.png')
-- Integer nearest-neighbor magnification for visual inspection, no resampling.
local preview=Sprite(1024,256,ColorMode.RGB)
local large=Image(1024,256,ColorMode.RGB)
for y=0,31 do for x=0,127 do local p=sheetImage:getPixel(x,y)
 for yy=0,7 do for xx=0,7 do large:drawPixel(x*8+xx,y*8+yy,p) end end
end end
preview:newCel(preview.layers[1],1,large,Point(0,0))
preview:saveCopyAs(out..'concept-08-preview.png')
print('Saved 32x32 concept 8, four frames and four material layers: '..out)
