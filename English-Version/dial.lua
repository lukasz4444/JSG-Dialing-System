os = require("os")
c = require("component")
event = require("event")
term = require("term")
pc = require("computer")
sh = require("shell")
local dir = "/JDS"
sh.setWorkingDirectory(dir)
local settings = dofile("settings.cfg")
local DHDPresent = false
if not c.isAvailable("stargate") then
  io.stderr:write("StarGate not connected.")
  os.exit(1)
elseif c.isAvailable("stargate") then
  sg = c.stargate
end

local function openchoice()
    stargate_incoming_wormhole = event.listen("stargate_incoming_wormhole", function(_, _, caller, dialedAddressSize)
        print("OffWorld Activation!")
        os.sleep(4)     
    end)
  term.clear()
  print("What JDS should do:")
  print("1. Disengage the gate!")
  print("2. Send Iris Code")
  choice = io.read()
  if choice == "1" then 
    os.execute("off.lua") 
    pc.shutdown(true) 
  end
  if choice == "2" then 
    print("Please Write Iris Code")
    local iriscode = tonumber(io.read())
    sg.sendIrisCode(iriscode)
    code_respond = event.listen("code_respond", function(_, _, caller, msg)
      msg = string.sub(msg, 1, -3)
      print("")
      print(msg)
      os.sleep(10)
      openchoice()
    end)
    openchoice()
  end
end

if settings.usedhd == true then
  if not c.isAvailable("dhd") then
    io.stderr:write("DHD not connected.")
    os.exit(1)
  elseif c.isAvailable("dhd") then
    dhd = c.dhd
    DHDPresent = true
  end
end

local sgtype = sg.getGateType()
address = {}
glyphs = {
  "Andromeda",
  "Aquarius",
  "Aquila",
  "Aries",
  "Auriga",
  "Bootes",
  "Cancer",
  "Canis Minor",
  "Capricornus",
  "Centaurus",
  "Cetus",
  "Corona Australis",
  "Crater",
  "Equuleus",
  "Eridanus",
  "Gemini",
  "Hydra",
  "Leo Minor",
  "Leo",
  "Libra",
  "Lynx",
  "Microscopium",
  "Monoceros",
  "Norma",
  "Orion",
  "Pegasus",
  "Perseus",
  "Pisces",
  "Piscis Austrinus",
  "Sagittarius",
  "Scorpius",
  "Sculptor",
  "Scutum",
  "Serpens Caput",
  "Sextans",
  "Taurus",
  "Triangulum",
  "Virgo"
}
term.clear()
function manualDial()
  print("Symbol List: ")
  for i, v in ipairs(glyphs) do
    if i < 20 then
      if (i > 2 and i < 8) or i == 11 or i == 13 or i == 16 or i == 17 or i == 19 then
        print(i, v, "\t\t" .. i + 19, glyphs[i + 19])
      elseif i == 12 then print(i, v, i + 19, glyphs[i + 19])
      else print(i, v, "\t" .. i + 19, glyphs[i + 19]) end
    else break end
  end
  print("Enter the address in comma separated numbers or 'q' to quit.")

  raw_address = io.read()
  if raw_address == "q" then os.exit() end

  address = {}
  for num in string.gmatch(raw_address, '([^,]+)') do
    table.insert(address, glyphs[tonumber(num)])
  end

  print("Is this address correct? (y/n)")
  for i, v in ipairs(address) do print(i, v) end
  choice = io.read()
  if choice ~= "y" then os.exit() end
end
term.clear()
saved_addresses = {}
lines = {}
file = "addresses.csv"

for line in io.lines(file) do lines[#lines + 1] = line end
for i = 1, #lines do
  local t = {}
  for w in lines[i]:gmatch("([^,]+),?") do table.insert(t, w) end
  table.insert(saved_addresses, t)
end
print("To what stargate you wanna open wormhole? (NUMBERS ONLY!)")
print("0. Manual Input (Milky Way stargate only!)")
for i = 1, #saved_addresses do print(i .. ". " .. saved_addresses[i][1]) end

choice = io.read()
if choice == "0" then manualDial()
elseif tonumber(choice) ~= nil then
  index = tonumber(choice)
  if (saved_addresses[index] ~= nil) or (saved_addresses[index] ~= {}) then
    for i = 2, #(saved_addresses[index]) do
      table.insert(address, saved_addresses[index][i])
    end
  else
    print("Incorrect Choice.")
    os.exit()
  end
else
  print("Incorrect Choice.")
  os.exit()
end
if sgtype == "MILKYWAY" then
  table.insert(address, "Point of Origin")
end

if sgtype == "UNIVERSE" then
  table.insert(address, "G17")
end

if sgtype == "PEGASUS" then
  table.insert(address, "SUBIDO")
end

loop = true
term.clear()
  function DHDDial(dialed)
    glyph = address[dialed + 1]
    os.sleep(0.5)
    dhd.pressButton(glyph)
  end
  function dialNext(dialed)
    glyph = address[dialed + 1]
    local test = dialed
    local test = test + 1
    print("Chevron " .. test .. " Encoded -", glyph)
    sg.engageSymbol(glyph)
  end
print("Sequence in progress.")

key_down = event.listen("key_down", function(_, _, _, code, _)
  if code == 208 then
    os.execute("off.lua")
    os.sleep(0.4)
    if settings.dorestart == true then
      pc.shutdown(1)
    else
      pc.shutdown()
    end
  end
end)

function cancelEvents()
  event.cancel(eventEngaged)
  event.cancel(openEvent)
  event.cancel(failEvent)
  event.cancel(key_down)
  loop = false
end

eventEngaged = event.listen("stargate_spin_chevron_engaged", function(evname, address, caller, num, lock, glyph)
  if lock then
    print("Chevron " .. num .. " Locked -", glyph)
    os.sleep(0.5)
    sg.engageGate()
  else
    print("Chevron " .. num .. " Locked -", glyph)
    os.sleep(0.5)
  dialNext(num)
  end
end)
DHD = event.listen("stargate_dhd_chevron_engaged", function(evname, address, caller, num, lock, glyph)
  if lock then
    lock = true
    print("Chevron " .. num .. " Locked")
    os.sleep(0.2)
    dhd.pressBRB()
  else
    print("")
    print("Chevron " .. num .. " Locked -", glyph)
    print("")
    os.sleep(0.1)
    DHDDial(num)
  end
end)

if settings.usedhd == true then
  DHDDial(0)
elseif settings.usedhd == false then
  dialNext(0)
end
  openEvent = event.listen("stargate_open", function()
    print("StarGate Open!")
    if not settings.justone == true then
      openchoice()
    end
    if settings.justone == true then
      while true do
        sending = event.listen("stargate_traveler", function(inbound,_,_)
          if inbound == "stargate_traveler" then
            os.execute("off.lua")
            if settings.dorestart == true then
              pc.shutdown(1)
            else
              pc.shutdown()
            end
          end
        end)
        os.sleep(0.1)
      end
      cancelEvents()
    end
    os.sleep(3)
    cancelEvents()
  end)
  failEvent = event.listen("stargate_failed", function(address, caller, reason)
    print("Unable to establish a connection:")
  end)
  eventEngaged = event.listen("stargate_spin_chevron_engaged", function(_, _, caller, num, lock, glyph) end)
  failEvent = event.listen("stargate_failed", function(_, _, caller, reason)
    if reason == "not_enough_power" then print("Not enough power to open!") end
    if reason == "address_malformed" then print("StarGate not Found.") end
    if reason == "aborted" then print("Universe Dialer aborted dialing sequence.") end
    cancelEvents()
  end)
  while loop do os.sleep(0.1) end
