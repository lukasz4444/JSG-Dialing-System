os = require("os")
term = require("term")
c = require("component")
pc = require("computer")
sg = c.stargate
term.clear()
local g,d = sg.disengageGate()
if d == "stargate_failure_wrong_end" then
    print("Nie można wyłączyć przychodzącego tunelu")
elseif d == "stargate_failure_not_open" then
    print("Anuluję ciąg")
    sg.abortDialing()
elseif g == "stargate_disengage" then
    print("Wrota pomyślnie wyłączono.")
end