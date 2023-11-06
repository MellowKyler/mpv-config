function open_folder()
    local path = mp.get_property('path')
    local cmd
    if string.sub(path,1,4) == "http" then
        cmd = { "xdg-open", path }
    else
        cmd = { 'nemo', path }
    end
    mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
end

--notes: xdg-open will opens links, directories, files, everything
--so i had hopes i could use it to launch both links and directories in a glorius oneliner
--but alas i need to split the directory and filename and open only the directory
--(which breaks links anyway)
--otherwise it will actually just open a new session of the same video lol
--also, i like when i launch with nemo that it highlights the exact video 
--i could mimic and make more interoperable by doing xdg-mime query default inode/directory
--and then stripping things but 1) thats still not guarantee 
--and fuck you this is for me <3
local utils = require 'mp.utils'
function open_folder()
    local directory, filename = utils.split_path(mp.get_property('path'))
    mp.command_native({ name = "subprocess", playback_only = false, args = { "xdg-open", directory } })
end

function open_folder()
    mp.command_native({ name = "subprocess", playback_only = false, args = { "xdg-open", mp.get_property('path') } })
end

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)