
local msg = require 'mp.msg'
local options = require 'mp.options'

local o = {
    skipped_chapters = dofile('/home/kyler/.config/mpv/scripts/.utils/chapters_to_skip.lua'),
    --toggle = true,
}
options.read_options(o)

local on_screen = false

local function format_time(seconds)
    local parts = {}
    parts.h = math.floor(seconds / 3600)
    parts.m = math.floor(seconds / 60) % 60
    parts.s = math.floor(seconds % 60)
    local ret = string.format("%02dm%02ds", parts.m, parts.s)
    if parts.h > 0 then ret = string.format('%dh%s', parts.h, ret) end
    return ret
end

local function skip_calc(duration,chapter_count)
    local end_time
    local skipped_time = 0
    for i=0,chapter_count-1 do
        local title = mp.get_property('chapter-list/'..tostring(i)..'/title')
        for k , skipped in pairs(o.skipped_chapters) do
            if string.match(title,skipped) then
                msg.info("Skipped chapter match: "..skipped.." and "..title)
                if i+1 == chapter_count then end_time = duration
                else end_time = tonumber(mp.get_property('chapter-list/'..tostring(i+1)..'/time'))
                end
                local start_time = tonumber(mp.get_property('chapter-list/'..tostring(i)..'/time'))
                skipped_time = skipped_time + (end_time - start_time)
            end
        end
    end
    ep_skip_info = format_time(skipped_time).." ("..(math.floor((skipped_time/duration)*10000)/100).."%)"
    duration = duration - skipped_time
    return duration, ep_skip_info
end

local function time_remaining(toggle)
    return function()
        --toggle = o.toggle
        if on_screen == true then 
            mp.commandv("set", "osd-msg1", "")
            msg.info("Turning off OSD...")
            on_screen = not on_screen
            return
        end
        -- // Get Properties // --
        local playlist_count = tonumber(mp.get_property('playlist-count'))
        local playlist_pos = tonumber(mp.get_property('playlist-pos-1'))
        local speed = tonumber(mp.get_property('speed'))
        local duration = tonumber(mp.get_property('duration'))
        local time_remaining = tonumber(mp.get_property('time-remaining'))
        local chapter_count = tonumber(mp.get_property('chapter-list/count'))
        -- // Calculations // --
        duration, ep_skip_info = skip_calc(duration,chapter_count)
        local seconds = (duration * (playlist_count - playlist_pos - 1)) + time_remaining
        local speed_seconds = seconds / speed
        local time = format_time(seconds)
        local speed_time = format_time(speed_seconds)
        -- // Output // --
        local printout = "Remaining: "..time.."\nWithSpeed: "..speed_time.."\nSkipPerEP: "..ep_skip_info
        if toggle == false then
            mp.osd_message(printout,5)
            msg.info(printout)
            return
        end
        mp.commandv("set", "osd-msg1", printout)
        msg.info(printout)
        on_screen = not on_screen
        return
    end
end

mp.add_key_binding('Alt+p', 'time-rem', time_remaining(false))
mp.add_key_binding('Alt+Shift+p', 'time-rem-toggle', time_remaining(true))
-- mp.register_script_message('time-rem', time_remaining(false))
-- mp.register_script_message('time-rem-toggle', time_remaining(true))