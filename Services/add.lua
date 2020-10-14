local c = require("component")
local holo = c.hologram
local letters = require("holo_letters")

local text = "welcome to omega research facility"

local cursorX = 1
local cursorY = 16
local cursorZ = 24

local padding = 5

holo.clear()
holo.setTranslation(0, .3, 0)
holo.setScale(2)

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
                    if c == 1 and cursorX + offset + x > 0 and cursorX + offset + x < 48 then
                        holo.set(cursorX + offset + x, cursorY + 5 - y, cursorZ, color)
                    end
                end
            end
            offset = offset + 1 + width
        end
    end
end

length = 0

for _, char in ipairs({string.byte(text, 1, #text)}) do
    if char == 32 then
        length = length + 3
    else
        length = length + 1 + letters[string.char(char)][1]
    end
end

cursorX = 48 + padding

while true do
    drawText(0)

    cursorX = cursorX - 1
    if cursorX == -length - padding then
        cursorX = 48 + padding
    end

    drawText(3)

    os.sleep(.01)
end