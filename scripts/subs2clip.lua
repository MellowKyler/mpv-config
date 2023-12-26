

--local msg = require 'mp.msg'

local function subs2clip()
    --still don't understand why the return saves this from crumbling, and now i'm starting to argue
    return function()
        local sub_text = mp.get_property('sub-text')
        --msg.info("sub-text: "..tostring(sub_text))
        if (sub_text ~= nil) and (sub_text:gsub("%s*","") ~= "") then
            local pop = io.popen('xclip -selection clipboard', "w")
            pop:write(sub_text)
            pop:close()
            mp.osd_message("Copied subtitles to clipboard", 1)
        else mp.osd_message("No subs found.") end
    end
end

--mp.add_key_binding('Alt+b', subs2clip())
mp.register_script_message('copy-current-subs', subs2clip())