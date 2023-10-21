-- SOURCE: https://github.com/kelciour/mpv-scripts/blob/master/sub-export.lua
-- SOURCE: https://github.com/dyphire/mpv-scripts/blob/main/sub_export.lua
-- LAST UPDATE: 28 Aug 2023
--
-- Usage:
-- add bindings to input.conf:
-- key   script-message-to sub-export-clipboard copy-subtitles

local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

---- Script Options ----
local o = {
    --mkvextract or ffmpeg
    mode = "mkvextract",
}

options.read_options(o)
------------------------

local function copy_subtitles()

    local i = 0
    local tracks_count = mp.get_property_number("track-list/count")

    while i < tracks_count do

        msg.info("I: "..i)
        local track_type = mp.get_property(string.format("track-list/%d/type", i))
        local track_selected = mp.get_property(string.format("track-list/%d/selected", i))

        if track_type == "sub" and track_selected == "yes" then

            local track_external = mp.get_property(string.format("track-list/%d/external", i))
            if track_external == "yes" then
                msg.info("Error: external subtitles have been selected")
                mp.osd_message("Error: external subtitles have been selected", 2)
                return
            end

            local track_codec = mp.get_property(string.format("track-list/%d/codec", i))
            local subtitles_ext = ".srt"
            if string.find(track_codec, "ass") ~= nil then
                subtitles_ext = ".ass"
            elseif string.find(track_codec, "pgs") ~= nil then
                subtitles_ext = ".sup"
            end

            local track_lang = mp.get_property(string.format("track-list/%d/lang", i))
            if track_lang ~= nil then
                subtitles_ext = "." .. track_lang .. subtitles_ext
            end

            local path = mp.get_property('path')
            local dir, path_filename = utils.split_path(path)
            local filename = mp.get_property("filename/no-ext")
            local subtitles_file = dir .. filename .. subtitles_ext

            msg.info("PATH: "..path)
            msg.info("DIR: "..dir)
            msg.info("PATH_FILENAME: "..path_filename)
            msg.info("Copying export subtitles command")
            mp.osd_message("Copying export subtitles command")

            local track_index = mp.get_property_number(string.format("track-list/%d/ff-index", i))
            if o.mode == 'ffmpeg' then
                local index = string.format("0:%d", track_index)
                cmd = string.format("ffmpeg -y -hide_banner -loglevel error -i '%s' -map '%s' -vn -an -c:s copy '%s'",
                    path, index, subtitles_file)
                msg.info("ffmpeg mode")
            elseif o.mode == 'mkvextract' then
                local mkve_index = string.format("%d", track_index)
                cmd = string.format("mkvextract tracks '%s' '%s':'%s'",
                    path, mkve_index, subtitles_file)
                msg.info("mkvextract mode")
            else
                msg.info("Incorrectly set mode" .. o.mode)
                mp.osd_message("Incorrectly set mode")
                break
            end

            local clipboard_cmd = string.format("xclip -silent -in -selection clipboard")

            local pipe = io.popen(clipboard_cmd, "w")
            pipe:write(cmd)
            pipe:close()

            mp.osd_message(string.format("Copied to clipboard"))

            --args = { "gnome-terminal" }
            --utils.subprocess({ args = args})

            local table = {}
            table.name = "subprocess"
            table.args = {"gnome-terminal"}
            local res = mp.command_native(table)

            break
        end
        i = i + 1
    end
end


--mp.add_key_binding('b', copy_subtitles)
mp.register_script_message("copy-subtitles", copy_subtitles)
