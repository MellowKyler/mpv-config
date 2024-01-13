--consider adding "Comments" as a valid match alongside dialogue

local function split(str, sep, incl_time)
    local time = ""
    for i=1,9 do
        if i==2 and incl_time then time = "["..str:match("^.-,"):gsub(",$","").."] " end
        str = str:gsub("^.-,","")
    end
    return time..str
end

local function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

local function ass2txt(file, incl_time)
    if not file_exists(file) then return io.write("File does not exist") end
    if incl_time == "false" then incl_time = false end
    txt = file:gsub("%.ass$", "")..".txt"
    local out = io.open(txt, 'w')
    for line in io.lines(file) do
        if string.match(line, "^Title: ") then line = line.."\n"
        elseif string.match(line, "^Last Style Storage: ") then line = line.."\n\n"
        elseif string.match(line, "^Dialogue: ") then line = split(line, ",", incl_time):gsub("%b{}",""):gsub("\\N","")
        else line = "" end
        if line ~= nil then out:write(line) end
    end
    out:close()
end

--manual entry
if ... == nil then
    io.write("ASS file: ")
    local file = io.read()
    io.write("Include time boolean: ")
    local incl_time = io.read()
    ass2txt(file, incl_time)
else ass2txt(...) end
