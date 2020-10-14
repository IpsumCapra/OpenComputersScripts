local c = require("component")
local term = require("term")
local event = require("event")
local sides = require("sides")
local floors = require("floors")
local encom = require("encom")
local ser = require("serialization")
local computer = require("computer")
local fs = require("filesystem")

local mod = c.modem
local red = c.redstone
local drv = c.disk_drive

local gpu = c.proxy(c.get("5c1"))
local gpu2 = c.proxy(c.get("95d"))

local button = sides.left
local door = sides.front

local floor = 3

local authPort = 1812
local elevatorPort = 6004
local port = 6005

local status = ""

local currentFloor = false

local called = false

local function getKey()
    local f = io.open("/home/key", "r")
    local data = f:read()
    f:close()
    return data
end

local function requestMove(floor)
    local msg = {
        userdata = getKey(),
        request = { type = "move", floor = floor },
        id = mod.address
    }
    encom.sendMessage(ser.serialize(msg), elevatorPort)
end

local function setDoor(state)
    if state == "open" then
        red.setOutput(door, 0)
    elseif state == "closed" then
        red.setOutput(door, 15)
    end
end

local function printLevels()
    term.bind(gpu)
    term.clear()
    print("Select floor")
    local Ycursor = 3

    for k, v in pairs(floors) do
        gpu.setBackground(0xFF0000)
        gpu.setForeground(0xFFFFFF)
        gpu.fill(3, Ycursor, 3, 1, " ")
        term.setCursor(4, Ycursor)
        term.write(tostring(k - 1))
        gpu.setBackground(0xFFFFFF)
        gpu.setForeground(0xFF0000)
        gpu.fill(7, Ycursor, 31, 1, " ")
        term.setCursor(8, Ycursor)
        term.write(v.name)
        gpu.setBackground(0x000000)
        gpu.setForeground(0xFFFFFF)
        Ycursor = Ycursor + 2
    end
end

local function printStatus()
    term.bind(gpu2)
    term.clear()
    print("This is: " .. tostring(floor - 1) .. " - " .. floors[floor].name)
    print(status)
    if called then
        print("Elevator has been called.")
    end
end

local function handleFloorRequest(floor)
    if floors[floor].clearance == 0 then
        requestMove(floor)
    else
        term.bind(gpu)
        term.clear()
        print("Insert keycard to continue.")
        while drv.isEmpty() do
            os.sleep(0.05)
        end
        term.clear()

        local path = "/mnt/" .. string.sub(drv.media(), 1, 3) .. "/key"

        if fs.exists(path) then
            local f = io.open(path, "r")

            local cardData = f:read()

            local authMsg = {
                userdata=cardData,
                id=mod.address
            }

            local authResponse = encom.interaction(ser.serialize(authMsg), authPort)

            if floors[floor].clearance <= ser.unserialize(authResponse[2]).clearance then
                requestMove(floor)
            else
                term.bind(gpu)
                term.clear()
                print("Insufficient clearance.")
                os.sleep(3)
            end
        else
            term.bind(gpu)
            term.clear()
            print("Invalid keycard.")
            os.sleep(3)
        end
        drv.eject()
    end
end

local function handleElevatorCall(_, _, side, _, value)
    if side == button and value == 15 and not called then
        called = true
        requestMove(floor)
        term.bind(gpu2)
        term.setCursor(0, 3)
        print("Elevator has been called.")
    end
end

local function handleMessage(sender, message)
    message = ser.unserialize(message)

    if string.sub(sender, 1, 3) == "73a" then
        if message.type == "door" and (message.floor == floor or message.floor == -1) then
            setDoor(message.state)
        elseif message.type == "status" then
            status = message.status
            printStatus()
        elseif message.type == "update" then
            currentFloor = message.curFloor
            if currentFloor then
                called = false
                printLevels()
            else
                term.bind(gpu)
                term.clear()
            end
            printStatus()
        end
    end
end

--setDoor("closed")

event.listen("redstone_changed", handleElevatorCall)
encom.setupServer(handleMessage, port)

gpu.bind(c.get("ed3"))
gpu2.bind(c.get("dcf"))

gpu2.setResolution(48, 6)
gpu.setResolution(40, 20)

term.bind(gpu)
term.clear()

printStatus()

while true do
    if currentFloor then
        term.bind(gpu)
        term.clear()
        printLevels()
        local _, _, x, y = event.pull("touch")
        if x > 2 and x < 38 then
            y = (y - 1) / 2
            if floors[y] ~= nil and y ~= floor then
                computer.beep()
                handleFloorRequest(y)
            end
        end
    else
        os.sleep(0.5)
    end
end