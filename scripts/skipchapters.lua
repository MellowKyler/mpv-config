local options = require 'mp.options'

local o = {
    skip_chapter_list = dofile('/home/kyler/.config/mpv/scripts/.utils/chapters_to_skip.lua'),
}
options.read_options(o)

function check_chapter(_, chapter)
    if not chapter then
        return
    end
    for _, p in pairs(o.skip_chapter_list) do
        if string.match(chapter, p) then
            print("Skipping chapter:", chapter)
            mp.command("no-osd add chapter 1")
            return
        end
    end
end

mp.observe_property("chapter-metadata/by-key/title", "string", check_chapter)


-- require 'mp.options'

-- local opt = {
--     patterns = {
--         "OP","[Oo]pening$", "^[Oo]pening:", "[Oo]pening [Cc]redits",
--         "ED","[Ee]nding$", "^[Ee]nding:", "[Ee]nding [Cc]redits", "Closing",
--         "[Pp]review$", "Next Prev.", "Next", "Preview", "PV",
-- 		--Temporary
--         --The World God Only Knows
--         "Chapter 2", "Chapter 5", "Chapter 6", "Chapter 7", "Chapter 8",
-- 		--"Chapter 02", "Chapter 05", "Chapter 06",
--         --"Chapter 2", "Chapter 5", "Chapter 6",
-- 		--"Prologue",
--     },
-- }
-- read_options(opt)

-- function check_chapter(_, chapter)
--     if not chapter then
--         return
--     end
--     for _, p in pairs(opt.patterns) do
--         if string.match(chapter, p) then
--             print("Skipping chapter:", chapter)
--             mp.command("no-osd add chapter 1")
--             return
--         end
--     end
-- end