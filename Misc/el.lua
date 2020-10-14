local c = require("component")
local r = c.proxy(c.get("862"))
local s = require("sides")

args = {...}

if args[1] == "up" then
    for i = 1, args[2] do
        r.setOutput(s.bottom, 15)
        os.sleep(1)
        r.setOutput(s.bottom, 0)
    end
elseif args[1] == "down" then
    for i = 1, args[2]  do
        r.setOutput(s.top, 15)
        os.sleep(1)
        r.setOutput(s.top, 0)
    end
else
    print("Invalid arguments.")
end