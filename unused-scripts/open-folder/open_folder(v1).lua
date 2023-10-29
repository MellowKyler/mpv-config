-- redundancy
    --local path = mp.get_property('path')
    --local dir, filename = utils.split_path(path)
    --local dir = mp.get_property("working-directory")
    --local video_file = mp.get_property("working-directory") .. "/" .. mp.get_property("filename")
    --mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })

-- schitzo notes

    --local dir, filename = utils.split_path(path)

    --have to use command_native, command_native_async, or utils.subprocess
    --can't use mp.command or mp.commandv because native types have to be used to run nemo
    --shouldn't use utils.subprocess because 
    --1) it's deprecated 2) it's lazy 3) it stops nemo when the process ends

    --local path = mp.get_property('path')
    --local cmd = { 'nemo', path }
    --mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = cmd })

    --utils = require 'mp.utils'
    --local path = mp.get_property('path')
    --cmd = { 'nemo', path }
    --utils.subprocess({ args = cmd })
    
    --notes on optional command_native parameters:
    --capture_stdout (MPV_FORMAT_FLAG)
    --Capture all data the process outputs to stdout and return it once the process ends (optional, default: no).
    --shouldn't need
    --playback_only (MPV_FORMAT_FLAG)
    --Boolean indicating whether the process should be killed when playback of the current playlist entry terminates (optional, default: true). If enabled, stopping playback will automatically kill the process, and you can't start it outside of playback.
    --should need? but it actually lasts without it in my testing. weird.

    --Note
    --The subprocess will always be terminated on player exit if it wasn't started in detached mode, even if playback_only is false.
    --Warning
    --Don't forget to set the playback_only field to false if you want the command to run while the player is in idle mode, or if you don't want the end of playback to kill the command.
    --These seem blatantly contradictory at first glance, but i think it actually makes sense. 
    --obviously the mpv subprocess is terminated when mpv exits, but the processes started by the subprocess won't be
    --<strikethrough>honestly its just confusing that utils.subprocess ended nemo, since it does set playback_only to false<strikethrough>
    --actually, it just renames the cancellable field to playback_only, whatever that means lol

    --you have to name it subprocess for it to work

    --mp.command_native_async works, but has this error when running
    --[open_folder] Lua error: mp.defaults:640: attempt to call local 'cb' (a nil value)
    --which i don't feel like figuring out, so i'll just use mp.command_native
    -- local path = mp.get_property('path')
    -- local cmd = { 'nemo', path }
    -- mp.command_native_async({ name = "subprocess", playback_only = false, args = cmd }, callback)

    --async command that's even worse lol
    -- local table = {}
    -- table.name = "subprocess"
    -- table.playback_only = "false"
    -- table.args = { 'nemo', path }
    -- mp.command_native_async(table)

utils = require 'mp.utils'

function open_folder()
    local path = mp.get_property('path')
    cmd = { 'nemo', path }
    utils.subprocess({ args = cmd })
end

--mp.add_key_binding("Ctrl+e", "open-folder", open_folder)
mp.register_script_message("open-folder", open_folder)