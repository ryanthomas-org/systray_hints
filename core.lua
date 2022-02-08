-- S Y S T R A Y   H I N T S 
-- rts/oarion7 - ryanthomas.org 
-- Module to control the awesomewm systray from the keyboard using
-- vimium-like number hints. Developed and tested on awesome v4.3. 

--TODO:
--Continue testing, clean up

local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")


local was_hidden
local icon_count
local icon_width
local half_icon 
local first_icon_x
local icons_y

local s

local systray_hints_font = beautiful.systray_hints_font or beautiful.taglist_font or beautiful.font
local systray_hints_bg = beautiful.systray_hints_bg or beautiful.taglist_bg_occupied or "#d6d"
local systray_hints_hi = beautiful.systray_hints_bg_highlight or beautiful.bg_urgent or "#dd6"
local systray_hints_fg = beautiful.systray_hints_fg or beautiful.taglist_fg_occupied or "#000000" 


awful.screen.connect_for_each_screen(function(screen) if screen.systray then s = screen end end) 
if s == nil then return nil end

-- G L O B A L S 
-- Edit here or override to configure options.

-- Arrows are key names optionally pressed at run-time before entering a number to specify which mouse button is to be clicked. Default is right-click, which is last in the index. The first key will set a left click, and the two middle options (up/down) trigger hover (no click).

systray_hints = {
    arrows = { "Left", "Down", "Up", "Right" },
    --arrows = { "h", "j", "k", "l" },
    default_button = 3, -- right-click by default
    --default_button = 1, -- left click by default
    wibox = s.mywibox, --where to look for the system tray
    systray = s.systray,
}




local function click(choice, mouse_button)
--local function click(choice, mouse_button, first_icon_x, icons_y, icon_width)

    local target
    local factor
    local saved_coords

    saved_coords = mouse.coords({x = x, y = y}) --save
    if choice == 1 then factor = 0 else factor = choice - 1 end
    target = first_icon_x + ( icon_width * factor )
    mouse.coords { x = target , y = icons_y }

    if mouse_button ~= 2 then -- don't click; just hover
        root.fake_input("button_press" , tostring(mouse_button))
        root.fake_input("button_release", tostring(mouse_button))

        gears.timer( {  timeout = 0.05,
            autostart = true,
            single_shot = true,
            callback =  function()
                mouse.coords({x = saved_coords.x, y = saved_coords.y}, true) --restore
        end } )
    end

end





local function get_key_input(total)

    local grabber
    local mouse_button
    local mouse_button = systray_hints.default_button
    local function conc(n) return tonumber( 1 .. n ) end

    local function execute(n, mouse_button) 



        click(n, mouse_button)

        if systray_hints_widget then systray_hints_widget.visible = false end
        


    end

    grabber = awful.keygrabber {

        mask_modkeys = true,
        autostart = true,
        --start_callback     = bcn("Let us begin."), --test
        keypressed_callback  = function(self, mod, key, cmd)

            if key == '1' and total > 9 then 
                
                if systray_hints_widget then
                    systray_hints_widget.widget:get_children()[1]:get_all_children()[1].systray_hint_background_item_1.bg = systray_hints_hi
                end
                grabber.keypressed_callback  = function(self, mod, key, cmd)
                        if key == "Return" then
                            execute(1, mouse_button)
                            grabber:stop()
                        elseif not key:match("%D") then 
                            execute(conc(key), mouse_button)
                            grabber:stop()
                        else
                            grabber:stop()
                            if was_hidden then s.systray.visible = false end
                            if systray_hints_widget then systray_hints_widget.visible = false end
                        end
                end
            elseif key == systray_hints.arrows[1] then mouse_button = 1
            elseif key == systray_hints.arrows[4] then mouse_button = 3
            elseif key == systray_hints.arrows[2] or key == systray_hints.arrows[3] then mouse_button = 2
            elseif not key:match("%D") then 
                execute(key, mouse_button)
                grabber:stop()
            else
                grabber:stop()
                if was_hidden then s.systray.visible = false end
                if systray_hints_widget then systray_hints_widget.visible = false end
            end

        end,

    }

end



local function show_systray_hints_widget(sys_hints_geo_x, sys_hints_geo_y, w, sys_hints_icon_count, s)

   local sys_hints_icon_width = w - 2




 --Subtract 2px from icon width for left/right margins



   if sys_hints_geo_y >= 100 then 
      sys_hints_geo_y = sys_hints_geo_y - sys_hints_icon_width
   else sys_hints_geo_y = sys_hints_geo_y + sys_hints_icon_width
 --Decide if hints should display above or below systray icons.
   end

   --hide if already displayed
   if systray_hints_widget then
      systray_hints_widget.visible = false 
   end

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
      text_alias.font = systray_hints_font -- "Sans 14"
      text_alias.markup = '<span color="' .. systray_hints_fg ..
      '">' .. v .. '</span>'

      local item_container_place = {}
      table.insert(item_container_place, text_alias)
      item_container_place.widget = wibox.container.place

      local item_container_background = {}
      table.insert(item_container_background, item_container_place)
      item_container_background.widget = wibox.container.background
      item_container_background.bg = systray_hints_bg -- "#ff00ff"
      item_container_background.forced_width = sys_hints_icon_width
      item_container_background.shape  = widget_shape
      item_container_background.shape_border_width = 2
      item_container_background.shape_border_color = systray_hints_fg .. 33
      item_container_background.id = "systray_hint_background_item_" ..
      tostring(v)

      local item_container_margin = {}
      table.insert(item_container_margin, item_container_background)
      item_container_margin.widget = wibox.container.margin
      item_container_margin.right  = 1
      item_container_margin.left  = 1

      local complete_widget = item_container_margin
      table.insert(systray_widget_list, complete_widget)

   end 

   systray_widget_list.layout = wibox.layout.fixed.horizontal
   systray_hints_widget = awful.popup {
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
     --hide_on_right_click = true
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
      
      show_systray_hints_widget( math.floor(x), math.floor(y), icon_width, icon_count, s )
      get_key_input(icon_count)

   end

   local function traverse(hi)
      if hi:get_widget() == wdg then
            get_geometry(hi)
            return 
      end
      for _, child in ipairs(hi:get_children()) do
            traverse(child)
         -- Others have return traverse(child) here instead, but for us this returned
         -- only container widgets. Removing "return" allows for an
         -- additional round of recursion. 
      end
   end
   return traverse(wb._drawable._widget_hierarchy)
end

systray_hints.run = function ()

    if not s.systray.visible then 
        was_hidden = true
        s.systray.visible = true 
        gears.timer( {  timeout = 0.05,
            autostart = true,
            single_shot = true,
            callback =  function()
                find_widget_in_wibox(systray_hints.wibox, systray_hints.systray)
            end } )
    else
        find_widget_in_wibox(systray_hints.wibox, systray_hints.systray)
    end

end

