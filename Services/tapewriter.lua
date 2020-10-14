local c = require("component")
local term = require("term")
local drv = c.tape_drive

local f = io.open("/home/dreams", "r")
local size = f:seek("end")

f:seek("set", 0)

print("Writing...")

while true do
    term.clear()
    print("Progress: " .. tostring(f:seek()) .. " / " .. tostring(size))

    drv.write(f:read(1))

    if f:seek() == size then
        print("Done.")
        return
    end
end
