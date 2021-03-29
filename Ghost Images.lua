do
    local spr = app.activeSprite
    if not spr then return app.alert "There is no active sprite" end

    if not(spr.spec.colorMode == ColorMode.RGB) then return app.alert "Sprite needs to be in RGB color mode" end

    local renderCount = 0

    local function tableConcat(t1,t2)
        for i=1,#t2 do
            t1[#t1+1] = t2[i]
        end
        return t1
    end

    local function buildCustomLayerTable(layers, groupString, layerCount)
        layers = layers or spr.layers
        groupString = groupString or ''
        layerCount = layerCount or 1

        local clt = {}

        for i=#layers,1,-1 do
            layer = layers[i]
            if layer.isGroup then
                layerCount, groupLayers = buildCustomLayerTable(layer.layers, groupString..layer.name..'/', layerCount)
                tableConcat(clt, groupLayers)
            elseif layer.isImage then
                table.insert(clt, {name=layerCount..': '..groupString..layer.name, layer=layer})
                layerCount = layerCount + 1
            end
        end

        return layerCount, clt
    end

    local function findInCustomLayerTable(clt, name)
        for _, l in ipairs(clt) do
            if l.name == name then
                return l.layer
            end
        end
        return nil
    end

    local function listNamesInCustomLayerTable(clt)
        names = {}
        for _, l in ipairs(clt) do
            table.insert(names, l.name)
        end
        return names
    end

    local function scaleAlpha(img, bounds, scale)
        maxX = bounds.x + bounds.width - 1
        maxY = bounds.y + bounds.height - 1

        for y=bounds.y, maxY do
            for x=bounds.x, maxX do
                local col = img:getPixel(x, y)

                local r = app.pixelColor.rgbaR(col)
                local g = app.pixelColor.rgbaG(col)
                local b = app.pixelColor.rgbaB(col)
                local a = app.pixelColor.rgbaA(col) * scale

                img:drawPixel(x, y, Color{ r=r, g=g, b=b, a=a })
            end
        end
    end

    local function tintAndScaleAlpha(img, bounds, scale, tintColor)
        local r = tintColor.red
        local g = tintColor.green
        local b = tintColor.blue
        local tintScale = scale * (tintColor.alpha / 255)

        maxX = bounds.x + bounds.width - 1
        maxY = bounds.y + bounds.height - 1

        for y=bounds.y, maxY do
            for x=bounds.x, maxX do
                local col = img:getPixel(x, y)

                local a = app.pixelColor.rgbaA(col) * tintScale

                img:drawPixel(x, y, Color{ r=r, g=g, b=b, a=a })
            end
        end
    end

    local function renderGhosts(userSettings,clt)
        app.transaction(
            function()
                renderCount = renderCount + 1
                local sourceLayer = findInCustomLayerTable(clt, userSettings.layerSelect)
                local sourceOpacity = sourceLayer.opacity
                local ghosts = {}

                local lowerLayer = spr:newLayer()
                lowerLayer.name = "Ghosts "..renderCount
                lowerLayer.opacity = 255

                for i= userSettings.nGhosts,0,-1 do

                    local upperLayer = spr:newLayer()
                    upperLayer.name = "temp" .. i
                    upperLayer.opacity = 255

                    local offsetX = i * userSettings.shiftX
                    local offsetY = i * userSettings.shiftY

                    for frmNumber,frame in ipairs(spr.frames) do
                        local offsetFrameNumber = frmNumber - (i * userSettings.delay) % #spr.frames

                        if offsetFrameNumber > 0 or userSettings.loop then
                            if offsetFrameNumber < 1 then
                                offsetFrameNumber = #spr.frames + offsetFrameNumber
                            end

                            if i == 0 then
                                local img = Image(spr.spec)
                                local ghostFrame = spr.frames[offsetFrameNumber]
                                local layerCel = sourceLayer:cel(ghostFrame)
                                if layerCel then
                                    img:drawImage(layerCel.image, layerCel.position)
                                end
                                spr:newCel(upperLayer, frame, img, Point(0, 0))
                            else
                                local img = Image(spr.spec)
                                local ghostFrame = spr.frames[offsetFrameNumber]
                                local layerCel = sourceLayer:cel(ghostFrame)
                                if layerCel then
                                    local pos = Point(layerCel.position.x + offsetX, layerCel.position.y + offsetY)
                                    local bounds = Rectangle(pos.x, pos.y, layerCel.bounds.width, layerCel.bounds.height)
                                    img:drawImage(layerCel.image, pos)
                                    if userSettings.doTint then
                                        tintAndScaleAlpha(img, bounds, 1 - i / (userSettings.nGhosts+1), userSettings.tintColor)
                                    else
                                        scaleAlpha(img, bounds, 1 - i / (userSettings.nGhosts+1))
                                    end                                  
                                end
                                spr:newCel(upperLayer, frame, img, Point(0, 0))
                            end
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

    local _,clt = buildCustomLayerTable()

    local dlg = Dialog("Create a Layer of Ghost Images")
    dlg:combobox{ id="layerSelect", label="Input Layer", option=clt[1].name, options=listNamesInCustomLayerTable(clt)}
    dlg:slider{ id="nGhosts", label="Number of Ghosts", min=1, max=20, value=5 }
    dlg:slider{ id="delay", label="Delay between Ghosts", min=1, max=math.max(1, #spr.frames-1), value=math.min(5, #spr.frames-1) }
    dlg:check{ id="loop", label="Looping Animation", selected=true, onclick=function() return end}
    dlg:check{ id="doTint", label="Use Solid Color for Ghosts", selected=false, onclick=function() return end}
    dlg:color{ id="tintColor", label="Solid Color", color=Color{ r=0, g=0, b=0, a=255 }}
    dlg:number{ id="shiftX", label="Shift Ghost in X axis", text="0", decimals=0}
    dlg:number{ id="shiftY", label="Shift Ghost in Y axis", text="0", decimals=0}
    dlg:button{ id="start", text="Start", onclick=function() renderGhosts(dlg.data, clt) end }
    dlg:button{ id="exit", text="Exit" }
    dlg:show{wait=false}
end