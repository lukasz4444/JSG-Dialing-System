os = require("os")
c = require("component")
event = require("event")
term = require("term")
pc = require("computer")
local settings = require("settings")
local DHDPresent = false
if not c.isAvailable("stargate") then
  io.stderr:write("Nie Podłączono Gwiezdnych Wrót.")
  os.exit(1)
elseif c.isAvailable("stargate") then
  sg = c.stargate
end

if settings.usedhd == true then
  if not c.isAvailable("dhd") then
    io.stderr:write("Nie Podłączono Sterownika Gwiezdnych Wrót. (DHD) ")
    os.exit(1)
  elseif c.isAvailable("dhd") then
    dhd = c.dhd
    DHDPresent = true
  end
end

local typ = sg.getGateType()
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
  print("Lista Symboli: ")
  for i, v in ipairs(glyphs) do
    if i < 20 then
      if (i > 2 and i < 8) or i == 11 or i == 13 or i == 16 or i == 17 or i == 19 then
        print(i, v, "\t\t" .. i + 19, glyphs[i + 19])
      elseif i == 12 then print(i, v, i + 19, glyphs[i + 19])
      else print(i, v, "\t" .. i + 19, glyphs[i + 19]) end
    else break end
  end
  print("Wprowadź adres w liczbach oddzielonych przecinkami lub 'q' , aby przerwać.")

  raw_address = io.read()
  if raw_address == "q" then os.exit() end

  address = {}
  for num in string.gmatch(raw_address, '([^,]+)') do
    table.insert(address, glyphs[tonumber(num)])
  end

  print("Czy ten adres jest poprawny? (t/n)")
  for i, v in ipairs(address) do print(i, v) end
  choice = io.read()
  if choice ~= "t" then os.exit() end
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
print("Do jakich wrót chcesz otworzyć tunel? (WPROWADZAJ TYLKO LICZBY!)")
print("0. Manualne Wprowadzanie (Tylko wrota MilkyWay.)")
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
    print("Niewłaściwy wybór.")
    os.exit()
  end
else
  print("Niewłaściwy wybór.")
  os.exit()
end
if typ == "MILKYWAY" then
  table.insert(address, "Point of Origin")
end

if typ == "UNIVERSE" then
  table.insert(address, "G17")
end

if typ == "PEGASUS" then
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
    sg.engageSymbol(glyph)
  end
print("Przetwarzam ciąg.")

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

  loop = false
end

eventEngaged = event.listen("stargate_spin_chevron_engaged", function(evname, address, caller, num, lock, glyph)
  if lock then
    print("Szewron " .. num .. " Zablokowany")
    os.sleep(0.5)
    sg.engageGate()
  else
    print("Szewron " .. num .. " Wprowadzony -", glyph)
    os.sleep(0.5)
  dialNext(num)
  end
end)
DHD = event.listen("stargate_dhd_chevron_engaged", function(evname, address, caller, num, lock, glyph)
  if lock then
    lock = true
    print("Chevron " .. num .. " Zablokowany -", glyph)
    os.sleep(0.2)
    dhd.pressBRB()
  else
    print("Szewron " .. num .. " Wprowadzony -", glyph)
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
    print("Wrota Otwarte")
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
  end)
  failEvent = event.listen("stargate_failed", function(address, caller, reason)
    print("Symbol Ziemi Odmowa Wprowadzenia:")
  end)
  eventEngaged = event.listen("stargate_spin_chevron_engaged", function(_, _, caller, num, lock, glyph) end)
  failEvent = event.listen("stargate_failed", function(_, _, caller, reason)
    if reason == "not_enough_power" then print("Za mało zasilania aby otworzyć Gwiezdne Wrota.") end
    if reason == "address_malformed" then print("Pod podanym adresem nie ma Gwiezdnych Wrót.") end
    if reason == "aborted" then print("Sterownik Wrót typu Universe anulował ciąg.") end
    cancelEvents()
  end)
  while loop do os.sleep(0.1) end