-- SOURCE: https://github.com/kelciour/mpv-scripts/blob/master/sub-export.lua
-- SOURCE: https://github.com/dyphire/mpv-scripts/blob/main/sub_export.lua
-- LAST UPDATE: 28 Aug 2023
--
-- Usage:
-- add bindings to input.conf:
-- key   script-message-to sub_export export-selected-subtitles
-- key   script-message-to sub_export ffmpeg-export-subs
-- key   script-message-to sub_export mkvextract-export-subs


local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

---- Script Options ----
local o = {
    --mkvextract or ffmpeg
    mode = "ffmpeg",
}

options.read_options(o)
------------------------

local function export_selected_subtitles()
    local i = 0
    local tracks_count = mp.get_property_number("track-list/count")
    while i < tracks_count do
        local track_type = mp.get_property(string.format("track-list/%d/type", i))
        local track_index = mp.get_property_number(string.format("track-list/%d/ff-index", i))
        local track_selected = mp.get_property(string.format("track-list/%d/selected", i))
        local track_title = mp.get_property(string.format("track-list/%d/title", i))
        local track_lang = mp.get_property(string.format("track-list/%d/lang", i))
        local track_external = mp.get_property(string.format("track-list/%d/external", i))
        local track_codec = mp.get_property(string.format("track-list/%d/codec", i))
        local path = mp.get_property('path')
        local dir, filename = utils.split_path(path)
        local fname = mp.get_property("filename/no-ext")
        local index = string.format("0:%d", track_index)
        local mkvextract_index = string.format("%d", track_index)

        if track_type == "sub" and track_selected == "yes" then
            if track_external == "yes" then
                msg.info("Error: external subtitles have been selected")
                mp.osd_message("Error: external subtitles have been selected", 2)
                return
            end

            local video_file = utils.join_path(dir, filename)

            local subtitles_ext = ".srt"
            if string.find(track_codec, "ass") ~= nil then
                subtitles_ext = ".ass"
            elseif string.find(track_codec, "pgs") ~= nil then
                subtitles_ext = ".sup"
            end

            if track_lang ~= nil then
                if track_title ~= nil then
                    subtitles_ext = "." .. track_title .. "." .. track_lang .. subtitles_ext
                else
                    subtitles_ext = "." .. track_lang .. subtitles_ext
                end
            end

            subtitles_file = utils.join_path(dir, fname .. subtitles_ext)
            subtitles_file = string.gsub(subtitles_file,"/","")

            
            msg.info("Exporting selected subtitles")
            mp.osd_message("Exporting selected subtitles")
            
            if o.mode == 'ffmpeg' then
                args = { 'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-i', video_file, "-map", index, subtitles_file }
                msg.info("ffmpeg mode")
                mp.osd_message("ffmpeg mode")
            elseif o.mode == 'mkvextract' then
                mkvextract_output = string.format(mkvextract_index .. ":" .. subtitles_file)
                args = { 'mkvextract', 'tracks', video_file, mkvextract_output}
                msg.info("mkvextract mode")
                mp.osd_message("mkvextract mode")
            else
                msg.info("Incorrectly set mode")
                mp.osd_message("Incorrectly set mode")
                break
            end

            --if o.mode == 'ffmpeg' then
                --cmd = string.format("ffmpeg -y -hide_banner -loglevel error -i '%s' -map '%s' -vn -an -c:s copy '%s'",
                    --video_file, index, subtitles_file)
            --else
                --cmd = string.format("mkvextract tracks '%s' '%s':'%s'",
                    --video_file, mkvextract_index, subtitles_file)
            --end
            --args = { cmd }

            
            mp.add_timeout(mp.get_property_number("osd-duration") * 0.001, process)

            break
        end

        i = i + 1
    end
end

function process()
    local screenx, screeny, aspect = mp.get_osd_size()

    mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
    --local res = mp.command(cmd)
    --local res = mp.command_native({ name = "subprocess", capture_stdout = true, playback_only = false, args = args })
    local res = utils.subprocess({ args = args })
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

local function mkvextract_mode()
    o.mode = 'mkvextract'
    export_selected_subtitles()
    --mp.add_timeout(mp.get_property_number("osd-duration") * 0.001, export_selected_subtitles)
end

local function ffmpeg_mode()
    o.mode = 'ffmpeg'
    export_selected_subtitles()
    --mp.add_timeout(mp.get_property_number("osd-duration") * 0.001, export_selected_subtitles)
end

mp.add_key_binding('Alt+n', ffmpeg_mode)
mp.add_key_binding('Alt+m', mkvextract_mode)
mp.add_key_binding('Alt+b', export_selected_subtitles)
mp.register_script_message("ffmpeg-export-subs", mkvextract_mode)
mp.register_script_message("mkvextract-export-subs", mkvextract_mode)
mp.register_script_message("export-selected-subtitles", export_selected_subtitles)
