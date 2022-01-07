#!/usr/bin/env bash
#rts/oarion7

# Displays a numbered hint widget next to each systray icon to allow use of the systray
# via the keyboard. Uses a hidden rofi instance as keygrabber to receive number inputs.
# Uses mouse.coords, iocane, and xdotool to simulate mouse actions because the dude who
# wrote this is crazy, and his other personalities don't know anything about computers.

# https://github.com/TrilbyWhite/Iocane

# Defaults to right-click mode. Left-click & hover via Ctrl+L & Ctrl-O, respectively.

# Tested with awesome v4.3

# See "README" !

script_path="$HOME/scripts/systraykeys/old"
rofi_theme="${script_path}/invisible.rasi"
lua1="${script_path}/find_systray_lua" #bash function get_systray_geometry 
lua2="${script_path}/show_hints_lua" #bash function show_hints() + global lua functions
exit_key='s' #you can always hit Esc to exit rofi, but this can be useful! See README.
hover_time='3' #time to hover in seconds if Ctrl+O

[ -f "$lua1" ] && source "$lua1" || { echo "Could not read $lua1"; exit 1; }
[ -f "$lua2" ] && source "$lua2" || { echo "Could not read $lua2"; exit 1; }

deps=( awesome-client iocane rofi xdotool ) 
for i in "${deps[@]}"; do command -v "$i" >/dev/null || 
errors=$(printf '%s %s\n' "$errors" "$i" | sed -e 's/^ //'); done
[[ "$errors" ]] && { notify-send -u critical \
"Veuillez corriger ces dépendances non satisfaites:" "$errors"; exit 1; }

data=$(get_systray_geometry)
[[ -z "$data" ]] && { echo "Geometery data not found."; exit 0; }

parse_string() { printf '%s\n' "$1" | awk '{$1=""}1' | sed 's|[ "]||g' ; }
# 'string "X"' --> 'X'

mouse_location() {
    [[ "$1" == "save" ]] &&
    { awesome-client 'sys_hints_saved_coords = mouse.coords({x = x, y = y})'; return; }
    [[ "$1" == "restore" ]] &&
    awesome-client 'mouse.coords({x = sys_hints_saved_coords.x, y = sys_hints_saved_coords.y}, true)'
}

hide_systray_hints() { awesome-client 'hide_systray_hints()' >/dev/null ; }

hide_systray() { awesome-client 'sys_hints_hide_systray()' >/dev/null ; }

seq_with_exit_key() { (printf '%s\n%s\n' "$exit_key" "$(seq $1)") ; }

mouse_to_icon() { 
    [[ "$1" == "1" ]] && factor='0' || factor=$(("$1" - 1))
    target_position_x=$(( $first_icon_x + ( "$icon_width" * "$factor" ) )) 
    iocane -c "${target_position_x},${icons_y}" 
}

get_choice() {
    choice=$(seq_with_exit_key "$icon_count" | rofi \
    -kb-custom-1 "Ctrl+l" -kb-custom-2 "Ctrl+o" -dmenu -theme "$rofi_theme" \
    -no-custom -auto-select  2>/dev/null ) 
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

hide_systray_hints

[[ "$choice" == "$exit_key" ]] && unset choice
[[ -z "$choice" ]] && { hide_systray; exit 0; }

mouse_to_icon "$choice" && 

[[ -n "$mouse_button" ]] && xdotool click "$mouse_button" 
[[ -z "$mouse_button" ]] && sleep "$hover_time" #hover only (this is not that reliable)

mouse_location restore
