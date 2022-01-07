#!/usr/bin/env bash
#rts/oarion7

# * Displays number hints next to systray icons. The number entered on the keyboard sends
#   right click to the corresponding icon unless Ctrl+L (i.e. Left) is pressed first.
#
# * Uses rofi as temporary key grabber by invoking it with auto-select.
#
# * Because the menu options are displays in the widget, visibility  of rofi is 
#   unnecessary. Running rofi in normal window mode, we can put the following in
#   our rules to keep it hidden:
#
# * * * Currently, trying an "invisible" theme instead of -normal-window, so these rules are *NOT* read or needed!
#
#     { rule = { instance = "rofi" }, callback = function(c)
#        if systray_hints_widget and systray_hints_widget.visible then 
#            c.name = "Select item by number key" ; c.border_width = 0; c.floating = true ; 
#            c.x = 1 ; c.y = 1; c.width = 1; c.height = 1 
#        end end  }, --c.opacity = 0 doesn't work here, so resize window & hide borders for now
#
# * I am using the following function in global keys to make this as seamless as possible in my environment
#
#    awful.key({ modkey }, "s", function ()
#        local s
#        awful.screen.connect_for_each_screen(
#            function(screen) if screen.systray then s = screen end 
#        end)
#        if not s.systray.visible then 
#                s.systray.visible = true 
#                gears.timer.delayed_call(function() awful.util.spawn("/home/ryan/scripts/systraykeys/systraykeys.sh") end) 
#                --awful.util.spawn_with_shell("/home/ryan/scripts/systraykeys/systraykeys.sh")
#        else
#                s.systray.visible = false
#                if client.focus and client.focus.instance == "rofi" then
#                     client.focus:kill()
#                end
#        end
#    end, {description="toggle system tray", group="awesome"}),
#
# * The if statement relating to rofi (contained in the last else section of the above) is only relevant if rofi is launched in normal window mode, as the window could be accidentally unfocused and thus needed to be killed. Super+S will never be received by the window manager if using the invisible normal (non-window state) rofi. Because of that, I have modifed the line include the seq command below to include a single letter string (the value of exit key), "s", which will be selected and sent if I hit Super+S (which rofi will read as "S", allow me to hit the same combination key to cancel as I do to start). To disable this, set exit_key value to null or comment it out

exit_key='s'
rofi_theme='/home/ryan/scripts/systraykeys/invisible.rasi'
lua1='/home/ryan/scripts/systraykeys/find_systray_lua' # function: get_systray_geometry()
lua2='/home/ryan/scripts/systraykeys/show_hints_lua' # functions: show_hints() and hide_systray_hints()

[ -f "$lua1" ] && source "$lua1" || { echo "Could not read $lua1"; exit 1; }
[ -f "$lua2" ] && source "$lua2" || { echo "Could not read $lua2"; exit 1; }

deps=( awesome-client iocane rofi xdotool ) #https://github.com/TrilbyWhite/Iocane
for i in "${deps[@]}"; do command -v "$i" >/dev/null || errors=$(printf '%s %s\n' "$errors" "$i" | sed -e 's/^ //'); done
[[ "$errors" ]] && { notify-send -u critical "Veuillez corriger ces dépendances non satisfaites:" "$errors"; exit 1; }

data=$(get_systray_geometry) ; [[ -z "$data" ]] && { echo "Geometery data not found."; exit 0; }

parse_string() { printf '%s\n' "$1" | awk '{$1=""}1' | sed 's|[ "]||g' ; } # 'string "X"' --> 'X'

mouse_location() {
    [[ "$1" == "save" ]] &&
    { awesome-client 'sys_hints_saved_coords = mouse.coords({x = x, y = y})'; return; }
    [[ "$1" == "restore" ]] &&
    awesome-client 'mouse.coords({x = sys_hints_saved_coords.x, y = sys_hints_saved_coords.y}, true)'
}

#hide_systray() { awesome-client 'require("awful.screen").focused().systray.visible = false' >/dev/null ; }
hide_systray() { awesome-client 'sys_hints_hide_systray()' >/dev/null ; }

seq_with_exit_key() { (printf '%s\n%s\n' "$exit_key" "$(seq $1)") ; }

mouse_to_icon() { 
    [[ "$1" == "1" ]] && factor='0' || factor=$(("$1" - 1))
    target_position_x=$(( $first_icon_x + ( "$icon_width" * "$factor" ) )) 
    iocane -c "${target_position_x},${icons_y}" 
}

get_choice() {
    choice=$(seq_with_exit_key "$icon_count" | rofi \
    -kb-custom-1 "Ctrl+l" -kb-custom-2 "Ctrl+o" -dmenu -theme "$rofi_theme" -no-custom -auto-select  2>/dev/null ) 
    # Change -theme "$rofi_theme" and add -normal-window if desired.
    code="$?"
}

IFS=',' read -r -a array <<< "$(parse_string "$data")" 
[[ -n "${array[4]}" ]] || [[ -z "${array[3]}" ]] && { echo "Invalid data: $data"; exit 1; } 
x="${array[0]}" ; y="${array[1]}" ; w="${array[2]}" ; h="${array[3]}" 
#echo "${x}x$y ${w}x$h"
icon_count=$((( $w - ( $w % $h )) / $h + 1 ))
icon_width=$(( $w / $icon_count ))
half_icon=$(( $icon_width / 2 ))
first_icon_x=$(( $x + $half_icon ))
icons_y=$(( $y + $half_icon ))
#echo "Counted $icon_count icons."

show_hints "$x" "$y" "$icon_width" "$icon_count"

mouse_location save

mouse_button='3' #default to right click
get_choice; [[ "$code" == "10" ]] && { mouse_button='1';  get_choice; }
            [[ "$code" == "11" ]] && { unset mouse_button; get_choice; }

awesome-client 'hide_systray_hints()' >/dev/null

[[ "$choice" == "$exit_key" ]] && unset choice
[[ -z "$choice" ]] && { hide_systray; exit 0; }

awesome-client 'client.disconnect_signal("unfocus", sys_hints_kill_rofi)'
#needed only for "-normal-window" mode, if you comment out, then also remove the connect command from $lua2 file

mouse_to_icon "$choice" && 

[[ -n "$mouse_button" ]] && xdotool click "$mouse_button" 

[[ -z "$mouse_button" ]] && sleep 3 #hover only (this is not that reliable)

mouse_location restore
