local c = require("component")
local ser = require("serialization")
local encom = require("encom")
local keys = require("keys")

local dat = c.data

local authPort = 1812

function handleAuthRequest(_, request)
    print("Got request.")
    data = keys.getKeyData()

    request = ser.unserialize(request)

    local id
    local userData
    local responsePort

    if request.type == "interaction" then
        pkt = ser.unserialize(request.data)
        userData = pkt.userdata
        id = pkt.id
        responsePort = request.port
    else
        responsePort = request.port
        userData = request.userdata
        id = request.id
    end

    fullKey = dat.sha256(dat.decode64(data.key))
    key = string.sub(fullKey, 1, 16)
    iv = string.sub(fullKey, 17, 32)

    comPacket = ser.unserialize(dat.decrypt(dat.decode64(userData), key, iv))


    returnPacket = {
        clearance=-1,
        id=id,
        type="auth response"
    }

    for _, v in pairs(data) do
        entry = ser.unserialize(dat.decrypt(v, key, iv))
        if entry.name == comPacket.name and entry.password == comPacket.password then
            returnPacket["name"] = entry.name
            returnPacket["clearance"] = entry.clearance

            encom.sendMessage(ser.serialize(returnPacket), responsePort)
            return
        end
    end
    encom.sendMessage(ser.serialize(returnPacket), responsePort)
end

encom.setupServer(handleAuthRequest, authPort)