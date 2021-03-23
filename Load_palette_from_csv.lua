local spr = app.activeSprite
if not spr then return end

local function save_palette_csv(filename)
    local ncolors = #spr.palettes[1]
    local f = io.open(filename, "w")
    f:write(string.format('red,green,blue,alpha\n'))
    for i = 0, ncolors-1 do
       local c = spr.palettes[1]:getColor(i)
       local r = c.red
       local g = c.green
       local b = c.blue
       local a = c.alpha
       f:write(string.format('%d,%d,%d,%d\n',r,g,b,a))
    end
    f:close()
end

local function load_palette_csv(filename)
    local f = io.open(filename, "r")
    local colors = {}

    local line = f:read()

    if not line then
        app.alert("Empty File.")
        f:close()
        return nil
    end

    if not (line == "red,green,blue,alpha") then
        app.alert("File does not have valid first line.")
        f:close()
        return nil
    else
        line = f:read()
        while line do
            r,g,b,a = string.match(line, "(%d+),(%d+),(%d+),(%d+)")
            if r and g and b and a then
                table.insert(colors, Color{ r=r, g=g, b=b, a=a })
            else
                app.alert("Invalid RGBA data in file.")
                f:close()
                return nil
            end
            line = f:read()
        end
        f:close()
    end

    if #colors == 0 then
        app.alert("Empty color palette.")
        return nil
    end

    local pal = Palette(#colors)
    for i=0, #colors-1 do
        pal:setColor(i, colors[i+1])
    end

    return pal
end

local function enable_button(dlg, button_id)
    dlg:modify{ id=button_id, enabled=true }
end

local load_dlg = Dialog("Load Palette from CSV File")
load_dlg:file{ id="csv_in",
               label="Filename: ",
               filename="palette.csv",
               open=true,
               save=false,
               filetypes={ "csv", "txt" },
               onchange=function() enable_button(load_dlg, "load") end }
load_dlg:button{ id="load", text="Load", enabled=false }
load_dlg:button{ id="cancel", text="Cancel" }
load_dlg:show()

local data = load_dlg.data
if data.load then
    pal = load_palette_csv(data.csv_in)
    if pal then
        app.transaction(
            function()
                spr:setPalette(pal)
            end)
        app.refresh()
    end
end

