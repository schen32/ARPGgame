-- Eight static 64x64 concept 8 facings, redrawn from the project reference set.
-- Run: Aseprite --batch --script draw-hero-64-8dir.lua
local out='D:/Simon/Dev/ARPGgame/GodotStarter/Art/Characters/Hero64EightDirections/'
app.fs.makeAllDirectories(out)
local hex={
 outline='292d40',hair_dark='987044',hair_mid='c79b55',hair='e7bd70',hair_light='ffe2a0',
 skin_dark='bb8062',skin='e9b391',skin_light='ffdab3',eye='344667',
 blue_dark='263d67',blue='3b65a0',blue_light='6493c8',blue_high='9ac6df',
 cloth_dark='a5a29b',cloth='d8d4bd',cloth_light='fff0d4',
 gold_dark='9b713c',gold='dfb65f',gold_light='ffe2a0',
 leather_dark='4c3c3a',leather='76513e',leather_light='ac7850',gem='5cc4db'
}
local c={}
for k,v in pairs(hex) do c[k]=app.pixelColor.rgba(tonumber(v:sub(1,2),16),tonumber(v:sub(3,4),16),tonumber(v:sub(5,6),16),255) end
local img
local function dot(x,y,col)
 if x>=0 and x<64 and y>=0 and y<64 then img:drawPixel(x,y,c[col]) end
end
local function rect(x,y,w,h,col) for yy=y,y+h-1 do for xx=x,x+w-1 do dot(xx,yy,col) end end end
local function line(x0,y0,x1,y1,col)
 local dx=math.abs(x1-x0);local sx=x0<x1 and 1 or -1
 local dy=-math.abs(y1-y0);local sy=y0<y1 and 1 or -1;local err=dx+dy
 while true do dot(x0,y0,col);if x0==x1 and y0==y1 then break end
  local e=2*err;if e>=dy then err=err+dy;x0=x0+sx end;if e<=dx then err=err+dx;y0=y0+sy end
 end
end
local function poly(p,col,edge)
 local pixels={}
 for y=0,63 do for x=0,63 do
  local inside=false;local j=#p
  for i=1,#p do local a,b=p[i],p[j]
   if (a[2]>y+.5)~=(b[2]>y+.5) and x+.5<(b[1]-a[1])*(y+.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
   j=i
  end
  if inside then pixels[#pixels+1]={x,y} end
 end end
 if edge~=false then for _,q in ipairs(pixels) do
  dot(q[1]-1,q[2],'outline');dot(q[1]+1,q[2],'outline');dot(q[1],q[2]-1,'outline');dot(q[1],q[2]+1,'outline')
 end end
 for _,q in ipairs(pixels) do dot(q[1],q[2],col) end
end
local function boots()
 poly({{27,45},{32,45},{32,54},{30,55},{26,55}},'leather_dark')
 poly({{35,45},{40,45},{40,54},{38,55},{35,55}},'leather_dark')
 poly({{26,51},{31,51},{31,57},{29,59},{24,59},{24,56}},'leather')
 poly({{35,51},{40,51},{40,56},{42,58},{42,59},{35,59}},'leather')
 rect(26,51,5,2,'leather_light');rect(35,51,5,2,'leather_light')
 rect(25,56,3,1,'leather_light');rect(37,56,3,1,'leather_light')
 rect(24,58,6,1,'leather_dark');rect(35,58,7,1,'leather_dark')
end
local function robe()
 poly({{27,27},{37,27},{39,37},{41,46},{38,49},{34,48},{32,45},{29,49},{24,48},{24,44},{26,37}},'cloth')
 poly({{29,28},{35,28},{34,37},{35,43},{34,48},{31,45},{29,47},{27,47},{28,38}},'cloth_light',false)
 line(26,39,25,46,'cloth_dark');line(38,39,39,46,'cloth_dark')
 line(32,39,31,44,'gold');line(33,42,33,46,'gold_light')
end
local function face()
 poly({{27,12},{36,12},{39,16},{38,23},{35,25},{30,25},{26,22},{25,17}},'skin')
 poly({{28,16},{35,15},{37,18},{36,22},{34,24},{30,23},{28,21}},'skin_light',false)
 rect(28,19,2,2,'eye');rect(35,19,2,2,'eye')
 dot(29,19,'blue_high');dot(36,19,'blue_high');dot(32,22,'skin_dark');rect(32,24,2,1,'skin_dark')
end
local function frontHair()
 poly({{25,9},{28,7},{35,7},{39,9},{41,12},{41,21},{39,26},{38,29},{36,26},{37,20},{37,15},{34,13},{29,16},{25,18},{24,25},{25,32},{23,36},{20,34},{21,26},{20,19},{21,13}},'hair_mid')
 poly({{25,10},{29,8},{35,8},{39,11},{39,15},{36,14},{33,12},{28,15},{24,17},{23,24},{24,31},{22,34},{22,25},{22,17}},'hair',false)
 poly({{28,9},{34,9},{36,10},{34,11},{31,11},{28,14},{25,14},{26,11}},'hair_light',false)
 poly({{21,24},{23,22},{23,31},{22,37},{20,40},{18,38},{19,32},{19,27}},'hair',false)
 line(20,31,19,37,'hair_dark');line(24,27,24,32,'hair_dark');line(38,17,38,23,'hair_dark')
 -- Narrow blue headband and its small gold clasp, visible in the reference.
 line(23,15,31,10,'blue');line(24,15,31,11,'blue_dark');rect(24,14,2,2,'blue');dot(24,14,'gold_light')
end
local function down()
 img=Image(64,64,ColorMode.RGB);boots();robe()
 poly({{23,26},{27,25},{29,29},{27,36},{27,42},{24,49},{20,46},{20,39},{21,32}},'blue')
 poly({{39,26},{43,27},{46,33},{47,40},{47,47},{43,50},{40,45},{39,37}},'blue')
 poly({{23,28},{26,27},{27,29},{25,36},{24,44},{21,42}},'blue_light',false)
 poly({{41,29},{44,31},{44,39},{45,46},{43,47},{41,41}},'blue_light',false)
 line(20,46,24,49,'gold');line(43,50,47,47,'gold')
 poly({{23,26},{27,25},{29,31},{27,37},{26,44},{23,49},{20,46}},'blue_dark',false)
 poly({{39,27},{43,27},{46,33},{47,47},{43,50},{41,43}},'blue_dark',false)
 -- Oversized ivory bell cuffs with separate gold edging, matching concept 8.
 poly({{22,34},{27,35},{28,41},{25,49},{22,53},{18,50},{18,45}},'cloth')
 poly({{23,37},{26,37},{26,42},{24,49},{22,51},{20,49}},'cloth_light',false)
 line(18,49,22,53,'gold');line(22,53,25,50,'gold')
 poly({{42,35},{46,35},{50,41},{52,47},{49,52},{45,51},{42,46}},'cloth')
 poly({{43,38},{46,38},{49,44},{50,48},{48,50},{45,47}},'cloth_light',false)
 line(49,52,52,47,'gold');line(46,51,49,52,'gold')
 poly({{20,49},{23,49},{24,52},{22,54},{19,53}},'skin')
 poly({{48,49},{51,48},{53,50},{52,53},{49,53}},'skin')
 rect(28,35,10,2,'leather');rect(32,35,3,3,'gold_dark');rect(32,35,3,1,'gold_light');dot(33,36,'outline')
 -- Brown cross-body strap and hip pouch.
 line(38,29,29,38,'leather_dark');line(37,30,30,37,'leather_light')
 poly({{22,39},{27,38},{30,40},{29,46},{27,49},{22,49},{20,46}},'leather')
 rect(22,40,6,1,'leather_light');rect(21,45,2,1,'gold');dot(27,46,'gold_light')
 rect(30,23,5,4,'skin');rect(31,24,3,2,'skin_light');face();frontHair()
 poly({{38,27},{40,26},{42,28},{40,30},{38,29}},'gold_dark');dot(40,27,'gold_light');rect(39,28,2,1,'gold');dot(40,28,'blue_high')
 -- Gold chain and turquoise charm stay in her anatomical left hand.
 line(52,51,53,56,'gold');line(53,54,54,58,'gold')
 poly({{52,57},{55,58},{55,62},{53,63},{51,61}},'blue_dark')
 rect(52,58,2,3,'gem');dot(52,58,'blue_high');dot(53,61,'blue_light')
 return img
end
local function up()
 img=Image(64,64,ColorMode.RGB);boots();robe()
 poly({{21,29},{25,28},{26,39},{24,42},{20,42},{19,38}},'cloth')
 poly({{40,28},{44,29},{46,38},{45,42},{41,42},{40,38}},'cloth')
 poly({{24,25},{39,25},{44,29},{44,36},{47,42},{47,47},{42,50},{38,46},{33,49},{27,47},{20,47},{20,42},{22,35},{21,29}},'blue')
 poly({{25,28},{29,26},{29,35},{27,42},{24,44},{23,40}},'blue_light',false)
 poly({{35,28},{40,28},{41,34},{45,43},{44,47},{40,44},{37,37}},'blue_light',false)
 poly({{29,34},{34,32},{36,39},{35,46},{31,45}},'blue_dark',false)
 line(20,46,27,48,'gold');line(27,48,33,49,'gold');line(38,46,42,49,'gold')
 -- Back of broad sleeves and cuff piping.
 poly({{19,35},{24,35},{25,41},{22,49},{18,52},{15,49},{16,43}},'cloth')
 poly({{18,43},{22,42},{21,48},{18,50},{17,48}},'cloth_light',false);line(15,49,18,52,'gold')
 poly({{42,35},{47,36},{50,42},{50,48},{47,52},{44,50},{43,43}},'cloth')
 poly({{44,40},{47,40},{49,46},{47,50},{45,48}},'cloth_light',false);line(47,52,50,48,'gold')
 poly({{17,49},{20,48},{22,51},{20,54},{17,53}},'skin')
 poly({{46,49},{49,48},{51,51},{50,54},{47,53}},'skin')
 poly({{25,9},{28,7},{35,7},{39,9},{41,13},{41,21},{39,27},{40,31},{36,35},{33,33},{30,35},{25,34},{22,37},{20,34},{21,27},{20,20},{21,14}},'hair_mid')
 poly({{26,10},{29,8},{35,8},{39,11},{39,19},{37,24},{38,30},{35,32},{32,30},{29,33},{25,32},{23,35},{22,33},{23,25},{22,20},{23,14}},'hair',false)
 poly({{28,10},{33,9},{37,11},{38,14},{35,13},{32,12},{28,14},{25,19},{24,18},{25,13}},'hair_light',false)
 line(26,20,25,28,'hair_light');line(30,18,28,27,'hair_mid');line(35,18,33,27,'hair_mid')
 line(39,19,37,26,'hair_dark');line(23,29,22,34,'hair_dark');line(35,29,35,32,'hair_light')
 -- Keep the upper mantle visible below the flowing hair on the back.
 line(25,41,24,45,'blue');line(24,45,22,48,'gold');line(39,39,41,44,'blue');line(41,44,44,47,'gold')
 -- Rear view of the same hip pouch; strap crosses the back to the right hip.
 line(31,29,39,37,'leather_dark');line(32,29,39,36,'leather_light')
 poly({{39,37},{44,37},{47,41},{46,48},{42,50},{38,47}},'leather')
 rect(40,39,5,1,'leather_light');rect(43,45,2,1,'gold')
 -- Anatomical left hand and dangling charm are on viewer-left from behind.
 line(17,52,16,56,'gold');poly({{14,57},{17,57},{19,60},{17,63},{14,62},{13,59}},'blue_dark')
 rect(14,58,3,3,'gem');dot(15,58,'blue_high');line(16,54,17,56,'gold')
 -- Blue band wraps around the back of her head.
 line(22,20,39,20,'blue');line(23,21,38,21,'blue_dark');dot(38,20,'gold_light')
 return img
end
local function side(mirror)
 img=Image(64,64,ColorMode.RGB)
 poly({{29,43},{34,43},{33,54},{30,57},{27,56}},'leather_dark')
 poly({{34,44},{39,44},{39,55},{36,57},{33,55}},'leather_dark')
 poly({{28,51},{32,51},{32,57},{30,59},{24,59},{24,57},{27,55}},'leather')
 poly({{34,51},{39,51},{39,57},{37,59},{31,59},{31,57},{34,55}},'leather')
 rect(28,52,4,2,'leather_light');rect(35,52,4,2,'leather_light');rect(25,57,4,1,'leather_light')
 poly({{29,26},{35,26},{38,33},{36,38},{40,46},{39,50},{34,49},{32,47},{29,50},{25,47},{27,37},{27,32}},'cloth')
 poly({{29,29},{32,28},{33,36},{31,39},{33,46},{30,48},{27,45},{29,38}},'cloth_light',false)
 line(36,38,38,45,'cloth_dark');line(30,39,29,44,'gold')
 poly({{33,26},{39,25},{43,29},{41,35},{45,43},{45,48},{40,50},{35,46},{34,35}},'blue')
 poly({{36,27},{40,28},{40,35},{43,42},{43,47},{40,45},{37,37}},'blue_light',false)
 line(36,42,40,44,'gold');line(40,44,45,48,'gold')
 poly({{28,27},{31,28},{31,34},{29,37},{29,41},{26,43},{24,41},{25,36},{25,31}},'cloth')
 poly({{28,28},{29,31},{28,38},{27,40},{26,40},{27,34}},'cloth_light',false)
 poly({{27,39},{30,40},{30,44},{28,46},{25,44},{25,42}},'skin');rect(26,41,2,2,'skin_light')
 rect(29,35,7,2,'leather');rect(29,35,2,2,'gold')
 poly({{29,21},{34,21},{34,27},{31,29},{28,26}},'skin')
 poly({{26,12},{33,12},{36,16},{35,23},{31,25},{26,23},{25,20},{23,19},{25,17}},'skin')
 poly({{27,16},{31,15},{32,18},{31,22},{27,22},{26,19}},'skin_light',false)
 rect(26,18,2,2,'eye');dot(27,18,'blue_high');dot(25,22,'skin_dark')
 poly({{28,8},{35,7},{40,10},{42,15},{41,22},{39,27},{41,32},{40,38},{37,42},{33,39},{31,35},{29,32},{30,25},{29,21},{30,16},{26,15},{25,12}},'hair_mid')
 poly({{28,9},{35,8},{39,11},{40,15},{37,16},{33,14},{30,12},{27,14},{27,11}},'hair',false)
 poly({{30,9},{34,9},{37,10},{38,12},{34,11},{30,11},{28,13}},'hair_light',false)
 poly({{34,16},{39,16},{39,23},{37,27},{39,33},{38,38},{35,40},{33,37},{32,33}},'hair',false)
 line(35,18,34,25,'hair_light');line(39,20,37,26,'hair_dark');line(35,33,35,38,'hair_light')
 rect(30,14,2,1,'gold');dot(30,15,'gold_light')
 -- Right-facing side contains the same charm in her left hand.
 if mirror then
  local flipped=Image(64,64,ColorMode.RGB)
  for y=0,63 do for x=0,63 do flipped:drawPixel(63-x,y,img:getPixel(x,y)) end end
  img=flipped
  line(35,46,35,51,'gold');poly({{34,51},{37,52},{38,55},{36,58},{33,57},{32,54}},'blue_dark')
  rect(34,53,2,3,'gem');dot(34,53,'blue_high');dot(35,56,'blue_light')
 end
 return img
end

-- Give diagonal directions a true turned silhouette while retaining upright
-- pixel-art anatomy: compress across the facing axis with nearest-pixel sampling.
-- Front diagonals show the face; rear diagonals show the back of the hair and cape.
local function diagonal(source, sideSign)
 local result=Image(64,64,ColorMode.RGB)
 local widthScale=0.76
 for y=0,63 do
  local perspective=(y-31.5)*sideSign*0.09
  for x=0,63 do
   local sourceX=math.floor(31.5+(x-31.5-perspective)/widthScale+0.5)
   if sourceX>=0 and sourceX<64 then
    local pixel=source:getPixel(sourceX,y)
    if pixel~=0 then result:drawPixel(x,y,pixel) end
   end
  end
 end
 return result
end

local downImage=down()
local upImage=up()
local leftImage=side(false)
local rightImage=side(true)
local directions={
 {'up',upImage},
 {'up-right',diagonal(upImage,1)},
 {'right',rightImage},
 {'down-right',diagonal(downImage,1)},
 {'down',downImage},
 {'down-left',diagonal(downImage,-1)},
 {'left',leftImage},
 {'up-left',diagonal(upImage,-1)}
}

local order={'outline','hair_dark','hair_mid','hair','hair_light','skin_dark','skin','skin_light','eye',
 'blue_dark','blue','blue_light','blue_high','cloth_dark','cloth','cloth_light','gold_dark','gold','gold_light',
 'leather_dark','leather','leather_light','gem'}
local palette=Palette(#order+1);palette:setColor(0,Color{r=0,g=0,b=0,a=0})
for n,key in ipairs(order) do
 local v=hex[key]
 palette:setColor(n,Color{r=tonumber(v:sub(1,2),16),g=tonumber(v:sub(3,4),16),b=tonumber(v:sub(5,6),16),a=255})
end

-- Eight selectable direction frames, each tagged, on a transparent 64x64 canvas.
local sprite=Sprite(64,64,ColorMode.RGB)
sprite:deleteLayer(sprite.layers[1])
sprite.gridBounds=Rectangle(0,0,64,64)
sprite.data='Concept 8 blonde heroine. Eight static facings, clockwise from up: up, up-right, right, down-right, down, down-left, left, up-left. Each 64x64 cel is individually editable. Based on Art/Characters/Concept08References8.'
local layer=sprite:newLayer();layer.name='Hero pixels'
for n,item in ipairs(directions) do
 if n>1 then sprite:newEmptyFrame() end
 sprite.frames[n].duration=1000
 sprite:newCel(layer,n,item[2],Point(0,0))
 local tag=sprite:newTag(n,n);tag.name=item[1];tag.color=Color{r=71,g=125,b=181,a=255}
 item[2]:saveAs(out..'hero-64-'..item[1]..'.png')
end
local root=sprite:newSlice(Rectangle(0,0,64,64));root.name='hero-ground-pivot';root.pivot=Point(32,59)
sprite:setPalette(palette)
sprite:saveAs(out..'hero-64-8-directions.aseprite')

-- Also provide a compact 4x2 review sheet, matching the frame order above.
local sheet=Sprite(256,128,ColorMode.RGB)
sheet:deleteLayer(sheet.layers[1]);sheet.gridBounds=Rectangle(0,0,64,64);sheet:setPalette(palette)
local sheetImage=Image(256,128,ColorMode.RGB)
for n,item in ipairs(directions) do
 local x=((n-1)%4)*64;local y=math.floor((n-1)/4)*64
 sheetImage:drawImage(item[2],Point(x,y))
 local slice=sheet:newSlice(Rectangle(x,y,64,64));slice.name=item[1];slice.pivot=Point(32,59)
end
local sheetLayer=sheet:newLayer();sheetLayer.name='Up clockwise to up-left'
sheet:newCel(sheetLayer,1,sheetImage,Point(0,0))
sheet.data='Eight 64x64 static reference facings, arranged left-to-right then top-to-bottom: up, up-right, right, down-right / down, down-left, left, up-left.'
sheet:saveAs(out..'hero-64-8-directions-sheet.aseprite')
sheet:saveCopyAs(out..'hero-64-8-directions-sheet.png')

-- Nearest-neighbor zoom for quick review; the sprite exports above stay native 64x64.
local preview=Sprite(1536,768,ColorMode.RGB)
local enlarged=Image(1536,768,ColorMode.RGB)
for y=0,127 do for x=0,255 do
 local p=sheetImage:getPixel(x,y)
 if p~=0 then for yy=0,5 do for xx=0,5 do enlarged:drawPixel(x*6+xx,y*6+yy,p) end end end
end end
preview:newCel(preview.layers[1],1,enlarged,Point(0,0));preview:saveCopyAs(out..'hero-64-8-directions-preview.png')
print('Saved eight tagged 64x64 concept 8 directions to '..out)
