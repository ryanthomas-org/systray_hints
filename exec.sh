#!/usr/bin/env bash
#rts/oarion7

# See "README" ! Tested with awesome v4.3

script_path="$(dirname $(realpath "$BASH_SOURCE"))"
rofi_theme="${script_path}/invisible.rasi" #key grabber only
exit_key='s' # See "README" !
hover_time='3' #time to hover in seconds if Ctrl+O

deps=( awesome-client iocane rofi xdotool ) 
for i in "${deps[@]}"; do command -v "$i" >/dev/null || 
errors=$(printf '%s %s\n' "$errors" "$i" | sed -e 's/^ //'); done
[[ "$errors" ]] && { notify-send -u critical \
"Veuillez corriger ces dépendances non satisfaites:" "$errors"; exit 1; }

parse_string() { printf '%s\n' "$1" | awk '{$1=""}1' | sed 's|[ "]||g' ; }
# 'string "X"' --> 'X'

awesome-exec() {
    local file
    [[ "$(realpath "$1")" == "$1" ]] && file="$1" || file="${script_path}/${1}"
	[ -f "$file" ] && awesome-client 'dofile("'"$file"'")' ||
    { echo "Could not find ${1}."; exit 1; }
}

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

awesome-exec "core.lua" 
data=$(awesome-client "return found_widget_geometry")

[[ -z "$data" ]] && { echo "Geometery data not found."; exit 1; }

IFS=',' read -r -a array <<< "$(parse_string "$data")" 
[[ -n "${array[4]}" ]] || [[ -z "${array[3]}" ]] && { echo "Invalid data: $data"; exit 1; }

x="${array[0]}" ; y="${array[1]}" ; w="${array[2]}" ; h="${array[3]}" 
icon_count=$((( $w - ( $w % $h )) / $h + 1 ))
icon_width=$(( $w / $icon_count ))
half_icon=$(( $icon_width / 2 ))
first_icon_x=$(( $x + $half_icon ))
icons_y=$(( $y + $half_icon ))

awesome-client 'systray_show_hints('"${x}, ${y}, ${icon_width}, ${icon_count}"')'

mouse_location save

mouse_button='3' #default to right click
get_choice; [[ "$code" == "10" ]] && { mouse_button='1';  get_choice; }
            [[ "$code" == "11" ]] && { unset mouse_button; get_choice; }

hide_systray_hints

[[ "$choice" == "$exit_key" ]] && unset choice
[[ -z "$choice" ]] && { hide_systray; exit 0; }

mouse_to_icon "$choice" && 

[[ -n "$mouse_button" ]] && xdotool click "$mouse_button" 
[[ -z "$mouse_button" ]] && sleep "$hover_time" #hover only (not so reliable)

mouse_location restore
