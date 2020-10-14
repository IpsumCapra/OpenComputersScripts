local encom = {}

local c = require("component")
local ser = require("serialization")
local event = require("event")

local mod = c.modem
local dat = c.data

local connections = {}

local response

local receivePort = 6503

local serverCallback = {}

local waiting = true

local pubKey, privKey = dat.generateKeyPair()

function encom.getConnection(host)
    for k, v in pairs(connections) do
        if k == host then
            return v
        end
    end
    return nil
end

local function messageReturn(originHost, data)
    response = { originHost, data }
    waiting = false
end

local function handleMessage(_, _, originHost, port, _, data)
    local recPacket = ser.unserialize(data)
    local flags = recPacket.flags
    local orPort = recPacket.port
    local clientPubKey = recPacket.publicKey

    if flags == "SYN" then
        connections[originHost] = { clientPubKey, dat.ecdh(dat.deserializeKey(privKey.serialize(), "ec-private"), dat.deserializeKey(clientPubKey, "ec-public")) }
        mod.send(originHost, orPort, pubKey.serialize())
    elseif encom.getConnection(originHost) then
        serverCallback[port](originHost, dat.decrypt(recPacket.data, string.sub(dat.sha256(connections[originHost][2]), 1, 16), string.sub(dat.sha256(connections[originHost][2]), 17, 32)))
    end
end

function encom.setupServer(callback, port)
    serverCallback[port] = callback
    mod.open(port)
    event.listen("modem_message", handleMessage)
end

function encom.sendMessage(data, port)
    local comPacket = {
        publicKey = pubKey.serialize()
    }

    comPacket["flags"] = "SYN"
    comPacket["port"] = receivePort

    mod.open(receivePort)
    mod.broadcast(port, ser.serialize(comPacket))

    while true do
        local _, _, _, originPort, _, receivedData = event.pull(5, "modem_message")

        if originPort == receivePort then
            local dhkey = dat.ecdh(dat.deserializeKey(privKey.serialize(), "ec-private"), dat.deserializeKey(receivedData, "ec-public"))
            local hashKey = dat.sha256(dhkey)

            local key = string.sub(hashKey, 1, 16)
            local iv = string.sub(hashKey, 17, 32)

            comPacket["data"] = dat.encrypt(data, key, iv)
            comPacket["flags"] = "DAT"

            mod.broadcast(port, ser.serialize(comPacket))
            mod.close(receivePort)
            return
        end
    end
end

function encom.sendDirectMessage(data, address, port)
    local comPacket = {
        publicKey = pubKey.serialize()
    }

    comPacket["flags"] = "SYN"
    comPacket["port"] = receivePort

    mod.open(receivePort)
    mod.send(address, port, ser.serialize(comPacket))

    while true do
        local _, _, _, originPort, _, receivedData = event.pull(5, "modem_message")

        if originPort == receivePort then
            local dhkey = dat.ecdh(dat.deserializeKey(privKey.serialize(), "ec-private"), dat.deserializeKey(receivedData, "ec-public"))
            local hashKey = dat.sha256(dhkey)

            local key = string.sub(hashKey, 1, 16)
            local iv = string.sub(hashKey, 17, 32)

            comPacket["data"] = dat.encrypt(data, key, iv)
            comPacket["flags"] = "DAT"

            mod.send(address, port, ser.serialize(comPacket))
            mod.close(receivePort)
            return
        end
    end
end

function encom.interaction(data, port)
    local resPort = 1
    for i = 1, 65535 do
        if mod.open(i) then
            resPort = i
            break
        end
    end

    local comPacket = {
        data = data,
        port = resPort,
        type = "interaction"
    }

    waiting = true
    encom.setupServer(messageReturn, resPort)
    encom.sendMessage(ser.serialize(comPacket), port)

    while waiting do
        os.sleep(0.05)
    end

    mod.close(resPort)
    return response
end

return encom