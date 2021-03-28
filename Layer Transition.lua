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

    local function straightWipe(imgA, imgB, bounds, testFunction)
        maxX = bounds.x + bounds.width - 1
        maxY = bounds.y + bounds.height - 1

        for y=bounds.y, maxY do
            for x=bounds.x, maxX do
                if testFunction(x, y) then
                    local col = imgB:getPixel(x, y)
                    local r = app.pixelColor.rgbaR(col)
                    local g = app.pixelColor.rgbaG(col)
                    local b = app.pixelColor.rgbaB(col)
                    local a = app.pixelColor.rgbaA(col)

                    imgA:drawPixel(x, y, Color{ r=r, g=g, b=b, a=a })
                end
            end
        end
    end

    local function randomWipe(imgA, imgB, bounds, randomValues, threshold)
        maxX = bounds.x + bounds.width - 1
        maxY = bounds.y + bounds.height - 1

        for y=bounds.y, maxY do
            for x=bounds.x, maxX do
                local i = 1 + x + y * imgA.width
                if randomValues[i] <= threshold then
                    local col = imgB:getPixel(x, y)
                    local r = app.pixelColor.rgbaR(col)
                    local g = app.pixelColor.rgbaG(col)
                    local b = app.pixelColor.rgbaB(col)
                    local a = app.pixelColor.rgbaA(col)

                    imgA:drawPixel(x, y, Color{ r=r, g=g, b=b, a=a })
                end
            end
        end
    end

    local function renderTransition(userSettings,clt)
        app.transaction(
            function()
                renderCount = renderCount + 1
                local fromLayer = findInCustomLayerTable(clt, userSettings.fromLayerSelect)
                local toLayer = findInCustomLayerTable(clt, userSettings.toLayerSelect)

                local transitionLayer = spr:newLayer()
                transitionLayer.name = "Transition "..renderCount
                transitionLayer.opacity = 255

                local progressStep = 1 / (#spr.frames - 2)
                local progress = 0

                math.randomseed(userSettings.seed)
                local randomValues = {}
                if userSettings.transitionType == "Random Pixels" then
                    local nPixels = spr.spec.width * spr.spec.height
                    for i = 1, nPixels do
                        randomValues[i] = math.random(2,#spr.frames)
                    end
                end

                for frmNumber,frame in ipairs(spr.frames) do
                    local fromImg = Image(spr.spec)
                    local toImg = Image(spr.spec)
                    local toLayerCel = toLayer:cel(frame)
                    local fromLayerCel = fromLayer:cel(frame)

                    if fromLayerCel and toLayerCel then
                        fromImg:drawImage(fromLayerCel.image, fromLayerCel.position)
                        toImg:drawImage(toLayerCel.image, toLayerCel.position)
                        
                        bounds = fromLayerCel.bounds
                        bounds = bounds:union(toLayerCel.bounds)
                        if bounds:intersects(spr.bounds) then
                            bounds = bounds:intersect(spr.bounds)
                            print(bounds.x, bounds.y, bounds.width, bounds.height)

                            if userSettings.transitionType == "Left to Right" then
                                local edge = math.floor(0.1 + (fromImg.width - 2) * progress)
                                straightWipe(fromImg, toImg, bounds, function(x,y) return x < edge end)
                            elseif userSettings.transitionType == "Right to Left" then
                                local edge = fromImg.width - math.floor(0.1 + (fromImg.width - 2) * progress)
                                straightWipe(fromImg, toImg, bounds, function(x,y) return x >= edge end)
                            elseif userSettings.transitionType == "Top to Bottom" then
                                local edge = math.floor(0.1 + (fromImg.height - 2) * progress)
                                straightWipe(fromImg, toImg, bounds, function(x,y) return y < edge end)
                            elseif userSettings.transitionType == "Bottom to Top" then
                                local edge = fromImg.height - math.floor(0.1 + (fromImg.height - 2) * progress)
                                straightWipe(fromImg, toImg, bounds, function(x,y) return y >= edge end)
                            elseif userSettings.transitionType == "Random Pixels" then
                                randomWipe(fromImg, toImg, bounds, randomValues, frmNumber)
                            end
                        end

                        spr:newCel(transitionLayer, frame, fromImg, Point(0, 0))
                    end
                    progress = progress + progressStep
                end
            end
        )
        app.refresh()
    end

    local _,clt = buildCustomLayerTable()

    local dlg = Dialog("Create a Layer of Ghost Images")
    dlg:combobox{ id="fromLayerSelect", label="From Layer", option=clt[1].name, options=listNamesInCustomLayerTable(clt)}
    dlg:combobox{ id="toLayerSelect", label="To Layer", option=clt[1].name, options=listNamesInCustomLayerTable(clt)}
    dlg:combobox{ id="transitionType", label="Transition", "Left to Right", options={"Left to Right", "Right to Left", "Top to Bottom", "Bottom to Top", "Random Pixels"}}
    dlg:number{ id="seed", label="Random Seed", text="1234", decimals=0}
    dlg:button{ id="start", text="Start", onclick=function() renderTransition(dlg.data, clt) end }
    dlg:button{ id="exit", text="Exit" }
    dlg:show{wait=false}
end