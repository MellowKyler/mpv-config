

local msg = require 'mp.msg'

-- local function callback(success, result, error)
--     if success == true then
--         mp.osd_message("Copied subtitles to clipboard", 1)
--     else
--         mp.osd_message("Subtitle clipboard copy failed", 3)
--     end
-- end


-- local function copy(subs)
--     -- local cmd = { 'run', 'echo', '-n', subs, '|', 'xclip', '-selection', 'clipboard' }
--     -- mp.command_native_async(cmd)
--     --mp.command_native_async({'run', unpack(cmd)})
--     --local pop = io.popen('echo -n '..subs..' | xclip -selection clipboard', "w")
--     --local pipe = io.popen(pop, "w")

--     --works
--     local pop = io.popen('xclip -selection clipboard', "w")
--     pop:write(subs)
--     pop:close()
--     mp.osd_message("Copied subtitles to clipboard", 1)

--     os.execute(tostring('echo -n '..subs.." | xclip -selection clipboard"))
-- end

local function subs2clip()
    --still don't understand why the return saves this from crumbling, and now i'm starting to argue
    return function()
        local sub_text = mp.get_property('sub-text')
        msg.info("sub-text: "..tostring(sub_text))
        --local secondary_sub_text=(mp.get_property('secondary-sub-text'))
        --msg.info("secondary-sub-text: "..tostring(secondary_sub_text))
        --msg.info("sub-text-ass: "..(mp.get_property('sub-text-ass')))
        if (sub_text ~= nil) and (sub_text:gsub("%s*","") ~= "") then
            local pop = io.popen('xclip -selection clipboard', "w")
            pop:write(sub_text)
            pop:close()
            mp.osd_message("Copied subtitles to clipboard", 1)
            --elseif secondary_sub_text ~= nil then copy(secondary_sub_text)
        else mp.osd_message("No subs found.")
        end
    end
end

mp.add_key_binding('Alt+w', subs2clip())
--mp.register_script_message('copy-subs', subs2clip())