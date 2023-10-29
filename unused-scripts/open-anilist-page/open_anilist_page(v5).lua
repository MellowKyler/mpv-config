--TODO: strip special characters and brackets from search_str (especially directories)

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

function count_check()
    if count == 0 then
        search_str = work_dir:gsub(".*/", "")
    elseif count == 2 then
        search_str = mp.get_property("filename/no-ext")
    elseif count == 1 then
        local direct = "/" .. work_dir:gsub(".*/", "")
        direct = direct:gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%*', '%%*'):gsub('%?', '%%?'):gsub('%[', '%%['):gsub('%^', '%%^'):gsub('%$', '%%$')
        local temp_dir = work_dir:gsub(direct, "")
        search_str = temp_dir:gsub(".*/", "")
        if (search_str == 'Anime') or (search_str == 'qBittorrent') or (search_str == 'kyler') then
            return
        end
    else
        return
    end
end

function anilist_python()
    count_check()
    msg.info("SEARCH_STR: "..search_str)
    local table = {}
    table.name = "subprocess"
    table.args = {"python", script_dir.."open-anilist-page.py", search_str}
    local cmd = mp.command_native_async(table, callback)
end

function launch_anilist()
    script_dir = debug.getinfo(1).source:match("@?(.*/)")
    work_dir = mp.get_property("working-directory")
    mp.osd_message("Finding Anilist URL...", 30)
    count = 0
    anilist_python()
end

-- change key binding as desired 
--mp.add_key_binding('ctrl+a', 'launch_anilist', launch_anilist)
mp.register_script_message("launch-anilist", launch_anilist)