local spr = app.activeSprite
if not spr then return app.alert "There is no active sprite" end

if not(spr.spec.colorMode == ColorMode.RGB) then return app.alert "Sprite needs to be in RGB color mode" end

local renderCount = 0
local warningDialogViewed = false
local maxSpriteDimension = math.max(spr.spec.width, spr.spec.height)
local oldSelection = Selection()
oldSelection:add(spr.selection)

local function sqr(x)
    return x * x
end

local function dist2(x1, y1, x2, y2)
    return sqr(x1-x2) + sqr(y1-y2)
end

local function distanceToLineSquared(xA,yA,xB,yB,xP,yP)
    local l2 = dist2(xA,yA,xB,yB)
    if (l2 == 0) then
        return dist2(xA,yA, xP,yP)
    end
    local t = ((xP - xA) * (xB - xA) + (yP - yA) * (yB - yA)) / l2
    t = math.max(0, math.min(1, t))
    return dist2(xP, yP, xA + t * (xB - xA), yA + t * (yB - yA))
end

local function overlayRectangleCorners(centerX, centerY, width, height, angle)
    local sel = Selection()

    local radians = math.rad(angle)
    local cosR = math.cos(radians)
    local sinR = math.sin(radians)
    local halfWidth = width * 0.5
    local halfHeight = height * 0.5

    local corner1X = centerX + (halfWidth * cosR - halfHeight * sinR)
    local corner1Y = centerY + (halfWidth * sinR + halfHeight * cosR)

    local corner2X = centerX + (halfWidth * cosR + halfHeight * sinR)
    local corner2Y = centerY + (halfWidth * sinR - halfHeight * cosR)

    local corner3X = centerX - (halfWidth * cosR - halfHeight * sinR)
    local corner3Y = centerY - (halfWidth * sinR + halfHeight * cosR)

    local corner4X = centerX - (halfWidth * cosR + halfHeight * sinR)
    local corner4Y = centerY - (halfWidth * sinR - halfHeight * cosR)

    local boxSize = 1 + math.floor(maxSpriteDimension/100)

    sel:add(Rectangle(corner1X-boxSize, corner1Y-boxSize, boxSize*2, boxSize*2))
    sel:add(Rectangle(corner2X-boxSize, corner2Y-boxSize, boxSize*2, boxSize*2))
    sel:add(Rectangle(corner3X-boxSize, corner3Y-boxSize, boxSize*2, boxSize*2))
    sel:add(Rectangle(corner4X-boxSize, corner4Y-boxSize, boxSize*2, boxSize*2))
    sel:add(Rectangle(centerX-boxSize, centerY-boxSize, boxSize*2, boxSize*2))

    spr.selection = sel
end

local function overlayAngle(angle, spread)
    local sel = Selection()

    local radians = math.rad(angle)
    local cosR = math.cos(radians)
    local sinR = math.sin(radians)

    local centerX = math.floor(spr.spec.width / 2)
    local centerY = math.floor(spr.spec.height / 2)

    local smallBoxSize = 1 + math.floor(maxSpriteDimension/50)
    local smallBoxOffset = math.floor(smallBoxSize/2)
    local largeBoxSize = smallBoxSize * 2
    local largeBoxOffset = math.floor(largeBoxSize/2)

    local segmentSize = maxSpriteDimension * 0.25

    sel:add(Rectangle(centerX-smallBoxOffset, centerY-smallBoxOffset, smallBoxSize, smallBoxSize))

    local x = centerX + segmentSize * sinR
    local y = centerY - segmentSize * cosR
    sel:add(Rectangle(x-smallBoxOffset, y-smallBoxOffset, smallBoxSize, smallBoxSize))

    x = centerX + 2 * segmentSize * sinR
    y = centerY - 2 * segmentSize * cosR
    sel:add(Rectangle(x-largeBoxOffset, y-largeBoxOffset, largeBoxSize, largeBoxSize))

    if spread > 0 then
        radians = math.rad(angle + spread * 0.5)
        cosR = math.cos(radians)
        sinR = math.sin(radians)
        x = centerX + 2 * segmentSize * sinR
        y = centerY - 2 * segmentSize * cosR
        sel:add(Rectangle(x-smallBoxOffset, y-smallBoxOffset, smallBoxSize, smallBoxSize))

        radians = math.rad(angle - spread * 0.5)
        cosR = math.cos(radians)
        sinR = math.sin(radians)
        x = centerX + 2 * segmentSize * sinR
        y = centerY - 2 * segmentSize * cosR
        sel:add(Rectangle(x-smallBoxOffset, y-smallBoxOffset, smallBoxSize, smallBoxSize))
    end

    spr.selection = sel
end

local function overlayMagnitude(magnitude, variance)
    local selMagnitude = Selection()
    local stepX = math.max(1, spr.width*0.2)

    selMagnitude:add(stepX*2-2, 0, stepX+4, magnitude)

    if variance > 0 then
        local varianceFloat = variance / 100
        local varianceOffset = math.floor(magnitude * varianceFloat)

        local selVarianceA = Selection(Rectangle(stepX*2, magnitude, stepX, varianceOffset))
        local selVarianceB = Selection(Rectangle(stepX*2, magnitude-varianceOffset, stepX, varianceOffset))

        selMagnitude:add(selVarianceA)
        selMagnitude:subtract(selVarianceB)
    end

    spr.selection = selMagnitude
end

local function overlay(userSettings, id)
    if not userSettings.useOverlays then return end

    if id == 'emitter' then
        overlayRectangleCorners(userSettings.emitterX,
                                userSettings.emitterY,
                                userSettings.emitterLength + userSettings.emitterRadius * 2,
                                userSettings.emitterRadius * 2,
                                userSettings.emitterAngle)
    elseif id == 'gravityAngle' then
        overlayAngle(userSettings.gravityAngle,
                     0)
    elseif id == 'gravityMagnitude' then
        overlayMagnitude(userSettings.gravityMagnitude,
                         0)
    elseif id == 'startVectorAngle' then
        overlayAngle(userSettings.startVectorAngle,
                     userSettings.startVectorAngleVariance)
    elseif id == 'startVectorMagnitude' then
        overlayMagnitude(userSettings.startVectorMagnitude,
                         userSettings.startVectorMagnitudeVariance)
    end

    app.refresh()
end

local function calcEmitterPixel(centerX, centerY, length, angle, radius)
    local radians = math.rad(angle)
    local cosR = math.cos(radians)
    local sinR = math.sin(radians)
    local halfLength = length * 0.5
    local xA = centerX - halfLength * cosR
    local yA = centerY - halfLength * sinR
    local xB = centerX + halfLength * cosR
    local yB = centerY + halfLength * sinR
    local minX = math.min(xA,xB) - radius
    local maxX = math.max(xA,xB) + radius
    local minY = math.min(yA,yB) - radius
    local maxY = math.max(yA,yB) + radius
    local radiusSquared = sqr(radius)

    local emissionPixels = {{x=centerX, y=centerY}}
    for iy = minY, maxY do
        for ix = minX, maxX do
            if distanceToLineSquared(xA,yA,xB,yB,ix,iy) < radiusSquared then
                table.insert(emissionPixels, {x=ix,y=iy})
            end
        end
    end

    return emissionPixels 
end

local function renderEmitterPixels(emissionPixels)
    local layer = spr:newLayer()
    layer.name = "Emitter"
    layer.opacity = 255

    local img = Image(spr.spec)

    for _,pixel in ipairs(emissionPixels) do
        img:drawPixel(pixel.x, pixel.y, Color{ r=0, g=0, b=0, a=255 })
    end

    spr:newCel(layer, 1, img, Point(0, 0))
    app.refresh()
end

local function pixelOver(x, y, col, sAlpha, img)
    local bgndCol = img:getPixel(x, y)

    local bgndA = app.pixelColor.rgbaA(bgndCol)
    if bgndA == 0 then
        a = col.alpha * sAlpha
        img:drawPixel(x, y, Color{ r=col.red, g=col.green, b=col.blue, a=col.alpha*sAlpha })
        return
    end

    local fgndR = col.red
    local fgndG = col.green
    local fgndB = col.blue
    local fgndA = col.alpha * sAlpha

    local bgndR = app.pixelColor.rgbaR(bgndCol)
    local bgndG = app.pixelColor.rgbaG(bgndCol)
    local bgndB = app.pixelColor.rgbaB(bgndCol)

    local floatFgndA = fgndA / 255
    local floatBgndA = bgndA / 255

    local a0 = (floatFgndA + (floatBgndA * (1 - floatFgndA)))
    local fgndScale = floatFgndA / a0
    local bgndScale = (floatBgndA * (1 - floatFgndA)) / a0

    local outR = (fgndR * fgndScale) + (bgndR * bgndScale)
    local outG = (fgndG * fgndScale) + (bgndG * bgndScale)
    local outB = (fgndB * fgndScale) + (bgndB * bgndScale)
    local outA = 255 * a0

    img:drawPixel(x, y, Color{ r=outR, g=outG, b=outB, a=outA })
end

local function plotLineLow(x0, y0, x1, y1, img, col, reversed)
    local dx = x1 - x0
    local dy = y1 - y0
    local yi = 1
    if dy < 0 then
        yi = -1
        dy = -dy
    end
    local D = (2 * dy) - dx
    local y = y0

    local dAlpha = math.abs(1/dx)
    local sAlpha = 0
    if not reversed then
        sAlpha = 1
        dAlpha = - dAlpha
    end

    for x = x0, x1 do
        pixelOver(x, y, col, sAlpha, img)
        sAlpha = sAlpha + dAlpha
        if D > 0 then
            y = y + yi
            D = D + (2 * (dy - dx))
        else
            D = D + 2*dy
        end
    end
end

local function plotLineHigh(x0, y0, x1, y1, img, col, reversed)
    local dx = x1 - x0
    local dy = y1 - y0
    local xi = 1
    if dx < 0 then
        xi = -1
        dx = -dx
    end
    local D = (2 * dx) - dy
    local x = x0

    local dAlpha = math.abs(1/dy)
    local sAlpha = 0
    if not reversed then
        sAlpha = 1
        dAlpha = - dAlpha
    end

    for y = y0, y1 do
        pixelOver(x, y, col, sAlpha, img)
        sAlpha = sAlpha + dAlpha
        if D > 0 then
            x = x + xi
            D = D + (2 * (dx - dy))
        else
            D = D + 2*dx
        end
    end
end

local function plotLine(x0, y0, x1, y1, img, col)
    if (x0 < 0) and (x1 < 0) then return end
    if (y0 < 0) and (y1 < 0) then return end
    if (x0 > img.width) and (x1 > img.width) then return end
    if (y0 > img.height) and (y1 > img.height) then return end

    if math.abs(y1 - y0) < math.abs(x1 - x0) then
        if x0 > x1 then
            plotLineLow(x1, y1, x0, y0, img, col, true)
        else
            plotLineLow(x0, y0, x1, y1, img, col, false)
        end
    else
        if y0 > y1 then
            plotLineHigh(x1, y1, x0, y0, img, col, true)
        else
            plotLineHigh(x0, y0, x1, y1, img, col, false)
        end
    end
end

local function renderParticles(userSettings)
    app.transaction(
        function()
            renderCount = renderCount + 1
            local layer = spr:newLayer()
            layer.name = "Particles "..renderCount
            layer.opacity = 255

            math.randomseed(userSettings.seed)

            emissionPixels = calcEmitterPixel(userSettings.emitterX,
                                            userSettings.emitterY,
                                            userSettings.emitterLength,
                                            userSettings.emitterAngle,
                                            userSettings.emitterRadius)

            local particles = {}

            local startAngle = {min = math.rad(userSettings.startVectorAngle - userSettings.startVectorAngleVariance / 2),
                                range = math.rad(userSettings.startVectorAngleVariance)}

            local startVectorMagnitude = (maxSpriteDimension / 10) * (userSettings.startVectorMagnitude / 100)
            local startMagnitude = {min = startVectorMagnitude * (1.0 - userSettings.startVectorMagnitudeVariance / 100),
                                    range = startVectorMagnitude * (userSettings.startVectorMagnitudeVariance / 50)}

            local gravityRadians = math.rad(userSettings.gravityAngle)
            local gravityMagnitude = (maxSpriteDimension / 10) * (userSettings.gravityMagnitude / 100)
            local gravityVector = {x = gravityMagnitude * math.sin(gravityRadians),
                                y = - (gravityMagnitude * math.cos(gravityRadians))}

            local floatDrag = 1.0 - userSettings.drag / 100

            local startH = userSettings.startColor.hue
            local diffH = userSettings.endColor.hue - userSettings.startColor.hue
            if math.abs(diffH) > 180 then
                if diffH > 0 then
                    diffH = diffH - 360
                else
                    diffH = diffH + 360
                end
            end

            local startS = userSettings.startColor.saturation
            local diffS = userSettings.endColor.saturation - userSettings.startColor.saturation

            local startV = userSettings.startColor.value
            local diffV = userSettings.endColor.value - userSettings.startColor.value

            local startA = userSettings.startColor.alpha
            local diffA = userSettings.endColor.alpha - userSettings.startColor.alpha

            for frmNumber = 1, userSettings.simDuration do
                local img = Image(spr.spec)

                for i = 1, userSettings.particlesPerFrame do
                    local startPosition = math.random(#emissionPixels)
                    local angle = startAngle.min + startAngle.range * math.random()
                    local magnitude = startMagnitude.min + startMagnitude.range * math.random()
                    local cosR = math.cos(angle)
                    local sinR = math.sin(angle)
                    local startPositionCopy = {}
                    startPositionCopy['x'] = emissionPixels[startPosition].x
                    startPositionCopy['y'] = emissionPixels[startPosition].y
                    local subFrame
                    table.insert(particles, {age = 0,
                                            subFrameTiming = math.random(),
                                            currentPosition = startPositionCopy,
                                            vector = {x = magnitude * sinR, y = - (magnitude * cosR) }} )
                end


                for _,p in ipairs(particles) do
                    p.age = p.age + 1
                    if p.age > userSettings.simDuration then
                        p = nil
                    else
                        local previousPosition = {}
                        previousPosition['x'] = p.currentPosition.x
                        previousPosition['y'] = p.currentPosition.y
                        p.vector.x = (p.vector.x + gravityVector.x) * floatDrag
                        p.vector.y = (p.vector.y + gravityVector.y) * floatDrag
                        p.currentPosition.x = p.currentPosition.x + p.vector.x
                        p.currentPosition.y = p.currentPosition.y + p.vector.y

                        local subFrameX = previousPosition.x + (p.currentPosition.x - previousPosition.x) * p.subFrameTiming
                        local subFrameY = previousPosition.y + (p.currentPosition.y - previousPosition.y) * p.subFrameTiming

                        local y0 = math.floor(subFrameY)
                        local y1 = math.floor(subFrameY - p.vector.y)

                        local x0 = math.floor(subFrameX)
                        local x1 = math.floor(subFrameX - p.vector.x)

                        local ageFloat = math.min(p.age+p.subFrameTiming, userSettings.simDuration) / userSettings.simDuration

                        local h = startH + math.floor(diffH * ageFloat)
                        if h > 360 then
                            h = h - 361
                        elseif h < 0 then
                            h =  361 + h
                        end
                        local s = startS + diffS * ageFloat
                        local v = startV + diffV * ageFloat
                        local a = startA + diffA * ageFloat

                        if frmNumber > 0 then
                            plotLine(x0, y0, x1, y1, img, Color{hue=h, saturation=s, value=v, alpha=a})
                        end
                    end
                end
                
                if frmNumber > #spr.frames then
                    spr:newEmptyFrame(frmNumber)
                end
                spr:newCel(layer, frmNumber, img, Point(0, 0))
            end

            for frmNumber = 1, userSettings.simDuration do
                local img = Image(spr.spec)
                local layerCel = layer:cel(spr.frames[frmNumber])

                if layerCel then
                    img:drawImage(layerCel.image, layerCel.position)

                    for _,p in ipairs(particles) do
                        p.age = p.age + 1
                        if p.age > userSettings.simDuration then
                            p = nil
                        else
                            local previousPosition = {}
                            previousPosition['x'] = p.currentPosition.x
                            previousPosition['y'] = p.currentPosition.y
                            p.vector.x = (p.vector.x + gravityVector.x) * floatDrag
                            p.vector.y = (p.vector.y + gravityVector.y) * floatDrag
                            p.currentPosition.x = p.currentPosition.x + p.vector.x
                            p.currentPosition.y = p.currentPosition.y + p.vector.y

                            local subFrameX = previousPosition.x + (p.currentPosition.x - previousPosition.x) * p.subFrameTiming
                            local subFrameY = previousPosition.y + (p.currentPosition.y - previousPosition.y) * p.subFrameTiming

                            local y0 = math.floor(subFrameY)
                            local y1 = math.floor(subFrameY - p.vector.y)

                            local x0 = math.floor(subFrameX)
                            local x1 = math.floor(subFrameX - p.vector.x)

                            local ageFloat = math.min(p.age+p.subFrameTiming, userSettings.simDuration) / userSettings.simDuration

                            local h = startH + math.floor(diffH * ageFloat)
                            if h > 360 then
                                h = h - 361
                            elseif h < 0 then
                                h =  361 + h
                            end
                            local s = startS + diffS * ageFloat
                            local v = startV + diffV * ageFloat
                            local a = startA + diffA * ageFloat

                            if frmNumber > 0 then
                                plotLine(x0, y0, x1, y1, img, Color{hue=h, saturation=s, value=v, alpha=a})
                            end
                        end
                    end
                end
                spr:newCel(layer, frmNumber, img, Point(0, 0))
            end

            app.refresh()
        end
    )
end

local function showWarningDialog()
    if warningDialogViewed then return end

    app.alert{ title = "Warning Experimental Feature",
               text = {"Warning this is and experimental feature.",
                       "While active multiple events will be added to Undo History."},
               buttons="OK" }

    warningDialogViewed = true
end

local function onExit(dlg)
    spr.selection = oldSelection
    app.refresh()

    dlg:close()
end

local function updateDialog(dlg, id)
    if id == "seed" then
        if dlg.data.seed < 1 then
            dlg:modify{ id="seed", text="1" }
        elseif dlg.data.seed > 999999 then
            dlg:modify{ id="seed", text="999999" }
        end
    end
end

local dlg = Dialog("Particle Simulator")

dlg:slider{
    id="simDuration",
    label="Simulation Duration",
    min=1,
    max=200,
    value=25,
    onchange=function() updateDialog(dlg, "simDuration") end
}

dlg:slider{
    id="particlesPerFrame",
    label="Particles Per Frame",
    min=1,
    max=500,
    value=20
}

dlg:color{
    id="startColor",
    label="Particle Start Color",
    color=Color{ r=255, g=255, b=0, a=255 }
}
dlg:color{
    id="endColor",
    label="Particle End Color",
    color=Color{ r=255, g=0, b=0, a=255 }
}

dlg:slider{
    id="emitterX",
    label="Emitter Center X",
    min=-spr.width,
    max=spr.width*2,
    value=math.ceil(spr.width*0.5),
    onchange=function() overlay(dlg.data, 'emitter') end
}

dlg:slider{
    id="emitterY",
    label="Emitter Center Y",
    min=-spr.height,
    max=spr.height*2,
    value=math.ceil(spr.height*0.1),
    onchange=function() overlay(dlg.data, 'emitter') end
}

dlg:slider{
    id="emitterLength",
    label="Emitter Length",
    min=1,
    max=maxSpriteDimension*2,
    value=maxSpriteDimension,
    onchange=function() overlay(dlg.data, 'emitter') end
}

dlg:slider{
    id="emitterAngle",
    label="Emitter Angle",
    min=-90,
    max=90,
    value=0,
    onchange=function() overlay(dlg.data, 'emitter') end
}

dlg:slider{
    id="emitterRadius",
    label="Emitter Radius",
    min=1,
    max=math.ceil(maxSpriteDimension*0.5),
    value=5,
    onchange=function() overlay(dlg.data, 'emitter') end
}

dlg:slider{
    id="gravityAngle",
    label="Gravity Angle",
    min=0,
    max=360,
    value=180,
    onchange=function() overlay(dlg.data, 'gravityAngle') end
}

dlg:slider{
    id="gravityMagnitude",
    label="Gravity Magnitude",
    min=0,
    max=100,
    value=10,
    onchange=function() overlay(dlg.data, 'gravityMagnitude') end
}

dlg:slider{
    id="startVectorAngle",
    label="Start Vector Angle",
    min=0,
    max=360,
    value=180,
    onchange=function() overlay(dlg.data, 'startVectorAngle') end
}

dlg:slider{
    id="startVectorAngleVariance",
    label="Start Vector Angle Variance",
    min=0,
    max=360,
    value=5,
    onchange=function() overlay(dlg.data, 'startVectorAngle') end
}

dlg:slider{
    id="startVectorMagnitude",
    label="Start Vector Magnitude",
    min=0,
    max=100,
    value=10,
    onchange=function() overlay(dlg.data, 'startVectorMagnitude') end
}

dlg:slider{
    id="startVectorMagnitudeVariance",
    label="Start Vector Magnitude Variance",
    min=0,
    max=100,
    value=10,
    onchange=function() overlay(dlg.data, 'startVectorMagnitude') end
}

dlg:slider{
    id="drag",
    label="Drag",
    min=0,
    max=100,
    value=10
}

dlg:number{
    id="seed",
    label="Seed",
    text="1234",
    decimals=0,
    onchange=function() updateDialog(dlg, "seed") end
}

dlg:check{
    id="useOverlays",
    label="Use Overlays",
    selected=false,
    onclick=function() showWarningDialog() end
}

dlg:button{
    id="start",
    text="Start",
    onclick=function() renderParticles(dlg.data) end
}

dlg:button{
    id="exit",
    text="Exit",
    onclick=function() onExit(dlg) end
}

local bounds = dlg.bounds
dlg.bounds = Rectangle(85, 55, bounds.width*1.25, bounds.height)

dlg:show{wait=false}