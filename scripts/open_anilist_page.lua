function callback(success, result, error)
    if result.status == 0 then
        mp.osd_message("Launched browser", 1)
    elseif count < 2 then
        count = count + 1
        anilist_python()
    else
        mp.osd_message("Unable to find Anilist URL.", 3)
    end
end

function anilist_python()
    if count == 0 then
        search_str = dir:gsub(".*/", "")
    elseif count == 1 then
        search_str = mp.get_property("filename/no-ext")
    elseif count == 2 then
        local direct = string.format("/" .. dir:gsub(".*/", ""))
        direct = direct:gsub('%(', '%%(')
        direct = direct:gsub('%)', '%%)')
        direct = direct:gsub('%.', '%%.')
        direct = direct:gsub('%+', '%%+')
        direct = direct:gsub('%-', '%%-')
        direct = direct:gsub('%*', '%%*')
        direct = direct:gsub('%?', '%%?')
        direct = direct:gsub('%[', '%%[')
        direct = direct:gsub('%^', '%%^')
        direct = direct:gsub('%$', '%%$')
        local temp_dir = dir:gsub(direct, "")
        search_str = temp_dir:gsub(".*/", "")
        if (search_str == 'Anime') or (search_str == 'qBittorrent') or (search_str == 'kyler') then
            return
        end
    else
        return
    end
    local table = {}
    table.name = "subprocess"
    table.args = {"python", script_dir.."open-anilist-page.py", search_str}
    local cmd = mp.command_native_async(table, callback)
end

function launch_anilist()
    script_dir = debug.getinfo(1).source:match("@?(.*/)")
    dir = mp.get_property("working-directory") 
    mp.osd_message("Finding Anilist URL...", 30)
    count = 0
    anilist_python()
end

-- change key binding as desired 
--mp.add_key_binding('ctrl+a', 'launch_anilist', launch_anilist)
mp.register_script_message("launch-anilist", launch_anilist)