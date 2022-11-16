os = require("os")
term = require("term")
c = require("component")
pc = require("computer")
sg = c.stargate
term.clear()
local g,d = sg.disengageGate()
if d == "stargate_failure_wrong_end" then
    print("Unable to close incoming wormhole.")
elseif d == "stargate_failure_not_open" then
    print("Aborting Dialing Sequence.")
    sg.abortDialing()
elseif g == "stargate_disengage" then
    print("StarGate Closed successfully.")
end