--TODO: local variables, remove mp.msg, 
--Abandoned ideas:
--      if a string matches both filename and containing directory, or two containing directories in a row, then set that as title


local msg = require 'mp.msg'
local options = require 'options'


---- Script Options ----
local o = {
    --number of containing directories you want to search through
    dir_num = 3,
    include_ms = false,
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
    else then
        parts.ms = math.floor((seconds * 1000) % 1000)
        ret = string.format("%02dm%02ds%03dms", parts.m, parts.s, parts.ms)
    if parts.h > 0 then
        ret = string.format('%dh%s', parts.h, ret)
    end
    return ret
end

local function format_filename(filename)
    filename = filename:gsub('%b()', ''):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('%s+', ' ')
    --%b[] matches a sequence of characters starting with '[' and ending with ']'
    --[%-_] matches all instances of '-' and '_'
    --[%c%p] matches all instances of control characters and punctuation characters
    --%s+ matches space characters, and + modifies it to be any number in a row
    --:gsub('%d.*', '') -- a number and anything following it
    --:gsub('%d+', '') -- one or more repetitions of numbers
    --:gsub('[Ss]%d%d[Ee]', ''):gsub('[Ss]%d[Ee]', '') -- S02E05 destroyer
    if string.find(filename, '%a+%s*[Ss]%d%d%s*[Ee]%d%d%s*%a+') or string.find(filename, '%a+%s*[Ss]%d%s*[Ee]%d%d%s*%a+') then
        filename = filename:gsub('%s*[Ss]%d%d%s*[Ee]%d%d%s*%a+', ''):gsub('%s*[Ss]%d%s*[Ee]%d%d%s*%a+', '')
    end
    -- if there are 1 or more repetitions of letters followed by 0 or 1 spaces followed by 'S' or 's' followed by one or two digits
    -- followed by 0 or 1 spaces followed by 'E' or 'e' followed by two digits followed by 0 or 1 spaces followed by 1 or more repetitions of letters
    -- remove S02E05 and subsequent words
    -- intended to remove episode titles
    for i=1,string.find(filename, '%l%u') do
        filename = filename:gsub('(%l)(%u)', '%1 %2')
        --if there is a lowercase letter followed by an uppercase letter, 
        --put a space in between them
    end
    filename = filename:gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    return filename
end

local function format_save_dir(save_dir)
    save_dir = save_dir:gsub("#", ""):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    msg.info("FORMATTED SAVE DIR:", save_dir)
    if save_dir == '' or save_dir == nil then
        uncategorized = true
    end
    return save_dir
end

local function directory_exists(directory)
    local exists, err = os.rename(directory, directory)
    msg.info("EXISTS?", exists)
    msg.info("ERROR:", err)
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
        msg.info("COUNT 0 TITLE:", temp_title)
        return temp_title
    elseif count > 0 then
        temp_dir = work_dir
        for i=1,count do
            temp_dir = remove_direct(temp_dir)
        end
        temp_title = temp_dir:gsub(".*/", "")
        if (temp_title == 'Anime') or (temp_title == 'qBittorrent') or (temp_title == 'kyler') or (temp_title == 'home') then
            uncategorized = true
            return "uncategorized"
        end
        msg.info("COUNT", count, "TITLE:", temp_title)
        return temp_title
    else
        uncategorized = true
        return "uncategorized"
    end
end

local function validate(temp_title)
    if string.find(temp_title, "^# %[") or string.find(temp_title, "%[DUB+SUB]") or string.find(temp_title, "%[SUB]") then
        msg.info("TITLE VALIDATED")
        temp_title = format_save_dir(temp_title)
        valid = true
        return temp_title
    else
        return "validation_failed"
    end
end

local function get_title()
    work_dir = mp.get_property("working-directory")
    count = 0
    valid = false
    while valid == false and count < o.dir_num do
        temp_title = count_check()
        temp_title = validate(temp_title)
        msg.info("Count:", count, "Valid?", valid)
        count = count + 1
    end
    return temp_title
end

local function construct_filename(arg)
    local time = format_time(mp.get_property("time-pos"))
    local arg_append = arg:sub(1, 1)
    title = get_title()
    msg.info("FINAL TITLE:", title)
    if uncategorized == true or title == "validation_failed" then
        title = format_filename(mp.get_property("filename/no-ext"))
    end
    directory = "/home/kyler/Pictures/mpv/" .. title
    exists = directory_exists(directory)
    if exists == nil then
        mp.commandv('run', 'mkdir', directory)
    end
    filename = title:gsub('%s+', '')
    msg.info("DIRECTORY:", directory)
    filename = time .. "[" .. arg_append .. "]" .. filename .. ".jpg"
    local file = directory .. "/" .. filename
    return file, filename
end

local function btr_ss(arg)
    return function()
        local file, filename = construct_filename(arg)
        msg.info("FILENAME:", file)
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
