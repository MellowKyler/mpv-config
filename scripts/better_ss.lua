-- Abandoned ideas:
--  +   if a string matches both filename and containing directory, or two containing directories in a row, then set that as title

--Future Options:
--  +   since i'm already getting my custom title for the folder, i'm tempted to use it for the images
--      themselves. and it would definitely be possible to maintain "S01E02" and the like. however,
--      it would be really easy to miss an edge case, and i can't count on every show actually following
--      "S01E02" or even just numbering naming convention (sometimes titles of eps are used for ex.).
--      the result would be me being at a high risk of writing over past files, even with time included.
--      count included would solve, but i can't count on that. once i add redundant, worth revisiting.

-- Try_Get_Title
--  could do a "try_get_title", where i first search containing folders for my custom title
--  and then if i can't find it, "fallback_get_title"
--  re-treads same loop it just went to, but this time going with whatever the containing folder is
--  could also add it as an option

-- Redundant
--  if file already exists, don't overwrite, append "_<num>" or something similar
--  useful if person does not have time or count included
--  also useful if the titles of works in a folder are not unique
--  rare case but think of a multi-season anime where each of the episodes in each season 
--  are titled "0", "1", "2". without count, even files with timestamps can be written over.
--  add as option

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

---- Script Options ----
local o = {
    --custom save directory (be sure to include final "/")
    custom_save_dir = "/home/kyler/Pictures/mpv-scs/",
    --number of containing directories you want to search through
    dir_num = 4,
    --number of digits to trail for filename numbering (used by filename_order and mpv_default)
    count_num = 1,
    --wrap count in brackets in filename
    count_num_brackets = true,
    --include ms in time formatted title
    include_ms = true,
    --include time in the filename
    filename_time = true,
    --wrap time in brackets in filename
    time_brackets = true,
    --include flag (subtitles, video, window) reference in filename
    filename_flag = true,
    --enable custom filename ordering
    fno_opt = true,
    --the order you want the elements to appear in the filename. 
    --      options are: time, flag, title, delim, count, str(<string>)
    --      note: count MUST be at the end to work
    --      delimeter between elements is "_" (underscore)
    filename_order = "title_time_flag",
    --delimeter to be used in filename ordering
    fno_delim = "_",
    --output image filetype
    filetype = ".jpg",
    --enable default mpv behavior
    restore_mpv_default = false,
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

local function file_exists(file)
    local exists = io.open(file, "r")
    if exists ~= nil then exists:close() return true
    else return false
    end
end

local function iterate_filecount(directory,filename_prefix)
    local str_count, add_len, file
    local count = 0
    local finished = false
    if (o.count_num < 1) or (o.count_num > 10) then
        msg.info("ERROR: " .. o.count_num .. " digits entered as count_num option. Excluding count.")
        file = directory .. filename_prefix .. o.filetype
        local filename = filename_prefix .. o.filetype
        return file, filename
    end
    local max_count = ""
    for loop=1,o.count_num do
        max_count = max_count .. "9"
    end
    max_count = tonumber(max_count)
    while finished==false do
        count = count + 1
        str_count = tostring(count)
        add_len = o.count_num-string.len(str_count)
        for loop=1,add_len do
            str_count = "0" .. str_count
        end
        if o.count_num_brackets == true then
            str_count = "[" .. str_count .. "]"
        end
        file = directory .. filename_prefix .. str_count .. o.filetype
        if file_exists(file)==false then finished = true end
    end
    --still on the fence about how i want this to behave. if i want it to just replace max_count img
    --just add "and count<max_count" as a condition to the above while loop
    --i don't like using a "finished" variable above, i'd rather just break, but i need to use it
    --(or something like it) if i don't have the count<max_count there
    --i could just refuse to screenshot at all if above max_count, but i don't like that option
    if count > max_count then msg.info("INFO: Image count above stated max count. Creating image anyway.") end
    local filename = filename_prefix .. str_count .. o.filetype
    return file, filename, str_count
end

local function filename_ordering(filename,arg_append,time)
    local fno_str = ""
    msg.info("INFO: filename_ordering reached")
    for element in o.filename_order:gmatch("[^_]+") do
        if element == "time" then 
            fno_str = fno_str .. time
        elseif element == "flag" then
            fno_str = fno_str .. arg_append
        elseif element == "title" then
            fno_str = fno_str .. filename
        elseif element == "delim" then
            fno_str = fno_str .. o.fno_delim
        elseif element:match("str") then
            fno_str = fno_str .. element:match("%((.-)%)")
        elseif element == "count" then
            local file, filename, count = iterate_filecount(o.custom_save_dir,fno_str)
            fno_str = fno_str .. count
        else
            fno_str = fno_str .. "fail"
            msg.info("FILENAME_ORDERING ERROR [Bad element]: " .. element)
        end
    end
    return fno_str
end

local function construct_filename(arg)
    local time = ""
    if o.filename_time == true then
        time = format_time(mp.get_property("time-pos"))
        if o.time_brackets == true then
            time = "[" .. time .. "]"
        end
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
    local directory = o.custom_save_dir .. title
    local exists = directory_exists(directory)
    if exists == nil then
        mp.commandv('run', 'mkdir', directory)
    end
    local filename = format_filename(mp.get_property("filename/no-ext"))
    filename = filename:gsub('%s+', '')
    if o.fno_opt == true then 
        filename = filename_ordering(filename,arg_append,time) .. o.filetype
    else 
        filename = filename .. arg_append .. time .. o.filetype
    end
    local file = directory .. "/" .. filename
    return file, filename
end

local function mpv_default()
    msg.info("INFO: mpv_default reached")
    local directory = "/home/kyler/Pictures/mpv/"
    local filename_prefix = "mpv-shot"
    local file, filename, count = iterate_filecount(directory,filename_prefix)
    return file, file
end

local function btr_ss(arg)
    return function()
        local file, filename
        if o.restore_mpv_default == true then
            file, filename = mpv_default()
        else
            file, filename = construct_filename(arg)
        end
        mp.osd_message("Screenshot: "..filename, 2)
        msg.info("FILE: "..file)
        mp.commandv('screenshot-to-file', file, arg)
    end
end

--mp.add_key_binding('Ctrl+g', 'btr_ss-subs', btr_ss('subtitles'))
--mp.add_key_binding('Ctrl+Shift+g', 'btr_ss-video', btr_ss('video'))
--mp.add_key_binding('Ctrl+Alt+g', 'btr_ss-window', btr_ss('window'))
mp.register_script_message('btr-ss-subs', btr_ss('subtitles'))
mp.register_script_message('btr-ss-video', btr_ss('video'))
mp.register_script_message('btr-ss-window', btr_ss('window'))
