local msg = require 'mp.msg'
local utils = require 'mp.utils'
local options = require "mp.options"



local function test()
    args = { "ffmpeg -y -hide_banner -loglevel error -i './test.mkv' -map '0:4' -vn -an -c:s copy './test.Shiro (WBDP).jpn.ass'" }
    utils.subprocess({ args = args })
end

--mp.add_key_binding('b', test)