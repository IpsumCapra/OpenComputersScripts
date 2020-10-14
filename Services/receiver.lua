local c = require("component")
local ser = require("serialization")
local event = require("event")
local encom = require("encom")
local t = require("term")

local dat = c.data
local mod = c.modem
local drv = c.disk_drive


f = io.open("/mnt/" .. string.sub(drv.media(), 1, 3) .. "/key")

data = {
    userdata=f:read(),
    request={type="move",floor=4},
    id=mod.address
}

data = ser.serialize(data)

encom.sendMessage(data, 6004)