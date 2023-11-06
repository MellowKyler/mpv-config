
local function format_save_dir(save_dir)
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
    local direct = string.format("/" .. temp_dir)
    direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
    local temp_dir = temp_dir:gsub(direct, "")
    return temp_dir
end

local function count_check()
    local temp_dir = work_dir
    for i=1,count do
        temp_dir = remove_direct(temp_dir)
    end
    temp_title = temp_dir:gsub(".*/", "")
    if (temp_title == 'Anime') or (temp_title == 'qBittorrent') or (temp_title == 'kyler') or (temp_title == 'home') or 
            (temp_title == '.etc') or (temp_title == '.delay') or (temp_title == '.short') or (temp_title == 'Completed') or
            (temp_title == 'mnt') or (temp_title == '# Short') then
        uncategorized = true
        return "uncategorized"
    end
    return temp_title
end

-- get work_dir and filename
-- remove trailing / in work_dir
-- loop (for specificied count) through containing folders for desired folder name
--  for count, remove_direct folder layer
--      

local function validate_title(temp_title)
    if string.find(temp_title, "^# %[") or string.find(temp_title, "%[DUB%+SUB%]") or string.find(temp_title, "%[SUB%]") then
        temp_title = format_save_dir(temp_title)
        valid = true
        --msg.info("VALIDATE_TITLE success: "..temp_title)
        return temp_title
    else
        --msg.info("VALIDATE_TITLE failed: "..temp_title)
        return "validation_failed"
    end
end


local function get_title()
    local work_path = mp.get_property('path')
    local work_dir, path_filename = utils.split_path(work_path)
    -- remove the trailing '/' in work_dir
    work_dir = work_dir:sub(1, -2)
    local count = 0
    local valid = false
    local temp_title
    while valid == false and count < o.dir_num do
        temp_title = count_check()
        if uncategorized == true then break end
        --msg.info("TEMP_TITLE: "..temp_title)
        temp_title = validate_title(temp_title)
        count = count + 1
    end
    --msg.info("GET_TITLE returns: "..temp_title)
    return temp_title
end
