--lua script that is a rounding function
--tostring
--find position of '.'
--multiply by 1XXX (number of zeros = how many digits you want to be accurate to)
--math.floor
--divide by 1XXX


local msg = require 'mp.msg'
local options = require 'mp.options'

local o = {
    skipped_chapters = dofile('/home/kyler/.config/mpv/scripts/.shared_utils/chapters_to_skip.lua'),
    toggle_mode = true,
}
options.read_options(o)

-- local o = {
--     patterns = {
--         "OP","[Oo]pening$", "^[Oo]pening:", "[Oo]pening [Cc]redits",
--         "ED","[Ee]nding$", "^[Ee]nding:", "[Ee]nding [Cc]redits", "Closing",
--         "[Pp]review$", "Next Prev.", "Next", "Preview", "PV",
-- 		--Temporary
--         --The World God Only Knows
--         --"Chapter 2", "Chapter 5", "Chapter 6", "Chapter 7", "Chapter 8",
-- 		--"Chapter 02", "Chapter 05", "Chapter 06",
--         --"Chapter 2", "Chapter 5", "Chapter 6",
-- 		--"Prologue",
--     },
-- }
-- options.read_options(o)

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
        -- for k , skipped in pairs(opt.patterns) do
        for k , skipped in pairs(o.skipped_chapters) do
            if string.match(title,skipped) then
                msg.info("Skipped match: "..skipped.." and "..title)
                if i+1 == chapter_count then end_time = duration
                else
                    end_time = tonumber(mp.get_property('chapter-list/'..tostring(i+1)..'/time'))
                end
                local start_time = tonumber(mp.get_property('chapter-list/'..tostring(i)..'/time'))
                skipped_time = skipped_time + (end_time - start_time)
            end
        end
    end
    ep_skip_info = format_time(skipped_time).." ("..(math.floor((skipped_time/duration)*10000)/100).."%)"
    --msg.info("Time skipped per episode: "..ep_skip_info)
    duration = duration - skipped_time
    return duration, ep_skip_info
end

local on_screen = false

local function time_remaining()
    -- -- // Turn off OSD if in use // --
    -- if on_screen == true then
    --     mp.commandv("set", "osd-msg1", "")
    --     on_screen = false
    --     msg.info("Turning off OSD...")
    --     return
    -- end
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
    local printout = "Remaining: "..time.."\nWith speed: "..speed_time.."\nSkipPerEP: "..ep_skip_info
    --mp.osd_message(printout,5)
    if o.toggle_mode == false then
        mp.osd_message(printout,5)
        msg.info(printout)
    elseif o.toggle_mode == true then
        mp.commandv("set", "osd-msg1", printout)
        msg.info(printout)
        on_screen = true
    end
end

local function delay_loop()
    -- // Turn off OSD if in use // --
    if on_screen == true then
        mp.commandv("set", "osd-msg1", "")
        on_screen = false
        timer:kill()
        msg.info("Turning off OSD...")
        return
    elseif on_screen == false then
        time_remaining()
        timer = mp.add_periodic_timer(5, function() time_remaining() end)
    end
end

mp.add_key_binding('Alt+w', time_remaining)
mp.add_key_binding('Alt+Shift+w', delay_loop)