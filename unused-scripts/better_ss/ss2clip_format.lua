--jpeg and jpg don't work with some programs (discord), so its best to use png
--based off clipshot.lua

--cmd = {'xclip', '-sel', 'c', '-t', type, '-i', file} --abreviated, if i wanna use type
--mp.commandv('run', unpack(cmd)) --this works properly, just wanna have a callback thing

local function format_time(seconds)
    --stolen from videoclip.lua
    local parts = {}
    parts.h = math.floor(seconds / 3600)
    parts.m = math.floor(seconds / 60) % 60
    parts.s = math.floor(seconds % 60)
    parts.ms = math.floor((seconds * 1000) % 1000)
    local ret = string.format("%02dm%02ds%03dms", parts.m, parts.s, parts.ms)
    if parts.h > 0 then
        ret = string.format('%dh%s', parts.h, ret)
    end
    return ret
end

local function format_filename(filename)
    filename = filename:gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('%s+', '')
    --%b[] matches a sequence of characters starting with '[' and ending with ']'
    --[%-_] matches all instances of '-' and '_'
    --[%c%p] matches all instances of control characters and punctuation characters
    --%s+ matches space characters, and + modifies it to be any number in a row
    return filename
end

local function construct_filename(arg,mode)
    --if save then jpg; if clip then png
    --if save then use guessit to find title, mkdir for title, save to dir
    --if save guessit fails, just default to main folder
    local time = format_time(mp.get_property("time-pos"))
    local filename = format_filename(mp.get_property("filename/no-ext"))
    local arg_append = arg:sub(1, 1)
    local file
    file = "/tmp/" .. time .. "_" .. filename .. arg_append .. ".png"
    return file
end

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
        --local file = '/tmp/mpv-screenshot.png'
        file = construct_filename(arg)
        local cmd = { 'xclip', '-selection', 'clipboard', '-t', 'image/png', '-i', file }
        mp.commandv('screenshot-to-file', file, arg)
        mp.command_native_async({'run', unpack(cmd)}, callback)
    end
end

--mp.add_key_binding('Ctrl+d', 'ss2clip-subs', ss2clip('subtitles'))
--mp.add_key_binding('Ctrl+Shift+d', 'ss2clip-video', ss2clip('video'))
--mp.add_key_binding('Ctrl+Alt+d', 'ss2clip-window', ss2clip('window'))

