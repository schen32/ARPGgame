-- Authored on native 32 x 32 canvases in Aseprite. No image resampling.
local out = 'D:/Simon/Dev/ARPGgame/GodotStarter/Art/Characters/Cleric32/'
local colors = {
  ink='33283e', edge='31516d', shade='9b85a4', lilac='c8b9d3', cloth='e9e4f0', white='fff9ef',
  hairDark='9b314d', hairShade='c08a59', hair='e9b974', hairLight='ffdb91', hairShine='fff0b9',
  skinShade='ca8678', skin='f1b99b', skinLight='ffdfb7', blush='e4a093',
  blueDark='172c65', blueShade='234b96', blue='366ac0', blueLight='6d9cdb',
  goldDark='805335', gold='c68b3f', goldLight='efc469', goldShine='ffe3a0',
  eye='286bc2', crystal='35b6ed', ice='b5f4ff', boot='59434b', bootLight='873155'
}
local P={}
for k,v in pairs(colors) do P[k]=app.pixelColor.rgba(tonumber(v:sub(1,2),16),tonumber(v:sub(3,4),16),tonumber(v:sub(5,6),16),255) end
local layerNames={'Hair behind','Boots and legs','Robes and goldwork','Face and hair','Headdress','Staff and hands'}
local function canvas() local t={} for i=1,6 do t[i]=Image(32,32,ColorMode.RGB) end return t end
local function px(im,x,y,c) if x>=0 and x<32 and y>=0 and y<32 then im:drawPixel(x,y,P[c] or c) end end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,c) end end end
local function line(im,x0,y0,x1,y1,c)
 local dx,dy=math.abs(x1-x0),-math.abs(y1-y0); local sx=x0<x1 and 1 or -1; local sy=y0<y1 and 1 or -1;local e=dx+dy
 while true do px(im,x0,y0,c);if x0==x1 and y0==y1 then break end;local e2=2*e;if e2>=dy then e=e+dy;x0=x0+sx end;if e2<=dx then e=e+dx;y0=y0+sy end end
end
local function poly(im,points,fill,outline)
 for y=0,31 do
  local cuts={};local j=#points
  for i=1,#points do local a,b=points[i],points[j];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then cuts[#cuts+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end;j=i end
  table.sort(cuts);for i=1,#cuts-1,2 do for x=math.ceil(cuts[i]),math.floor(cuts[i+1]) do px(im,x,y,fill) end end
 end
 if outline then for i=1,#points do local a,b=points[i],points[i%#points+1];line(im,a[1],a[2],b[1],b[2],outline) end end
end
local function cross(im,x,y)
 rect(im,x,y,1,4,'goldLight');rect(im,x-1,y+1,3,1,'goldLight')
end
local function staff(im,x)
 rect(im,x,11,2,18,'ink');rect(im,x,12,1,16,'gold');px(im,x,27,'goldLight')
 poly(im,{{x,6},{x+3,9},{x,13},{x-3,10},{x-3,9}},'gold','ink')
 poly(im,{{x,7},{x+2,9},{x,12},{x-2,10},{x-2,9}},'goldLight')
 rect(im,x-1,9,2,2,'crystal');px(im,x,8,'ice');px(im,x-1,9,'white');px(im,x,11,'blue')
 rect(im,x,4,1,3,'goldLight');rect(im,x-1,5,3,1,'gold')
 rect(im,x-3,12,1,3,'cloth');px(im,x-3,15,'shade')
end
local function boots(im,side)
 if side then
  rect(im,15,25,3,4,'ink');rect(im,19,25,3,4,'ink')
  rect(im,15,28,5,3,'ink');rect(im,19,28,5,3,'ink')
  rect(im,16,28,2,2,'bootLight');rect(im,20,28,2,2,'bootLight');px(im,16,27,'gold');px(im,20,27,'gold')
 else
  rect(im,12,25,3,4,'ink');rect(im,17,25,3,4,'ink')
  rect(im,11,28,4,3,'ink');rect(im,17,28,4,3,'ink')
  rect(im,12,28,2,2,'bootLight');rect(im,18,28,2,2,'bootLight');px(im,13,27,'gold');px(im,18,27,'gold')
 end
end
local function front()
 local t=canvas();local im=t[1]
 poly(im,{{12,8},{20,8},{22,13},{22,18},{25,22},{24,25},{20,26},{16,24},{12,26},{8,25},{7,22},{10,17},{10,12}},'hair','ink')
 line(im,11,14,9,22,'hairShade');line(im,21,15,23,22,'hairShade');line(im,11,18,10,23,'hairLight')
 boots(t[2],false);im=t[3]
 poly(im,{{12,16},{20,16},{23,18},{22,21},{25,26},{21,28},{17,25},{13,26},{10,28},{8,26},{10,21},{9,19}},'cloth','ink')
 poly(im,{{11,18},{13,18},{12,22},{10,26},{9,25}},'white');poly(im,{{21,19},{22,20},{21,22},{23,26},{21,26},{19,22}},'lilac')
 poly(im,{{13,17},{19,17},{19,22},{18,27},{16,28},{14,26}},'blueShade','blueDark');rect(im,15,19,3,5,'blue')
 line(im,14,19,14,25,'gold');line(im,19,19,18,25,'gold');cross(im,16,23)
 line(im,12,17,16,19,'goldLight');line(im,16,19,20,17,'gold');px(im,16,17,'goldLight')
 poly(im,{{10,18},{11,20},{8,22},{6,20},{7,18}},'white','ink');px(im,8,21,'goldLight')
 poly(im,{{22,18},{25,20},{24,23},{21,22},{20,20}},'cloth','ink');line(im,22,22,24,21,'blueShade');px(im,24,22,'gold')
 im=t[4]
 poly(im,{{12,9},{19,9},{21,12},{20,15},{18,17},{13,16},{11,14}},'skin','hairDark')
 rect(im,13,11,6,4,'skinLight');rect(im,14,15,4,1,'skinLight');px(im,16,16,'skinShade')
 rect(im,12,12,3,1,'ink');rect(im,13,13,2,2,'eye');px(im,13,13,'ice')
 rect(im,17,12,3,1,'ink');rect(im,17,13,2,2,'eye');px(im,17,13,'ice')
 poly(im,{{11,8},{16,8},{14,11},{11,14},{10,13}},'hairLight','hairShade');line(im,13,9,12,11,'hairShine')
 poly(im,{{16,8},{19,9},{21,12},{20,14},{18,11},{17,12}},'hairLight');px(im,16,10,'hairShine')
 im=t[5]
 poly(im,{{15,1},{17,1},{21,4},{24,7},{23,10},{20,11},{17,9},{13,9},{10,11},{8,9},{8,6},{12,3}},'cloth','ink')
 poly(im,{{15,2},{17,2},{21,5},{21,7},{16,6},{10,9},{9,7},{12,4}},'white')
 poly(im,{{22,5},{23,7},{22,9},{20,9},{20,7}},'lilac')
 poly(im,{{10,8},{14,6},{17,6},{22,8},{22,10},{17,8},{14,8},{10,10}},'blueShade','blueDark')
 line(im,10,7,14,5,'gold');line(im,14,5,17,5,'goldLight');line(im,17,5,22,7,'gold');cross(im,16,2)
 im=t[6];staff(im,5);rect(im,5,18,3,3,'ink');rect(im,5,18,2,2,'skinLight');rect(im,22,23,2,2,'skin');px(im,23,23,'skinLight')
 return t
end
local function right()
 local t=canvas();local im=t[1]
 poly(im,{{12,8},{18,8},{20,12},{18,16},{19,19},{21,23},{18,26},{14,25},{10,26},{7,24},{8,20},{10,16}},'hair','ink')
 poly(im,{{12,12},{14,13},{12,18},{10,23},{9,24},{9,21}},'hairShade');line(im,14,16,12,23,'hairLight');line(im,16,18,17,23,'hairLight')
 boots(t[2],true);im=t[3]
 poly(im,{{15,16},{20,16},{22,19},{21,22},{24,26},{21,28},{18,25},{15,28},{12,27},{12,25},{14,21}},'cloth','ink')
 poly(im,{{16,17},{18,18},{16,22},{14,26},{13,26},{15,21}},'white')
 poly(im,{{20,18},{21,18},{20,22},{22,26},{20,27},{18,23}},'blueShade','blueDark');line(im,20,23,21,26,'goldLight')
 poly(im,{{18,18},{21,18},{23,20},{22,22},{19,22},{17,20}},'white','ink');line(im,19,22,22,21,'blueShade');px(im,21,22,'goldLight')
 line(im,14,26,16,24,'goldLight');px(im,22,26,'gold')
 im=t[4]
 poly(im,{{16,9},{20,10},{21,12},{21,13},{23,14},{21,15},{20,16},{17,16},{15,14}},'skin','hairDark')
 rect(im,17,11,3,4,'skinLight');rect(im,19,12,2,1,'ink');rect(im,19,13,1,2,'eye');px(im,19,13,'ice');px(im,20,15,'skinShade')
 poly(im,{{13,8},{17,8},{19,10},{17,12},{16,15},{14,14},{14,17},{12,17}},'hairLight','hairShade');px(im,15,10,'hairShine')
 im=t[5]
 poly(im,{{14,1},{17,2},{20,4},{22,7},{21,10},{18,10},{15,9},{12,12},{9,11},{8,8},{10,4}},'cloth','ink')
 poly(im,{{14,2},{16,3},{19,5},{19,7},{15,7},{11,10},{9,8},{11,5}},'white')
 poly(im,{{11,7},{14,8},{18,5},{21,7},{20,9},{18,8},{14,11},{11,9}},'blueShade','blueDark');line(im,12,7,14,8,'goldLight');line(im,15,7,18,4,'gold');cross(im,15,3)
 im=t[6];staff(im,26);rect(im,23,19,4,3,'ink');rect(im,24,19,2,2,'skinLight');px(im,26,20,'skin')
 return t
end
local function back()
 local t=canvas();boots(t[2],false);local im=t[3]
 poly(im,{{12,17},{20,17},{23,20},{22,23},{25,26},{22,28},{19,26},{16,28},{13,26},{10,28},{8,26},{10,22},{10,19}},'cloth','ink')
 poly(im,{{14,22},{18,22},{19,26},{16,28},{14,26}},'blueShade','blueDark');cross(im,16,24)
 px(im,10,26,'goldLight');px(im,22,26,'goldLight')
 im=t[4]
 poly(im,{{11,9},{20,9},{22,13},{21,17},{23,21},{25,24},{23,26},{20,27},{17,25},{14,27},{11,26},{8,26},{7,23},{10,17},{10,13}},'hair','ink')
 poly(im,{{12,13},{14,14},{12,20},{10,24},{9,24},{10,20}},'hairLight')
 poly(im,{{15,13},{17,14},{16,20},{14,25},{12,25},{14,20}},'hairShade')
 poly(im,{{18,13},{20,14},{20,19},{23,24},{21,25},{18,22}},'hairLight');px(im,11,20,'hairShine');px(im,21,22,'hairShine')
 im=t[5]
 poly(im,{{15,1},{17,1},{21,4},{24,7},{23,10},{20,12},{12,12},{9,10},{8,7},{11,4}},'cloth','ink')
 poly(im,{{15,2},{17,2},{21,5},{21,7},{17,8},{12,10},{10,8},{12,5}},'white')
 poly(im,{{20,8},{23,7},{22,10},{19,11},{16,10}},'lilac')
 line(im,10,10,13,12,'blueDark');line(im,13,12,20,12,'blueShade');line(im,20,12,23,10,'blueDark');line(im,12,10,20,10,'goldLight');cross(im,16,4)
 poly(im,{{15,12},{17,12},{18,16},{17,18},{15,16},{14,18},{14,15}},'cloth','blueDark');rect(im,15,12,2,1,'gold');px(im,16,14,'white')
 im=t[6];staff(im,26);rect(im,23,20,4,3,'ink');rect(im,24,20,2,2,'skinLight')
 return t
end
local function mirror(t)
 local r=canvas();for i=1,6 do for y=0,31 do for x=0,31 do r[i]:drawPixel(31-x,y,t[i]:getPixel(x,y)) end end end;return r
end
local ok,err=pcall(function()
 local r=right();local art={front(),r,back(),mirror(r)};local names={'front','right','back','left'}
 local s=Sprite(32,32,ColorMode.RGB);s.layers[1].name=layerNames[1];local layers={s.layers[1]}
 for i=2,6 do layers[i]=s:newLayer();layers[i].name=layerNames[i] end
 for f=2,4 do s:newEmptyFrame(f) end
 for f=1,4 do
  for i=1,6 do s:newCel(layers[i],f,art[f][i],Point(0,0)) end
  local tag=s:newTag(f,f);tag.name=names[f];s.frames[f].duration=0.2
 end
 local palette=Palette(1);palette:setColor(0,Color{r=0,g=0,b=0,a=0});local keys={};for k in pairs(colors) do keys[#keys+1]=k end;table.sort(keys);palette:resize(#keys+1);for i,k in ipairs(keys) do palette:setColor(i,Color(P[k])) end;s:setPalette(palette)
 s.data='Native 32x32 cleric, redrawn for small-pixel readability. Four static facings: front/right/back/left. Left mirrors right. Six editable layers.'
 s:saveAs(out..'cleric-32-four-directions.aseprite')
 local sheet=Image(64,64,ColorMode.RGB)
 for f=1,4 do
  local im=Image(32,32,ColorMode.RGB);im:drawSprite(s,f);im:saveAs(out..'cleric-32-'..names[f]..'.png')
  sheet:drawImage(im,Point(((f-1)%2)*32,math.floor((f-1)/2)*32))
 end
 sheet:saveAs(out..'cleric-32-sheet.png')
 local preview=Image(512,512,ColorMode.RGB);preview:clear(app.pixelColor.rgba(31,34,42,255))
 for y=0,63 do for x=0,63 do local c=sheet:getPixel(x,y);if app.pixelColor.rgbaA(c)>0 then for yy=0,7 do for xx=0,7 do preview:drawPixel(x*8+xx,y*8+yy,c) end end end end end
 preview:saveAs(out..'cleric-32-preview.png')
 local log=io.open(out..'aseprite-build.log','w');log:write('OK: native 32x32; 4 tagged frames; 6 layers; transparent exports.');log:close()
end)
if not ok then local log=io.open(out..'aseprite-build.log','w');log:write(tostring(err));log:close();error(err) end