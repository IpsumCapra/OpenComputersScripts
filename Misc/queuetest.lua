local event = require("event")

local queue = {}

local function addAssignment()
    table.insert(queue, tostring(os.clock()))
end

event.listen("touch", addAssignment)

while true do
    if #queue > 0 then
        print(queue[1])
        table.remove(queue, 1)
        os.sleep(3)
    else
        os.sleep(0.05)
    end
end