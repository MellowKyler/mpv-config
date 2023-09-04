--kyler modified this script!

--local utils = require 'mp.utils'
local msg = require 'mp.msg'

function callback(success, result, error)
    if result.status == 0 then
        mp.osd_message("Launched browser", 1)
    elseif count < 2 then
        --mp.osd_message("Next method.", 3)
        count = count + 1
        anilist_python()
    else
        mp.osd_message("Unable to find Anilist URL.", 3)
    end
end

function anilist_python()
    if count == 0 then
        --containing folder
        --TODO: make dir not a local variable and reuse below
        local dir = mp.get_property("working-directory") 
        search_str = dir:gsub(".*/", "")
        local message = string.format("Search String: '%s'",
            search_str)
        msg.info(message)
    elseif count == 1 then
        --filename
        search_str = mp.get_property("filename/no-ext")
        local message = string.format("Search String: '%s'",
            search_str)
        msg.info(message)
    elseif count == 2 then
        --one directory above containing folder
        local dir = mp.get_property("working-directory")
        local message = string.format("Working Directory: '%s'",
            dir)
        msg.info(message)
        direct = string.format("/" .. dir:gsub(".*/", ""))
        --escape magic characters: ( ) . % + - * ? [ ^ $
        --i'm choosing to ignore actual % because it legit fucks with everything - just rename files that have it
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
        local message = string.format("Direct Directory: '%s'",
            direct)
        msg.info(message)
        --gsub struggles with "+" and "[" and "]" characters and can't replace the string. '#' and ' ' are okay.
        dir = dir:gsub(direct, "")
        --dir = "/directory/to/# [DUB+SUB] Canaan"
        --dir = dir:gsub("/# %[DUB%+SUB%] Canaan", "")
        local message = string.format("Final Directory: '%s'",
            dir)
        msg.info(message)
        search_str = dir:gsub(".*/", "")
        local message = string.format("Search String: '%s'",
            search_str)
        msg.info(message)
        --don't continue if reaching base directory, can add as many as you need.
        if (search_str == 'Anime') or (search_str == 'qBittorrent') or (search_str == 'kyler') then
            msg.info("Breaking out! Base directory.")
            return "smile"
        end
        msg.info("You didn't break out!")
    else
        return "smile"
    end
    --mp.add_timeout(1, anilist_python)
    --anilist_python()
    --count = count + 1
    local table = {}
    table.name = "subprocess"
    table.args = {"python", script_dir.."open-anilist-page.py", search_str}
    local cmd = mp.command_native_async(table, callback)
    --sending message after so i can see how long it takes to complete? i dont think it works that way
    local message = string.format("Final Search String: '%s'",
        search_str)
    msg.info(message)
    --can i run these two commands separately so I can add delay? i hope so
    --separately i can also add a success condition
    --local cmd = mp.command_native(table)
    --cmd = mp.add_timeout(1, callback)
    --if cmd == "success" then
    --    msg.info("Breaking out! Anilist page found.")
    --    break
    --end
    msg.info(count)
end

function launch_anilist()
    script_dir = debug.getinfo(1).source:match("@?(.*/)")
    mp.osd_message("Finding Anilist URL...", 30)
    count = 0
    anilist_python()
end



-- change key binding as desired 
mp.add_key_binding('ctrl+a', 'launch_anilist', launch_anilist)