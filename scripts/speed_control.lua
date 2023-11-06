--local msg = require 'mp.msg'

-- prev_speed needs to be set every time a new mpv process is launched, so it will be nil on first input no matter what
-- current behavior: when prev_speed is nil, run the command, and set prev_speed = cur_speed
-- if persist properties has set the cur_speed, cur_speed *should* still apply, but I haven't verified this

-- this works because prev_speed is a global variable (*CORRECTION*: actually i just local it outside the function)
-- a fallback alternative solution to do this:
--  use a file in /tmp/ to track prev_speed, overwriting it each time
--  would behave differently, as prev_speed would maintain between processes and would only reset on OS restart
--  I like how the current version works better so we're keeping this

local prev_speed

local function set_speed(command, value)
    return function() --still don't understand how this works with input parameters
        local cur_speed = tonumber(mp.get_property("speed")) --can also omit tonumber and set the input values to "1.000000" strings, but this seems more consistent and durable
        local set_value = value -- have to use an intermediary variable otherwise when value gets updated it persists weirdly and doesn't reset with new key input
        --msg.info("CURRENT SPEED TYPE: ".. type(cur_speed)) -- command to get the type of a variable (string vs number)
        if (command == "set") and (cur_speed == set_value) and (prev_speed ~= nil) then
            set_value = prev_speed
        end
        -- commandv works, but doesn't give osd, also some weirdness with non-set commands interacting with prev_speed
        --mp.commandv(command, "speed", set_value)
        mp.command( command .. " speed " .. set_value )
        prev_speed = cur_speed
    end
end

mp.register_script_message('r-speed', set_speed('set', 1))
mp.register_script_message('g-speed', set_speed('set', 2))
mp.register_script_message('h-speed', set_speed('set', 3))

mp.register_script_message('d-speed', set_speed('add', .5))
mp.register_script_message('s-speed', set_speed('add', -.5))
mp.register_script_message('c-speed', set_speed('add', .25))
mp.register_script_message('x-speed', set_speed('add', -.25))

mp.register_script_message('double-speed', set_speed('multiply', 2))
mp.register_script_message('half-speed', set_speed('multiply', .5))
mp.register_script_message('mult-.1-speed', set_speed('multiply', 1.1))
mp.register_script_message('div-.1-speed', set_speed('multiply', 1/1.1))

-- new input.conf

-- r script-message-to speed_control r-speed
-- g script-message-to speed_control g-speed
-- h script-message-to speed_control h-speed
-- d script-message-to speed_control d-speed
-- s script-message-to speed_control s-speed
-- c script-message-to speed_control c-speed
-- x script-message-to speed_control x-speed

-- Shift+d script-message-to speed_control double-speed
-- Shift+s script-message-to speed_control half-speed
-- Shift+c script-message-to speed_control mult-.1-speed
-- Shift+x script-message-to speed_control div-.1-speed

-- old input.conf

--r set speed 1
--g set speed 2
--h set speed 3
--d add speed .5
-- s add speed -.5
-- c add speed .25
-- x add speed -.25

--Shift+d multiply speed 2
--Shift+s multiply speed 0.5
--Shift+c multiply speed 1.1
--Shift+x multiply speed 1/1.1