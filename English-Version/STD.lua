os = require("os")
c = require("component")
event = require("event")
term = require("term")
pc = require("computer")
fs = require("filesystem")
local gpu = c.gpu
local sg = c.stargate
settings = dofile("settings.cfg")
local username = settings.username
function clear()
    gpu.setForeground(0xFFFFFF)
    term.clear()
end
function help()
    sg.sendIrisCode(1234)
    gpu.setForeground(0xFFFFFF) print("Welcome to Stargate Data Transmitter v0.0.1)
    print("Press t to type message")
    print("Press q to exit")
end
clear()
help()
local function cancel ()
cancelEvents(key)
end
while true do
    os.sleep(0.1)
    event.listen("code_respond", function(_, _, _, message)
        message2 = string.gsub(message,"(§r)", "")
        print(message2)
    end)
    key = event.listen("key_down", function(_, _, _, key, _)
        if key == 16 then
            sg.sendMessageToIncoming(username .. ": " .. "left")
            os.execute("off.lua")
            os.sleep(2)
            pc.shutdown(1)
        elseif key == 20 then
            gpu.setForeground(0x33f5ff)
            print("write message:")
            message = io.read()
            sg.sendMessageToIncoming(username .. ": " .. message)
            cancel()
        end
    end)
end
