local c = require("component")
local ser = require("serialization")
local encom = require("encom")

local mod = c.modem
local drv = c.disk_drive

f = io.open("/mnt/" .. string.sub(drv.media(), 1, 3) .. "/key")

msg = {
    userdata = f:read(),
    id = mod.address
}

print(encom.interaction(ser.serialize(msg), 1812)[2])