local c = require("component")
local event = require("event")
local sides = require("sides")
local encom = require("encom")
local floors = require("floors")
local ser = require("serialization")

local red = c.redstone

local up = sides.back
local down = sides.top

local authPort = 1812
local serverPort = 6004
local floorPort = 6005

local queue = {}

local function getY()
    local f = io.open("/home/floor", "r")
    local y = tonumber(f:read())
    f:close()
    return y
end

local function updateY(dir)
    local y = getY()

    if dir == up then
        y = y + 1
    else
        y = y - 1
    end

    local f = io.open("/home/floor", "w")
    f:write(tostring(y))
    f:flush()
    f:close()
end

local function move(dir, amount)
    for _ = 1, amount do
        red.setOutput(dir, 15)
        red.setOutput(dir, 0)
        updateY(dir)
        os.sleep(0.5)
    end
end

local function sendToAllFloors(data)
    for _, v in pairs(floors) do
        if v.netCard ~= "" then
            encom.sendDirectMessage(data, v.netCard, floorPort)
        end
    end
end

local function doorRequest(floor, state)
    local packet = {
        type = "door",
        floor = floor,
        state = state
    }

    sendToAllFloors(ser.serialize(packet))
end

local function statusRequest(floor, text)
    local packet = {
        type = "status",
        floor = floor,
        status = text
    }

    sendToAllFloors(ser.serialize(packet))
end

local function updateRequest(floor, curFloor)
    local packet = {
        type = "update",
        floor = floor,
        curFloor = curFloor
    }

    sendToAllFloors(ser.serialize(packet))
end

local function moveToLevel(level)
    local y = getY()
    if y > level then
        move(down, y - level)
    elseif y < level then
        move(up, level - y)
    end
end

local function moveToFloor(floor)
    doorRequest(-1, "closed")

    statusRequest(-1, "Elevator moving.")
    updateRequest(-1, false)

    moveToLevel(floors[floor].y)
    doorRequest(floor, "open")

    statusRequest(-1, "")
    updateRequest(floor, true)
    statusRequest(floor, "Elevator has arrived. ")
end

local function handleCommand(_, data)
    print("Got request.")
    local comPacket = ser.unserialize(data)
    local msg = {
        userdata = comPacket.userdata,
        id = comPacket.id
    }

    local auth = encom.interaction(ser.serialize(msg), authPort)

    local aResponse = ser.unserialize(auth[2])

    if aResponse.clearance == -1 then
    else
        local request = comPacket.request
        if request.type == "move" then
            if floors[request.floor].clearance <= aResponse.clearance then
                table.insert(queue, request.floor)
            else
                print("insufficient clearance.")
            end
        elseif request.type == "floor" then
            print("Floor request sending.")
            sendToAllFloors(request.data)
        end
    end
end

encom.setupServer(handleCommand, serverPort)

while true do
    if #queue > 0 then
        moveToFloor(queue[1])
        table.remove(queue, 1)
        os.sleep(10)
    else
        os.sleep(0.05)
    end
end