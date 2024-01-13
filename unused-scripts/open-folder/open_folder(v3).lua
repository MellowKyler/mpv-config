
local msg = require 'mp.msg'

function open_folder()
    local path = mp.get_property('path')
    local cmd
    if string.sub(path,1,4) == "http" then
        cmd = { "xdg-open", path }
    else
        --cmd = { 'nemo', path }
        -- 2 monitors
        -- cmd = { 'setwindow', 'nemo '..'"'..path..'"', "970", "900", "960", "512" }
        -- tv plus 2 monitors
        cmd = { 'setwindow', 'nemo '..'"'..path..'"', "2890", "900", "960", "512" }
    end
    mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
end

-- /home/kyler/.local/bin/setwindow
-- REQUIRES wmctrl AND xdotool
-- setwindow <application + parameters> <horizontal-position> <vertical-position> <horizontal-size> <vertical-size>
-- more precisely: horizontal position pixels from left boundary, vertical position pixels from top
-- 970 900 960 512 is bottom right corner (with two monitors)
-- 2890 900 960 512 is bottom right corner (with tv + two monitors)
-- you have to be EXTREMELY CAREFUL with positioning and adding monitors since it completely switches values
--      even the relative height of a side monitor can shift things
-- wmctrl -Gl lists windows and their geometry

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)