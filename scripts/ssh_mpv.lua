local msg = require 'mp.msg'

local function ssh_mpv()
    return function()
        local path = mp.get_property('path')
        msg.info("Now streaming "..path.." to ssh location specified in ~/.local/ssh-mpv.")
        msg.info("WARNING: This process will hang until video on ssh client finishes.")
        mp.osd_message("Now streaming file through SSH")
        cmd = { 'ssh-mpv', "-r", path }
        mp.command_native_async({ name = "subprocess", playback_only = false, args = cmd , detach = yes})
    end
end

-- mp.add_key_binding('Alt+Shift+s', ssh_mpv())
mp.register_script_message('ssh-mpv', ssh_mpv())