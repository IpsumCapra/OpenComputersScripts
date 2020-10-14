local c = require("component")
local term = require("term")
local event = require("event")
local colors = require("colors")
local thread = require("thread")

local gpu = c.gpu
local core = c.warpdriveEnanReactorCore

local refreshRate = 0.1
local screenRefresh = 0.2

local function getColor(color)
    return gpu.getPaletteColor(colors[color])
end

local function cycleOutputMode()
    local mode, rate = core.outputMode()

    if mode == "off" then
        core.outputMode("unlimited", rate)
    elseif mode == "unlimited" then
        core.outputMode("above", rate)
    elseif mode == "above" then
        core.outputMode("at_rate", rate)
    else
        core.outputMode("off", rate)
    end
end

local function handleKey(_, _, char)
    char = string.char(char)

    if char == "e" then
        core.enable(not core.enable())
    elseif char == "=" then
        core.instabilityTarget(core.instabilityTarget() - 1)
    elseif char == "-" then
        core.instabilityTarget(core.instabilityTarget() + 1)
    elseif char == "c" then
        cycleOutputMode()
    elseif char == "o" or char == "p" then
        local mode, rate = core.outputMode()
        if rate >= 1000 and char == "o" then
            rate = rate - 1000
        elseif char == "p" then
            rate = rate + 1000
        end
        core.outputMode(mode, rate)
    end
end

local function stabilizer()
    while true do
        local instab = {core.getInstabilities()}

        for k, _ in c.list("warpdriveEnanReactorLaser", true) do
            local laser = c.proxy(k)
            local side = laser.side() + 1

            if instab[side] > core.instabilityTarget() then
                laser.stabilize(core.stabilizerEnergy())
            end
        end

        os.sleep(refreshRate)
    end
end

local function refresher()
    while true do
        event.pull()
        core = c.proxy(c.list("warpdriveEnanReactorCore", true)())
        gpu = c.proxy(c.list("gpu", true)())
        local screen = c.list("screen", true)()
        gpu.bind(screen)
    end
end

thread.create(refresher)
event.listen("key_down", handleKey)

while true do
    term.clear()
    print("Laser stability: ")

    local instab = {core.getInstabilities()}
    local releaseMode, rate = core.outputMode()
    local stored, max, unit, _, output = core.getEnergyStatus()

    local amount = 0
    local x = 1
    local y = 2

    for k, _ in c.list("warpdriveEnanReactorLaser", true) do
        local laser = c.proxy(k)
        local side = laser.side() + 1

        term.setCursor(x, y)
        y = y + 1
        if y == 6 then
            x = x + 15
            y = 2
        end
        term.write("Laser " .. side .. ": ")

        if instab[side] > core.instabilityTarget() then
            gpu.setBackground(getColor("red"))
        else
            gpu.setBackground(getColor("lime"))
        end

        print(100 - (math.floor(instab[side] * 100) / 100))
        gpu.setBackground(getColor("black"))
    end

    gpu.setBackground(getColor("black"))

    term.write("\nReactor is: ")

    if core.enable() then
        gpu.setBackground(getColor("lime"))
        print("enabled")
    else
        print("disabled")
    end

    gpu.setBackground(getColor("black"))
    print("Stability target: " .. 100 - core.instabilityTarget() .. "%")
    print("Release mode: " .. releaseMode)
    print("Release rate: " .. rate)
    print("Energy stored: " .. stored .. "/" .. max .. unit .. "(" .. math.floor(stored / max * 100) .. "%)")
    print("Generated: " .. output .. unit .. "/t")
    os.sleep(screenRefresh)
end