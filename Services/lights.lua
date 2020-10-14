local c = require("component")
local thread = require("thread")

local lightColor = 0XFFFFE8
local delay = 0.5

for k, _ in pairs(c.list("light_board")) do
    local board = c.proxy(k)
    for i = 1, 4 do
        board.setColor(i, lightColor)
    end
end

local function lights()
    while true do
        for k, _ in pairs(c.list("light_board")) do
            local board = c.proxy(k)
            for i = 1, 4 do
                if math.random(2) == 1 then
                    board.setActive(i, true)
                else
                    board.setActive(i, false)
                end
            end
        end
        os.sleep(delay)
    end
end

math.randomseed(os.clock())

thread.create(lights):detach()