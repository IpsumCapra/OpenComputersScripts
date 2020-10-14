local component = component
local d = component.proxy(component.list("drone")())
local n = component.proxy(component.list("navigation")())

local delay = 0.6

local function performMovement(x, y, z)
    d.setLightColor(0x80FF99)
    d.move(x, y, z)

    while d.getOffset() > 0.1 do

    end
    d.setLightColor(0xFFFFFF)
end

local function moveToOrigin()
    for _, v in ipairs(n.findWaypoints(50)) do
        if v.label == d.name() .. " Field" then
            local pos = v.position
            performMovement(pos[1], pos[2], pos[3])
            return
        end
    end
end

local function getDistanceToWaypoint(name)
    for _, v in ipairs(n.findWaypoints(50)) do
        if v.label == name then
            return v.position
        end
    end
    d.setLightColor(0xFF0000)
end

local function depositHarvest()
    local dropPoint = getDistanceToWaypoint("Drop Point")
    performMovement(dropPoint[1], dropPoint[2], dropPoint[3])

    d.setLightColor(0x4D82FF)

    for i = 1, 4 do
        d.select(i)
        d.drop(0)
    end

    moveToOrigin()
end

local function performFarmCycle()
    performMovement(0, 1, 0)

    local size = getDistanceToWaypoint(d.name() .. " End")

    local x = math.abs(size[1])
    local z = math.abs(size[3])

    local flip = false
    if size[3] < 0 then
        flip = true
    end

    for i = 1, x + 1 do
        for i = 1, z do
            d.use(0)
            if flip then
                performMovement(0, 0, -1)
            else
                performMovement(0, 0, 1)
            end
        end

        if i ~= x + 1 then
            flip = not flip
            if size[1] < 0 then
                performMovement(-1, 0, 0)
            else
                performMovement(1, 0, 0)
            end
        end
    end
    depositHarvest()
end

moveToOrigin()
while true do
    performFarmCycle()
    d.setLightColor(0x858585)
    local curTime = os.clock()

    while os.clock() - curTime < delay do
        d.setStatusText(tostring(os.clock() - curTime))
    end
    d.setStatusText(" ")

    d.setLightColor(0xFFFFFF)
end