-- Abandoned ideas:
--  +   if a string matches both filename and containing directory, or two containing directories in a row, then set that as title

--Future Options:
--  +   clean up validate_title() and count_check()
--      have options where user sets table of strings to loop through.
--      generally a sloppy and poor job. revamp and basically all the comments above here are solved.
--      don't use globals if you can help it. very sloppy. look at everything that calls get_title()
--  +   modularize construct_filename?
--  +   add EP01 logic to S01E02

-- Try_Get_Title
--  could do a "try_get_title", where i first search containing folders for my custom title
--  and then if i can't find it, "fallback_get_title"
--  re-treads same loop it just went to, but this time going with whatever the containing folder is
--  could also add it as an option
--  i kinda did this, but i feel my execution was poor. leaving this note as a reminder to revisit.

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

---- Script Options ----
local o = {
    -- // GENERAL // --
    --output image filetype
    filetype = ".jpg",
    --enable default mpv behavior
    restore_mpv_default = false,

    -- // DIRECTORY // --
    --custom save directory (do NOT include trailing "/") (not used by mpv_default)
    custom_save_dir = "/home/kyler/Pictures/mpv-scs",
    --directory to use for mpv_default (default is "home/<user>/Pictures/mpv")
    default_save_dir = "/home/kyler/Pictures/mpv-scs/.mpv",
    
    -- // TITLE // --
    --number of containing directories you want to search through for custom title
    dir_num = 4,
    --delimiter to replace spaces in title. set to "" for blank.
    title_delim = " ",
    --coverts title to uppercase
    title_upper = false,
    --coverts title to lowercase (if both upper and lower are true, lower takes precedence)
    title_lower = false,

    -- // FILENAME // --
    -- default filename is 
    -- /// General /// --
    --uses the title value as a filename. useful when custom title (ex. from [DUB+SUB])
    --beware: it will maintain upper/lowercase and non-space delimiters used in title
    use_title_as_filename = false,
    --delimiter to replace spaces in filename. set to "" for blank.
    filename_delim = "",
    --coverts filename to uppercase
    filename_upper = false,
    --coverts filename to lowercase (if both upper and lower are true, lower takes precedence)
    filename_lower = false,

    -- /// Season & Episode /// --
    --sets the filename to only season and episode (ex. "S01E02")
    only_szn_ep = true,
    --removes season and episode from filename
    no_szn_ep = false,

    -- /// Count /// --
    --number of digits to trail for filename numbering (used by custom_filename)
    --mpv_default will not respect this field
    count_len = 3,
    --wrap count between two user inputted characters in filename. leave "" to disable wrap.
    --mpv_default will not respect this field
    count_wrap = "[]",

    -- /// Duplicate /// --
    --if enabled, will append an iterating number to filename to avoid overwriting
    duplicate_check_enabled = true,
    --delimiter to be used when duplicate images are found. set to "" for blank.
    duplicate_delim = " ",
    --wrap duplicate count between two user inputted characters in filename. leave "" to disable wrap.
    duplicate_count_wrap = "()",

    -- /// Time /// --
    --include ms in time formatted filename
    include_ms = true,
    --wrap time between two user inputted characters in filename. leave "" to disable wrap.
    time_wrap = "[]",

    -- /// Argument /// --
    --wrap arg between two user inputted characters in filename. leave "" to disable wrap.
    --arg is the first letter of the screenshot mode selected. s is subtitles, v is video, w is window
    arg_wrap = "[]",

    -- /// Custom Filename /// --
    --default filename is StrippedVideoFilename[argument]time.jpg or title_arg_time
    --enable custom custom filenaming
    cf_opt = true,
    --custom filename
    --      options are: time, arg, title, delim, count, str(<string>)
    --      note: count MUST be at the end to work
    --      delimiter between elements is "_" (underscore)
    custom_filename = "title_time_arg",
    --delim value in o.custom_filename
    cf_delim = "_",

    valid_titles = {"^# %[", "%[DUB%+SUB%]", "%[SUB%]"},
    invalid_titles = {'Anime', 'qBittorrent', 'kyler', 'home', '.etc', '.delay', '.short', 'Completed', 'mnt','# Short'},
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

--replace_str replaces the letters of a filename while maintaining szn_ep
local function format_filename(filename, replace_str)
    local szn_ep = string.match(filename, '[Ss]%d%d?[Ee]%d%d?')
    filename = filename:gsub('%b()', ''):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('^(%s*)', ''):gsub('(%s*)$', '')--:gsub('%s+', ' ')
    if replace_str ~= "" then
        if szn_ep ~= nil then filename = replace_str .. szn_ep
        else filename = replace_str
        end
    end
    if o.only_szn_ep and szn_ep ~= nil then filename = szn_ep end
    if o.no_szn_ep and szn_ep ~= nil then filename = filename:gsub('%s*[Ss]%d%d?[Ee]%d%d?%s*', '') end
    --removes duplicate spaces, replaces spaces with delimiter, removes spaces at the start, and spaces at the end.
    filename = filename:gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    return filename
end

local function format_valid_dir(save_dir)
    save_dir = save_dir:gsub("#", ""):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    if save_dir == '' or save_dir == nil then
        uncategorized = true
    end
    return save_dir
end

local function directory_exists(directory)
    local exists, err = os.rename(directory, directory)
    if exists == nil then
        mp.commandv('run', 'mkdir', directory)
    end
end

local function remove_direct(temp_dir)
    msg.info("INFO: Arrived at remove_direct")
    msg.info("INFO: path is "..temp_dir)
    local direct = string.format("/" .. temp_dir:gsub(".*/", ""))
    msg.info("INFO: direct is "..direct)
    direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
    msg.info("INFO: direct is "..direct)
    local temp_dir = temp_dir:gsub(direct, "")
    msg.info("INFO: temp_dir is "..temp_dir)
    return temp_dir
end

local function invalid_title(temp_title)
    for key, value in ipairs(o.invalid_titles) do
        if temp_title == value then msg.info("INVALID TITLE: "..temp_title) return true end
    end
    return false
end

local function count_check(temp_dir, count)
    --if count == 0 then
        --temp_title = work_dir:gsub(".*/", "")
    --elseif count > 0 then
    --local temp_dir = work_dir
    for i=0,count do
        temp_dir = remove_direct(temp_dir)
    end
    temp_title = temp_dir:gsub(".*/", "")
    --end
    --local invalid = invalid_title(temp_title)
    return temp_title, invalid
end

local function validate_title(temp_title)
    for key, value in ipairs(o.invalid_titles) do
        if temp_title == value then msg.info("INVALID TITLE: "..temp_title) return false end
    end
    for key, value in ipairs(o.valid_titles) do
        if string.find(temp_title, value) then
            --temp_title = format_valid_dir(temp_title)
            --valid = true
            msg.info("VALIDATE_TITLE success: "..temp_title)
            return true
        end
    end
    -- else
    --     msg.info("VALIDATE_TITLE failed: "..temp_title)
    --     return "validation_failed"
    -- end
    -- if string.find(temp_title, "^# %[") or string.find(temp_title, "%[DUB%+SUB%]") or string.find(temp_title, "%[SUB%]") then
    --     temp_title = format_valid_dir(temp_title)
    --     valid = true
    --     msg.info("VALIDATE_TITLE success: "..temp_title)
    --     return temp_title
    -- else
    --     msg.info("VALIDATE_TITLE failed: "..temp_title)
    --     return "validation_failed"
    -- end
end

local function get_title()
    local work_path = mp.get_property('path')
    local work_dir, path_filename = utils.split_path(work_path)
    -- remove the trailing '/' in work_dir
    work_dir = work_dir:sub(1, -2)
    local count = 0
    local invalid, temp_title, valid
    --valid = false
    --valid == false and 
    while count < o.dir_num-1 do
        temp_title = count_check(work_dir, count)
        --, invalid
        --if invalid == true then valid = false break end
        --if uncategorized == true then break end
        --msg.info("TEMP_TITLE: "..temp_title)
        valid = validate_title(temp_title)
        if valid == true then 
            temp_title = format_valid_dir(temp_title)
            msg.info("VALID: "..temp_title)
        end
        if valid ~= nil then msg.info("QUITTING WITH VALID STATUS: "..tostring(valid)) break end
        --if valid == true then invalid = false break end
        count = count + 1
        --valid = nil
        --invalid = nil
    end
    --msg.info("GET_TITLE returns: "..temp_title)
    return temp_title, valid
end

local function file_exists(file)
    local exists = io.open(file, "r")
    if exists ~= nil then exists:close() return true
    else return false
    end
end

local function iterate_filecount(directory,filename_prefix,count_len,delimiter,wrap)
    msg.info("INFO: Function iterate_filecount reached")
    msg.info("INFO: iterate_debug: "..directory)
    msg.info("INFO: iterate_debug: "..directory..", "..filename_prefix..", "..count_len..", "..delimiter..", "..wrap)
    local str_count, add_len, file
    local count = 0
    if (count_len < 1) or (count_len > 9) then
        msg.info("ERROR: " .. count_len .. " digits entered as count_len option. Excluding count.")
        file = directory .. "/" .. filename_prefix .. o.filetype
        local filename = filename_prefix .. o.filetype
        return file, filename
    end
    local max_count = ""
    for loop=1,count_len do
        max_count = max_count .. "9"
    end
    max_count = tonumber(max_count)
    --msg.info("INFO: max_count set to "..max_count)
    while true do
        count = count + 1
        str_count = tostring(count)
        add_len = count_len-string.len(str_count)
        for loop=1,add_len do
            str_count = "0" .. str_count
        end
        str_count = wrap:sub(1,1) .. str_count .. wrap:sub(2,2)
        file = directory .. "/" .. filename_prefix .. delimiter .. str_count .. o.filetype
        if file_exists(file)==false then break end --msg.info("INFO: file "..file.." does not already exist. Exiting loop...")
    end
    --still on the fence about how i want this to behave. if i want it to just replace max_count img
    --just add "and count<max_count" as a condition to the above while loop
    --i could just refuse to screenshot at all if above max_count, but i don't like that option
    if count > max_count then msg.info("INFO: Image count above maximum specified count_len ("..count_len.."). Creating image anyway.") end
    local no_ext = filename_prefix .. delimiter .. str_count
    local filename = no_ext .. o.filetype
    --msg.info("INFO: Exiting iterate_filecount with... file: "..file..", filename: "..filename..", no_ext: "..no_ext..", str_count: "..str_count)
    return file, filename, no_ext, str_count
end

local function custom_filenaming(filename,arg_append,time)
    local cf_str = ""
    msg.info("INFO: custom_filenaming function reached")
    for element in o.custom_filename:gmatch("[^_]+") do
        if element == "time" then 
            cf_str = cf_str .. time
        elseif element == "arg" then
            cf_str = cf_str .. arg_append
        elseif element == "title" then
            cf_str = cf_str .. filename
        elseif element == "delim" then
            cf_str = cf_str .. o.cf_delim
        elseif element:match("str") then
            cf_str = cf_str .. element:match("%((.-)%)")
        elseif element == "count" then
            local file, filename, no_ext, str_count = iterate_filecount(o.custom_save_dir,cf_str,o.count_len,"",o.count_wrap)
            cf_str = cf_str .. str_count
        else
            --cf_str = cf_str .. "fail"
            msg.info("CUSTOM_FILENAMING ERROR [Bad element]: " .. element)
        end
    end
    return cf_str
end

local function mpv_default()
    msg.info("INFO: mpv_default function reached")
    local directory = o.default_save_dir
    directory_exists(directory)
    local filename_prefix = "mpv-shot"
    local file, filename, no_ext, count = iterate_filecount(directory,filename_prefix,4,"","")
    return file, filename, no_ext, directory
end

-- local function empty_name(name, context)
--     --msg.info("INFO: empty_name function reached with a context of "..context)
--     if name == "" then
--         msg.info("ERROR: Variable '"..context.."' was blank after format_filename. Reverting to default mpv behavior. Consider revising options in better_ss config.")
--         if context == "custom_filename" then  msg.info("HINT: Your custom_filename option may be null.") end
--         local file, filename, no_ext, directory = mpv_default()
--         return true, file, filename, no_ext, directory
--     else
--         return false
--     end
-- end

local function empty_name(name, context)
    msg.info("INFO: empty_name function reached with a context of "..context)
    if name == "" then
        msg.info("ERROR: Variable '"..context.."' was blank after format_filename. Reverting to default mpv behavior. Consider revising options in better_ss config.")
        if context == "custom_filename" then  msg.info("HINT: Your custom_filename option may be null.") end
        --local file, filename, no_ext, directory = mpv_default()
        return true--, file, filename, no_ext, directory
    else
        return false
    end
end

local function get_fallback_title()
    msg.info("INFO: get_fallback_title_reached")
    title = format_filename(mp.get_property("filename/no-ext"), "")
    msg.info("INFO: Title is "..title)
    title = title:gsub('[%-_%s]*[Ss]%d%d?[Ee]%d%d?[%-_%s]*', ''):gsub('[%-_%s]*[Ee][Pp]%d%d?[%-_%s]*', ''):gsub('%d', '')
    msg.info("INFO: Title is "..title)
    return title
end

local function get_filename(time,arg_append,title)
    local filename
    if o.use_title_as_filename then
        filename = format_filename(mp.get_property("filename/no-ext"), title)
    else
        filename = format_filename(mp.get_property("filename/no-ext"), "")
    end
    --local empty, en_file, en_filename, en_no_ext, en_directory = empty_name(filename, "filename")
    --if empty == true then return en_file, en_filename, en_no_ext, en_directory end
    --local empty = empty_name(filename, "filename")
    --if empty == true then return "" end
    if empty_name(filename, "filename") then return "" end
    filename = filename:gsub('%s+', o.filename_delim) -- TODO: since format_filename is also used by get_fallback_title(), these can't be included
    if o.filename_upper then filename = filename:upper() end -- the solution is to create something like title's get_title (ex. get_filename()) that calls format_filename() and has this additional formatting
    if o.filename_lower then filename = filename:lower() end -- also consider renaming format_filename? maybe it's fine tho.
    if o.cf_opt == true then 
        no_ext = custom_filenaming(filename,arg_append,time)
        --empty, en_file, en_filename, en_no_ext, en_directory = empty_name(no_ext, "custom_filename")
        --if empty == true then return en_file, en_filename, en_no_ext, en_directory end
        -- empty = empty_name(no_ext, "custom_filename")
        -- if empty == true then return "" end
        if empty_name(filename, "filename") then return "" end
        filename =  no_ext .. o.filetype
    else 
        no_ext = filename .. arg_append .. time
        filename = no_ext .. o.filetype
    end
    msg.info("INFO: Returning "..filename.." from get_filename")
    return filename, no_ext
end

local function construct_filename(arg)
    local no_ext, filename, file, empty, en_file, en_filename, en_no_ext, en_directory
    -- /// TIME /// --
    local time = o.time_wrap:sub(1,1) .. format_time(mp.get_property("time-pos")) .. o.time_wrap:sub(2,2)
    -- /// ARGUMENT /// --
    local arg_append = o.arg_wrap:sub(1,1) .. arg:sub(1, 1) .. o.arg_wrap:sub(2,2)
    -- /// TITLE /// --
    local title, valid = get_title()
    -- TODO gotta fix stuff here god
    if valid ~= true then
        title = get_fallback_title()
        -- empty = empty_name(no_ext, "custom_filename")
        -- if empty then
        --     local file, filename, no_ext, directory = mpv_default()
        --     return true, file, filename, no_ext, directory
        -- end
        if empty_name(no_ext, "custom_filename") then
            local file, filename, no_ext, directory = mpv_default()
            return true, file, filename, no_ext, directory
        end
        --empty, en_file, en_filename, en_no_ext, en_directory = empty_name(title, "title")
        --if empty == true then return en_file, en_filename, en_no_ext, en_directory end
    end
    -- if valid == false or uncategorized == true then -- TODO: could? modularize this into get_fallback_title()
    --     title = format_filename(mp.get_property("filename/no-ext"), "")
    --     title = title:gsub('%s*[Ss]%d%d?[Ee]%d%d?%s*', ''):gsub('%d', '')
    --     empty, en_file, en_filename, en_no_ext, en_directory = empty_name(title, "title")
    --     if empty == true then return en_file, en_filename, en_no_ext, en_directory end
    -- end
    title = title:gsub('%s+', o.title_delim)
    if o.title_upper then title = title:upper() end
    if o.title_lower then title = title:lower() end
    -- /// DIRECTORY /// --
    local directory = o.custom_save_dir .. "/" .. title
    directory_exists(directory)
    -- /// FILENAME /// --
    filename, no_ext = get_filename(time,arg_append,title)
    if filename == "" then
        --empty, en_file, en_filename, en_no_ext, en_directory = empty_name(title, "title")
        --if empty == true then return en_file, en_filename, en_no_ext, en_directory end
        local file, filename, no_ext, directory = mpv_default()
        return true, file, filename, no_ext, directory
    end

    -- if o.use_title_as_filename then
    --     filename = format_filename(mp.get_property("filename/no-ext"), title)
    -- else
    --     filename = format_filename(mp.get_property("filename/no-ext"), "")
    -- end
    -- empty, en_file, en_filename, en_no_ext, en_directory = empty_name(filename, "filename")
    -- if empty == true then return en_file, en_filename, en_no_ext, en_directory end
    -- filename = filename:gsub('%s+', o.filename_delim) -- TODO: since format_filename is also used by get_fallback_title(), these can't be included
    -- if o.filename_upper then filename = filename:upper() end -- the solution is to create something like title's get_title (ex. get_filename()) that calls format_filename() and has this additional formatting
    -- if o.filename_lower then filename = filename:lower() end -- also consider renaming format_filename? maybe it's fine tho.
    -- if o.cf_opt == true then 
    --     no_ext = custom_filenaming(filename,arg_append,time)
    --     empty, en_file, en_filename, en_no_ext, en_directory = empty_name(no_ext, "custom_filename")
    --     if empty == true then return en_file, en_filename, en_no_ext, en_directory end
    --     filename =  no_ext .. o.filetype
    -- else 
    --     no_ext = filename .. arg_append .. time
    --     filename = no_ext .. o.filetype
    -- end
    -- /// OUTPUT /// --
    file = directory .. "/" .. filename
    return file, filename, no_ext, directory
end

local function btr_ss(arg)
    return function()
        local file, filename, directory, no_ext
        if o.restore_mpv_default == true then
            file, filename, no_ext, directory = mpv_default()
        else
            file, filename, no_ext, directory = construct_filename(arg)
        end
        --duplicate checking
        if o.duplicate_check_enabled and file_exists(file) then
            msg.info("INFO: duplicate check enabled")
            file, filename = iterate_filecount(directory,no_ext,1,o.duplicate_delim,o.duplicate_count_wrap)
        end
        mp.osd_message("Screenshot: "..filename, 2)
        mp.commandv('screenshot-to-file', file, arg)
    end
end

--mp.add_key_binding('Ctrl+g', 'btr_ss-subs', btr_ss('subtitles'))
--mp.add_key_binding('Ctrl+Shift+g', 'btr_ss-video', btr_ss('video'))
--mp.add_key_binding('Ctrl+Alt+g', 'btr_ss-window', btr_ss('window'))
mp.register_script_message('btr-ss-subs', btr_ss('subtitles'))
mp.register_script_message('btr-ss-video', btr_ss('video'))
mp.register_script_message('btr-ss-window', btr_ss('window'))
