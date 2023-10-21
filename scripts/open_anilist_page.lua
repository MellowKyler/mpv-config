-- could look at old/current versions of better_ss.lua for ideas on how to search for home folder
-- but tbh this almost never fails so its fine

local msg = require 'mp.msg'
local utils = require 'mp.utils'

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

function format_search_str()
    search_str = search_str:gsub('%b()', ''):gsub('%b[]', ''):gsub('[%-_]', ' ')
end

function count_check()
    if count == 0 then
        search_str = work_dir:gsub(".*/", "")
    elseif count == 1 then
        local direct = "/" .. work_dir:gsub(".*/", "")
        direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
        local temp_dir = work_dir:gsub(direct, "")
        search_str = temp_dir:gsub(".*/", "")
    elseif count == 2 then
        search_str = mp.get_property("filename/no-ext")
    else
        return
    end
    --if (search_str == 'Anime') or (search_str == 'qBittorrent') or (search_str == 'kyler') or (search_str == 'home') or (search_str == '.etc') or (search_str == '.delay') or (search_str == '.short')  then
    if (search_str == 'Anime') or (search_str == 'qBittorrent') or (search_str == 'kyler') or (search_str == 'home') or 
            (search_str == '.etc') or (search_str == '.delay') or (search_str == '.short') or (search_str == 'Completed') or
            (search_str == 'mnt') or (search_str == '# Short') then
        recount = true
    end
end

function anilist_python()
    count_check()
    if recount == true then
        count = count + 1
        recount = false
        msg.info("BAD SEARCH_STR: "..search_str)
        anilist_python()
        return
    end
    format_search_str()
    msg.info("SEARCH_STR: "..search_str)
    local table = {}
    table.name = "subprocess"
    table.args = {"python", script_dir.."open-anilist-page.py", search_str}
    local cmd = mp.command_native_async(table, callback)
end

function launch_anilist()
    script_dir = debug.getinfo(1).source:match("@?(.*/)")
    path = mp.get_property('path')
    work_dir, path_filename = utils.split_path(path)
    -- remove the trailing '/' in work_dir
    work_dir = work_dir:sub(1, -2)
    msg.info("PATH: "..path)
    msg.info("WORK_DIR: "..work_dir)
    msg.info("PATH_FILENAME: "..path_filename)
    mp.osd_message("Finding Anilist URL...", 30)
    count = 0
    anilist_python()
end

-- change key binding as desired 
--mp.add_key_binding('ctrl+a', 'launch_anilist', launch_anilist)
mp.register_script_message("launch-anilist", launch_anilist)