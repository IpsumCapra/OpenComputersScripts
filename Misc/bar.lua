component = require("component")
g = component.gpu
colors = require("colors")
t = require("term")
l = component.laser_amplifier

g.setResolution(80, 17)

-- " 100.00% "


function getAmpChargePercentage()
    return math.floor(l.getEnergy() / l.getMaxEnergy() * 100)
end

function drawBar()
    g.setBackground(0xFFFFFF)
    g.fill(2, 3, 72, 1, " ")
    g.setBackground(0xFF0000)
    g.fill(2, 3, math.floor(72 * getAmpChargePercentage() / 100), 1, " ")
    g.setBackground(0x000000)
    t.setCursor(75, 3)
    print(tostring(getAmpChargePercentage()).."%")
end

while true do
    t.clear()
    t.setCursor(2, 2)
    print("Ignition laser amplifier charge:")
    drawBar()
    t.setCursor(2, 4)
    print(tostring(l.getEnergy() / 2.5 / 1000000).."MRF")
    os.sleep(0.5)
end