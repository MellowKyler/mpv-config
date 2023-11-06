
local msg = require 'mp.msg'

function open_folder()
    local path = mp.get_property('path')
    local cmd
    if string.sub(path,1,4) == "http" then
        cmd = { "xdg-open", path }
    else
        --cmd = { 'nemo', path }
        cmd = { 'setwindow', 'nemo '..'"'..path..'"', "970", "900", "960", "512" }
    end
    mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
end

-- /home/kyler/.local/bin/setwindow
-- REQUIRES wmctrl AND xdotool
-- setwindow <application + parameters> <horizontal-position> <vertical-position> <horizontal-size> <vertical-size>
-- 970 900 960 512 is bottom right corner
-- wmctrl -Gl lists windows and their geometry

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)