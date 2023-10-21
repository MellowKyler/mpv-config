
function open_folder()
    local path = mp.get_property('path')
    local cmd = { 'nemo', path }
    mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
end

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)