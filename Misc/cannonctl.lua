local c = require("component")
local event = require("event")

local mainLaser = c.proxy(c.get("f05"))
local mainPos = {mainLaser.getLocalPosition()}

for k, _ in c.list("warpdriveLaser", true) do
    local laser = c.proxy(k)
    laser.beamFrequency(5000)
end

local function boost()
    for k, _ in c.list("warpdriveLaser", true) do
        if k ~= mainLaser.address then
            local laser = c.proxy(k)
            local pos = {laser.getLocalPosition()}
            laser.emitBeam(mainPos[1] - pos[1], mainPos[2] - pos[2], mainPos[3] - pos[3])
        end
    end
end

while true do
    local _, _, resultType, x, y, z = event.pull("laserScanning")

    if resultType == "BLOCK" then
        local targetPos = {
            x - mainPos[1],
            y - mainPos[2],
            z - mainPos[3]
        }
        boost()
        mainLaser.emitBeam(targetPos[1], targetPos[2], targetPos[3])
    end
end