-- /home/kyler/.local/bin/setwindow
-- REQUIRES wmctrl AND xdotool
-- setwindow <application + parameters> <horizontal-position> <vertical-position> <horizontal-size> <vertical-size>
-- more precisely: horizontal position pixels from left boundary, vertical position pixels from top
-- 970 900 960 512 is bottom right corner (with two monitors)
-- 2890 900 960 512 is bottom right corner (with tv + two monitors)
-- you have to be EXTREMELY CAREFUL with positioning and adding monitors since it completely switches values
--      even the relative height of a side monitor can shift things
-- wmctrl -Gl lists windows and their geometry

-- two approaches: 
--      1) an array with coords listed
--      2) a wrapper to call the function itself

local coords = {
    -- --tv plus two monitors
    -- "2890", -- horizontal position
    -- "900",  -- vertical position
    -- "960",  -- horizontal size
    -- "512",  -- vertical size
    --two monitors
    "970", -- horizontal position
    "900",  -- vertical position
    "960",  -- horizontal size
    "512",  -- vertical size
}
return coords







--local function setwindow_coords