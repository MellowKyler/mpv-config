-- TODO: not quite ready for prime time yet, even tho fully complete basically
-- change keybind assignment and function names, the variable names are confusing
-- figure out what youre gonna do with time_remaining.lua as a result


local utils = require 'mp.utils'
local msg = require 'mp.msg'
local options = require 'mp.options'

local o = {
    mode="lua",
    skipped_chapters = dofile('/home/kyler/.config/mpv/scripts/.utils/chapters_to_skip.lua'),
}
options.read_options(o)

local function format_time(seconds)
    local parts = {}
    parts.h = math.floor(seconds / 3600)
    parts.m = math.floor(seconds / 60) % 60
    parts.s = math.floor(seconds % 60)
    local ret = string.format("%02dm%02ds", parts.m, parts.s)
    if parts.h > 0 then ret = string.format('%dh%s', parts.h, ret) end
    return ret
end

local function get_cmd()
    local path = mp.get_property('path')
    local dir, path_filename = utils.split_path(path)
    local cmd = {}
    if o.mode == "raw" then
        cmd = { 'dir-dur', dir, "def", "raw" }
    elseif o.mode == "silent" then
        cmd = { 'dir-dur', dir, "def", "silent" }
    elseif o.mode == "lua" then
        local split_file_dur = mp.get_property('duration')
        cmd = { 'dir-dur', dir:sub(1, -2), 'def', 'lua', tostring(path), tostring(split_file_dur) }
    else
        cmd = { 'dir-dur', dir, "def", "silent" }
    end
    return cmd
end

local function assign_vars(output)
    local splitpoint, remaining, total
    local i = 1
    for seconds in output:gmatch("[^,]+") do
        if i == 1 then
            -- splitpoint = format_time(tonumber(seconds))
            splitpoint = tonumber(seconds)
        elseif i == 2 then
            -- remaining = format_time(tonumber(seconds))
            remaining = tonumber(seconds)
        elseif i == 3 then
            -- total = format_time(tonumber(seconds))
            total = tonumber(seconds)
        end
        i = i + 1
    end
    return splitpoint, remaining, total
end

local function skip_calc()
    local duration = mp.get_property('duration')
    local chapter_count = tonumber(mp.get_property('chapter-list/count'))
    local playlist_count = tonumber(mp.get_property('playlist-count'))
    local playlist_pos = tonumber(mp.get_property('playlist-pos-1'))
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
    -- duration = duration - skipped_time
    -- assume same skipped time in every video
    -- time_remaining doesn't take into account skipped chapters for the currently playing video
    -- skipped_time = (skipped_time * (playlist_count - playlist_pos - 1))
    return skipped_time, ep_skip_info
end

local function dump_properties()
    local playlist_count = tonumber(mp.get_property('playlist-count'))
    local playlist_pos = tonumber(mp.get_property('playlist-pos-1'))
    local cmd = get_cmd()
    local r = mp.command_native({ name = "subprocess", playback_only = false, capture_stdout = true, args = cmd })
    local output = tostring(r.stdout):sub(1, -2)
    local splitpoint, remaining, total = assign_vars(output)
    local skip_per_ep, ep_skip_info = skip_calc()
    local remaining = remaining - (skip_per_ep * (playlist_count - playlist_pos - 1))
    local skip_sum = (skip_per_ep * playlist_count)
    local skip_total = total - skip_sum

    local speed = tonumber(mp.get_property('speed'))
    speed_time = remaining / speed

    local printout = "Remaining: "..format_time(remaining).."\nWithSpeed: "..format_time(speed_time).."\nSkipPerEP: "..ep_skip_info
    mp.osd_message(printout,5)
    msg.info(printout)
    -- msg.info("Remaining: "..remaining)
    -- msg.info("Total: "..total)
    -- mp.osd_message("Remaining: "..remaining,5)
end



-- replace dump_properties
-- replace keybinding
mp.add_key_binding('Alt+w', dump_properties)
