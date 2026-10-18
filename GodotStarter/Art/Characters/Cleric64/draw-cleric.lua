-- Authored on native 64 x 64 canvases in Aseprite. No image resampling.
local out = 'D:/Simon/Dev/ARPGgame/GodotStarter/Art/Characters/Cleric64/'
local colors = {
  ink='33283e', edge='63516d', shade='9b85a4', lilac='c8b9d3', cloth='e9e4f0', white='fff9ef',
  hairDark='9b634d', hairShade='c08a59', hair='e9b974', hairLight='ffdb91', hairShine='fff0b9',
  skinShade='ca8678', skin='f1b99b', skinLight='ffdfb7', blush='e4a093',
  blueDark='172c65', blueShade='234b96', blue='366ac0', blueLight='6d9cdb',
  goldDark='805335', gold='c68b3f', goldLight='efc469', goldShine='ffe3a0',
  eye='286bc2', crystal='35b6ed', ice='b5f4ff', boot='59434b', bootLight='876355'
}
local P={}
for k,v in pairs(colors) do P[k]=app.pixelColor.rgba(tonumber(v:sub(1,2),16),tonumber(v:sub(3,4),16),tonumber(v:sub(5,6),16),255) end
local layerNames={'Hair behind','Boots and legs','Robes and goldwork','Face and hair','Headdress','Staff and hands'}
local function canvas() local t={} for i=1,6 do t[i]=Image(64,64,ColorMode.RGB) end return t end
local function px(im,x,y,c) if x>=0 and x<64 and y>=0 and y<64 then im:drawPixel(x,y,P[c] or c) end end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,c) end end end
local function line(im,x0,y0,x1,y1,c)
 local dx,dy=math.abs(x1-x0),-math.abs(y1-y0); local sx=x0<x1 and 1 or -1; local sy=y0<y1 and 1 or -1;local e=dx+dy
 while true do px(im,x0,y0,c);if x0==x1 and y0==y1 then break end;local e2=2*e;if e2>=dy then e=e+dy;x0=x0+sx end;if e2<=dx then e=e+dx;y0=y0+sy end end
end
local function poly(im,points,fill,outline)
 for y=0,63 do
  local cuts={};local j=#points
  for i=1,#points do local a,b=points[i],points[j];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then cuts[#cuts+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end;j=i end
  table.sort(cuts);for i=1,#cuts-1,2 do for x=math.ceil(cuts[i]),math.floor(cuts[i+1]) do px(im,x,y,fill) end end
 end
 if outline then for i=1,#points do local a,b=points[i],points[i%#points+1];line(im,a[1],a[2],b[1],b[2],outline) end end
end
local function cross(im,x,y,c) rect(im,x,y,1,6,c);rect(im,x-2,y+2,5,1,c);px(im,x-1,y+5,c);px(im,x+1,y+5,c) end
local function staff(im,x)
 rect(im,x-1,23,3,35,'ink');rect(im,x,24,1,33,'goldDark');rect(im,x,26,1,7,'gold');rect(im,x,45,1,10,'gold');rect(im,x-1,55,3,3,'goldDark');rect(im,x-1,55,2,2,'goldLight')
 poly(im,{{x,13},{x+6,19},{x+6,21},{x,27},{x-6,21},{x-6,19}},'gold','ink')
 poly(im,{{x,15},{x+4,19},{x+4,21},{x,25},{x-4,21},{x-4,19}},'goldLight','goldDark')
 poly(im,{{x,17},{x+2,20},{x,23},{x-2,20}},'crystal','blueDark');rect(im,x,18,1,3,'ice');px(im,x-1,20,'white');px(im,x+1,21,'blue')
 rect(im,x-1,11,3,5,'gold');rect(im,x,10,1,5,'goldLight');rect(im,x-2,13,5,1,'goldLight')
 rect(im,x-5,23,2,6,'shade');rect(im,x-5,24,1,4,'cloth');rect(im,x+4,23,2,6,'lilac');rect(im,x+4,24,1,4,'white')
end
local function boots(im)
 rect(im,27,49,6,7,'ink');rect(im,35,49,6,7,'ink');rect(im,28,50,4,5,'shade');rect(im,36,50,4,5,'shade')
 poly(im,{{26,55},{32,55},{33,61},{25,61},{25,58}},'boot','ink');poly(im,{{35,55},{41,55},{42,60},{41,61},{35,61}},'boot','ink')
 rect(im,27,56,4,2,'bootLight');rect(im,36,56,4,2,'bootLight');rect(im,27,59,4,1,'edge');rect(im,36,59,4,1,'edge');rect(im,28,53,3,2,'gold');rect(im,37,53,3,2,'gold');px(im,28,53,'goldLight');px(im,37,53,'goldLight')
end
local function front()
 local t=canvas();local im=t[1]
 poly(im,{{25,15},{39,14},{44,24},{44,33},{49,40},{48,48},{42,51},{37,47},{29,49},{21,51},{16,47},{17,40},{21,32},{21,23}},'hair','ink')
 poly(im,{{23,22},{25,26},{23,36},{20,42},{21,47},{18,46},{19,39},{21,30}},'hairShade')
 poly(im,{{40,21},{43,25},{41,34},{46,42},{45,47},{42,48},{40,42},{39,34}},'hairShade')
 line(im,23,32,20,42,'hairLight');line(im,42,32,46,42,'hairLight');line(im,23,42,22,47,'hairShine')
 boots(t[2]);im=t[3]
 poly(im,{{25,32},{39,32},{44,36},{43,43},{47,53},{42,56},{36,51},{33,55},{28,52},{23,56},{19,53},{22,43},{20,38}},'cloth','ink')
 poly(im,{{24,34},{28,35},{27,43},{23,53},{21,52},{24,42}},'white');poly(im,{{40,35},{43,37},{41,43},{45,52},{42,54},{38,45}},'lilac')
 poly(im,{{26,34},{39,34},{38,44},{36,53},{32,55},{29,52},{28,44}},'blueShade','blueDark')
 poly(im,{{29,36},{36,36},{35,45},{36,49},{32,53},{31,46}},'blue');rect(im,30,36,6,1,'blueLight')
 line(im,28,36,29,48,'gold');line(im,37,36,36,49,'gold');line(im,29,49,32,53,'goldLight');line(im,32,53,36,49,'gold');cross(im,33,46,'goldLight')
 poly(im,{{25,32},{31,34},{33,32},{38,32},{40,35},{34,38},{31,37},{24,35}},'white','shade')
 line(im,25,35,30,37,'gold');line(im,34,37,39,35,'gold');rect(im,31,33,3,4,'gold');rect(im,30,34,5,1,'goldLight')
 poly(im,{{22,35},{24,39},{19,43},{15,40},{16,36}},'white','ink');line(im,16,40,20,42,'gold');line(im,17,39,20,41,'goldLight')
 poly(im,{{42,35},{47,38},{48,42},{43,44},{40,40}},'cloth','ink');poly(im,{{44,37},{46,38},{46,40},{43,42},{42,40}},'white');line(im,43,42,47,40,'blueShade');line(im,43,43,48,41,'gold')
 line(im,23,53,27,50,'goldLight');line(im,39,51,44,54,'gold');px(im,24,50,'gold');px(im,43,50,'goldLight')
 im=t[4]
 poly(im,{{24,19},{29,17},{38,18},{41,22},{40,29},{37,32},{28,32},{25,29}},'skin','hairDark')
 rect(im,28,21,9,8,'skinLight');rect(im,29,28,8,3,'skinLight');rect(im,27,28,2,1,'blush');rect(im,38,28,2,1,'blush');px(im,33,30,'skinShade')
 rect(im,27,24,4,1,'ink');rect(im,28,25,3,3,'blueDark');rect(im,28,26,2,2,'eye');px(im,28,25,'white');px(im,29,28,'blueLight')
 rect(im,35,24,4,1,'ink');rect(im,35,25,3,3,'blueDark');rect(im,35,26,2,2,'eye');px(im,35,25,'white');px(im,36,28,'blueLight')
 poly(im,{{24,17},{31,16},{29,21},{25,26},{23,30},{22,25}},'hairLight','hairShade')
 poly(im,{{30,17},{34,17},{35,23},{33,25},{31,20},{29,23}},'hairShine')
 poly(im,{{35,17},{40,18},{43,24},{41,29},{39,25},{38,22}},'hair','hairShade');line(im,39,20,41,24,'hairLight')
 im=t[5]
 poly(im,{{31,2},{34,2},{37,5},{42,7},{46,11},{48,16},{45,21},{41,21},{37,18},{27,18},{23,21},{18,18},{18,13},{23,8},{28,5}},'cloth','ink')
 poly(im,{{31,4},{34,4},{40,8},{42,12},{39,15},{32,13},{23,17},{20,16},{21,12},{26,8}},'white')
 poly(im,{{42,9},{45,12},{46,16},{44,19},{40,17},{42,14}},'lilac')
 poly(im,{{23,16},{31,12},{35,12},{43,16},{45,19},{41,19},{35,16},{30,16},{24,19},{21,18}},'blueShade','blueDark')
 line(im,23,15,31,11,'gold');line(im,31,11,35,11,'goldLight');line(im,35,11,43,15,'gold');line(im,25,17,30,14,'blueLight')
 cross(im,33,5,'goldLight');px(im,33,7,'gold');px(im,32,8,'gold')
 im=t[6];staff(im,13)
 poly(im,{{13,35},{16,35},{18,37},{17,40},{13,39}},'skin','ink');rect(im,14,36,2,2,'skinLight');px(im,15,39,'skinShade')
 poly(im,{{44,43},{47,42},{48,44},{46,46},{43,45}},'skin','ink');rect(im,44,43,2,2,'skinLight')
 return t
end
local function right()
 local t=canvas();local im=t[1]
 poly(im,{{27,15},{38,17},{38,28},{34,33},{35,39},{39,45},{34,50},{27,48},{21,50},{16,47},{16,42},{19,35},{21,24}},'hair','ink')
 poly(im,{{24,24},{27,23},{26,33},{22,40},{21,46},{18,46},{19,40},{22,33}},'hairShade')
 poly(im,{{28,27},{31,27},{29,36},{26,42},{27,46},{24,47},{23,42},{26,35}},'hairLight');line(im,20,39,19,44,'hairShine')
 im=t[2];rect(im,31,48,5,10,'ink');rect(im,37,48,4,10,'ink');rect(im,32,49,3,6,'shade')
 poly(im,{{31,55},{36,55},{36,58},{40,59},{40,61},{31,61},{30,59}},'boot','ink');rect(im,32,56,3,2,'bootLight');rect(im,32,54,3,2,'gold')
 poly(im,{{37,55},{41,55},{41,58},{44,59},{44,61},{36,61},{36,59}},'boot','ink');rect(im,38,56,3,2,'bootLight');rect(im,38,54,3,2,'gold')
 im=t[3]
 poly(im,{{30,32},{38,32},{42,36},{42,44},{45,53},{40,56},{36,51},{32,55},{26,54},{24,51},{28,42}},'cloth','ink')
 poly(im,{{32,34},{36,33},{36,42},{30,52},{27,52},{30,42}},'white');poly(im,{{39,36},{41,38},{39,45},{43,53},{40,54},{36,46}},'lilac')
 poly(im,{{38,35},{40,36},{39,44},{42,51},{39,54},{35,47}},'blueShade','blueDark');line(im,39,40,38,47,'blue');line(im,39,49,40,52,'goldLight')
 poly(im,{{35,34},{38,34},{42,37},{44,38},{43,42},{38,43},{34,39}},'white','ink');line(im,38,41,43,40,'blueShade');line(im,38,42,43,41,'gold')
 line(im,28,53,32,50,'goldLight');line(im,41,53,43,52,'gold')
 im=t[4]
 poly(im,{{33,18},{39,19},{41,23},{41,25},{43,27},{41,28},{40,31},{35,32},{32,29}},'skin','hairDark')
 poly(im,{{35,21},{39,21},{40,25},{41,27},{39,29},{35,29}},'skinLight');rect(im,38,24,3,1,'ink');rect(im,38,25,2,3,'eye');px(im,38,25,'white');px(im,40,29,'skinShade')
 poly(im,{{29,17},{36,17},{38,20},{35,24},{33,28},{32,24},{28,28},{27,24}},'hairLight','hairShade');line(im,33,19,30,24,'hairShine')
 poly(im,{{28,26},{32,24},{32,31},{29,36},{26,38},{27,33}},'hair','hairShade')
 im=t[5]
 poly(im,{{29,3},{34,3},{39,7},{43,12},{43,17},{39,20},{34,17},{28,18},{23,23},{18,20},{17,15},{21,9}},'cloth','ink')
 poly(im,{{29,5},{33,5},{38,9},{39,13},{33,15},{26,15},{21,19},{19,17},{22,12}},'white')
 poly(im,{{20,18},{23,21},{27,17},{29,18},{25,23},{20,21}},'lilac')
 poly(im,{{23,15},{28,17},{36,12},{40,15},{39,18},{36,16},{29,21},{23,18}},'blueShade','blueDark');line(im,24,15,28,17,'goldLight');line(im,29,16,36,11,'gold');line(im,31,17,36,14,'blueLight')
 cross(im,31,6,'goldLight')
 im=t[6];staff(im,49);poly(im,{{44,36},{48,35},{50,37},{49,40},{45,40},{43,38}},'skin','ink');rect(im,46,36,2,2,'skinLight')
 return t
end
local function back()
 local t=canvas();boots(t[2]);local im=t[3]
 poly(im,{{25,32},{39,32},{44,37},{43,44},{47,53},{43,56},{38,53},{33,56},{27,53},{22,56},{18,53},{22,44},{21,37}},'cloth','ink')
 poly(im,{{21,47},{25,45},{28,51},{24,54},{21,53}},'white');poly(im,{{41,46},{43,46},{46,52},{43,54},{39,51}},'lilac')
 poly(im,{{30,43},{35,43},{37,52},{33,55},{29,52}},'blueShade','blueDark');line(im,30,52,33,54,'gold');line(im,33,54,36,52,'goldLight');cross(im,33,47,'goldLight')
 line(im,20,52,23,54,'goldLight');line(im,43,54,46,52,'gold')
 im=t[4]
 poly(im,{{23,16},{40,16},{43,23},{43,31},{46,39},{48,44},{46,49},{40,51},{35,49},{31,51},{25,50},{21,51},{17,47},{18,41},{22,31},{21,23}},'hair','ink')
 poly(im,{{24,24},{28,25},{26,34},{23,41},{22,47},{19,46},{20,41},{23,32}},'hairLight')
 poly(im,{{29,24},{33,25},{32,34},{29,42},{29,48},{26,48},{26,43},{29,34}},'hairShade')
 poly(im,{{35,24},{39,24},{39,34},{44,43},{43,48},{40,49},{37,43},{36,35}},'hairLight')
 line(im,24,33,21,41,'hairShine');line(im,39,33,42,40,'hairShine');line(im,33,41,32,48,'hairDark')
 im=t[5]
 poly(im,{{31,2},{34,2},{40,6},{46,10},{48,16},{46,21},{41,23},{25,23},{20,21},{18,17},{19,12},{24,7}},'cloth','ink')
 poly(im,{{31,4},{34,4},{42,9},{44,13},{40,17},{31,16},{24,19},{21,17},{22,12},{26,8}},'white')
 poly(im,{{39,17},{45,14},{46,17},{43,21},{37,21},{34,19}},'lilac')
 poly(im,{{22,19},{26,21},{40,21},{45,18},{45,21},{40,24},{27,24},{22,22}},'blueShade','blueDark');line(im,23,19,28,21,'gold');line(im,28,21,39,21,'goldLight');line(im,40,21,44,19,'gold')
 cross(im,33,7,'goldLight')
 poly(im,{{32,23},{30,28},{31,35},{33,33},{35,36},{37,28},{35,23}},'cloth','blueDark');poly(im,{{32,25},{32,30},{33,31},{34,30},{34,25}},'white');rect(im,31,23,5,2,'gold');px(im,33,23,'goldLight')
 im=t[6];staff(im,50);poly(im,{{45,39},{49,38},{51,40},{49,43},{46,42}},'skin','ink');rect(im,47,39,2,2,'skinLight')
 return t
end
local function mirrored(t)
 local result=canvas();for i=1,#t do for y=0,63 do for x=0,63 do result[i]:drawPixel(63-x,y,t[i]:getPixel(x,y)) end end end;return result
end
local ok,err=pcall(function()
 local rightView=right();local art={front(),rightView,back(),mirrored(rightView)}
 local names={'front','right','back','left'}
 local s=Sprite(64,64,ColorMode.RGB);s.layers[1].name=layerNames[1]
 local layers={s.layers[1]};for i=2,6 do layers[i]=s:newLayer();layers[i].name=layerNames[i] end
 for f=2,4 do s:newEmptyFrame(f) end
 for f=1,4 do
  for i=1,6 do s:newCel(layers[i],f,art[f][i],Point(0,0)) end
  s.frames[f].duration=0.2;local tag=s:newTag(f,f);tag.name=names[f]
 end
 s.data='Reference-inspired cleric. Four static directions: front, right, back, left. Native 64x64 pixels per frame. Authored directly in Aseprite using draw-cleric.lua.'
 local palette=Palette(1);palette:setColor(0,Color{r=0,g=0,b=0,a=0});local keys={};for k in pairs(colors) do keys[#keys+1]=k end;table.sort(keys);palette:resize(#keys+1);for i,k in ipairs(keys) do palette:setColor(i,Color(P[k])) end;s:setPalette(palette)
 s:saveAs(out..'cleric-64-four-directions.aseprite')
 local sheet=Image(128,128,ColorMode.RGB)
 for f=1,4 do
  local im=Image(64,64,ColorMode.RGB);im:drawSprite(s,f);im:saveAs(out..'cleric-64-'..names[f]..'.png')
  sheet:drawImage(im,Point(((f-1)%2)*64,math.floor((f-1)/2)*64))
 end
 sheet:saveAs(out..'cleric-64-sheet.png')
 local preview=Image(768,768,ColorMode.RGB);preview:clear(app.pixelColor.rgba(31,34,42,255))
 for y=0,127 do for x=0,127 do local c=sheet:getPixel(x,y);if app.pixelColor.rgbaA(c)>0 then for yy=0,5 do for xx=0,5 do preview:drawPixel(x*6+xx,y*6+yy,c) end end end end end
 preview:saveAs(out..'cleric-64-preview.png')
 local log=io.open(out..'aseprite-build.log','w');log:write('OK: 64x64; 4 frames; 6 layers; front/right/back/left; transparent PNG exports.');log:close()
end)
if not ok then local log=io.open(out..'aseprite-build.log','w');log:write(tostring(err));log:close();error(err) end
