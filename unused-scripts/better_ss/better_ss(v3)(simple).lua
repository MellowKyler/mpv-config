-- simple version of better_ss
-- simple because it exclusively relies upon the file itself for naming

-- pros:
-- no containing folders required, doesn't require my naming structure
-- makes for nicer naming in some cases (specifically series with multiple seasons), and reduced code complexity

-- cons:
-- but crucially relies upon there being the series title in the name
-- titles from torrents are often the japanese title, with my folders I'm guaranteed the name I intended
-- less backups in case of poor name

-- videos without a title name in the filename will still be still be saved
-- if the formatted title is "" the file gets saved to "/home/kyler/Pictures/mpv-scs//filename.jpg"
-- the "//" gets treated as "/" and the file is saved to the mpv-scs folder

-- could easily bring back the functionality of directory titles by:
-- if title = "" then get_title() end
-- and pasting everything back in from better_ss(v2)

-- overall, this is a more risky script that might bloat things up with slightly different titles
-- or simply back to square one with sorting files back into folders
-- will try it out for a bit, see what I think

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

---- Script Options ----
local o = {
    --include ms in time formatted title
    include_ms = false,
    --include time in the filename
    filename_time = true,
    --include flag (subtitles, video, window) reference in filename
    filename_flag = true,
    filetype = ".jpg",
}
options.read_options(o)
------------------------

local function format_time(seconds)
    local parts = {}
    parts.h = math.floor(seconds / 3600)
    parts.m = math.floor(seconds / 60) % 60
    parts.s = math.floor(seconds % 60)
    local ret
    if o.include_ms == false then
        ret = string.format("%02dm%02ds", parts.m, parts.s)
    else
        parts.ms = math.floor((seconds * 1000) % 1000)
        ret = string.format("%02dm%02ds%03dms", parts.m, parts.s, parts.ms)
    end
    if parts.h > 0 then
        ret = string.format('%dh%s', parts.h, ret)
    end
    return ret
end

local function format_filename(filename)
    filename = filename:gsub('%b()', ''):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('%s+', ' ')
    if string.find(filename, '%a+%s*[Ss]%d%d%s*[Ee]%d%d%s*%a+') or string.find(filename, '%a+%s*[Ss]%d%s*[Ee]%d%d%s*%a+') then
        filename = filename:gsub('%s*[Ss]%d%d%s*[Ee]%d%d%s*%a+', ''):gsub('%s*[Ss]%d%s*[Ee]%d%d%s*%a+', '')
    end
    local lower_upper = string.find(filename, '%l%u')
    if lower_upper ~= nil then
        for i=1,lower_upper do
            filename = filename:gsub('(%l)(%u)', '%1 %2')
            -- consider changing this to '%1-%2' so directories don't have spaces
        end
    end
    filename = filename:gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    --consider filename = lower(filename) so directories don't have caps (important to do this last since earlier functionality relies on uppercase)
    return filename
end

local function directory_exists(directory)
    local exists, err = os.rename(directory, directory)
    return exists
end

local function time()
    local time = ""
    if o.filename_time == true then
        time = format_time(mp.get_property("time-pos"))
    end
    return time
end

local function arg_append(arg)
    local arg_append = ""
    if o.filename_flag == true then
        arg_append = string.format('[' .. arg:sub(1, 1) .. ']')
    end
    return arg_append
end

local function name()
    local filename = format_filename(mp.get_property("filename/no-ext"))
    local title = filename:gsub('%d', ''):gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    filename = filename:gsub('%s+', '')
    return filename, title
end

local function directory(title)
    local directory = "/home/kyler/Pictures/mpv-scs/" .. title
    local exists = directory_exists(directory)
    if exists == nil then
        mp.commandv('run', 'mkdir', directory)
    end
    return directory
end

local function construct_filename(arg)
    local time = time()
    local arg_append = arg_append(arg)
    local filename, title = name()
    local directory = directory(title)
    
    filename = time .. arg_append .. filename .. o.filetype
    local file = directory .. "/" .. filename
    return file, filename
end

local function btr_ss(arg)
    return function()
        local file, filename = construct_filename(arg)
        mp.osd_message("Screenshot: "..filename, 3)
        mp.commandv('screenshot-to-file', file, arg)
    end
end

--mp.add_key_binding('Ctrl+g', 'btr_ss-subs', btr_ss('subtitles'))
--mp.add_key_binding('Ctrl+Shift+g', 'btr_ss-video', btr_ss('video'))
--mp.add_key_binding('Ctrl+Alt+g', 'btr_ss-window', btr_ss('window'))
mp.register_script_message('btr-ss-subs', btr_ss('subtitles'))
mp.register_script_message('btr-ss-video', btr_ss('video'))
mp.register_script_message('btr-ss-window', btr_ss('window'))
