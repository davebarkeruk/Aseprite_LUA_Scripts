do
    local spr = app.activeSprite
    if not spr then return app.alert "There is no active sprite" end

    local function imageOver(fgnd, fgndOpacity, bgnd)
        local fgndOpacityFloat = fgndOpacity / 255
        for y=0, bgnd.height-1 do
            for x=0, bgnd.width-1 do
                local fgndCol = fgnd:getPixel(x, y)
                local bgndCol = bgnd:getPixel(x, y)

                local fgndR = app.pixelColor.rgbaR(fgndCol)
                local fgndG = app.pixelColor.rgbaG(fgndCol)
                local fgndB = app.pixelColor.rgbaB(fgndCol)
                local fgndA = (app.pixelColor.rgbaA(fgndCol) / 255) * fgndOpacityFloat

                local bgndR = app.pixelColor.rgbaR(bgndCol)
                local bgndG = app.pixelColor.rgbaG(bgndCol)
                local bgndB = app.pixelColor.rgbaB(bgndCol)
                local bgndA = app.pixelColor.rgbaA(bgndCol) / 255

                local a0 = (fgndA + (bgndA * (1 - fgndA)))
                local fgndScale = fgndA / a0
                local bgndScale = (bgndA * (1 - fgndA)) / a0

                local outR = (fgndR * fgndScale) + (bgndR * bgndScale)
                local outG = (fgndG * fgndScale) + (bgndG * bgndScale)
                local outB = (fgndB * fgndScale) + (bgndB * bgndScale)
                local outA = 255 * a0

                bgnd:drawPixel(x, y, Color{ r=outR, g=outG, b=outB, a=outA })
            end
        end
    end

    local function orderedLayerLookup(layers)
        local lookup = {}
        for i,l in ipairs(layers) do
            table.insert(lookup, {tableIndex=i, stackIndex=l.stackIndex})
        end
        table.sort(lookup, function(a,b) return a.stackIndex < b.stackIndex end)
        return lookup
    end

    local function renderOnion(userSettings)
        app.transaction(
            function()
                local layers = app.range.layers
                local newLayer = spr:newLayer()
                local nSkins = userSettings.nframes
                newLayer.name = "Onion"
                newLayer.opacity = 255

                local lookup = orderedLayerLookup(layers)

                for frmNumber,frame in ipairs(spr.frames) do
                    local img = Image(spr.spec)
                    img:clear(Color{ r=0, g=0, b=0, a=0 })
                    for skin = 1, nSkins do
                        local skinFrameNumber = frmNumber + skin - nSkins
                        if skinFrameNumber < 1 then
                            skinFrameNumber = #spr.frames + skinFrameNumber
                        end
                        local skinFrame = spr.frames[skinFrameNumber]
                        local skinOpacity = skin / nSkins
                        for _,lup in ipairs(lookup) do
                            local l = layers[lup.tableIndex]
                            local layerCel = l:cel(skinFrame)
                            if layerCel then
                                local fgnd = Image(spr.spec)
                                fgnd:drawImage(layerCel.image, layerCel.position)
                                imageOver(fgnd, l.opacity * skinOpacity, img)
                            end
                        end
                    end
                    spr:newCel(newLayer, frame, img, Point(0, 0))
                end

            end
        )
        app.refresh()
    end

    local function scaleAlpha(img, scale)
        for it in img:pixels() do
            local col = it()

            local r = app.pixelColor.rgbaR(col)
            local g = app.pixelColor.rgbaG(col)
            local b = app.pixelColor.rgbaB(col)
            local a = app.pixelColor.rgbaA(col)

            it( app.pixelColor.rgba(r, g, b, a*scale) )
        end
    end

    local function renderOnionB(userSettings)
        app.transaction(
            function()
                local sourceLayer = app.activeLayer
                local sourceOpacity = sourceLayer.opacity
                local lowerLayer = spr:newLayer()
                local nSkins = userSettings.nframes

                lowerLayer.name = "Onion"
                lowerLayer.opacity = 255

                for skin = 1, nSkins do 
                    local upperLayer = spr:newLayer()
                    upperLayer.name = "temp"..skin
                    upperLayer.opacity = 255

                    for frmNumber,frame in ipairs(spr.frames) do
                        local skinFrameNumber = frmNumber + skin - nSkins
                        if skinFrameNumber > 0 or userSettings.loop then
                            if skinFrameNumber < 1 then
                                skinFrameNumber = #spr.frames + skinFrameNumber
                            end
                            
                            local img = Image(spr.spec)
                            local skinFrame = spr.frames[skinFrameNumber]
                            local layerCel = sourceLayer:cel(skinFrame)
                            if layerCel then
                                img:drawImage(layerCel.image, layerCel.position)
                                scaleAlpha(img, skin / nSkins)
                            end
                            spr:newCel(upperLayer, frame, img, Point(0, 0))
                        end
                    end
                    app.activeLayer = upperLayer
                    app.command.MergeDownLayer()
                end
                app.activeLayer.opacity = sourceOpacity
            end
        )
        app.refresh()
    end

    local dlg = Dialog("Create Onion as Layer")
    dlg:slider{ id="nframes", label="Number of frames", min=1, max=math.max(1, #spr.frames-1), value=math.min(5, #spr.frames-1) }
    dlg:check{ id="loop", label="Looping Animation", selected=false, onclick=function() return end}
    dlg:button{ id="start", text="Start", onclick=function() renderOnion(dlg.data) end }
    dlg:button{ id="exit", text="Exit" }
    dlg:show{wait=false}
end