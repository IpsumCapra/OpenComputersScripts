local c = require("component")
local holo = c.hologram
local letters = require("holo_letters")

endText = "the end is"


local text = args[1]

local indicators = {
    { 1, 1, 1 },
    { 1, 1, 48 },
    { 48, 1, 1 },
    { 48, 1, 48 },
    { 1, 32, 1 },
    { 1, 32, 48 },
    { 48, 32, 1 },
    { 48, 32, 48 },
}

local cursorX = 1
local cursorY = 16
local cursorZ = 24

local padding = 5

holo.clear()
holo.setScale(3)

function drawIndicators()
    for _, v in ipairs(indicators) do
        holo.set(v[1], v[2], v[3], 1)
    end
end



function drawText(color)
    offset = 0
    for _, char in ipairs({string.byte(text, 1, #text)}) do

        if char == 32 then
            offset = offset + 3
        else
            letter = letters[string.char(char)]

            width = letter[1]
            chr = letter[2]

            for y, r in ipairs(chr) do
                for x, c in ipairs(r) do
                    if c == 1 then
                        holo.set(cursorX + offset + x, cursorY + 5 - y, cursorZ, color)
                    end
                end
            end

            offset = offset + 1 + width
        end
    end
end

drawIndicators()

cursorX = 48 + padding

while true do
    drawText(0)

    cursorX = cursorX - 1
    if cursorX == -length - padding then
        cursorX = 48 + padding
    end

    drawText(2)

    os.sleep(.01)
end