--jpeg and jpg don't work with some programs (discord), so its best to use png
--based off clipshot.lua

--cmd = {'xclip', '-sel', 'c', '-t', type, '-i', file} --abreviated, if i wanna use type
--mp.commandv('run', unpack(cmd)) --this works properly, just wanna have a callback thing

local function callback(success, result, error)
    if success == true then
        mp.osd_message("Copied screenshot to clipboard", 1)
    else
        mp.osd_message("Screenshot clipboard failed", 3)
    end
end

local function ss2clip(arg)
    return function()
        --still don't understand why the above return saves this from crumbling, but i'm not arguing
        local file = '/tmp/mpv-screenshot.png'
        local cmd = { 'xclip', '-selection', 'clipboard', '-t', 'image/png', '-i', file }
        mp.commandv('screenshot-to-file', file, arg)
        mp.command_native_async({'run', unpack(cmd)}, callback)
    end
end

--mp.add_key_binding('Ctrl+d', 'ss2clip-subs', ss2clip('subtitles'))
--mp.add_key_binding('Ctrl+Shift+d', 'ss2clip-video', ss2clip('video'))
--mp.add_key_binding('Ctrl+Alt+d', 'ss2clip-window', ss2clip('window'))
mp.register_script_message('ss2clip-subs', ss2clip('subtitles'))
mp.register_script_message('ss2clip-video', ss2clip('video'))
mp.register_script_message('ss2clip-window', ss2clip('window'))
