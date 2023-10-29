--jpeg and jpg don't work with some programs (discord), so its best to use png
--based off clipshot.lua
--to consider: part of the benefit of having a static name for clipboard images is that it rewrites the previous image.
-- unique filenames destroy this, and it isn't usually that important to have a nicely named copy screenshot
-- plus discord just names it "image.png" so its not like i can see it there either

--cmd = {'xclip', '-sel', 'c', '-t', type, '-i', file} --abreviated, if i wanna use type
--mp.commandv('run', unpack(cmd)) --this works properly, just wanna have a callback thing

local msg = require 'mp.msg'

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

function directory_exists(directory)
    local exists, err = os.rename(directory, directory)
    msg.info("EXISTS?", exists)
    msg.info("ERROR:", err)
    return exists
end

function py_callback(success, result, err)
    msg.info("PY SUCCESS VALUE:", success)
    msg.info("PY RESULT VALUE:", result)
    msg.info("PY ERROR VALUE:", err)
    if result.status == 0 then
        mp.osd_message("Found Title", 1)
    elseif count < 2 then
        count = count + 1
        guessit_title()
    else
        mp.osd_message("Unable to find title.", 3)
    end
end

function count_check()
    if count == 0 then
        search_str = work_dir:gsub(".*/", "")
    elseif count == 1 then
        search_str = mp.get_property("filename/no-ext")
    elseif count == 2 then
        local direct = string.format("/" .. work_dir:gsub(".*/", ""))
        direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
        local temp_dir = work_dir:gsub(direct, "")
        search_str = temp_dir:gsub(".*/", "")
        if (search_str == 'Anime') or (search_str == 'qBittorrent') or (search_str == 'kyler') then
            return
        end
    else
        return
    end
end

function construct_save_filename(title)
    if QUIT == 'true' then
        return
    end
    if title == nil or title == '' then
        title = 'uncategorized'
    end
    directory = "/home/kyler/Pictures/mpv/" .. title
    msg.info("DIRECTORY:", directory)
    exists = directory_exists(directory)
    if exists == true then
        file = directory .. "/" .. time .. "_" .. filename .. arg_append .. ".jpg"
    else
        mp.commandv('run', 'mkdir', directory)
        file = directory .. "/" .. time .. "_" .. filename .. arg_append .. ".jpg"
    end
end

function guessit_title()
    count_check()
    local table = {}
    table.name = "subprocess"
    table.args = {"python", script_dir.."screenshot.py", search_str}
    local cmd = mp.command_native_async(table, py_callback)
    return gi_title
end

function return_guessit_title(gi_title, gi_complete)
    if gi_title == '' then
        gi_complete = 'false'
    end
    if gi_complete == 'true' then
        QUIT = 'true'
    end
    construct_save_filename(gi_title)
end

function call_guessit_title()
    if QUIT == 'true' then
        return
    end
    count_check()
    msg.info("SEARCH_STR:", search_str)
    local table = {}
    table.name = "subprocess"
    table.args = {"python", script_dir.."screenshot.py", search_str}
    local cmd = mp.command_native_async(table, py_callback)
end

local function construct_filename(arg,mode)
    --if save then jpg; if clip then png
    --if save then use guessit to find title, mkdir for title, save to dir
    --if save guessit fails, just default to main folder
    local time = format_time(mp.get_property("time-pos"))
    local filename = format_filename(mp.get_property("filename/no-ext"))
    local arg_append = arg:sub(1, 1)
    local file, directory, exists
    if mode == 'clip' then
        file = "/tmp/" .. time .. "_" .. filename .. arg_append .. ".png"
    elseif mode == 'save' then
        count = 0
        work_dir = mp.get_property("working-directory")
        script_dir = debug.getinfo(1).source:match("@?(.*/)")
        call_guessit_title()
    end
    return file
end

local function callback(success, result, error)
    if success == true then
        mp.osd_message("Copied screenshot to clipboard", 1)
    else
        mp.osd_message("Screenshot clipboard failed", 3)
    end
end

local function ss_2_clip(arg,mode)
    return function()
        file = construct_filename(arg,mode)
        msg.info("MODE:", mode)
        msg.info("FILENAME:", file)
        mp.commandv('screenshot-to-file', file, arg)
        if mode == 'clip' then
            local cmd = { 'xclip', '-selection', 'clipboard', '-t', 'image/png', '-i', file }
            mp.command_native_async({'run', unpack(cmd)}, callback)
        end
    end
end

--mp.add_key_binding('Ctrl+d', 'ss-clip-subs', ss_2_clip('subtitles', 'clip'))
--mp.add_key_binding('Ctrl+Shift+d', 'ss-clip-video', ss_2_clip('video', 'clip'))
--mp.add_key_binding('Ctrl+Alt+d', 'ss-clip-window', ss_2_clip('window', 'clip'))
mp.add_key_binding('Ctrl+g', 'ss-save-subs', ss_2_clip('subtitles', 'save'))
mp.add_key_binding('Ctrl+Shift+g', 'ss-save-video', ss_2_clip('video', 'save'))
mp.add_key_binding('Ctrl+Alt+g', 'ss-save-window', ss_2_clip('window', 'save'))

