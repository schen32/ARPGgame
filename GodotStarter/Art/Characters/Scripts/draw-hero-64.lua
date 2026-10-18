-- Original 64x64 redraw of our selected blonde heroine. Four static views.
local out="D:/Simon/Dev/ARPGgame/GodotStarter/Art/Characters/Hero64/"
app.fs.makeAllDirectories(out)
local hex={
 outline="292d40",hair_dark="987044",hair_mid="c79b55",hair="e7bd70",hair_light="ffe2a0",
 skin_dark="bb8062",skin="e9b391",skin_light="ffdab3",eye="344667",
 blue_dark="263d67",blue="3b65a0",blue_light="6493c8",blue_high="9ac6df",
 cloth_dark="a5a29b",cloth="d8d4bd",cloth_light="fff0d4",
 gold_dark="9b713c",gold="dfb65f",gold_light="ffe2a0",
 leather_dark="4c3c3a",leather="76513e",leather_light="ac7850",gem="5cc4db"
}
local c={}
for k,v in pairs(hex) do c[k]=app.pixelColor.rgba(tonumber(v:sub(1,2),16),tonumber(v:sub(3,4),16),tonumber(v:sub(5,6),16),255) end
local img
local function dot(x,y,col)
 if x>=0 and x<64 and y>=0 and y<64 then img:drawPixel(x,y,c[col]) end
end
local function rect(x,y,w,h,col)
 for yy=y,y+h-1 do for xx=x,x+w-1 do dot(xx,yy,col) end end
end
local function line(x0,y0,x1,y1,col)
 local dx=math.abs(x1-x0); local sx=x0<x1 and 1 or -1
 local dy=-math.abs(y1-y0); local sy=y0<y1 and 1 or -1; local err=dx+dy
 while true do
  dot(x0,y0,col); if x0==x1 and y0==y1 then break end
  local e=2*err; if e>=dy then err=err+dy;x0=x0+sx end
  if e<=dx then err=err+dx;y0=y0+sy end
 end
end
local function poly(points,col,edge)
 local pixels={}
 for y=0,63 do for x=0,63 do
  local inside=false;local j=#points
  for i=1,#points do
   local a,b=points[i],points[j]
   if (a[2]>y+.5)~=(b[2]>y+.5) and x+.5<(b[1]-a[1])*(y+.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
   j=i
  end
  if inside then pixels[#pixels+1]={x,y} end
 end end
 if edge~=false then for _,p in ipairs(pixels) do
  dot(p[1]-1,p[2],"outline");dot(p[1]+1,p[2],"outline");dot(p[1],p[2]-1,"outline");dot(p[1],p[2]+1,"outline")
 end end
 for _,p in ipairs(pixels) do dot(p[1],p[2],col) end
end
local function boots()
 poly({{27,45},{32,45},{32,54},{30,55},{26,55}},"leather_dark")
 poly({{35,45},{40,45},{40,54},{38,55},{35,55}},"leather_dark")
 poly({{26,51},{31,51},{31,57},{29,59},{24,59},{24,56}},"leather")
 poly({{35,51},{40,51},{40,56},{42,58},{42,59},{35,59}},"leather")
 rect(26,51,5,2,"leather_light");rect(35,51,5,2,"leather_light")
 rect(25,56,3,1,"leather_light");rect(37,56,3,1,"leather_light")
 rect(24,58,6,1,"leather_dark");rect(35,58,7,1,"leather_dark")
end
local function robe()
 poly({{27,27},{37,27},{39,37},{41,46},{38,49},{34,48},{32,45},{29,49},{24,48},{24,44},{26,37}},"cloth")
 poly({{29,28},{35,28},{34,37},{35,43},{34,48},{31,45},{29,47},{27,47},{28,38}},"cloth_light",false)
 line(26,39,25,46,"cloth_dark");line(38,39,39,46,"cloth_dark")
 line(32,39,31,44,"gold");line(33,42,33,46,"gold_light")
end
local function face()
 poly({{27,12},{36,12},{39,16},{38,23},{35,25},{30,25},{26,22},{25,17}},"skin")
 poly({{28,16},{35,15},{37,18},{36,22},{34,24},{30,23},{28,21}},"skin_light",false)
 rect(28,19,2,2,"eye");rect(35,19,2,2,"eye")
 dot(29,19,"blue_high");dot(36,19,"blue_high")
 dot(32,22,"skin_dark");rect(32,24,2,1,"skin_dark")
end
local function frontHair()
 poly({{25,9},{28,7},{35,7},{39,9},{41,12},{41,21},{39,26},{38,29},{36,26},{37,20},{37,15},{34,13},{29,16},{25,18},{24,25},{25,32},{23,36},{20,34},{21,26},{20,19},{21,13}},"hair_mid")
 poly({{25,10},{29,8},{35,8},{39,11},{39,15},{36,14},{33,12},{28,15},{24,17},{23,24},{24,31},{22,34},{22,25},{22,17}},"hair",false)
 poly({{28,9},{34,9},{36,10},{34,11},{31,11},{28,14},{25,14},{26,11}},"hair_light",false)
 poly({{21,24},{23,22},{23,31},{22,34},{21,32}},"hair",false)
 line(24,27,24,32,"hair_dark");line(38,17,38,23,"hair_dark")
 rect(34,11,3,1,"gold_light");rect(36,12,2,1,"gold")
end
local function down()
 img=Image(64,64,ColorMode.RGB)
 boots();robe()
 poly({{23,26},{27,25},{27,31},{25,37},{25,41},{22,42},{19,39},{19,34}},"cloth")
 poly({{39,27},{43,27},{46,33},{47,39},{44,42},{41,41},{40,35}},"cloth")
 line(21,33,21,38,"cloth_light");line(44,33,45,38,"cloth_light")
 poly({{23,25},{27,25},{29,27},{27,32},{27,38},{24,43},{20,41},{21,35},{20,30}},"blue")
 poly({{36,26},{40,25},{44,28},{44,33},{46,40},{43,43},{39,41},{38,34}},"blue")
 poly({{23,27},{26,26},{27,28},{25,34},{24,40},{22,39}},"blue_light",false)
 poly({{39,27},{42,28},{42,33},{44,40},{42,41},{40,35}},"blue_light",false)
 line(21,40,24,42,"gold");line(40,41,43,42,"gold")
 rect(28,35,10,2,"leather");rect(32,35,3,3,"gold_dark");rect(32,35,3,1,"gold_light");rect(33,36,1,1,"outline")
 poly({{20,40},{23,40},{24,43},{22,45},{20,44}},"skin")
 poly({{43,40},{46,40},{47,43},{45,45},{43,44}},"skin")
 dot(21,41,"skin_light");dot(44,41,"skin_light")
 line(46,43,46,46,"gold");poly({{46,46},{48,48},{46,50},{44,48}},"blue_dark")
 rect(46,47,1,2,"gem");dot(45,48,"blue_light")
 rect(30,23,5,4,"skin");rect(31,24,3,2,"skin_light")
 face();frontHair()
 poly({{38,27},{40,26},{42,28},{40,30},{38,29}},"gold_dark")
 dot(40,27,"gold_light");rect(39,28,2,1,"gold");dot(40,28,"blue_high")
 return img
end
local function up()
 img=Image(64,64,ColorMode.RGB)
 boots();robe()
 poly({{21,29},{25,28},{26,39},{24,42},{20,42},{19,38}},"cloth")
 poly({{40,28},{44,29},{46,38},{45,42},{41,42},{40,38}},"cloth")
 poly({{24,25},{39,25},{44,29},{44,36},{47,42},{43,45},{38,43},{33,45},{27,44},{20,42},{22,35},{21,29}},"blue")
 poly({{25,28},{29,26},{29,35},{27,42},{24,42},{25,36}},"blue_light",false)
 poly({{35,28},{40,28},{41,34},{44,42},{40,42},{37,37}},"blue_light",false)
 poly({{29,34},{34,32},{36,39},{35,44},{31,43}},"blue_dark",false)
 line(21,41,27,44,"gold");line(28,44,33,45,"gold");line(38,43,43,44,"gold")
 poly({{20,41},{23,41},{24,44},{22,46},{20,45}},"skin")
 poly({{42,41},{45,41},{46,44},{44,46},{42,45}},"skin")
 poly({{25,9},{28,7},{35,7},{39,9},{41,13},{41,21},{39,27},{40,31},{36,35},{33,33},{30,35},{25,34},{22,37},{20,34},{21,27},{20,20},{21,14}},"hair_mid")
 poly({{26,10},{29,8},{35,8},{39,11},{39,19},{37,24},{38,30},{35,32},{32,30},{29,33},{25,32},{23,35},{22,33},{23,25},{22,20},{23,14}},"hair",false)
 poly({{28,10},{33,9},{37,11},{38,14},{35,13},{32,12},{28,14},{25,19},{24,18},{25,13}},"hair_light",false)
 line(26,20,25,28,"hair_light");line(30,18,28,27,"hair_mid")
 line(35,18,33,27,"hair_mid");line(39,19,37,26,"hair_dark")
 line(23,29,22,34,"hair_dark");line(35,29,35,32,"hair_light")
 return img
end
local function side(mirror)
 img=Image(64,64,ColorMode.RGB)
 poly({{29,43},{34,43},{33,54},{30,57},{27,56}},"leather_dark")
 poly({{34,44},{39,44},{39,55},{36,57},{33,55}},"leather_dark")
 poly({{28,51},{32,51},{32,57},{30,59},{24,59},{24,57},{27,55}},"leather")
 poly({{34,51},{39,51},{39,57},{37,59},{31,59},{31,57},{34,55}},"leather")
 rect(28,52,4,2,"leather_light");rect(35,52,4,2,"leather_light");rect(25,57,4,1,"leather_light")
 poly({{29,26},{35,26},{38,33},{36,38},{40,46},{37,49},{32,47},{29,49},{25,47},{27,37},{27,32}},"cloth")
 poly({{29,29},{32,28},{33,36},{31,39},{33,46},{29,47},{27,45},{29,38}},"cloth_light",false)
 line(36,38,38,45,"cloth_dark");line(30,39,29,44,"gold")
 poly({{33,26},{39,25},{43,29},{41,35},{45,43},{40,45},{35,42},{34,35}},"blue")
 poly({{36,27},{40,28},{40,35},{43,42},{40,43},{37,37}},"blue_light",false)
 line(36,42,40,44,"gold");line(40,44,44,43,"gold")
 poly({{28,27},{31,28},{31,34},{29,37},{29,41},{26,43},{24,41},{25,36},{25,31}},"cloth")
 poly({{28,28},{29,31},{28,38},{27,40},{26,40},{27,34}},"cloth_light",false)
 poly({{27,39},{30,40},{30,44},{28,46},{25,44},{25,42}},"skin")
 rect(26,41,2,2,"skin_light")
 rect(29,35,7,2,"leather");rect(29,35,2,2,"gold")
 poly({{29,21},{34,21},{34,27},{31,29},{28,26}},"skin")
 poly({{26,12},{33,12},{36,16},{35,23},{31,25},{26,23},{25,20},{23,19},{25,17}},"skin")
 poly({{27,16},{31,15},{32,18},{31,22},{27,22},{26,19}},"skin_light",false)
 rect(26,18,2,2,"eye");dot(27,18,"blue_high");dot(25,22,"skin_dark")
 poly({{28,8},{35,7},{40,10},{42,15},{41,22},{39,27},{41,32},{38,36},{34,33},{31,35},{29,32},{30,25},{29,21},{30,16},{26,15},{25,12}},"hair_mid")
 poly({{28,9},{35,8},{39,11},{40,15},{37,16},{33,14},{30,12},{27,14},{27,11}},"hair",false)
 poly({{30,9},{34,9},{37,10},{38,12},{34,11},{30,11},{28,13}},"hair_light",false)
 poly({{34,16},{39,16},{39,23},{37,27},{39,31},{37,33},{34,30},{32,33},{31,30},{32,23}},"hair",false)
 line(35,18,34,25,"hair_light");line(39,20,37,26,"hair_dark");line(35,29,36,32,"hair_light")
 rect(30,14,2,1,"gold");dot(30,15,"gold_light")
 if mirror then
  local flipped=Image(64,64,ColorMode.RGB)
  for y=0,63 do for x=0,63 do flipped:drawPixel(63-x,y,img:getPixel(x,y)) end end
  img=flipped
  line(35,44,35,46,"gold")
  poly({{35,46},{37,48},{35,50},{33,48}},"blue_dark")
  rect(35,47,1,2,"gem");dot(34,48,"blue_light")
 end
 return img
end
local images={down(),up(),side(false),side(true)}
local names={"down","up","left","right"}
local sprite=Sprite(256,64,ColorMode.RGB)
sprite:deleteLayer(sprite.layers[1]);sprite.gridBounds=Rectangle(0,0,64,64)
sprite.data="Original 64x64 redraw of concept 8. Blonde heroine, blue mantle, ivory robe, gold clasp, blue charm. Four static views, one frame."
for n,name in ipairs(names) do
 local layer=sprite:newLayer();layer.name=name
 sprite:newCel(layer,1,images[n],Point((n-1)*64,0))
 local slice=sprite:newSlice(Rectangle((n-1)*64,0,64,64));slice.name=name;slice.pivot=Point(32,59)
 images[n]:saveAs(out.."hero-64-"..name..".png")
end
local order={"outline","hair_dark","hair_mid","hair","hair_light","skin_dark","skin","skin_light","eye","blue_dark","blue","blue_light","blue_high","cloth_dark","cloth","cloth_light","gold_dark","gold","gold_light","leather_dark","leather","leather_light","gem"}
local palette=Palette(#order+1);palette:setColor(0,Color{r=0,g=0,b=0,a=0})
for n,key in ipairs(order) do local v=hex[key];palette:setColor(n,Color{r=tonumber(v:sub(1,2),16),g=tonumber(v:sub(3,4),16),b=tonumber(v:sub(5,6),16),a=255}) end
sprite:setPalette(palette)
sprite:saveAs(out.."hero-64-facing-views.aseprite")
sprite:saveCopyAs(out.."hero-64-facing-views.png")
