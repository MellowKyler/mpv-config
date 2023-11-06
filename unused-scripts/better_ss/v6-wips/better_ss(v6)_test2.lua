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
    --msg.info("INFO: Arrived at remove_direct")
    --msg.info("INFO: path is "..temp_dir)
    local direct = string.format("/" .. temp_dir:gsub(".*/", ""))
    --msg.info("INFO: direct is "..direct)
    direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
    --msg.info("INFO: direct is "..direct)
    local temp_dir = temp_dir:gsub(direct, "")
    --msg.info("INFO: temp_dir is "..temp_dir)
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
    work_path = mp.get_property('path')
    work_dir, path_filename = utils.split_path(work_path)
    -- remove the trailing '/' in work_dir
    work_dir = work_dir:sub(1, -2)
    count = 0
    valid = false
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