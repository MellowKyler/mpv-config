
local msg = require 'mp.msg'

function open_folder()
    local path = mp.get_property('path')
    local cmd
    if string.sub(path,1,4) == "http" then
        cmd = { "xdg-open", path }
    else
        -- 'se' = 'south east' = bottom right corner
        cmd = { 'sww', 'nemo "'..path..'"', 'se' }
    end
    mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
end

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)

-- /home/kyler/.local/bin/sww
-- /home/kyler/.local/bin/setwindow