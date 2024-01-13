local options = require 'mp.options'
local o = {
    sw_coords = dofile('/home/kyler/.config/mpv/scripts/.utils/setwindow_coords.lua'),
}
options.read_options(o)

local path
mp.register_event("file-loaded", function(ev)
    --can't get path property during shutdown or end-file
    path = mp.get_property('path')
    --print("path: "..path) 
end)

mp.register_event(
    --end-file also works
    "shutdown", function(ev)
    local playlist_count = tonumber(mp.get_property('playlist-count'))
    local playlist_pos = mp.get_property('playlist-pos')
    if playlist_pos == "-1" and playlist_count > 6 and string.find(path,"/mnt/Torrent/") then
        -- local cmd = { 'nemo', path }
        -- local cmd = { 'setwindow', 'nemo '..'"'..path..'"', "970", "900", "960", "512" }
        -- local cmd = { 'setwindow', 'nemo '..'"'..path..'"', "2890", "900", "960", "512" }
        cmd = { 'setwindow', 'nemo '..'"'..path..'"', o.sw_coords[1], o.sw_coords[2], o.sw_coords[3], o.sw_coords[4] }
        mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
    end
end)

-- /home/kyler/.local/bin/setwindow
-- REQUIRES wmctrl AND xdotool
-- setwindow <application + arguments> <horizontal-position> <vertical-position> <horizontal-size> <vertical-size>
-- 970 900 960 512 is bottom right corner
-- wmctrl -Gl lists windows and their geometry