-- S Y S T R A Y   H I N T S 
-- rts/oarion7 - ryanthomas.org 
-- Module to control the awesomewm systray from the keyboard using
-- vimium-like number hints. Developed and tested on awesome v4.3. 

-- TO DO: move widget to table (remove globals)
-- cleanup 

local awful = require("awful")
local gears = require("gears")
local b     = require("beautiful")
local wibox = require("wibox")

local s

local font          = b.systray_hints_font or b.taglist_font or b.font
local bgcolor       = b.systray_hints_bg or b.taglist_bg_occupied or "#55465a"
local highlight     = b.systray_hints_bg_highlight or "#aa53aa"
local highlight_alt = b.systray_hints_bg_highlight_alt or "#426f5a"
local fgcolor       = b.systray_hints_fg or b.taglist_fg_occupied or "#fdf6e3" 
local bordercolor   = "#fdf6e333"

awful.screen.connect_for_each_screen(function(screen) if screen.systray then s = screen end end) 
if s == nil then return nil end

local systray_hints = {
    arrows = { "Left", "Down", "Up", "Right" },
    --arrows = { "h", "j", "k", "l" },
    default_button = 3, 
    --default_button = 1, 
    hints = hints,
    systray = s.systray,
    wibox = s.mywibox, --where the system tray is located
    run = run,
}

local total
local was_hidden
local icon_count
local icon_width
local half_icon 
local first_icon_x
local icons_y

local function delay(time, cmd)
    gears.timer( {  timeout = time, autostart = true, single_shot = true, 
        callback = function () cmd () end, } )
end


local function execute(choice, mouse_button)

    local target
    local factor
    local saved_coords

    saved_coords = mouse.coords({x = x, y = y}) 
    if choice == 1 then factor = 0 else factor = choice - 1 end
    target = first_icon_x + ( icon_width * factor )
    mouse.coords { x = target , y = icons_y }

    if mouse_button ~= 2 then 
        root.fake_input("button_press" , tostring(mouse_button))
        root.fake_input("button_release", tostring(mouse_button))
        delay(0.05, function () mouse.coords({x = saved_coords.x, y = saved_coords.y}, true) end) 
    end

    if systray_hints.hints then systray_hints.hints.visible = false end

end

local function highlight_options(total)
    local color    
    for i = 9, total do
        color = highlight_alt
        if i == 9 then 
            i = 1 
            color = highlight
        end
        systray_hints.hints.widget:get_children()[1]:get_children()[i].widget:set_bg(color)
    end
end


local function get_key_input(total)

    local grabber
    local mouse_button
    local mouse_button = systray_hints.default_button
    local function conc(n) return tonumber( 1 .. n ) end

    grabber = awful.keygrabber {

        mask_modkeys = true,
        autostart = true,
        keypressed_callback  = function(self, mod, key, cmd)

            if key == '1' and total > 9 then 
                
                if systray_hints.hints then
                    highlight_options(total)
                end
                grabber.keypressed_callback  = function(self, mod, key, cmd)
                        if key == "Return" then
                            execute(1, mouse_button)
                            grabber:stop()
                        elseif not key:match("%D") and conc(key) <= total then 
                            execute(conc(key), mouse_button)
                            grabber:stop()
                        else
                            grabber:stop()
                            if was_hidden then s.systray.visible = false end
                            if systray_hints.hints then systray_hints.hints.visible = false end
                        end
                end
            elseif key == systray_hints.arrows[1] then mouse_button = 1
            elseif key == systray_hints.arrows[4] then mouse_button = 3
            elseif key == systray_hints.arrows[2] or key == systray_hints.arrows[3] then mouse_button = 2
            elseif not key:match("%D") and tonumber(key) <= total then 
                execute(tonumber(key), mouse_button)
                grabber:stop()
            else
                grabber:stop()
                if was_hidden then s.systray.visible = false end
                if systray_hints.hints then systray_hints.hints.visible = false end
            end

        end,

    }

end



local function show_hints(sys_hints_geo_x, sys_hints_geo_y, w, sys_hints_icon_count, s)

    local sys_hints_icon_width = w - 2 --subtract for margins

    if sys_hints_geo_y >= 100 then 
        sys_hints_geo_y = sys_hints_geo_y - sys_hints_icon_width
    else sys_hints_geo_y = sys_hints_geo_y + sys_hints_icon_width
    --Decide if hints should display above or below systray icons.
    end

    --hide if already displayed
    if systray_hints.hints then systray_hints.hints.visible = false end

    local num_rows = sys_hints_icon_count
    local sys_hints_list = {}
    local systray_widget_list = {}

    local widget_shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 5)
    end

    local var = {}
    for i = 1, num_rows do table.insert(sys_hints_list, tostring(i)) end 
    for k, v in pairs(sys_hints_list) do

        var["text_" .. v] = wibox.widget.textbox(tostring(v))
        local text_alias = var["text_" .. v]
        text_alias.font = font -- "Sans 14"
        text_alias.markup = '<span color="' .. fgcolor ..
        '">' .. v .. '</span>'

        local item_place = {}
        table.insert(item_place, text_alias)

        item_place.widget = wibox.container.place

        local item_background = {}
        table.insert(item_background, item_place)

        item_background.widget = wibox.container.background
        item_background.bg = bgcolor -- "#ff00ff"
        item_background.forced_width = sys_hints_icon_width
        item_background.shape  = widget_shape
        item_background.shape_border_width = 2
        item_background.shape_border_color = bordercolor
        tostring(v)

        local item_margin = {}
        table.insert(item_margin, item_background)

        item_margin.widget = wibox.container.margin
        item_margin.right  = 1
        item_margin.left  = 1

        local complete_widget = item_margin
        table.insert(systray_widget_list, complete_widget)
    end 

    systray_widget_list.layout = wibox.layout.fixed.horizontal
    systray_hints.hints = awful.popup {
        widget = {
        screen = s,
        systray_widget_list,

        layout = wibox.layout.fixed.horizontal,
        },
        x            = sys_hints_geo_x,
        y            = sys_hints_geo_y,
        visible      = true,
        ontop        = true,
        bg           = "#00000000",
   }

end

local function find_widget_in_wibox(wb, wdg)
    
   local function get_geometry(hi)
      local g = gears.matrix.transform_rectangle
      local x, y, w, h = g(hi:get_matrix_to_device(), 0, 0, hi:get_size())

      icon_count = math.floor( ( w - ( w % h) ) / h + 1 )
      icon_width = math.floor(w / icon_count )
      half_icon = math.floor( icon_width / 2)
      first_icon_x = math.floor( x + half_icon)
      icons_y = math.floor(y + half_icon)
      
      show_hints( math.floor(x), math.floor(y), icon_width, icon_count, s )
      get_key_input(icon_count)

   end

   local function traverse(hi)
      if hi:get_widget() == wdg then
            get_geometry(hi)
            return 
      end
      for _, child in ipairs(hi:get_children()) do
         -- return traverse(child)
            traverse(child)
         -- allow for additional round of recursion across container widgets.
      end
   end
   return traverse(wb._drawable._widget_hierarchy)
end

systray_hints.run = function ()

    if not s.systray.visible then 
        was_hidden = true
        s.systray.visible = true 
        delay(0.05, function () find_widget_in_wibox(systray_hints.wibox, systray_hints.systray) end) 
    else
        find_widget_in_wibox(systray_hints.wibox, systray_hints.systray)
    end

end

return systray_hints