--kyler modified this script!
--I could definitely modularize a bit better with the two separate functions.

--local utils = require 'mp.utils'
--local msg = require 'mp.msg'

function fallback()
    mp.osd_message("Finding Anilist URL (2)...", 30)
    local script_dir = debug.getinfo(1).source:match("@?(.*/)")
    local table = {}
    table.name = "subprocess"
    table.args = {"python", script_dir.."open-anilist-page.py", mp.get_property("filename/no-ext")}
    local cmd = mp.command_native_async(table, callback)
end

function callback(success, result, error)
    if result.status == 0 then
        mp.osd_message("Launched browser", 1)
    else
        mp.osd_message("Unable to find Anilist URL.", 3)
        local cmd = fallback()
    end
end

function launch_anilist()
    mp.osd_message("Finding Anilist URL...", 30)
    local script_dir = debug.getinfo(1).source:match("@?(.*/)")
    local table = {}
    table.name = "subprocess"
    local dir = mp.get_property("working-directory")
    dir = dir:gsub(".*/", "")
    --debugging help:
    --local message = string.format("Directory: '%s'",
    --    dir)
    --msg.info(message)
    table.args = {"python", script_dir.."open-anilist-page.py", dir}
    local cmd = mp.command_native_async(table, callback)
end

-- change key binding as desired 
mp.add_key_binding('ctrl+a', 'launch_anilist', launch_anilist)