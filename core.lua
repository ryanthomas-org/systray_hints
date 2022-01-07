found_widget_geometry = nil
local awful = require("awful")
local gears = require("gears")
local b = require("beautiful")
local s

function hide_systray_hints()
   if systray_hints_widget then
      systray_hints_widget.visible = false 
   end
end

function sys_hints_hide_systray()
   local s
   awful.screen.connect_for_each_screen(function(screen)
      if screen.systray then s = screen end
   end)
   s.systray.visible = false 
end

function systray_show_hints(x, y, w, count)

   local sys_hints_geo_x = x or 1390
   local sys_hints_geo_y = y or 0
   local sys_hints_icon_width = w or 28
   local sys_hints_icon_count = count or 8

   local systray_hints_font = b.systray_hints_font or b.font
   local systray_hints_bg = b.systray_hints_bg or "#ff00ff"
   local systray_hints_fg = b.systray_hints_fg or "#000000"

   sys_hints_icon_width = sys_hints_icon_width - 2 
 --Subtract 2px from icon width for left/right margins

   if sys_hints_geo_y >= 100 then 
      sys_hints_geo_y = sys_hints_geo_y - sys_hints_icon_width
   else sys_hints_geo_y = sys_hints_geo_y + sys_hints_icon_width
 --Decide if hints should display above or below systray icons.
   end

   awful.screen.connect_for_each_screen(function(screen)
      if screen.systray.visible == true then s = screen end
   end)

   if s == nil then return nil end

   hide_systray_hints() --hide if already displayed

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
      local x = math.floor(x) ; local y = math.floor(y)
      local w = math.floor(w) ; local h = math.floor(h)
      found_widget_geometry = x .. "," .. y .. "," .. w .. "," .. h
   end

   local function traverse(hi)
      if hi:get_widget() == wdg then
            get_geometry(hi)
            return
      end
      for _, child in ipairs(hi:get_children()) do
         -- return traverse(child)
            traverse(child)
         -- Others have the above line instead, but for us it returned
         -- only container widgets. Removing "return" allows for an
         -- additional round of recursion. 
      end
   end
   return traverse(wb._drawable._widget_hierarchy)
end

awful.screen.connect_for_each_screen(function(screen)
   if screen.systray.visible == true then s = screen end
end)

if s == nil then return nil end
find_widget_in_wibox(s.mywibox, s.systray)
return found_widget_geometry

