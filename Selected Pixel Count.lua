----------------------------------------------------------------------
-- Count the number of pixels inside an arbitrary selection
----------------------------------------------------------------------

local spr = app.activeSprite
if not spr then return end

local sel = spr.selection
local im = Image(spr)
local count = 0

if not sel.isEmpty then
  local rect = sel.bounds

  for x = rect.x, rect.x + rect.width do
    for y = rect.y, rect.y + rect.height do
      if sel:contains(x, y) then
        count = count + 1
     end
    end
  end
end

local total = 0

for it in im:pixels() do
  local pixelValue = it()
  if app.pixelColor.rgbaA(pixelValue) > 128 then
    total = total + 1
  end
end 

print(string.format('%s%d', "Selected pixels: ", count))
print(string.format('%s%d', "Opaque pixels: ", total))
if total > 0 then
  print(string.format('%s%0.2f%%',"As percentage: ", (count/total)*100))
end
