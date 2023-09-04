-- redundancy
    --local path = mp.get_property('path')
    --local dir, filename = utils.split_path(path)
    --local dir = mp.get_property("working-directory")
    --local video_file = mp.get_property("working-directory") .. "/" .. mp.get_property("filename")
    --mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })

utils = require 'mp.utils'

function open_folder()
    local path = mp.get_property('path')
    args = { 'nemo', path }
    utils.subprocess({ args = args })
end

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)