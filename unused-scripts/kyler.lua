--ffmpeg -y -hide_banner -loglevel error -i './test.mkv' -map '0:4' -vn -an -c:s copy subs.ass

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

local function export_selected_subtitles()
--cmd = string.format("%s -y -hide_banner -loglevel error -i '%s' -map '%s' -vn -an -c:s copy '%s'",
    --o.ffmpeg_path, video_file, index, subtitles_file)
    --mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = {'bash', "ffmpeg -y -hide_banner -loglevel error -i '/home/kyler/qBittorrent/test.mkv' -map '0:4' -vn -an -c:s copy subs.ass"}})
    mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = {'bash', 'mkvextract tracks "/home/kyler/qBittorrent/test.mkv" 4:subs.ass'}})
end
--cmd = "ffmpeg -y -hide_banner -loglevel error -i '/home/kyler/qBittorrent/test.mkv' -map '0:4' -vn -an -c:s copy subs.ass"
--unix_args = { 'bash', cmd }
--args = unix_args

--mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
--mp.add_timeout(mp.get_property_number("osd-duration") * 0.001, process)

if false then
    function process()
        local screenx, screeny, aspect = mp.get_osd_size()

        mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
        local res = mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
        mp.set_osd_ass(screenx, screeny, "")
        if res.status == 0 then
            msg.info("Finished exporting subtitles")
            mp.osd_message("Finished exporting subtitles")
            mp.commandv("sub-add", subtitles_file)
            mp.set_property("sub-visibility", "yes")
        else
            msg.info("Failed to export subtitles")
            mp.osd_message("Failed to export subtitles, check console for more info.")
        end
    end
end

mp.add_key_binding('b', export_selected_subtitles)