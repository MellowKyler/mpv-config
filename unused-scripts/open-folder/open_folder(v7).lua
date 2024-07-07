
local msg = require 'mp.msg'
local utils = require 'mp.utils'

function open_folder()
    local path = mp.get_property('path')
    local path, path_filename = utils.split_path(path)
    local cmd
    if string.sub(path,1,4) == "http" then
        cmd = { "xdg-open", path }
    else
        -- 'se' = 'south east' = bottom right corner

        --cmd = { 'sww \'nemo "'..path..'"\' se' }

        cmd = { 'sww', 'nemo \"'..path..'\"', 'se' }
        msg.info("Command: " .. table.concat(cmd, " "))

        --everything sucks and this is a bad solution.
        --i can't figure out how to get mpv to be normal so here we are
        -- os.execute('sww \'nemo "'..path..'"\' se')
        -- msg.info("Command: " .. 'sww \'nemo "'..path..'"\' se')
        -- do return end
    end
    mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
end

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)

-- /home/kyler/.local/bin/sww
-- /home/kyler/.local/bin/setwindow