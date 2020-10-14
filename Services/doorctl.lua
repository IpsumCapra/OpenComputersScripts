local c = require("component")
local event = require("event")
local sides = require("sides")
local doors = require("doors")
local encom = require("encom")
local fs = require("filesystem")
local ser = require("serialization")

local red = c.redstone
local beep = c.beep
local mod = c.modem

local drives = {}

local authPort = 1812

local doorsSide = sides.bottom

for i, v in pairs(doors) do
    drives[i] = c.proxy(c.get(v.drive))
end

local function getKey(drv)
    fs.mount(drv.media(), "/mnt/" .. string.sub(drv.media(), 1, 3))

    local f = io.open("/mnt/" .. string.sub(drv.media(), 1, 3) .. "/key")

    if f ~= nil then
        local data = f:read()
        f:close()
        return data
    else
        return false
    end
end

local function getDoor(drv)
    for _, v in pairs(doors) do
        if v.drive == string.sub(drv.address, 1, 3) then
            return v
        end
    end
    return false
end

local function reject(drv)
    drv.eject()
    beep.beep({ [440] = 0.4, [600] = 0.2 })
end

local function handleRequest()
    for _, drv in pairs(drives) do
        if not drv.isEmpty() then
            local data = getKey(drv)
            if data == false then
                print("No data found.")
                reject(drv)
                return
            else
                local msg = {
                    userdata = data,
                    id = mod.address
                }

                local auth = encom.interaction(ser.serialize(msg), authPort)

                local aResponse = ser.unserialize(auth[2])

                if aResponse == -1 then
                    print("Invalid data.")
                    reject(drv)
                else
                    local door = getDoor(drv)

                    if door ~= false then
                        if door.clearance <= aResponse.clearance then
                            drv.eject()
                            red.setBundledOutput(doorsSide, door.color, 255)
                            beep.beep({ [1000] = 1 })
                            os.sleep(3)
                            red.setBundledOutput(doorsSide, door.color, 0)
                        else
                            print("Insufficient clearance.")
                            reject(drv)
                        end
                    end
                end
            end
        end
    end
end

event.listen("component_added", handleRequest)

--event.pull("component_added")
--handleRequest()
