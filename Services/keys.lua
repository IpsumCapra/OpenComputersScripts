local c = require("component")
local ser = require("serialization")
local dat = c.data

local keys = {}

function keys.getKeyData()
    f = io.open("/home/keys", "r")
    data = ser.unserialize(f:read())
    f:close()
    return data
end

function keys.writeKeyData(data)
    f = io.open("/home/keys", "w")
    f:write(ser.serialize(data))
    f:flush()
    f:close()
end

function keys.getUser(index)
    data = keys.getKeyData()
    fullKey = dat.sha256(dat.decode64(data.key))
    key = string.sub(fullKey, 1, 16)
    iv = string.sub(fullKey, 17, 32)

    for k, v in pairs(data) do
        if k == index then
            return ser.unserialize(dat.decrypt(v, key, iv))
        end
    end
    return false
end

function keys.addUser(user, index)
    data = keys.getKeyData()
    fullKey = dat.sha256(dat.decode64(data.key))
    key = string.sub(fullKey, 1, 16)
    iv = string.sub(fullKey, 17, 32)
    table.insert(data, index, dat.encrypt(ser.serialize(user), key, iv))
    keys.writeKeyData(data)
end

function keys.removeUser(index)
    data = keys.getKeyData()
    table.remove(data, index)
    keys.writeKeyData(data)
end

function keys.modifyUserData(userData, index)
    keys.removeUser(index)
    keys.addUser(userData, index)
end

return keys