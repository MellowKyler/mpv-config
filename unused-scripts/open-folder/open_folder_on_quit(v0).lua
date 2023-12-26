
local msg = require 'mp.msg'

mp.register_event("start-file", function()

end)

local function open_folder_on_quit(one,two,three,four,five)
    --msg.info(string.format("1. %s, 2. $s, 3. $s, 4. $s, 5. $s",one,two,three,four,five))
    --msg.info(tostring(one))
    if one.id ~= nil then msg.info(tostring(one.reason)) end
    -- for k,v in pairs(one) do
    --     msg.info(k..". "..v)
    -- end
    local path = mp.get_property('path')
    local cmd = { 'nemo', path }
    mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
end


-- mp.register_event(
--     "shutdown", function() open_folder_on_quit(one,two,three,four,five) end
-- )

-- mp.register_event(
--     "end-file", function() open_folder_on_quit() end
-- )

--playlist-count
--oef-reached

-- mp.register_event(
--     "shutdown", function(ev) 
--     for k,v in pairs(ev) do
--         msg.info(k..". "..v)
--     end
--     local playlist_count = mp.get_property('playlist-count')
--     msg.info(playlist_count)
--     msg.info(type(playlist_count))
--     local playlist_pos = mp.get_property('playlist-pos')
--     msg.info(playlist_pos)
--     msg.info(type(playlist_pos))
-- end)

mp.register_event(
    "end-file", function(ev)
    local playlist_count = tonumber(mp.get_property('playlist-count'))
    local playlist_pos = mp.get_property('playlist-pos')
    if playlist_pos == "-1" and playlist_count > 6 then
        local path = mp.get_property('path')
        local cmd = { 'nemo', path }
        mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
    end
end)

-- mp.register_event(
--     "end-file", function(ev)
--     msg.info(tostring(ev))
--     msg.info(tostring(ev.reason))
--     msg.info(tostring(ev.event))
--     msg.info(tostring(ev.playlist_entry_id))
--     msg.info(type(ev.playlist_entry_id))
--     --tostring(ev.playlist_entry_id)
--     for k,v in pairs(ev) do
--         msg.info(k..". "..v)
--     end
--     local playlist_count = mp.get_property('playlist-count')
--     msg.info(playlist_count)
--     msg.info(type(playlist_count))
--     local playlist_pos = mp.get_property('playlist-pos')
--     msg.info(playlist_pos)
--     msg.info(type(playlist_pos))
--     if playlist_count == playlist_pos then
--         local path = mp.get_property('path')
--         local cmd = { 'nemo', path }
--         mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
--     end
-- end)
