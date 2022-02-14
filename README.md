We are surprised at the time of this writing that the system tray remains such an obvious bottleneck in the nevertheless ubiquitous fight against mouse-dependency among neckbeards the world over. We present accordingly: systray_hints.

# Overview

When `systray_hints.run()` is executed, a popup widget displays a number next to each icon in the system tray while keygrabber listens for input. The number entered on the keyboard sends a right click to the corresponding icon and the original position of the mouse pointer is restored. For most programs this opens a context menu the user may then navigate using arrows and the Return key. To cancel, submit any invalid entry; in practice this includes the Escape key as well as whatever keybinding was configured to launch the function.

The configured mouse button (right-click by default) can be overridden before entering a selection by pressing the Left or Right arrow key for a left or right click, respectively. Alternatively, pressing the Up arrow key will substitute hovering for clicking to display a given icon's tooltip, if any. 

If ten or more icons are displayed, the keygrabber will interpret the "1" key as the first digit of the selection and wait for the second digit, or for the Return key to select the first icon. Up to 19 icons are supported.

# Install

    cd ~/.config/awesome
    git clone https://github.com/ryanthomas-org/systray_hints

Add `systray_hints = require("systray_hints")` to rc.lua. Note this may work better at the end of the file.

# Configuration

Configure by overriding systray_hints table values after the require statement. For example, set the font, left-click by default, and redefine the keybindings for left-click [1], hover [2], and right-click [3].

    systray_hints                = require("systray_hints")
    systray_hints.font           = "Iosevka Bold 16"
    systray_hints.default_button = 1
    systray_hints.mouse_buttons  = { "h", "j", "l" }

By default, systray_hints looks for `s.systray` in `s.mywibox`. If your systray widget or wibox has a different name, set `systray_hints.systray` or `systray_hints.wibox` accordingly.

If the system tray is normally hidden in your environment and toggled as needed with a keybinding, you can replace that keybinding with something like this:

    awful.key({ modkey }, "s", function ()

        local s
        awful.screen.connect_for_each_screen(
            function(screen) if screen.systray then s = screen end 
        end)

        if s.systray.visible then
            s.systray.visible = false
        else
            systray_hints.run()
        end

    end, {description="toggle systray with hints", group="awesome"}),

The `systray_hints.run()` function will automatically unhide the system tray as needed and will return it to its original visiblity state whenever a selection is not made, such as when the key combination is pressed again.

If your system tray is always displayed, simply create a keybinding like the following:

    awful.key({ modkey }, "s", function ()

        local s
        awful.screen.connect_for_each_screen(
            function(screen) if screen.systray then s = screen end 
        end)

        systray_hints.run() 

    end, {description="toggle systray hints", group="awesome"}),

# Theme

Set custom colors in `theme.lua` as desired:

    theme.systray_hints_font             = "Iosevka Bold 16"
    theme.systray_hints_fg               = "#fdf6e3" 
    theme.systray_hints_bg               = "#55465a" 
    theme.systray_hints_bg_highlight     = "#aa53aa" 
    theme.systray_hints_bg_highlight_alt = "#426f5a"
    theme.systray_hints_border           = "#fdf6e333"

# Issues

The ability to obtain the geometry of the system tray is not referenced in the awesome API for a reason; in theory it may occasionally return incorrect data, requiring an additional execution of the keybinding.

This project was previously assembled as a quick hack in the form of a shell script requiring iocane, rofi, and xdotool. It has been rewritten as a native lua module for the latest stable release with no external dependencies. While deprecated functions were avoided, we have not yet tested it in the development version.
