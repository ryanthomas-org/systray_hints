Shell script to control the awesome wm systray from the keyboard using vimium-like number hints. Developed and tested on awesome v4.3. 

# Overview

When "exec.sh" is executed, the included files are referenced to display an interactive number hint widget next to each icon in the system tray. The number entered on the keyboard sends a right click to the corresponding icon. (To left-click instead, press Ctrl+L before selecting a number. Ctrl+O will do the same for a "hovering" functionality, but it may be less reliable.) The mouse pointer is then restored to its original position.

# Details

The script uses "awesome-client" to load and call functions from the included lua file. A consequent limitation is the inability to grab data in the shell from lua return statements directly. My approach therefore requires some use of global variables and functions. 

We also make use of rofi to function as a keygrabber to receive number inputs with the "-auto-select" flag so that hitting "return" is never necessary except when there are more than 9 icons to choose from. Finally, awesome's built-in mouse module, [iocane](https://github.com/TrilbyWhite/Iocane), and xdotool are used to simulate mouse actions.

Because the number hints are displayed in the form of a popup widget, visibility of rofi is redundant. An "invisible" theme file has been provided, and assumes a compositor is running. This proved more reliable for us in our tests than enabling rofi's -normal-window mode and attempting to hide the window in rules, and the temporary reassignment of key commands in awesome through the keygrabber module was out of our immediate reach. 

# Usage / Configuration

If the system tray is normally visible in your environment, it should be sufficient to run the script from a terminal or call it from `awful.util.spawn_with_shell` in a global keybinding. You will likely want to comment out the `hide` variable, or else your systray will disappear when you escape out of hints mode.

On our system, we hide the systray until it is needed, and thus a single keybinding is configured to display it and run this script at once. After interacting with the system tray through the script, the system tray will normally remain visible until the same keybinding is run again to hide it. 

    awful.key({ modkey }, "s", function ()

        local s
        awful.screen.connect_for_each_screen(
            function(screen) if screen.systray then s = screen end 
        end)
        if not s.systray.visible then 
                s.systray.visible = true 
                gears.timer.delayed_call(function() 
                awful.util.spawn_with_shell("$HOME/scripts/systray-hints/exec.sh") end) 
        else
                s.systray.visible = false
                if client.focus and client.focus.instance == "rofi" then
                     client.focus:kill()
                end
        end

    end, {description="toggle system tray", group="awesome"}),

One may sometimes wish to run the above keybinding and, without making a selection, immediately press the same key combination a second time to cancel. The escape key suits this purpose efficiently. However, when rofi is in use, our keybinding will never be received by the window manager; the super key will be ignored, and the key pressed simultaneously will be entered into rofi as input.

The "exit_key" variable should thus be assigned as its value the same character to which the script is bound, which should not be a number, and in our case is "S" by default to match our above example keybinding "Super+S." In the keybinding function provided, this allows one to press "Super+S" to display the systray with hints and press it again to cancel. 

Moreover, only modifiers that rofi ignores should be used for the keybinding. This allows for the Super and/or Alt keys, but not the Control key, the functions of which have been noted above. 

# Issues

The ability to obtain the geometry of the system tray is not referenced in the awesome API for a reason; sometimes it is incorrect and requires a second execution to display correctly. Occasionally one encounters a situation where several icons appear but only one or two hints display. In the example configuration provided, a series of two quick taps of the shortcut key is usually sufficient to resolve it right away.

# To Do (Dependencies)

This script as-is requires iocane, rofi, and xdotool to function. This can no doubt be minimized. It should be re-written without the shell layer, making use of the keygrabber and mouse modules. The current version also contains "bashisms," which some people find offensive.

As a more wm-neutral alternative, it may also be possible in place of widgets to configure rofi to display options with fixed widths tied to the geometry of the systray icons, but this would become unintuitive in any use case where multi-digit numbers become necessary. One may also elect to incorporate this functionality directly into a standalone systray application such as [trayer-srg](https://github.com/sargon/trayer-srg).

We are surprised at the time of this writing that the system tray remains such an obvious bottleneck in the nevertheless ubiquitous fight against mouse-dependency among neckbeards the world over. 