
local msg = require 'mp.msg'
local utils = require 'mp.utils'

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
            -- commented out msg.infos below are for debugging
            local path = mp.get_property('path')
            local dir, path_filename = utils.split_path(path)
            --msg.info("PATH: "..path)
            --msg.info("DIR: "..dir)
            --msg.info("PATH_FILENAME: "..path_filename)
            local filename = mp.get_property("filename/no-ext")
            --msg.info("FILENAME: ".. filename)
            local subtitles_file = dir .. filename .. subtitles_ext
            --msg.info("SUBTITLES_FILE : ".. subtitles_file)

            msg.info("Exporting selected subtitles")
            mp.osd_message("Exporting selected subtitles")

            -- get the track index in ffmpeg acceptable form (also works for mkvextract)
            local track_index = mp.get_property_number(string.format("track-list/%d/ff-index", i))
            --msg.info("TRACK_INDEX: ".. track_index)

            -- specific index variables and debugging msg.infos depending on mode
            -- decided against an options.mode for this script since they're basically identical
            -- mkvextract mode
            local mkve_index = string.format("%d", track_index)
            -- cmd = "mkvextract tracks " .. path .. " " .. mkve_index .. ":" .. subtitles_file
            -- msg.info("ARGS: ".. cmd)

            -- ffmpeg mode
            local index = string.format("0:%d", track_index)
            -- cmd = string.format("ffmpeg -y -hide_banner -loglevel error -i '%s' -map '%s' -vn -an -c:s copy '%s'",
            --    path, index, subtitles_file)
            -- msg.info("ARGS: "..cmd)

            -- construct a table and set its contents to be the extract command
            local table = {}
            table.name = "subprocess"
            table.args = {'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-i', path, "-map", index, subtitles_file}
            --table.args = {'mkvextract', 'tracks', path, mkve_index .. ":" .. subtitles_file}
            local res = mp.command_native(table)

            -- report if the command ran successfully or not
            if res.status == 0 then
                msg.info("Finished exporting subtitles")
                mp.osd_message("Finished exporting subtitles")
            else
                msg.info("Failed to export subtitles")
                mp.osd_message("Failed to export subtitles, check console for more info.")
            end

        end
        i = i + 1
    end
end

mp.register_script_message("export-selected-subtitles", export_selected_subtitles)