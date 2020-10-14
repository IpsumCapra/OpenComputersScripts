local c = require("component")
local ser = require("serialization")
local term = require("term")
local keys = require("keys")
local dat = c.data
local drv = c.disk_drive

local options = { "add user", "edit user", "remove user", "burn key" }
local modOptions = { "name", "clearance", "password" }

local function confirm()
    term.write("[Y/n]: ")
    response = term.read()
    if respone == "y\n" or response == "Y\n" or response == "\n" then
        return true
    else
        return false
    end
end

local function selectUser()
    data = keys.getKeyData()
    for k, v in pairs(data) do
        if k ~= "key" then
            print(k .. ": " .. keys.getUser(k).name)
        end
    end
    print("Enter user index, or enter 'q' to exit.")
    while true do
        term.write("> ")
        selection = term.read()
        if selection == "q\n" then
            return false
        else
            selection = tonumber(selection)
            if data[selection] ~= nil then
                return selection
            else
                print("Invalid input.")
            end
        end
    end
end

local function printUserData(userData)
    print("Name: " .. userData.name)
    print("Clearance level: " .. tostring(userData.clearance))
    term.write("Password: ")
    for _ = 1, #userData.password do
        term.write("*")
    end
    print("\n\n")
end

local function addUserInterface()
    term.clear()
    term.write("Full name: ")
    uName = string.sub(term.read(), 1, -2)
    while true do
        term.write("Clearance level: ")
        cLevel = tonumber(term.read())
        if cLevel == nil or cLevel < 1 then
            print("Invalid clearance level.")
        else
            break
        end
    end
    while true do
        term.write("User password: ")
        password = string.sub(term.read({ pwchar = "*" }), 1, -2)
        term.write("\nRetype password: ")
        if string.sub(term.read({ pwchar = "*" }), 1, -2) ~= password then
            print("\nPasswords do not match. Try again.")
        else
            break
        end
    end
    term.clear()
    print("Name: " .. uName)
    print("Clearance level: " .. tostring(cLevel))
    term.write("Password: ")
    for _ = 1, #password do
        term.write("*")
    end
    print("\n\n")
    print("Add user?")
    if confirm() then
        user = {
            name = uName,
            clearance = cLevel,
            password = password
        }
        keys.addUser(user, 1)
    end
end

local function modUserInterface()
    term.clear()
    print("Select user to modify")
    selection = selectUser()
    if selection ~= false then
        while true do
            term.clear()
            userData = keys.getUser(selection)
            printUserData(userData)

            print("Select item to modify.")
            for i, v in ipairs(modOptions) do
                print(tostring(i) .. ": " .. v)
            end
            print("Enter valid index, or enter 'q' to exit.")
            term.write("> ")
            option = term.read()
            if option == "1\n" then
                term.clear()
                term.write("New name: ")
                name = string.sub(term.read(), 1, -2)
                print("Set " .. name .. " as new name?")
                if confirm() then
                    userData.name = name
                    keys.modifyUserData(userData, selection)
                end
            elseif option == "2\n" then
                term.clear()
                while true do
                    term.write("New clearance level: ")
                    cLevel = tonumber(term.read())
                    if cLevel == nil or cLevel < 1 then
                        print("Invalid clearance level.")
                    else
                        break
                    end
                end
                print("Set " .. cLevel .. " as new clearance level?")
                if confirm() then
                    userData.clearance = cLevel
                    keys.modifyUserData(userData, selection)
                end
            elseif option == "3\n" then
                term.clear()
                while true do
                    term.write("New password: ")
                    password = string.sub(term.read({ pwchar = "*" }), 1, -2)
                    term.write("\nRetype password: ")
                    if string.sub(term.read({ pwchar = "*" }), 1, -2) ~= password then
                        print("\nPasswords do not match. Try again.")
                    else
                        break
                    end
                end
                print("\nSet new password?")
                if confirm() then
                    userData.password = password
                    keys.modifyUserData(userData, selection)
                end
            elseif option == "q\n" then
                return
            else
                print("Invalid input.")
                os.sleep(0.5)
            end
        end
    end
end

local function delUserInterface()
    term.clear()
    print("Select user to delete")
    selection = selectUser()
    if selection ~= false then
        print("Remove user?")
        if confirm() then
            keys.removeUser(selection)
        end
    end
end

local function burnInterface()
    term.clear()
    print("Please enter floppy disk to continue.")
    while drv.isEmpty() do
        os.sleep(0.06)
    end
    term.clear()
    print("Select user to create card for.")
    selection = selectUser()
    if selection ~= false then
        user = keys.getUser(selection)
        print("Create card for user " .. user.name .. "? This will remove all data on the floppy disk.")
        if confirm() then
            data = keys.getKeyData()
            writeData = {
                name=user.name,
                password=user.password
            }

            fullKey = dat.sha256(dat.decode64(data.key))
            key = string.sub(fullKey, 1, 16)
            iv = string.sub(fullKey, 17, 32)

            writeData = dat.encode64(dat.encrypt(ser.serialize(writeData), key, iv))

            if not drv.isEmpty() then
                disk = c.proxy(drv.media())
                if disk.isReadOnly() then
                    print("Disk is read only. Aborting.")
                    os.sleep(0.5)
                    return
                end
                disk.remove("/")
                disk.setLabel("Key Card")
                handle = disk.open("/key", "w")
                disk.write(handle, writeData)
                disk.close(handle)
                drv.eject()
            end
        end
    end
end

while true do
    term.clear()
    for i, v in ipairs(options) do
        print(tostring(i) .. ": " .. v)
    end
    print("Enter valid index, or enter 'q' to exit.")
    term.write("> ")
    option = term.read()
    if option == "1\n" then
        addUserInterface()
    elseif option == "2\n" then
        modUserInterface()
    elseif option == "3\n" then
        delUserInterface()
    elseif option == "4\n" then
        burnInterface()
    elseif option == "q\n" then
        term.clear()
        return
    else
        print("Invalid input.")
        os.sleep(0.5)
    end
end