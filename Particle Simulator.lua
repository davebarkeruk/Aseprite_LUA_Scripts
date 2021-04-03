local spr = app.activeSprite
if not spr then return app.alert "There is no active sprite" end

local oldSelection = Selection()
oldSelection:add(spr.selection)

local warningDialogViewed = false

local maxSpriteDimension = math.max(spr.spec.width, spr.spec.height)

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

local function renderParticles(userSettings)
    local layer = spr:newLayer()
    layer.name = "Particles"
    layer.opacity = 255

    emissionPixels = calcEmitterPixel(userSettings.emitterX,
                                      userSettings.emitterY,
                                      userSettings.emitterLength,
                                      userSettings.emitterAngle,
                                      userSettings.emitterRadius)

    --renderEmitterPixels(emissionPixels)
    local particles = {}
    local lifespan = {min = userSettings.lifespan * (1.0 - userSettings.lifespanVariance / 100),
                      max = userSettings.lifespan * (1.0 + userSettings.lifespanVariance / 100)}
    local startAngle = {min = userSettings.startVectorAngle - userSettings.startVectorAngleVariance / 2,
                        range = userSettings.startVectorAngleVariance}
    local startMagnitude = {min = userSettings.startVectorMagnitude * (1.0 - userSettings.startVectorMagnitudeVariance / 100),
                            range = userSettings.startVectorMagnitude * (userSettings.startVectorMagnitudeVariance / 50)}

    local gravityRadians = math.rad(userSettings.gravityAngle)
    local gravityVector = {x = userSettings.gravityMagnitude * math.sin(gravityRadians),
                           y = - (userSettings.gravityMagnitude * math.cos(gravityRadians))}

    local floatDrag = 1.0 - userSettings.drag / 100

    for frmNumber,frame in ipairs(spr.frames) do
        local img = Image(spr.spec)
        for i = 1, userSettings.particlesPerFrame do
            local startPosition = math.random(#emissionPixels)
            local angle = startAngle.min + startAngle.range * math.random()
            local magnitude = startMagnitude.min + startMagnitude.range * math.random()
            local radians = math.rad(angle)
            local cosR = math.cos(radians)
            local sinR = math.sin(radians)
            local temp1 = {}
            temp1['x'] = emissionPixels[startPosition].x
            temp1['y'] = emissionPixels[startPosition].y
            local temp2 = {}
            temp2['x'] = emissionPixels[startPosition].x
            temp2['y'] = emissionPixels[startPosition].y
            table.insert(particles, {age = 0,
                                     currentPosition = temp1,
                                     previousPosition = temp2,
                                     lifespan = math.random(lifespan.min, lifespan.max),
                                     vector = {x = magnitude * sinR, y = - (magnitude * cosR) },
                                     dead = false } )
        end

        for _,p in ipairs(particles) do
            if not p.dead then
                p.age = p.age + 1
                if p.age > p.lifespan then
                    p.dead = true
                else
                    local temp = {}
                    temp['x'] = p.currentPosition.x
                    temp['y'] = p.currentPosition.y
                    p.previousPosition = temp
                    p.currentPosition.x = p.currentPosition.x + p.vector.x
                    p.currentPosition.y = p.currentPosition.y + p.vector.y
                    p.vector.x = (p.vector.x + gravityVector.x) * floatDrag
                    p.vector.y = (p.vector.y + gravityVector.y) * floatDrag

                    --img:drawPixel(p.previousPosition.x, p.previousPosition.y, Color{ r=255, g=0, b=0, a=128 })
                    img:drawPixel(p.currentPosition.x, p.currentPosition.y, Color{ r=0, g=0, b=0, a=255 })
                end
            end
        end
        spr:newCel(layer, frmNumber, img, Point(0, 0))
    end

    app.refresh()

    -- for eash frame
    --   birth particles
    --   kill particles
    --   move particles
    --   render particles
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

local dlg = Dialog("Particle Simulator")

dlg:slider{ id="particlesPerFrame",
            label="Particles Per Frame",
            min=1,
            max=500,
            value=20}

dlg:slider{ id="lifespan",
    label="Particle Lifespan",
    min=1,
    max=#spr.frames*2,
    value=math.min(50,#spr.frames)}

dlg:slider{ id="lifespanVariance",
    label="Particle Lifespan Variance",
    min=0,
    max=100,
    value=10}

dlg:slider{ id="emitterX",
            label="Emitter Center X",
            min=-spr.width,
            max=spr.width*2,
            value=math.ceil(spr.width*0.5),
            onchange=function() overlay(dlg.data, 'emitter') end }

dlg:slider{ id="emitterY",
            label="Emitter Center Y",
            min=-spr.height,
            max=spr.height*2,
            value=math.ceil(spr.height*0.5),
            onchange=function() overlay(dlg.data, 'emitter') end }

dlg:slider{ id="emitterLength",
            label="Emitter Length",
            min=1,
            max=maxSpriteDimension*2,
            value=maxSpriteDimension,
            onchange=function() overlay(dlg.data, 'emitter') end }

dlg:slider{ id="emitterAngle",
            label="Emitter Angle",
            min=-90,
            max=90,
            value=0,
            onchange=function() overlay(dlg.data, 'emitter') end }

dlg:slider{ id="emitterRadius",
            label="Emitter Radius",
            min=1,
            max=math.ceil(maxSpriteDimension*0.5),
            value=5,
            onchange=function() overlay(dlg.data, 'emitter') end }

dlg:slider{ id="gravityAngle",
            label="Gravity Angle",
            min=0,
            max=360,
            value=180,
            onchange=function() overlay(dlg.data, 'gravityAngle') end }

dlg:slider{ id="gravityMagnitude",
            label="Gravity Magnitude",
            min=0,
            max=maxSpriteDimension,
            value=math.ceil(maxSpriteDimension/20),
            onchange=function() overlay(dlg.data, 'gravityMagnitude') end }

dlg:slider{ id="startVectorAngle",
            label="Start Vector Angle",
            min=0,
            max=360,
            value=180,
            onchange=function() overlay(dlg.data, 'startVectorAngle') end }

dlg:slider{ id="startVectorAngleVariance",
            label="Start Vector Angle Variance",
            min=0,
            max=360,
            value=5,
            onchange=function() overlay(dlg.data, 'startVectorAngle') end }

dlg:slider{ id="startVectorMagnitude",
            label="Start Vector Magnitude",
            min=0,
            max=maxSpriteDimension,
            value=math.ceil(maxSpriteDimension/20),
            onchange=function() overlay(dlg.data, 'startVectorMagnitude') end }

dlg:slider{ id="startVectorMagnitudeVariance",
            label="Start Vector Magnitude Variance",
            min=0,
            max=100,
            value=10,
            onchange=function() overlay(dlg.data, 'startVectorMagnitude') end }

dlg:slider{ id="drag",
            label="Drag",
            min=0,
            max=100,
            value=10}

dlg:check{ id="useOverlays",
           label="Use Overlays",
           selected=false,
           onclick=function() showWarningDialog() end}

dlg:button{ id="start",
           text="Start",
           onclick=function() renderParticles(dlg.data) end }

dlg:button{ id="exit",
            text="Exit",
            onclick=function() onExit(dlg) end }

dlg:show{wait=false}