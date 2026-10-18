-- Draw the selected blonde/blue-mantle heroine directly with Aseprite pixels.
-- Four 32x32 slices, one static frame. Run with Aseprite --batch --script.
local output = "D:/Simon/Dev/ARPGgame/GodotStarter/Art/Characters/Hero/"
app.fs.makeAllDirectories(output)

local hex = {
  O="252635", m="987044", h="d1a45d", H="f5d689",
  s="e8b38d", S="ffdab0", E="2b3857",
  B="20395f", b="35649e", C="6a9ccf",
  v="aaa599", i="ddd5b6", I="fff0d0",
  g="aa7637", G="edc56b", t="654636", T="a0714c"
}
local colors = {}
for key, value in pairs(hex) do
  colors[key] = app.pixelColor.rgba(
    tonumber(value:sub(1,2),16), tonumber(value:sub(3,4),16),
    tonumber(value:sub(5,6),16), 255)
end

-- Each row is {y, x, pixels}; dots remain transparent.
local down = {
  {2,12,"OOOOOO"},
  {3,10,"OOmhhhhOOO"},
  {4,9,"OmhhHHHHhhmO"},
  {5,9,"OmhHHHHHHhhmO"},
  {6,8,"OmhhHHHHhhhhhO"},
  {7,8,"OmhHHHhhsssShO"},
  {8,8,"OmhHHhhSssssShO"},
  {9,8,"OmHhSssEssEsshO"},
  {10,8,"OhHhSsssSsssShO"},
  {11,8,"OhhSssssssssmHO"},
  {12,8,"OhhOssSSssOmhO"},
  {13,7,"OhhmOOssssOmhOO"},
  {14,6,"OmmhOBbGibbBmhCO"},
  {15,6,"OhmhOCbGiibbbhCO"},
  {16,5,"OmhhOCbGiiibbbhCO"},
  {17,5,"OmhhOCbGiiibbChCO"},
  {18,5,"OmhhOBbgiIvbbChCO"},
  {19,6,"OmhOBbiIiIvbbCO"},
  {20,7,"OhOssOiIiIvOOssO"},
  {21,7,"OsssOiIiIIiOsssgO"},
  {22,8,"OOOiIiIIiiivOOgO"},
  {23,10,"OviIiIIiivO..bO"},
  {24,10,"OviIiIIiivO..CO"},
  {25,10,"OviIiIIiivO...O"},
  {26,10,"OvviiIiivvO"},
  {27,10,"OOtvOOvvTtO"},
  {28,10,"OtTTO..OTTO"},
  {29,10,"OTtTO..OTtO"},
  {30,9,"OOOOO..OOOOO"}
}
local up = {
  {2,12,"OOOOOO"},
  {3,10,"OOmhhhhOOO"},
  {4,9,"OmhhHHHHhhmO"},
  {5,9,"OmhHHHHHHhhmO"},
  {6,8,"OmhhHHHHhhhhhO"},
  {7,8,"OmhHHHhhhHhhhO"},
  {8,8,"OmHHhhHHhhhhhO"},
  {9,8,"OhHhhhHHhhhhhmO"},
  {10,8,"OhHhhhHHhhhmhO"},
  {11,8,"OhhhhhHhhhmhOO"},
  {12,8,"OmhhhhhhhmmhO"},
  {13,7,"OmhmmmmmOOmhOO"},
  {14,6,"OmhOOOBbBCBhhCO"},
  {15,6,"OhhOCBCbbbbBhCO"},
  {16,5,"OmhhOCBCbbbbbBhCO"},
  {17,5,"OmhhOCBCbbbbbChCO"},
  {18,5,"OmhhOBBCbbbbbChCO"},
  {19,6,"OmhOBBBCbbbbCCO"},
  {20,7,"OhOssOBBCbCCOssO"},
  {21,7,"OsssOOBBCBCOsssO"},
  {22,8,"OOOviOBBBBOviOOO"},
  {23,10,"OviIiIIiivO"},
  {24,10,"OviIiIIiivO"},
  {25,10,"OviIiIIiivO"},
  {26,10,"OvviiIiivvO"},
  {27,10,"OOtvOOvvTtO"},
  {28,10,"OtTTO..OTTO"},
  {29,10,"OTtTO..OTtO"},
  {30,9,"OOOOO..OOOOO"}
}
local left = {
  {2,12,"OOOOO"},
  {3,10,"OOmhhhOO"},
  {4,9,"OmhhHHHhmO"},
  {5,8,"OhhHHHHHHmO"},
  {6,8,"OhHhhhHHhhmO"},
  {7,7,"OssshhHHhhhmO"},
  {8,6,"OSsssOhhhHhhO"},
  {9,6,"OsEssSOhhhhhO"},
  {10,6,"OsssssOmhhhhO"},
  {11,7,"OsssOmmhhhhmO"},
  {12,8,"OssOmmhhhhhO"},
  {13,8,"OOssOmmhhhhOO"},
  {14,7,"OBBGiOmmhhhCCO"},
  {15,7,"OCbGiimhhhhhCCO"},
  {16,7,"OCbGiimhOCCCCBO"},
  {17,7,"OBbGiiimhOBCCCO"},
  {18,8,"OBbgiIvOmhOCCO"},
  {19,8,"OBbiIiIvOmhCCO"},
  {20,7,"OsOiIiIvOmmCO"},
  {21,7,"OssOiIiIvOBBO"},
  {22,8,"OOviIiIivOOO"},
  {23,9,"OviIiIIivO"},
  {24,9,"OviIiIIivO"},
  {25,9,"OviIiIIivO"},
  {26,9,"OvviiIivvO"},
  {27,9,"OtTtOvTTtO"},
  {28,9,"OtTTO.OTTO"},
  {29,9,"OTtTO.OTtO"},
  {30,8,"OOOOO.OOOO"}
}

local function draw(rows, mirror)
  local image = Image(32,32,ColorMode.RGB)
  for _, row in ipairs(rows) do
    for column=1,#row[3] do
      local key = row[3]:sub(column,column)
      -- Plain face: replace eyes and face highlights with the base skin tone.
      if row[1] >= 7 and row[1] <= 12 and (key == "E" or key == "S") then
        key = "s"
      end
      if colors[key] then
        local x = row[2]+column-1
        if mirror then x=31-x end
        image:drawPixel(x,row[1],colors[key])
      end
    end
  end
  return image
end

local images = {draw(down,false), draw(up,false), draw(left,false), draw(left,true)}
-- The right view shows her small blue charm; the opposite hand is empty.
local right = images[4]
for _, p in ipairs({{25,21,"g"},{25,22,"g"},{25,23,"B"},
                    {24,24,"b"},{25,24,"C"},{26,24,"B"},{25,25,"B"}}) do
  right:drawPixel(p[1],p[2],colors[p[3]])
end

local sprite = Sprite(128,32,ColorMode.RGB)
sprite:deleteLayer(sprite.layers[1])
sprite.gridBounds = Rectangle(0,0,32,32)
sprite.data = "Concept 8: blonde heroine, blue mantle and ivory robe; plain faces with facial details removed. Single static frame. Cells: down, up, left, right."
local names = {"down","up","left","right"}
for i,name in ipairs(names) do
  local layer=sprite:newLayer()
  layer.name=name
  sprite:newCel(layer,1,images[i],Point((i-1)*32,0))
  local slice=sprite:newSlice(Rectangle((i-1)*32,0,32,32))
  slice.name=name
  slice.pivot=Point(16,29)
  images[i]:saveAs(output.."hero-"..name..".png")
end
local palette=Palette(18)
palette:setColor(0,Color{r=0,g=0,b=0,a=0})
local order={"O","m","h","H","s","S","E","B","b","C","v","i","I","g","G","t","T"}
for i,key in ipairs(order) do
  local value=hex[key]
  palette:setColor(i,Color{
    r=tonumber(value:sub(1,2),16),g=tonumber(value:sub(3,4),16),
    b=tonumber(value:sub(5,6),16),a=255})
end
sprite:setPalette(palette)
sprite:saveAs(output.."hero-facing-views.aseprite")
sprite:saveCopyAs(output.."hero-facing-views.png")
print("Saved four static 32x32 views to "..output)
