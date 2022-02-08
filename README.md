Control the AwesomeWM systray from the keyboard using vimium-like number hints. Developed and tested on awesome v4.3. 

We are surprised at the time of this writing that the system tray remains such an obvious bottleneck in the nevertheless ubiquitous fight against mouse-dependency among neckbeards the world over. 

# Overview

When `systray_hints.run()` is executed, a popup widget displays numbers next to each icon in the system tray while keygrabber listens for input. The number entered on the keyboard sends a right click to the corresponding icon and the original position of the mouse pointer is restored. For most programs this opens a context menu the user may then navigate using arrow keys and pressing Return. 

The default option of a right click may be overriden on the fly by pressing the Left or Right arrow key before making a selection for a left or right click, respectively. Alternatively, pressing either the Up or Down key will bypass all clicking and the pointer is simply moved to the location of the selected icon to display its on-hover tooltip, if any.

If ten or more icons are displayed, the function will interpret the "1" key as the first digit of the selection and wait for the second digit, or wait for the Return key. Up to 19 icons are supported.

# Install

    cd ~/.config/awesome
    git clone https://github.com/sawyer07/systray-hints

Add `require("systray-hints")` to rc.lua, and configure as follows. 

# Configuration

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

The `systray_hints.run()` function will automatically unhide the system tray as needed and will return it to its original visiblity state whenever a selection is not made.

If your system tray is always displayed, simply create a keybinding like the following:

    awful.key({ modkey }, "s", function ()

        local s
        awful.screen.connect_for_each_screen(
            function(screen) if screen.systray then s = screen end 
        end)

        systray_hints.run() 

    end, {description="toggle systray hints", group="awesome"}),

# Issues

The ability to obtain the geometry of the system tray is not referenced in the awesome API for a reason; in theory it may occasionally return incorrect data, requiring an additional execution of the keybinding.

This project was previously assembled as a quick hack in the form of a shell script requiring iocane, rofi, and xdotool. It has been rewritten as a native lua module for the latest stable release with no external dependencies. Final testing and clean-up in progress.

While deprecated functions were avoided, we have not yet tested it in the development version.
