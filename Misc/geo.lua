c = require("component")
holo = c.hologram
geo = c.geolyzer
args = { ... }

indicators = {
    { 1, 1, 1 },
    { 1, 1, 48 },
    { 48, 1, 1 },
    { 48, 1, 48 },
    { 1, 32, 1 },
    { 1, 32, 48 },
    { 48, 32, 1 },
    { 48, 32, 48 },
}

borderColor = 1
fillColor = 2

offset = 16

geoOffset = 32

holo.clear()

for _, v in ipairs(indicators) do
    holo.set(v[1], v[2], v[3], borderColor)
end

for z = 1, 48 do
    print("level " .. tostring(z) .. "/48")
    for x = 1, 48 do
        result = geo.scan(x - geoOffset, z - geoOffset)
        for i = 1, 32 do
            if result[i + offset] == 0 then
                holo.set(x, i, z, fillColor)
            end
        end
    end
end