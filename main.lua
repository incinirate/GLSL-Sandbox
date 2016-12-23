local cShad
local oShad
local fon = love.graphics.newFont("audimrg.ttf", 12)
local width, height = love.window.getMode()

local mainShader

local file = {
  "uniform float time;",
  "uniform vec2 resolution;",
  "",
  "vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 gl_FragCoord) {",
  "  vec2 q = gl_FragCoord / resolution;",
  "  q.y = 1 - q.y; // Unfortunate fix for love having a backwards y coordinate system",
  "  ",
  "  ",
  "  ",
  "  return vec4(q, 0.5 + 0.5*sin(time), 1.0);",
  "}"
}

local normalRGB = {10, 230, 20}
local currRGB = {10, 230, 20}



local line = 8
local linePos = #file[8]
local offset
local offsetY = 3 + 14*(line - 1)
local charWid = fon:getWidth("a")

local lineDrawOff = 0
local maxY = (height*0.4) / 14


local textBarPos = 0
local textBarTxt = ""

local offsetT

local state = 0 -- 0=code 1=save bar 2=load bar
local hideCode = false

local lastSave = 0

local function compileShader()
  local tempShader = love.graphics.newShader(table.concat(file, "\n"))
  if tempShader then
    mainShader = tempShader
    currRGB = {255, 255, 255}
  end
end

local function grabContent(fn)
    return love.filesystem.read(fn)
end

local function initShader(fn)
  local content = grabContent(fn)
  return love.graphics.newShader(content), content
end

local function loadShader(filename)
  if love.filesystem.exists(filename) then
    local shad = grabContent(filename)
    file = {}
    while #shad > 0 do
      local nextP, endP = shad:find("\r?\n")
      if not nextP then
        if #shad > 0 then
          table.insert(file, shad)
        end
        break
      end
      table.insert(file, shad:sub(1, nextP - 1))
      shad = shad:sub(endP + 1)
    end
    line = 1
    linePos = 0
    lineDrawOff = 0

    lastSave = filename
  end
end

local function saveShader(filename)
  love.filesystem.write(filename, table.concat(file, "\n"))
  lastSave = filename

  currRGB = {255, 255, 255}
end

function love.load()
  love.keyboard.setKeyRepeat(true)
  love.window.setTitle("GLSL Shadertoy")
  love.window.setIcon(love.image.newImageData("icon.png"))

  cShad = initShader("cursorShader_f.glsl")
  cShad:send("resolution", {24, 24})
  oShad = initShader("coverShader_f.glsl")
  oShad:send("resolution", {width, height})

  love.graphics.setFont(fon)

  xpcall(compileShader, function() print("rip") end)
end

local timer = 0
function love.update(dt)
  timer = timer + dt
  cShad:send("time", timer)
end

local function drawShader()
  love.graphics.setColor(255, 255, 255, 255)
  if mainShader:getExternVariable("time") then
    mainShader:send("time", timer)
  end
  if mainShader:getExternVariable("resolution") then
    mainShader:send("resolution", {width, height})
  end
  love.graphics.setShader(mainShader)
  love.graphics.rectangle("fill", 0, 0, width, height)
  love.graphics.setShader()
end

local function curs()
  love.graphics.clear(0, 0, 0, 255)
  love.graphics.setShader(cShad)
  love.graphics.rectangle("fill", 0, 0, 24, 24)
  love.graphics.setShader()
end

function love.draw()
  drawShader()

  if hideCode then
    return
  end

  love.graphics.setShader(oShad)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.rectangle("fill", 0, 0, width, height)
  love.graphics.setShader()

  if not offset then
    offset = fon:getWidth(file[7])
  end
  -- cCanv:renderTo(curs)
  -- curs()
  -- love.graphics.setBlendMode("alpha", "alphamultiply")
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  love.graphics.setColor(255, 255, 255, 255)
  local offsetgoal = charWid*linePos
  local offsetgoalY = 3 + 14*((line - lineDrawOff) - 1)
  offset = (offsetgoal - offset)*0.3 + offset
  offsetY = (offsetgoalY - offsetY)*0.3 + offsetY

  if state == 0 then
    love.graphics.setShader(cShad)
    cShad:send("offset", {offset, offsetY + height*0.3})
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setShader()
  end

  currRGB[1] = (normalRGB[1] - currRGB[1])*0.05 + currRGB[1]
  currRGB[2] = (normalRGB[2] - currRGB[2])*0.05 + currRGB[2]
  currRGB[3] = (normalRGB[3] - currRGB[3])*0.05 + currRGB[3]

  love.graphics.setShader(oShad)

  love.graphics.setColor(currRGB)
  for i=1, #file do
    love.graphics.print(file[i], 8, height*0.3 + 8 + 14*((i - lineDrawOff)-1), 0, 1, 1)
  end

  love.graphics.setShader()

  if state > 0 then
    love.graphics.setColor(0, 0, 0, 100)
    love.graphics.rectangle("fill", 0, height - 24, width, 24)
    love.graphics.setColor(255, 255, 255, 255)
    local ttd
    if state == 1 then
      ttd = "File to save to:  "
    else
      ttd = "File to load from:  "
    end

    love.graphics.print(ttd .. textBarTxt, 8, height - 18)

    if not offsetT then offsetT = fon:getWidth(ttd) end

    local offsetTgoal = charWid*textBarPos + fon:getWidth(ttd)
    offsetT = (offsetTgoal - offsetT)*0.3 + offsetT

    love.graphics.setShader(cShad)
    cShad:send("offset", {offsetT, height - 22})
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setShader()
  end
end

local alt = false
local ctrl = false
local shift = false

function love.keyreleased(key)
  if key == "lalt" then
    alt = false
  elseif key == "lctrl" then
    ctrl = false
  elseif key == "lshift" then
    shift = false
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "lalt" then
    alt = true
  elseif key == "lctrl" then
    ctrl = true
  elseif key == "lshift" then
    shift = true
  elseif key == "return" and alt then
    xpcall(compileShader, function() currRGB = {230, 20, 10} end)
    return
  elseif key == "s" and ctrl then
    if lastSave == 0 or shift then
      state = 1
      textBarTxt = ""
      textBarPos = 0
    elseif lastSave ~= 0 then
      saveShader(lastSave)
    end
    return
  elseif key == "o" and ctrl then
    state = 2
    textBarTxt = ""
    textBarPos = 0
    return
  elseif key == "escape" then
    state = 0
  elseif key == "e" and ctrl then
    hideCode = not hideCode
  end

  if state == 0 then
    if key == "left" then
      linePos = linePos - 1
      if linePos < 0 then
        if line > 1 then
          line = line - 1
          linePos = #file[line]
        else
          linePos = 0
        end
      end
    elseif key == "right" then
      linePos = linePos + 1
      if linePos > #file[line] then
        if line < #file then
          line = line + 1
          linePos = 0
        else
          linePos = #file[line]
        end
      end
    elseif key == "backspace" and linePos > 0 then
      file[line] = file[line]:sub(1, linePos - 1) .. file[line]:sub(linePos + 1)
      linePos = linePos - 1

      if (line - lineDrawOff) < 1 then
        lineDrawOff = lineDrawOff - 1
      end
    elseif key == "backspace" and linePos == 0 and line > 1 then
      local len = #file[line - 1]
      file[line - 1] = file[line - 1] .. file[line]
      table.remove(file, line)
      line = line - 1
      linePos = len

      if (line - lineDrawOff) < 1 then
        lineDrawOff = lineDrawOff - 1
      end
    elseif key == "delete" and linePos < #file[line] then
      file[line] = file[line]:sub(1, linePos) .. file[line]:sub(linePos + 2)
    elseif key == "delete" and linePos == #file[line] then
      local data = file[line + 1]
      file[line] = file[line] .. data
      table.remove(file, line + 1)
    elseif key == "down" then
      if line < #file then
        line = line + 1
        if linePos > #file[line] then
          linePos = #file[line]
        end

        if (line - lineDrawOff) > maxY then
          lineDrawOff = lineDrawOff + 1
        end
      end
    elseif key == "up" then
      if line > 1 then
        line = line - 1
        if linePos > #file[line] then
          linePos = #file[line]
        end

        if (line - lineDrawOff) < 1 then
          lineDrawOff = lineDrawOff - 1
        end
      end
    elseif key == "return" then
      local endOfLine = file[line]:sub(linePos + 1)
      local begOfLine = file[line]:sub(1, linePos)
      file[line] = begOfLine
      table.insert(file, line + 1, endOfLine)
      line = line + 1
      linePos = 0

      if (line - lineDrawOff) > maxY then
        lineDrawOff = lineDrawOff + 1
      end
    end
  else
    if key == "left" and textBarPos > 0 then
      textBarPos = textBarPos - 1
    elseif key == "right" and textBarPos < #textBarTxt then
      textBarPos = textBarPos + 1
    elseif key == "backspace" and textBarPos > 0 then
      textBarTxt = textBarTxt:sub(1, textBarPos - 1) .. textBarTxt:sub(textBarPos + 1)
      textBarPos = textBarPos - 1
    elseif key == "delete" and textBarPos < #textBarTxt then
      textBarTxt = textBarTxt:sub(1, textBarPos) .. textBarTxt:sub(textBarPos + 2)
    elseif key == "return" then
      if state == 1 then
        saveShader(textBarTxt)
      else
        loadShader(textBarTxt)
      end
      state = 0
    end
  end
end

function love.textinput(text)
  if state == 0 then
    file[line] = file[line]:sub(1, linePos) .. text .. file[line]:sub(linePos + 1)
    linePos = linePos + 1
  else
    textBarTxt = textBarTxt:sub(1, textBarPos) .. text .. textBarTxt:sub(textBarPos + 1)
    textBarPos = textBarPos + 1
  end
end
