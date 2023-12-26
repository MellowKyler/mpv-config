
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"

---- Script Options ----
local o = {
    --mkvextract or ffmpeg
    mode = "ffmpeg",
    ass2txt = true,
    ass2txt_dir = "/home/kyler/.config/mpv/scripts/.utils/ass2txt.lua",
    incl_timestamps = true
}

options.read_options(o)
------------------------

local function export_selected_subtitles()

    local i = 0
    local tracks_count = mp.get_property_number("track-list/count")

    -- loop through all tracks
    while i < tracks_count do

        local track_type = mp.get_property(string.format("track-list/%d/type", i))
        local track_selected = mp.get_property(string.format("track-list/%d/selected", i))

        -- if you reach a track that is both a subtitle track and the currently selected track
        if track_type == "sub" and track_selected == "yes" then
            
            -- exit the program with an error if the selected subtitle track is external
            local track_external = mp.get_property(string.format("track-list/%d/external", i))
            if track_external == "yes" then
                msg.info("Error: external subtitles have been selected")
                mp.osd_message("Error: external subtitles have been selected", 2)
                return
            end

            -- figure out what codec the subtitle uses and set that as the extension
            local track_codec = mp.get_property(string.format("track-list/%d/codec", i))
            local subtitles_ext = ".srt"
            if string.find(track_codec, "ass") ~= nil then
                subtitles_ext = ".ass"
            elseif string.find(track_codec, "pgs") ~= nil then
                subtitles_ext = ".sup"
            end

            -- if the track has a language, append that to the extension
            local track_lang = mp.get_property(string.format("track-list/%d/lang", i))
            if track_lang ~= nil then
                subtitles_ext = "." .. track_lang .. subtitles_ext
            end

            -- get the file path, directory, and name
            -- set the subtitle file to the file directory + file name + extension
            local path = mp.get_property('path')
            local dir, path_filename = utils.split_path(path)
            local filename = mp.get_property("filename/no-ext")
            local subtitles_file = dir .. filename .. subtitles_ext

            msg.info("PATH: "..path)
            msg.info("DIR: "..dir)
            msg.info("PATH_FILENAME: "..path_filename)

            msg.info("Exporting selected subtitles")
            mp.osd_message("Exporting selected subtitles")

            -- get the track index in ffmpeg acceptable form
            local track_index = mp.get_property_number(string.format("track-list/%d/ff-index", i))

            -- set the correct args for the mode
            if o.mode == 'ffmpeg' then
                local index = string.format("0:%d", track_index)
                args = {'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-i', path, "-map", index, subtitles_file}
                msg.info("ffmpeg mode")
            elseif o.mode == 'mkvextract' then
                local mkve_index = string.format("%d", track_index)
                args = {'mkvextract', 'tracks', path, mkve_index .. ":" .. subtitles_file}
                msg.info("mkvextract mode")
            else
                msg.info("Incorrectly set mode: " .. o.mode)
                mp.osd_message("Incorrectly set mode, check console for more info.")
                break
            end

            -- construct a table and set its contents to be the extract command
            local table = {}
            table.name = "subprocess"
            table.args = args
            local res = mp.command_native(table)

            -- report if the command ran successfully or not
            if res.status == 0 then
                msg.info("Finished exporting subtitles")
                mp.osd_message("Finished exporting subtitles")
            else
                msg.info("Failed to export subtitles")
                mp.osd_message("Failed to export subtitles, check console for more info.")
            end

            if o.ass2txt and string.match(subtitles_file, "(.ass)$") then
                assert(loadfile(o.ass2txt_dir))(subtitles_file,o.incl_timestamps)
            end

            break
        end
        i = i + 1
    end
end

mp.register_script_message("export-selected-subtitles", export_selected_subtitles)