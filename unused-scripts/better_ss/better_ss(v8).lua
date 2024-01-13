--haven't heavily tested, especially a lot of the newer functionality

--Future Options:
--  +   save to one "title" folder, but have distinct filenames
--  +   option: if no szn_ep found when only_szn_ep, retry  format_filename (using fb_title parameter somehow?)
--  +   if two digits besides each other, count as szn_ep (ex. angel beats)
--  +   keybinding to open screenshot folder
--  +   folder argument options to open mpv_default
--  +   before iteratively searching through each directory, at least start with a lua regex search on the whole path to see if valid_titles are present
--      can potentially jump specifically to that directory based on number of "/"

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local do_not_open_folder = false

---- Script Options ----
local o = {
    -- // GENERAL // --
    --output image filetype
    filetype = ".jpg",
    --enable default mpv behavior
    restore_mpv_default = false,

    -- // FOLDER ARG // --
    --the below options only apply to use with the folder argument
    --if true and there is not an existing directory, makes a new directory and opens to it
    fa_mkdir = true,
    --if true and the directory is empty, opens custom save directory (fa_mkdir takes precedence)
    --if both fa_mkdir and fa_open_savedir are false, no folder will be opened
    fa_open_savedir = true,
    --never open the specific directory, only open the custom savedir
    fa_always_savedir = false,

    -- // DIRECTORY // --
    --custom save directory (do NOT include trailing "/") (not used by mpv_default)
    custom_save_dir = "/home/kyler/Pictures/mpv-scs",
    --directory to use for mpv_default (default is "home/<user>/Pictures/mpv")
    default_save_dir = "/home/kyler/Pictures/mpv-scs/.mpv",
    --table list of (lua regex formatted) valid title indicators
    valid_titles = {"^# %[", "%[DUB%+SUB%]", "%[SUB%]"},
    --table list of (lua regex formatted) invalid titles. not indicators, should be exact folder
    invalid_titles = {'Anime', 'qBittorrent', 'kyler', 'home', '.etc', '.delay', '.short', 'Completed', 'mnt','# Short'},

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
local function format_filename(filename, replace_str, mode)
    local szn_ep = string.match(filename, '[Ss]%d%d?[Ee]%d%d?') or string.match(filename, '[Ee][Pp]%d%d?')
    msg.info("szn_ep set to "..tostring(szn_ep))
    filename = filename:gsub('%b()', ''):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('^(%s*)', ''):gsub('(%s*)$', '')--:gsub('%s+', ' ')
    if replace_str ~= "" then
        if szn_ep ~= nil then filename = replace_str .. szn_ep
        else filename = replace_str
        end
    end
    if o.only_szn_ep and szn_ep ~= nil and mode ~= "fb_title" then filename = szn_ep end
    if o.no_szn_ep and szn_ep ~= nil then filename = filename:gsub('%s*[Ss]%d%d?[Ee]%d%d?%s*', '') end
    --removes duplicate spaces, replaces spaces with delimiter, removes spaces at the start, and spaces at the end.
    filename = filename:gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    msg.info("format_filename returning "..filename)
    return filename
end

local function format_valid_dir(save_dir)
    save_dir = save_dir:gsub("#", ""):gsub('%b[]', ''):gsub('[%-_]', ' '):gsub('[%c%p]', ''):gsub('%s+', ' '):gsub('^%s', ''):gsub('%s$', '')
    if save_dir == '' or save_dir == nil then
        uncategorized = true
    end
    return save_dir
end

local function directory_exists(directory,arg)
    local exists, err = os.rename(directory, directory)
    if exists == nil then
        if (arg == 'folder') and not o.fa_mkdir then
            mp.osd_message("Screenshot directory does not exist", 2)
            msg.info("Screenshot directory does not exist: "..directory)
            do_not_open_folder = true
        else
            mp.commandv('run', 'mkdir', directory)
        end
    end
end

local function remove_direct(temp_dir, count)
    for i=0,count do
        local direct = string.format("/" .. temp_dir:gsub(".*/", ""))
        direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
        temp_dir = temp_dir:gsub(direct, "")
    end
    temp_title = temp_dir:gsub(".*/", "")
    return temp_title, invalid
end

local function validate_title(temp_title)
    for key, value in ipairs(o.invalid_titles) do if temp_title == value then return false end end
    --msg.info("INVALID TITLE: "..temp_title)
    for key, value in ipairs(o.valid_titles) do if string.find(temp_title, value) then return true end end
    --msg.info("VALIDATE_TITLE success: "..temp_title)
end

local function set_title_options(title)
    title = title:gsub('%s+', o.title_delim)
    if o.title_upper then title = title:upper() end
    if o.title_lower then title = title:lower() end
    return title
end

local function get_title()
    local work_path = mp.get_property('path')
    local work_dir, path_filename = utils.split_path(work_path)
    -- remove the trailing '/' in work_dir
    work_dir = work_dir:sub(1, -2)
    local count = 0
    local invalid, temp_title, valid
    while count < o.dir_num-1 do
        temp_title = remove_direct(work_dir, count)
        valid = validate_title(temp_title)
        if valid == true then temp_title = format_valid_dir(temp_title) end
        if valid ~= nil then break end
        count = count + 1
    end
    temp_title = set_title_options(temp_title)
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
    msg.info("iterate-filecount function reached")
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
    while true do
        count = count + 1
        str_count = tostring(count)
        add_len = count_len-string.len(str_count)
        for loop=1,add_len do
            str_count = "0" .. str_count
        end
        str_count = wrap:sub(1,1) .. str_count .. wrap:sub(2,2)
        file = directory .. "/" .. filename_prefix .. delimiter .. str_count .. o.filetype
        if file_exists(file)==false then break end
    end
    --still on the fence about how i want this to behave. if i want it to just replace max_count img
    --just add "and count<max_count" as a condition to the above while loop
    --i could just refuse to screenshot at all if above max_count, but i don't like that option
    if count > max_count then msg.info("Image count above maximum specified count_len ("..count_len.."). Creating image anyway.") end
    local no_ext = filename_prefix .. delimiter .. str_count
    local filename = no_ext .. o.filetype
    return file, filename, no_ext, str_count
end

local function custom_filenaming(filename,arg_append,time)
    local cf_str = ""
    --msg.info("custom_filenaming function reached")
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
            msg.info("ERROR in custom_filename [Bad element]: " .. element)
        end
    end
    return cf_str
end

local function mpv_default(arg)
    --msg.info("mpv_default function reached")
    local directory = o.default_save_dir
    directory_exists(directory,arg)
    --local filename_prefix = "mpv-shot"
    local file, filename, no_ext, count = iterate_filecount(directory,"mpv-shot",4,"","")
    return file, filename, no_ext, directory
end

local function empty_name(name, context)
    --msg.info("empty_name function reached with a context of "..context)
    if name == "" then
        msg.info("ERROR: Variable '"..context.."' was blank after format_filename. Reverting to default mpv behavior. Consider revising options in better_ss config.")
        if context == "custom_filename" then  msg.info("HINT: Your custom_filename option may be null.") end
        return true
    else
        return false
    end
end

local function get_fallback_title()
    msg.info("get_fallback_title function reached")
    title = format_filename(mp.get_property("filename/no-ext"), "", "fb_title")
    title = title:gsub('[%-_%s]*[Ss]%d%d?[Ee]%d%d?[%-_%s]*', ''):gsub('[%-_%s]*[Ee][Pp]%d%d?[%-_%s]*', ''):gsub('%d', '')
    title = set_title_options(title)
    msg.info("fallback_title is "..title)
    return title
end

local function get_filename(time,arg_append,title)
    local filename
    if o.use_title_as_filename then
        filename = format_filename(mp.get_property("filename/no-ext"), title, "")
    else
        filename = format_filename(mp.get_property("filename/no-ext"), "", "")
    end
    if empty_name(filename, "filename") then return "" end
    filename = filename:gsub('%s+', o.filename_delim) 
    if o.filename_upper then filename = filename:upper() end 
    if o.filename_lower then filename = filename:lower() end
    if o.cf_opt == true then 
        no_ext = custom_filenaming(filename,arg_append,time)
        if empty_name(filename, "custom-filename") then return "" end
        filename =  no_ext .. o.filetype
    else 
        no_ext = filename .. arg_append .. time
        filename = no_ext .. o.filetype
    end
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
    if valid ~= true then
        title = get_fallback_title()
        if empty_name(title, "title") then return mpv_default(arg) end
    end
    -- /// DIRECTORY /// --
    local directory = o.custom_save_dir .. "/" .. title
    directory_exists(directory,arg)
    -- /// FILENAME /// --
    filename, no_ext = get_filename(time,arg_append,title)
    if filename == "" then return mpv_default(arg) end
    -- /// OUTPUT /// --
    file = directory .. "/" .. filename
    return file, filename, no_ext, directory
end

local function open_folder(directory)
    if (o.fa_always_savedir) then 
        local cmd = { 'sww', 'nemo "'..o.custom_save_dir..'"', 'se' }
        mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
    elseif do_not_open_folder and not o.fa_open_savedir then return
    elseif (do_not_open_folder and o.fa_open_savedir) then 
        local cmd = { 'sww', 'nemo "'..o.custom_save_dir..'"', 'se' }
        mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
    else
        local cmd = { 'sww', 'nemo "'..directory..'"', 'se' }
        mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
    end
end

local function btr_ss(arg)
    return function()
        local file, filename, directory, no_ext
        if o.restore_mpv_default == true then
            file, filename, no_ext, directory = mpv_default(arg)
        else
            file, filename, no_ext, directory = construct_filename(arg)
        end
        if o.duplicate_check_enabled and file_exists(file) then
            file, filename = iterate_filecount(directory,no_ext,1,o.duplicate_delim,o.duplicate_count_wrap)
        end
        if (arg == 'folder') then open_folder(directory)
        else
            mp.osd_message("Screenshot: "..filename, 2)
            mp.commandv('screenshot-to-file', file, arg)
        end
    end
end

--mp.add_key_binding('Ctrl+g', 'btr_ss-subs', btr_ss('subtitles'))
--mp.add_key_binding('Ctrl+Shift+g', 'btr_ss-video', btr_ss('video'))
--mp.add_key_binding('Ctrl+Alt+g', 'btr_ss-window', btr_ss('window'))
mp.register_script_message('btr-ss-subs', btr_ss('subtitles'))
mp.register_script_message('btr-ss-video', btr_ss('video'))
mp.register_script_message('btr-ss-window', btr_ss('window'))
mp.register_script_message('btr-ss-folder', btr_ss('folder'))

