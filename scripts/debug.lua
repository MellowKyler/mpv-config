local msg = require 'mp.msg'
local utils = require 'mp.utils'

local function dump_properties()
    local working_directory = mp.get_property("working-directory")
    local path = mp.get_property('path')
    local dir, path_filename = utils.split_path(path)
    local video_file = utils.join_path(dir, path_filename)
    local filename = mp.get_property('filename')
    local filename_no_ext = mp.get_property('filename/no-ext')

    msg.info("WORKING DIRECTORY: "..working_directory)
    msg.info("PATH: "..path)
    msg.info("DIR: "..dir)
    msg.info("PATH_FILENAME: "..path_filename)
    msg.info("VIDEO_FILE: "..video_file)
    msg.info("FILENAME: "..filename)
    msg.info("FILENAME_NO_EXT: "..filename_no_ext)

    mp.osd_message("dump_properties done")
end

mp.add_key_binding('Alt+w', dump_properties)