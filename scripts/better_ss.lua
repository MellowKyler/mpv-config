-- Abandoned ideas:
--      options-defined order of variables in filename
--      if a string matches both filename and containing directory, or two containing directories in a row, then set that as title

-- Current ideas:
--  could do a "try_get_title", where i first search containing folders for my custom title
--  and then if i can't find it, "fallback_get_title"
--  re-treads same loop it just went to, but this time going with whatever the containing folder is
--  could also add it as an option


local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'


---- Script Options ----
local o = {
    --number of containing directories you want to search through
    dir_num = 4,
    --include ms in time formatted title
    include_ms = false,
    --include time in the filename
    filename_time = true,
    --include flag (subtitles, video, window) reference in filename
    filename_flag = true,
    --the order you want the elements to appear in: options are time, flag, title
    --filename_order = "time_flag_title",
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

local function format_save_dir(save_dir)
    save_dir = save_dir:gsub("#", ""):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    if save_dir == '' or save_dir == nil then
        uncategorized = true
    end
    return save_dir
end

local function directory_exists(directory)
    local exists, err = os.rename(directory, directory)
    return exists
end

local function remove_direct(path)
    local direct = string.format("/" .. path:gsub(".*/", ""))
    direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
    local temp_dir = path:gsub(direct, "")
    return temp_dir
end

local function count_check()
    if count == 0 then
        temp_title = work_dir:gsub(".*/", "")
    elseif count > 0 then
        temp_dir = work_dir
        for i=1,count do
            temp_dir = remove_direct(temp_dir)
        end
        temp_title = temp_dir:gsub(".*/", "")
    end
    if (temp_title == 'Anime') or (temp_title == 'qBittorrent') or (temp_title == 'kyler') or (temp_title == 'home') or 
            (temp_title == '.etc') or (temp_title == '.delay') or (temp_title == '.short') or (temp_title == 'Completed') or
            (temp_title == 'mnt') or (temp_title == '# Short') then
        uncategorized = true
        return "uncategorized"
    end
    return temp_title
end

local function validate(temp_title)
    if string.find(temp_title, "^# %[") or string.find(temp_title, "%[DUB+SUB]") or string.find(temp_title, "%[SUB]") then
        temp_title = format_save_dir(temp_title)
        valid = true
        return temp_title
    else
        return "validation_failed"
    end
end

local function get_title()
    work_path = mp.get_property('path')
    work_dir, path_filename = utils.split_path(work_path)
    -- remove the trailing '/' in work_dir
    work_dir = work_dir:sub(1, -2)
    count = 0
    valid = false
    while valid == false and count < o.dir_num do
        temp_title = count_check()
        if uncategorized == true then break end
        msg.info("TEMP_TITLE: "..temp_title)
        temp_title = validate(temp_title)
        count = count + 1
    end
    return temp_title
end

local function construct_filename(arg)
    local time = ""
    if o.filename_time == true then
        time = format_time(mp.get_property("time-pos"))
    end
    local arg_append = ""
    if o.filename_flag == true then
        arg_append = string.format('[' .. arg:sub(1, 1) .. ']')
    end
    local title = get_title()
    --if uncategorized == true or title == "validation_failed" then
    if valid == false or uncategorized == true then
        title = format_filename(mp.get_property("filename/no-ext"))
        title = title:gsub('%d', ''):gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    end
    local directory = "/home/kyler/Pictures/mpv-scs/" .. title
    local exists = directory_exists(directory)
    if exists == nil then
        mp.commandv('run', 'mkdir', directory)
    end
    local filename = format_filename(mp.get_property("filename/no-ext"))
    filename = filename:gsub('%s+', '')
    --filename = o.filename_order[1] .. o.filename_order[2] .. o.filename_order[3] .. o.filetype
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
