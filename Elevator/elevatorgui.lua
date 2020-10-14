local c = require("component")
local floors = require("floors")
local encom = require("encom")
local term = require("term")
local fs = require("filesystem")
local ser = require("serialization")

local mod = c.modem

local osdir = "379/"
local keydir = ""

local options = { "Open / close doors", "Move elevator", "Set status" }

local elevatorPort = 6004

local function getKey()
    local f = io.open("/mnt/" .. keydir .. "key", "r")
    local data = f:read()
    f:close()
    return data
end

local function generateFloorPacket(data)
    local msg = {
        userdata = getKey(),
        request = { type = "floor", data = data },
        id = mod.address
    }

    encom.sendMessage(ser.serialize(msg), elevatorPort)
end

local function doorInterface()
    local packet = {
        type = "door"
    }

    while true do
        term.clear()
        print("Change door state for floor: ")
        for k, v in pairs(floors) do
            print(tostring(k) .. ": " .. v.name)
        end
        print("Enter valid index, or '-1' for all doors. Enter 'q' to exit.")
        term.write("> ")
        local option = term.read()
        if option == "q" then
            term.clear()
            return
        else
            option = tonumber(option)
            if floors[option] ~= nil or option == -1 then
                packet.floor = option
                while true do
                    term.clear()
                    print("'open' or 'closed'")
                    local state
                    term.write("> ")
                    state = string.sub(term.read(), 1, -2)
                    if state == "open" or state == "closed" then
                        packet.state = state
                        generateFloorPacket(ser.serialize(packet))
                        return
                    else
                        print("Invalid state.")
                        os.sleep(0.5)
                    end
                end
            else
                print("Invalid input.")
                os.sleep(0.5)
            end
        end
    end
end

local function moveInterface()

end

for dir in fs.list("/mnt") do
    if dir ~= osdir then
        keydir = dir
        break
    end
end

if keydir == "" then
    print("Please enter a valid key card to continue.")
    return
end

while true do
    term.clear()
    for i, v in ipairs(options) do
        print(tostring(i) .. ": " .. v)
    end
    print("Enter valid index, or enter 'q' to exit.")
    term.write("> ")
    local option = term.read()
    if option == "1\n" then
        doorInterface()
    elseif option == "2\n" then
        moveInterface()
    elseif option == "q\n" then
        term.clear()
        return
    else
        print("Invalid input.")
        os.sleep(0.5)
    end
end