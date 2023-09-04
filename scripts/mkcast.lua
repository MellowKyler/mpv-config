utils = require 'mp.utils'

function mkcast()
    local path = mp.get_property('path')
    cmd = string.format("mkchromecast --video -i '%s'",
        path)
    --args = { 'mkchromecast', '--video', '-i', path }
    --utils.subprocess({ args = args }) --this is to run the command directly, but mkchromecast can't clean up after itself and everything hangs

    local clipboard_cmd = string.format("xclip -silent -in -selection clipboard")

    local pipe = io.popen(clipboard_cmd, "w")
    pipe:write(cmd)
    pipe:close()

    mp.osd_message(string.format("Copied to clipboard"))

    args = { "gnome-terminal" }
    utils.subprocess({ args = args})
end

--mp.add_key_binding("Alt+u", "mkcast", mkcast)
mp.register_script_message("mkcast", mkcast)