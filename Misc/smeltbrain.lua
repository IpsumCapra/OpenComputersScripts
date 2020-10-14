component = require("component")
s = require("sides")
t = require("term")
event = require("event")

smeltery = component.smeltery
tank = component.tinker_tank
ft = component.proxy(component.get("cbc"))
--it = c.proxy(c.get(""))

smelterDrainSide = s.right
tinkerTankSide = s.left
smelterCoreSide = s.front

tasks = { "Transfer fluids", "Create alloy" }
transferOptions = { "Smeltery > Tank", "Tank > Smeltery", "Purge smeltery contents to tank" }

alloys = {
    {name="bronze", amount=4, ingredients={copper=3, tin=1}},
    {name="signalum", amount=72, ingredients={copper=54, silver=18, redstone=128}},
    {name="electrum", amount=2, ingredients={gold=1, silver=1}},
    {name="manyullyn", amount=1, ingredients={ardite=1, cobalt=1}},
    {name="pig iron", amount=144, ingredients={iron=144, blood=40, clay=72}}
}


--tank = left, smelter = right for ft
--smelter = front, chest = right for it

function getSmelteryFluidCount()
    count = 0
    for _, _ in pairs({ smeltery.getContainedFluids() }) do
        count = count + 1;
    end
    return count
end

function getTankFluidCount()
    count = 0
    for _, _ in pairs(tank.getFluids()) do
        count = count + 1;
    end
    return count
end

function getSmelteryLiquidWithName(name)
    for i, fluid in ipairs({ smeltery.getContainedFluids() }) do
        if fluid.name == name then
            return fluid, i
        end
    end
    return false
end

function getTankLiquidWithName(name)
    if tank.getFluids().n == 0 then
        return false
    end

    for i, fluid in ipairs(tank.getFluids()) do
        if fluid.name == name then
            return fluid, i
        end
    end
    return false
end

function moveFluidToSmeltery(name, amount)
    fluid, index = getTankLiquidWithName(name)

    if fluid == false then
        return false
    end

    if fluid.amount < amount then
        return false
    end

    tank.moveFluidToBottom(index)
    ft.transferFluid(tinkerTankSide, smelterDrainSide, amount)

    return true
end

function moveFluidToTank(name, amount)
    fluid, index = getSmelteryLiquidWithName(name)

    if fluid == false then
        return false
    end

    if fluid.amount < amount then
        return false
    end

    smeltery.moveFluidToBottom(index)
    ft.transferFluid(smelterDrainSide, tinkerTankSide, amount)

    return true
end

function purge()
    print("PURGING")
    while getSmelteryFluidCount() > 0 do
        moveFluidToTank(smeltery.getContainedFluids().name, smeltery.getContainedFluids().amount)
    end
    print("Purge complete.")
    os.sleep(0.5)
end

function alloyingHandler()
    while true do
        t.clear()
        count = 0
        print("Alloying menu. Select alloy to create.")
        for i, v in pairs(alloys) do
            count = count + 1
            print(i..": "..v.name)
        end

        alloy = {}

        while true do
            t.write("> ")
            choice = io.read()
            if choice == "q" then
                return
            elseif tonumber(choice) > 0 and tonumber(choice) <= count then
                alloy = alloys[tonumber(choice)]
                break
            else
                print("Invalid input. Try again.")
            end
        end

        purge()
        t.clear()
        print("Forging requirements for "..alloy.name..", per "..alloy.amount.."mb:")
        for k, v in pairs(alloy.ingredients) do
            print(v.."mb "..k)
        end
        print("Amount to produce: ("..alloy.amount.."-"..smeltery.getCapacity()..")")

        alloyingAmount = 0

        while true do
            t.write("> ")
            alloyingAmount = tonumber(io.read())
            if alloyingAmount ~= nil then
                if alloyingAmount >= alloy.amount and alloyingAmount <= smeltery.getCapacity() then
                    break
                else
                    print("Invalid amount.")
                end
            else
                print("Invalid input.")
            end
        end

        t.clear()
        print("Alloying cost:")

        cost = {}
        ready = true

        for k, v in pairs(alloy.ingredients) do
            toggle = v * math.ceil(alloyingAmount / alloy.amount)
            cost[k] = toggle
            print(toggle .."mb "..k.." needed")
            aInStorage = 0
            if getTankLiquidWithName(k) ~= false then
                aInStorage = getTankLiquidWithName(k).amount
            end
            print(aInStorage.."mb "..k.." in storage")
            totCost = toggle - aInStorage
            if toggle - aInStorage > 0 then
                print("Additional "..totCost.."mb needed.")
                ready = false
            end
            print("---")
        end
        if ready then
            print("Alloying...")
            for k, v in pairs(cost) do
                moveFluidToSmeltery(k, v)
            end
            print("Done.")
            os.sleep(2)
        else
            print("Not enough ingredients. Press any key to continue.")
            event.pull("key_down")
        end
    end
end

function transferHandler()
    while true do
        t.clear()
        print("Transfer menu. Select direction.")
        dir = generateQuery(transferOptions)

        if dir == 1 then
            t.clear()
            if getSmelteryFluidCount() == 0 then
                print("No fluids in smeltery!")
                os.sleep(1)
                break
            end

            fluids = {}
            for _, fluid in pairs({ smeltery.getContainedFluids() }) do
                table.insert(fluids, fluid.name)
            end

            print("Fluid to transfer:")
            tIndex = generateQuery(fluids)

            if tIndex ~= -1 then
                max = getSmelteryLiquidWithName(fluids[tIndex]).amount
                print("Amount to transfer: " .. "(" .. 1 .. "-" .. max .. ")")
                while true do
                    t.write("> ")
                    amount = tonumber(io.read())

                    if amount ~= nil then
                        if amount < 1 or amount > max then
                            print("Invalid amount.")
                        else
                            print("Transferring...")
                            moveFluidToTank(fluids[tIndex], amount)
                            os.sleep(.5)
                            break
                        end
                    else
                        print("Please enter a number.")
                    end
                end
            end
        elseif dir == 2 then
            t.clear()
            if getTankFluidCount() == 0 then
                print("No fluids in tank!")
                os.sleep(1)
                break
            end

            fluids = {}
            for _, fluid in ipairs(tank.getFluids()) do
                table.insert(fluids, fluid.name)
            end

            print("Fluid to transfer:")
            tIndex = generateQuery(fluids)

            if tIndex ~= -1 then
                max = getTankLiquidWithName(fluids[tIndex]).amount
                print("Amount to transfer: " .. "(" .. 1 .. "-" .. max .. ")")
                while true do
                    t.write("> ")
                    amount = tonumber(io.read())

                    if amount ~= nil then
                        if amount < 1 or amount > max then
                            print("Invalid amount.")
                        else
                            print("Transferring...")
                            moveFluidToSmeltery(fluids[tIndex], amount)
                            os.sleep(.5)
                            break
                        end
                    else
                        print("Please enter a number.")
                    end
                end
            end
        elseif dir == 3 then
            purge()
        else
            return
        end

    end
end

function generateQuery(options)
    count = 0
    for i, v in ipairs(options) do
        count = count + 1
        print(i .. ": " .. v)
    end
    print("Enter index or 'q' to go back.")

    while true do
        t.write("> ")
        input = io.read()
        if input == "q" then
            return -1
        elseif tonumber(input) > 0 and tonumber(input) <= count then
            return tonumber(input)
        else
            print("Invalid input. Try again.")
        end
    end
end

while true do
    t.clear()
    print("Welcome to the CAFE. Select an option.")
    opt = generateQuery(tasks)
    if (opt == 1) then
        transferHandler()
    elseif opt == 2 then
        alloyingHandler()
    end
end