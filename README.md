Shell script to control the awesome wm systray from the keyboard using vimium-like number hints. Written for awesome v4.3. 

When "exec.sh" is executed, the included files are referenced to display an interactive number hint widget next to each icon in the system tray. The number entered on the keyboard sends a right click to the corresponding icon. (To left-click instead, press Ctrl+L before selecting a number. Ctrl+O will do the same for a "hovering" functionality, but it may be less reliable.) The mouse pointer is then restored to its original position.

The script uses "awesome-client" to load and call functions from the included lua file. A consequent limitation is the inability to grab data in the shell from lua return statements directly. My approach therefore requires some use of global variables and functions. 

We also make use of rofi to function as a keygrabber to receive number inputs with the "-auto-select" flag so that hitting "return" is never necessary except when there are more than 9 icons to choose from. Finally, mouse.coords, iocane (https://github.com/TrilbyWhite/Iocane), and xdotool are used to simulate mouse actions.

Because the number hints are displayed in the form of a popup widget, visibility of rofi is redundant. An "invisible" theme file has been provided, and assumes a compositor is running. This proved more reliable for us in our tests than enabling rofi's -normal-window mode and attempting to hide the window in rules, and the temporary reassignment of key commands in awesome was one of the relevant matters beyond our immediate grasp. It may also be possible in place of widgets to configure rofi to display options with fixed widths that could be tied to the geometry of the systray icons, but this would become unintuitive in any use case where multi-digit numbers are necessary.

We have been using the following function in global keys to make this as seamless as possible in our environment, where the systray is always hidden by default until needed and our script thus hides it whenever escaped.

    awful.key({ modkey }, "s", function ()

        local s
        awful.screen.connect_for_each_screen(
            function(screen) if screen.systray then s = screen end 
        end)
        if not s.systray.visible then 
                s.systray.visible = true 
                gears.timer.delayed_call(function() 
                     awful.util.spawn_with_shell("$HOME/scripts/systray-hints/exec.sh") 
                end) 
        else
                s.systray.visible = false
                if client.focus and client.focus.instance == "rofi" then
                     client.focus:kill()
                end
        end

    end, {description="toggle system tray", group="awesome"}),
    
Here one key combination is used to hide the systray if it is visible, or if not, to display the systray along with the number hints. Sometimes one may wish only to see what is running in the systray rather than actually click on anything in it, immediately pressing the same key combination to hide it. However, "Super+S" will never be received by the window manager when rofi (in its normal, non-windowed state) is in use. The "exit_key" variable, which should be assigned a single letter as its value, is added by the script to the list of valid options, which are themselves all numbers. The default value is "s" to pair with "Super+S". If we hit Super+S while rofi is active, rofi will read it as simply "s", which later triggers the script to clear the value. This allows us to hit the same combination key to cancel/hide the systray and hints as we do to display them. To disable this, exit_key can be set to null or simply commented out. Rofi can always be escaped via the "Escape" key, which should yield exactly the same result.

Additionally, note that obtaining the geometry of the system tray is not directly references in the awesome API for a reason; sometimes it is incorrect and requires a second execution to display correctly. If the same shortcut key is elected to display systray hints as well as to hide them, and one encounters a situation where several icons appear but only one or two hints, a series of two additional taps of the key shortcut is usually sufficient to resolve it right away.



