
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local function export_selected_subtitles()

    local i = 0
    local tracks_count = mp.get_property_number("track-list/count")

    while i < tracks_count do

        msg.info("i COUNT: " .. i)
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
            msg.info("PATH: "..path)
            msg.info("DIR: "..dir)
            msg.info("PATH_FILENAME: "..path_filename)
            --local working_directory = mp.get_property("working-directory")
            --msg.info("WORKING DIRECTORY: ".. working_directory)
            --local filename_ext = mp.get_property("filename")
            --msg.info("FILENAME_EXT: ".. filename_ext)
            local filename = mp.get_property("filename/no-ext")
            msg.info("FILENAME: ".. filename)
            --video_file needs, the extension
            --local video_file = working_directory .. "/" .. filename_ext
            --msg.info("VIDEO_FILE: ".. video_file)
            --subtitles file doesn't want it
            local subtitles_file = dir .. filename .. subtitles_ext
            msg.info("SUBTITLES_FILE : ".. subtitles_file)
            --subtitles_file = string.gsub(subtitles_file,"/","")

            msg.info("Exporting selected subtitles")
            mp.osd_message("Exporting selected subtitles")

            local track_index = mp.get_property_number(string.format("track-list/%d/ff-index", i))
            msg.info("TRACK_INDEX: ".. track_index)

            --mkvextract
            local mkve_index = string.format("%d", track_index)
            --args = {'mkvextract', 'tracks', video_file, mkve_index .. ":" .. subtitles_file}
            cmd = "mkvextract tracks " .. path .. " " .. mkve_index .. ":" .. subtitles_file
            msg.info("ARGS: ".. cmd)

            -- ffmpeg
            -- local index = string.format("0:%d", track_index)
            -- args = { 'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-i', video_file, "-map", index, subtitles_file }
            -- cmd = string.format("ffmpeg -y -hide_banner -loglevel error -i '%s' -map '%s' -vn -an -c:s copy '%s'",
            --    video_file, index, subtitles_file)
            -- args = { 'bash', cmd }

            local table = {}
            table.name = "subprocess"
            table.args = {'mkvextract', 'tracks', path, mkve_index .. ":" .. subtitles_file}
            --local res = mp.command_native_async(table, callback)
            local res = mp.command_native(table)
            if res.status == 0 then
                msg.info("Finished exporting subtitles")
                mp.osd_message("Finished exporting subtitles")
            else
                msg.info("Failed to export subtitles")
                mp.osd_message("Failed to export subtitles, check console for more info.")
            end
            --process()
            --mp.add_timeout(mp.get_property_number("osd-duration") * 0.001, process)

        end
        i = i + 1
    end
end

function callback(success, result, err)
    if result.status == 0 then
        msg.info("Finished exporting subtitles")
        mp.osd_message("Finished exporting subtitles")
    else
        msg.info("Failed to export subtitles")
        mp.osd_message("Failed to export subtitles, check console for more info.")
        msg.info("SUCCESS?: ".. tostring(success))
        for index, data in ipairs(result) do
            msg.info("RESULT.STATUS: "..result.status)
            msg.info(index)
            for key, value in pairs(data) do
                msg.info('\t', key, value)
            end
        end
        -- for results in result do
        --     msg.info("RESULT: ".. results)
        -- end
        if err ~= nil then
            msg.info("ERROR: ".. err)
        end
    end
end

function process()
    --local screenx, screeny, aspect = mp.get_osd_size()
    --mp.set_osd_ass(screenx, screeny, "{\\an9}● ")
    
    -- local table = {}
    -- table.name = "subprocess"
    -- table.args = {"python", script_dir.."open-anilist-page.py", search_str}
    -- local res = mp.command_native_async(table, callback)

    local res = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        playback_only = false,
        args = args 
    })

    --mp.set_osd_ass(screenx, screeny, "")

    if res.status == 0 then
        msg.info("Finished exporting subtitles")
        mp.osd_message("Finished exporting subtitles")
    else
        msg.info("Failed to export subtitles")
        mp.osd_message("Failed to export subtitles, check console for more info.")
    end
end

mp.register_script_message("export-selected-subtitles", export_selected_subtitles)