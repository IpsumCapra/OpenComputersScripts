component = require("component")
s = require("sides")
t = require("term")
g = component.gpu
colors = require("colors")
computer = require("computer")

event = require("event")

r = component.proxy(component.get("893"))
-- front = output

r1 = component.proxy(component.get("d7c"))
r2 = component.proxy(component.get("459"))
r3 = component.proxy(component.get("433"))
r4 = component.proxy(component.get("79f"))
-- right = output

inputSide = s.right
outputSide = s.front
plateSide = s.back

-- 0 = nothing selected, 1 = closest (5m)
selected = 1

--score={score, shots, lastShot}
scores = {
    { "50m", colors.white, "79f", 0, 0, 0 },
    { "30m", colors.silver, "433", 0, 0, 0 },
    { "15m", colors.gray, "459", 0, 0, 0 },
    { "5m", colors.black, "d7c", 0, 0, 0 }
}

selectorButtons = {
    { 19, 18 },
    { 38, 18 }
}

t.clear()
g.setResolution(40, 20)

function collapseAll()
    for _, range in ipairs(scores) do
        r.setBundledOutput(outputSide, range[2], 0)
    end
end

function deactivate()
    collapseAll()
    selected = 1

    t.clear()

    for i, range in ipairs(scores) do
        scores[i] = { range[1], range[2], range[3], 0, 0, 0 }
    end
end

function updateScreen()
    t.clear()

    -- print target info
    for _, range in ipairs(scores) do
        print(range[1] .. " mark info:")
        t.write("Avg. accuracy: ")
        if range[5] > 0 then
            print(tostring(math.floor(range[4] / range[5])) .. "%")
            print("Last hit shot accuracy: " .. range[6] .. "%")
        else
            print("--")
            print("Last hit shot accuracy: --")
        end
        print("Shots fired: " .. range[5])
    end

    -- print target selector
    print("\n Target selector:")
    t.setCursor(27, 18)
    if selected == 0 then
        print("none")
    else
        print(scores[selected][1])
    end

    g.setBackground(colors.black)
    g.setForeground(colors.white)
    t.setCursor(19, 18)
    t.write("<")
    t.setCursor(38, 18)
    t.write(">")
    g.setBackground(colors.white)
    g.setForeground(colors.black)
end

function updateTargets()
    collapseAll()
    if selected > 0 then
        r.setBundledOutput(outputSide, scores[selected][2], 255)
    end
end

function updateScores(value, address)
    for _, range in ipairs(scores) do
        if component.get(range[3]) == address then
            range[5] = range[5] + 1
            range[6] = math.floor(value / 14 * 100)
            range[4] = range[4] + range[6]
            updateScreen()
            return
        end
    end
end

while true do
    uName, address, toggle, b, c = event.pull()

    if uName == "redstone_changed" then
        if address == r.address then
            if toggle == plateSide then
                if c == 0 then
                    deactivate()
                    active = false
                else
                    active = true
                    updateScreen()
                    updateTargets()
                end
            end
        else
            if (c ~= 0) then
                computer.beep(500)
                updateScores(c, address)
            end
        end
    elseif uName == "touch" then
        for i, v in ipairs(selectorButtons) do
            if toggle == v[1] and b == v[2] then
                computer.beep()
                if i == 1 then
                    selected = selected + 1
                else
                    selected = selected - 1
                end
                selected = selected % 5
                updateScreen()
                updateTargets()
            end
        end
    end
end