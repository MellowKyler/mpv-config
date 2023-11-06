local msg = require 'mp.msg'
local utils = require 'mp.utils'

local function dump_properties()
    -- local working_directory = mp.get_property("working-directory")
    -- local path = mp.get_property('path')
    -- local dir, path_filename = utils.split_path(path)
    -- local video_file = utils.join_path(dir, path_filename)
    -- local filename = mp.get_property('filename')
    -- local filename_no_ext = mp.get_property('filename/no-ext')

    -- msg.info("WORKING DIRECTORY: "..working_directory)
    -- msg.info("PATH: "..path)
    -- msg.info("DIR: "..dir)
    -- msg.info("PATH_FILENAME: "..path_filename)
    -- msg.info("VIDEO_FILE: "..video_file)
    -- msg.info("FILENAME: "..filename)
    -- msg.info("FILENAME_NO_EXT: "..filename_no_ext)

    msg.info("playlist-pos: "..(mp.get_property('playlist-pos')))
    msg.info("playlist-pos-1: "..(mp.get_property('playlist-pos-1')))
    msg.info("playlist-current-pos: "..(mp.get_property('playlist-current-pos')))
    msg.info("playlist-playing-pos: "..(mp.get_property('playlist-playing-pos')))
    msg.info("playlist-count: "..(mp.get_property('playlist-count')))
    msg.info("video-speed-correction: "..(mp.get_property('video-speed-correction')))
    msg.info("audio-speed-correction: "..(mp.get_property('audio-speed-correction')))
    msg.info("speed: "..(mp.get_property('speed')))
    msg.info("duration: "..(mp.get_property('duration')))
    msg.info("time-remaining: "..(mp.get_property('time-remaining')))

    mp.osd_message("dump_properties done")
end

--mp.add_key_binding('Alt+w', dump_properties)