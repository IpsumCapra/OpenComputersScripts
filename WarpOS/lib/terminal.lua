local terminal = {}

local x = 1
local y = 1

local gpu = gpu
local w, h = gpu.maxResolution()

local foreground = 0xFFFFFF
local background = 0x000000

terminal.logo = {
    { 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1 },
    { 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
    { 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1 },
    { 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1 },
    { 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1 },
    { 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0 }
}

-- very primitive printing function.
function terminal.print(text)
    gpu.set(x, y, text)
    if y == h then
        gpu.copy(1, 2, w, h - 1, 0, -1)
        gpu.fill(1, h, w, 1, " ")
    else
        y = y + 1
    end
    x = 1
end

-- very primitive writing function.
function terminal.write(text)
    gpu.set(x, y, text)
    x = x + #text
    if x > w then
        x = 0
    end
end

-- set the cursor.
function terminal.setCursor(dX, dY)
    x = dX
    y = dY
end

-- get cursor.
function terminal.getCursor()
    return x, y
end

-- clear the screen.
function terminal.clear()
    gpu.fill(1, 1, w, h, " ")
    x = 1
    y = 1
end

function terminal.setForeground(color)
    foreground = color
    gpu.setForeground(color)
end

function terminal.setBackground(color)
    background = color
    gpu.setBackground(color)
end

function terminal.printMap(map, double)
    for setY, row in ipairs(map) do
        for setX, v in ipairs(row) do
            if v == 1 then
                gpu.setBackground(foreground)
            else
                gpu.setBackground(background)
            end
            if double then
                gpu.fill(1 + 2 * (setX - 1) + x - 1, setY + y - 1, 2, 1, " ")
            else
                gpu.set(setX + x - 1, setY + y - 1, " ")
            end
        end
    end
end

return terminal