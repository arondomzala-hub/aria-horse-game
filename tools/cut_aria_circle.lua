local spr = app.activeSprite
assert(spr, "no sprite")
-- Ensure alpha capable color mode
if spr.colorMode ~= ColorMode.RGB then
  app.command.ChangePixelFormat{ format="rgb" }
end
app.transaction("cut circle", function()
  local cel = app.activeCel
  local img = cel.image
  local w, h = img.width, img.height
  local cx = (w - 1) * 0.5
  local cy = (h - 1) * 0.5
  local radius = math.min(w, h) * 0.5 - 4
  local r2 = radius * radius
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local dx = x - cx
      local dy = y - cy
      if (dx * dx + dy * dy) > r2 then
        img:drawPixel(x, y, Color{ r=0, g=0, b=0, a=0 })
      end
    end
  end
end)
spr:saveAs("C:/Users/Aron Domżała/Aria Horse Game/assets/aria_portrait.png")