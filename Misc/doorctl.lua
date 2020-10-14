local c = require("component")
local colors = require("colors")
local event = require("event")
local sides = require("sides")
local mod = c.modem
local red = c.redstone
local holo = c.hologram

local doorside = sides.right

local right = colors.yellow
local left = colors.lightblue
local forward = colors.white
local backward = colors.red

local isOpen = false

local function move(dir, amount)
    for i = 1, amount do
        red.setBundledOutput(doorside, dir, 255)
        red.setBundledOutput(doorside, dir, 0)
        os.sleep(0.5)
    end
end

local function open()
    holo.clear()
    move(backward, 1)
    move(left, 5)
    isOpen = true
end

local function close()
    holo.clear()
    move(right, 5)
    move(forward, 1)
    isOpen = false
end

local function doorHandler(_, _, _, _, _, command)
    if command == "open" and not isOpen then
        open()
    elseif command == "close" and isOpen then
        close()
    elseif command == "cycle" then
        if not isOpen then
            open()
        end
        os.sleep(2)
        close()
    end
end

open()
close()

mod.open(776)
event.listen("modem_message", doorHandler)