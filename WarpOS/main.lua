local t = require("terminal")
local colors = require("colors")
local const = require("constants")
local gpu = gpu
local core = core
local screen = screen
local computer = computer

local page = "main"

local w, h = gpu.getResolution()

local function getColor(color)
    return gpu.getPaletteColor(colors[color])
end

local function getKey()
    while true do
        local name, _, char = computer.pullSignal(5)
        if name == "key_down" then
            return string.char(char), char
        end
        reloadComponents()
        if not gpu.getScreen() then
            local bg = gpu.getBackground()
            local fg = gpu.getForeground()

            if bg == nil then
                bg = 0x000000
            end
            if fg == nil then
                fg = 0xFFFFFF
            end

            gpu.bind(screen.address)
            gpu.setBackground(bg)
            gpu.setForeground(fg)
        end
    end
end

local function getText()
    local buffer = ""
    while true do
        local key = getKey()
        if key == "\13" then
            t.print("")
            return buffer
        elseif key == "\8" and buffer ~= "" then
            local x, y = t.getCursor()
            t.setCursor(x - 1, y)
            gpu.set(x - 1, y, " ")
            buffer = string.sub(buffer, 1, -2)
        elseif string.byte(key) > 31 and string.byte(key) ~= 127 then
            buffer = buffer .. key
            t.write(key)
        end
    end
end

local function generateSelector(options)
    t.setBackground(getColor("black"))
    t.setForeground(getColor("white"))

    local _, y = t.getCursor()

    local toggle = true

    local function toggleBackgroundColor()
        toggle = not toggle
        if toggle then
            t.setBackground(getColor("black"))
        else
            t.setBackground(getColor("gray"))
        end
    end

    for i = 1, #options + 1 do
        gpu.fill(1, y - 1 + i, w, 1, " ")
        toggleBackgroundColor()
    end

    if (#options + 1) % 2 ~= 0 then
        toggleBackgroundColor()
    end

    t.setCursor(1, y)
    t.print("0: Go home")
    toggleBackgroundColor()

    for i, v in ipairs(options) do
        t.print(i .. ": " .. v)
        toggleBackgroundColor()
    end
end

local function drawBanner(page)
    local curBg = gpu.getBackground()
    t.setBackground(getColor("black"))
    t.setForeground(getColor("yellow"))

    gpu.fill(1, 1, w, 1, " ")

    local bannerText = core.name() .. " - " .. page

    t.setCursor(math.floor((w - #bannerText) / 2), 1)
    t.print(bannerText)
    t.setBackground(curBg)
end

local function printError(text)
    t.setBackground(getColor("red"))
    gpu.fill(1, h, w, 1, " ")
    t.setCursor((w - #text) / 2, h)
    t.write(text)
end

local function prepPage(page)
    t.setBackground(getColor("silver"))
    t.clear()
    drawBanner(page)
    t.setForeground(getColor("white"))
end

local function displayMainScreen()
    prepPage("Home")
    t.setForeground(getColor("yellow"))
    t.setBackground(getColor("silver"))

    t.setCursor(8, 4)
    t.print("Welcome to")
    t.setCursor(8, 5)
    t.printMap(t.logo, true)
    local verText = "Version " .. string.gsub(_G._VERSION, "WarpOS ", "")
    t.setCursor(74 - #verText, 11)

    t.setForeground(getColor("white"))
    t.print(verText)

    t.setCursor(1, 18)
    generateSelector(const.mainOptions)
end

local function displaySettingsScreen()
    local position = { core.getLocalPosition() }
    local charge, max, unit = core.getEnergyStatus()
    local mass, volume = core.getShipSize()

    local posDim = { core.dim_positive() }
    local negDim = { core.dim_negative() }

    prepPage("Settings")

    t.setBackground(getColor("black"))
    t.setForeground(getColor("yellow"))
    gpu.fill(1, 3, w, 1, " ")
    t.setCursor(1, 3)
    t.print("Ship information:")

    t.setBackground(getColor("gray"))
    t.setForeground(getColor("white"))
    gpu.fill(1, 4, w, 13, " ")
    t.print("Current position")
    t.write("x: ")
    t.print(tostring(position[1]))
    t.write("y: ")
    t.print(tostring(position[2]))
    t.write("z: ")
    t.print(tostring(position[3]))

    t.print("")
    t.print("Energy")
    t.print(charge .. " / " .. max .. " " .. unit)

    t.print("")
    t.print("Dimensions")
    t.print("Front, right, up: " .. posDim[1] .. ", " .. posDim[2] .. ", " .. posDim[3])
    t.print("Back, left, down: " .. negDim[1] .. ", " .. negDim[2] .. ", " .. negDim[3])
    t.print("")
    t.print("Mass, volume: " .. mass .. ", " .. volume)

    t.setCursor(1, 18)
    generateSelector(const.settingOptions)
end

local function displayNavScreen()
    local position = { core.getLocalPosition() }
    local movement = { core.movement() }

    prepPage("Navigation")

    t.setBackground(getColor("black"))
    t.setForeground(getColor("yellow"))
    gpu.fill(1, 3, w, 1, " ")
    t.setCursor(1, 3)
    t.print("Current position:")

    t.setBackground(getColor("gray"))
    t.setForeground(getColor("white"))
    gpu.fill(1, 4, w, 3, " ")
    t.write("x: ")
    t.print(tostring(position[1]))
    t.write("y: ")
    t.print(tostring(position[2]))
    t.write("z: ")
    t.print(tostring(position[3]))

    t.setBackground(getColor("black"))
    t.setForeground(getColor("yellow"))
    gpu.fill(1, 9, w, 1, " ")
    t.setCursor(1, 9)
    t.print("Movement settings:")

    t.setBackground(getColor("gray"))
    t.setForeground(getColor("white"))
    gpu.fill(1, 10, w, 6, " ")
    t.write("x: ")
    t.print(tostring(movement[1]))
    t.write("y: ")
    t.print(tostring(movement[2]))
    t.write("z: ")
    t.print(tostring(movement[3]))
    t.print("")
    t.print("Target position: " .. position[1] + movement[1] .. " " .. position[2] + movement[2] .. " " .. position[3] + movement[3])
    t.print("Rotation: " .. const.rotationValues[core.rotationSteps() + 1][1])

    t.setCursor(1, 18)
    generateSelector(const.navOptions)
end

local function displayCrewScreen()
    prepPage("Crew")

    t.setBackground(getColor("silver"))

    t.setCursor(1, 18)
    generateSelector(const.advancedOptions)
end

local function displayAdvancedScreen()
    local isValid, msg = core.getAssemblyStatus()

    prepPage("Advanced settings")

    t.setBackground(getColor("black"))
    t.setForeground(getColor("yellow"))
    gpu.fill(1, 3, w, 1, " ")
    t.setCursor(1, 3)
    t.print("Current mode:")

    t.setBackground(getColor("gray"))
    t.setForeground(getColor("white"))
    gpu.fill(1, 4, w, 1, " ")
    t.print(core.command())

    t.setBackground(getColor("black"))
    t.setForeground(getColor("yellow"))
    gpu.fill(1, 6, w, 1, " ")
    t.setCursor(1, 6)
    t.print("Assembly status:")

    t.setBackground(getColor("gray"))
    t.setForeground(getColor("white"))
    gpu.fill(1, 7, w, 2, " ")
    t.print("Valid: " .. tostring(isValid))
    t.print("Message: " .. msg)

    t.setCursor(1, 18)
    generateSelector(const.advancedOptions)
end

local function namingScreen()
    prepPage("Naming")
    t.setBackground(getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Enter a new name and press enter to confirm.")
    t.setBackground(getColor("gray"))
    gpu.fill(1, 4, w, 1, " ")
    t.write("New name: ")
    core.name(getText())
    displaySettingsScreen()
end

local function dimensionsScreen()
    local pos = { core.dim_positive() }
    local neg = { core.dim_negative() }

    local dimensions = {
        ["Front"] = pos[1],
        ["Right"] = pos[2],
        ["Up"] = pos[3],
        ["Back"] = neg[1],
        ["Left"] = neg[2],
        ["Down"] = neg[3]
    }

    prepPage("Dimensions")
    t.setBackground(getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Enter new dimensions. Press enter to keep current value.")

    local y = 4

    for k, v in pairs(dimensions) do
        while true do
            t.setBackground(getColor("gray"))
            t.setCursor(1, y)
            gpu.fill(1, y, w, 1, " ")
            t.write(k .. "(" .. v .. ")" .. ": ")

            local value = getText()
            if value == "" then
                break
            end

            local dimension = tonumber(value)
            if dimension ~= nil then
                if dimension > -1 then
                    dimensions[k] = dimension
                    break
                else
                    printError("Value must be higher than, or equal to zero.")
                end
            else
                printError("Invalid value.")
            end
        end
        y = y + 1
    end

    core.dim_positive(dimensions["Front"], dimensions["Right"], dimensions["Up"])
    core.dim_negative(dimensions["Back"], dimensions["Left"], dimensions["Down"])
    displaySettingsScreen()
end

local function movementScreen()
    core.command("MANUAL", false)

    local pos = { core.dim_positive() }
    local neg = { core.dim_negative() }
    local movement = { core.movement() }
    local _, max = core.getMaxJumpDistance()
    local newMovement = {
        ["Front"] = movement[1],
        ["Up"] = movement[2],
        ["Right"] = movement[3],
    }

    prepPage("Movement")
    t.setBackground(getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Enter movement values. Negative value is opposite direction.")

    local y = 4
    for k, v in pairs(newMovement) do
        while true do
            printError("Choose a value between " .. pos[y - 3] + neg[y - 3] .. " and " .. max)
            t.setBackground(getColor("gray"))
            t.setCursor(1, y)
            gpu.fill(1, y, w, 1, " ")
            t.write(k .. "(" .. v .. ")" .. ": ")

            local value = getText()
            if value == "" then
                break
            end

            local amount = tonumber(value)
            if amount ~= nil then
                newMovement[k] = amount
                break
            else
                printError("Invalid value.")
            end
        end
        y = y + 1
    end
    prepPage("Rotation")

    t.setBackground(getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Set rotation using WASD.")

    t.setBackground(getColor("gray"))
    t.setCursor(1, 4)
    gpu.fill(1, 4, w, 1, " ")

    while true do
        t.setCursor(1, 4)
        gpu.fill(1, 4, w, 1, " ")
        t.write("Rotation: " .. const.rotationValues[core.rotationSteps() + 1][1])

        local key = getKey()
        if key == "\13" then
            break
        else
            for k, v in ipairs(const.rotationValues) do
                if v[2] == key then
                    core.rotationSteps(k - 1)
                end
            end
        end
    end

    local rotatedMovement = {
        newMovement["Front"],
        newMovement["Right"]
    }

    local rotation = core.rotationSteps()
    if rotation == 1 then
        rotatedMovement[1] = -newMovement["Right"]
        rotatedMovement[2] = newMovement["Front"]
    elseif rotation == 2 then
        rotatedMovement[1] = -newMovement["Front"]
        rotatedMovement[2] = -newMovement["Right"]
    elseif rotation == 3 then
        rotatedMovement[1] = newMovement["Right"]
        rotatedMovement[2] = -newMovement["Front"]
    end

    core.movement(rotatedMovement[1], newMovement["Up"], rotatedMovement[2])
    displayNavScreen()
end

local function jump()
    printError("Jump? [Y/n]")
    local key = getKey()
    if key == "y" or key == "\13" then
        core.command("MANUAL", true)
    end
    displayNavScreen()
end

local function maintenanceMode()
    core.command("MAINTENANCE", false)
    displayAdvancedScreen()
end

local function disableCore()
    core.command("OFFLINE", false)
    displayAdvancedScreen()
end

local screens = {
    main = displayMainScreen,
    settings = displaySettingsScreen,
    navigation = displayNavScreen,
    crew = displayCrewScreen,
    advanced = displayAdvancedScreen
}

local function switchToScreen(screen)
    page = screen
    screens[screen]()
end

local actions = {
    main = {
        "settings",
        "navigation",
        "crew",
        "advanced"
    },
    settings = {
        dimensionsScreen,
        namingScreen
    },
    navigation = {
        jump,
        targetingScreen,
        movementScreen
    },
    crew = {},
    advanced = {
        maintenanceMode,
        disableCore
    }
}

if core.name() == "" then
    namingScreen()
end

displayMainScreen()

while true do
    local key = getKey()
    if key == "0" and page ~= "main" then
        switchToScreen("main")
    else
        key = tonumber(key)
        if actions[page][key] ~= nil then
            if page == "main" then
                switchToScreen(actions["main"][key])
            else
                actions[page][key]()
            end
        end
    end
end