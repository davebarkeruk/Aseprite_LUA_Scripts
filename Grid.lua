do
    local spr = app.sprite

    if not spr then return app.alert "There is no active sprite" end

    if spr.spec.colorMode ~= ColorMode.RGB then return app.alert "Sprite needs to be in RGB color mode" end

    local function renderGrid(userSettings)
        app.transaction(
            string.format('Grid %sx%d', userSettings.gridWidth, userSettings.gridHeight),
            function()
                layer = spr:newLayer()
                layer.name = string.format('Grid %sx%d', userSettings.gridWidth, userSettings.gridHeight)
                cel = spr:newCel(layer, app.frame)
                im = cel.image:clone()
                for it in im:pixels() do
                    if (it.x % userSettings.gridWidth) == 0 or (it.y % userSettings.gridHeight) == 0 then
                        it(app.pixelColor.rgba(userSettings.gridColor.red,
                                                userSettings.gridColor.green,
                                                userSettings.gridColor.blue,
                                                userSettings.gridColor.alpha))
                    end
                end 
                cel.image = im
                app.refresh()
            end
        )
    end

    local dlg = Dialog("Draw Grid")

    dlg:color{ id="gridColor", label="Grid Color", color=Color{ r=0, g=0, b=0, a=255 }}
    dlg:number{ id="gridWidth", label="Grid Width", text="5", min=1, decimals=0}
    dlg:number{ id="gridHeight", label="Grid Height", text="5", min=1, decimals=0}
    dlg:button{ id="start", text="Start", onclick=function() renderGrid(dlg.data) end }
    dlg:button{ id="exit", text="Exit" }
    dlg:show{wait=false}
end
