-- Based on https://github.com/ShicKla/AuspexGateSystems/blob/release/ags/Installer.lua
local os = require("os")
local computer = require("computer")
local component = require("component")
local shell = require("shell")
local tty = require("tty")
local internet = nil
local fs = require("filesystem")
local HasInternet = component.isAvailable("internet")
local t = require("term")

t.clear()

print("Specify the path where the program should be installed.")
print("LEAVE IT EMPTY TO INSTALL TO /JDS DIRECTORY.")
print("Example path /home")

local path = io.read()
if path == "" then filepath = "/JDS" else filepath = path end
t.clear()

print("Choose your language:")
print("")
print("1. English")
print("2. Polish")

local ChooseLang = io.read()
if ChooseLang == "1" then
    BranchURL = "https://raw.githubusercontent.com/lukasz4444/JSG-Dialing-System/stable/English-Version/"
elseif ChooseLang == "2" then
    BranchURL = "https://raw.githubusercontent.com/lukasz4444/JSG-Dialing-System/stable/Polish-Version/"
else
    print("please choose language 1 or 2 as example")
    os.exit(1)
end
if path == "" then
    if not fs.isDirectory("/JDS") then
        local success, msg = fs.makeDirectory("/JDS")
        if success == nil then
            io.stderr:write("Failed to created \"/JDS\" directory, "..msg)
            os.exit(false) end
    end
    local function forceExit(code)
        if UsersWorkingDir ~= nil then shell.setWorkingDirectory(UsersWorkingDir) end
        tty.setViewport(table.unpack(OriginalViewport))
        os.exit(code)
    end
else
    if not fs.isDirectory(path) then
        local success, msg = fs.makeDirectory(path)
        if success == nil then
            io.stderr:write("Failed to created " .. path .. " directory, "..msg)
            os.exit(false) end
    end
end

shell.setWorkingDirectory(filepath)
local function forceExit(code)
    if UsersWorkingDir ~= nil then shell.setWorkingDirectory(UsersWorkingDir) end
    tty.setViewport(table.unpack(OriginalViewport))
    os.exit(code)
end

local function downloadFile(fileName, verbose)
    if verbose then print("Downloading..."..fileName) end
    local result = ""
    local response = internet.request(BranchURL..fileName)
    local isGood, err = pcall(function()
        local file, err = io.open(fileName, "w")
        if file == nil then error(err) end
        for chunk in response do
            file:write(chunk)
        end
        file:close()
    end)
    if not isGood then
        io.stderr:write("Unable to download file:")
        io.stderr:write("")
        io.stderr:write(err)
    end
end
if HasInternet then internet = require("internet") end

downloadFile("dial.lua",true)
downloadFile("STD.lua",true)
downloadFile("Iris-Codes.txt",true)
downloadFile("off.lua",true)

if not fs.exists("addresses.csv") then
    downloadFile("addresses.csv",true)
else
    print("File addresses.csv already exists")
end
downloadFile("settings.cfg",true)
shell.setWorkingDirectory("/home")
if not path == "" then
    shrc = io.open("/home/.shrc", "w")
    shrc:write(filepath .. "/dial.lua")
    shrc:close()
else
    shrc = io.open("/home/.shrc", "w")
    shrc:write(filepath .. "/dial.lua")
    shrc:close()
end
os.sleep(1)
computer.shutdown(true)

