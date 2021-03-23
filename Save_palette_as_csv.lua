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

local function enable_button(dlg, button_id)
    dlg:modify{ id=button_id, enabled=true }
end

local save_dlg = Dialog("Save Palette as CSV File")
save_dlg:file{ id="csv_out",
               label="Filename: ",
               filename="palette.csv",
               open=false,
               save=true,
               filetypes={ "csv", "txt" },
               onchange=function() enable_button(save_dlg, "save") end}
save_dlg:button{ id="save", text="Save", enabled=false }
save_dlg:button{ id="cancel", text="Cancel" }
save_dlg:show()

local data = save_dlg.data
if data.save then
    save_palette_csv(data.csv_out)
end

