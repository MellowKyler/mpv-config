local function count_check()
    if count == 0 then
        temp_title = work_dir:gsub(".*/", "")
        msg.info("COUNT 0 TITLE:", temp_title)
        return temp_title
    elseif count == 1 then
        local direct = string.format("/" .. work_dir:gsub(".*/", ""))
        direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
        local temp_dir = work_dir:gsub(direct, "")
        temp_title = temp_dir:gsub(".*/", "")
        if (temp_title == 'Anime') or (temp_title == 'qBittorrent') or (temp_title == 'kyler') then
            uncategorized = true
            return "uncategorized"
        end
        msg.info("COUNT 1 TITLE:", temp_title)
        return temp_title
    else
        uncategorized = true
        return "uncategorized"
    end
end

local function shutup()
    if count == 1 then
        path = work_dir
        temp_dir = remove_direct(temp_dir)
        temp_title = temp_dir:gsub(".*/", "")
    elseif count == 2 then
        path = work_dir
        temp_dir = remove_direct(path)
        temp_dir = remove_direct(temp_dir)
        temp_title = temp_dir:gsub(".*/", "")
    end
end


