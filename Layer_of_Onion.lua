do
    local spr = app.activeSprite
    if not spr then return app.alert "There is no active sprite" end

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

    local function renderOnion(userSettings)
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