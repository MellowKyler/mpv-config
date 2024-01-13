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
        cmd = { 'sww', 'nemo "'..path..'"', 'se' }
        mp.command_native({ name = "subprocess", playback_only = false, args = cmd })
    end
end)

-- /home/kyler/.local/bin/sww
-- /home/kyler/.local/bin/setwindow