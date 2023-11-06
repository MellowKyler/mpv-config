local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- local r = mp.command_native({
--     name = "subprocess",
--     playback_only = false,
--     capture_stdout = true,
--     args = {"gnome-terminal"}
-- })

local r = utils.subprocess({
    name = "subprocess",
    playback_only = false,
    capture_stdout = true,
    args = {"gnome-terminal"}
})

if r.killed_by_us then
    msg.info("KILLED_BY_US: " .. tostring(r.killed_by_us))
end