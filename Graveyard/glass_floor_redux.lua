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

    app.transaction(
        function()
            local bounds = Rectangle()
            local layers = app.range.layers
            local newLayer = spr:newLayer()
            newLayer.name = "Glass Floor"
            newLayer.opacity = 128

            local lookup = orderedLayerLookup(layers)

            for _,frame in ipairs(spr.frames) do
                local img = Image(spr.spec)
                img:clear(Color{ r=0, g=0, b=0, a=0 })
                for _,lup in ipairs(lookup) do
                    local l = layers[lup.tableIndex]
                    local layerCel = l:cel(frame)
                    if layerCel then
                        local fgnd = Image(spr.spec)
                        fgnd:drawImage(layerCel.image, layerCel.position)
                        imageOver(fgnd, l.opacity, img)
                        bounds = bounds:union(layerCel.bounds)
                    end
                end
                spr:newCel(newLayer, frame, img, Point(0, 0))
            end

            local oldFrame = app.activeFrame
            app.activeLayer = newLayer
            for _,cel in ipairs(newLayer.cels) do
                app.activeFrame = cel.frame
                app.command.Flip{ target="mask", orientation="vertical" }
                cel.position = Point(cel.position.x,
                                    cel.position.y + 2*(bounds.y + bounds.height - spr.height/2))
            end
            app.activeFrame = oldFrame
        end
    )
end