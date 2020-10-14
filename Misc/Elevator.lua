local c = require("component")
local e = require("event")
local t = require("term")
local g = c.gpu
local com = require("computer")
local m = c.modem
local s = require("sides")
local r = c.redstone

function validate(pass)
    toggle = c.data.decrypt(pass, "motherlovesyou12", "numberofthebeast")
    return toggle
end

function door(_, _, _, _, _, pass, id, op)
    if validate(pass) == "elevator" and id == string.sub(m.address, 1, 3) then
        if op == "open" then
            r.setOutput(s.top, 15)
        elseif op == "close" then
            r.setOutput(s.top, 0)
        end
    end
end

function drawButton(x,y,t)
    g.setBackground(0xFFFFFF)
    for i = x, x + 5 do
        for j = y, y + 2 do
            g.set(i,j,"*")
        end
    end
    g.setForeground(0x000000)
    g.set(x+2,y+1,tostring(t))
    g.setForeground(0xFFFFFF)
    g.setBackground(0x000000)
end

function getFloor()
    t.clear()
    drawButton(2,5,1)
    drawButton(10,5,2)
    drawButton(18,5,3)
    drawButton(2,9,4)
    drawButton(10,9,5)
    drawButton(18,9,6)
    drawButton(2,13,7)
    drawButton(10,13,8)
    drawButton(18,13,9)
    drawButton(26,5,"#")
    drawButton(26,9,0)
    drawButton(26,13,"-")

    local items = {
        {1, 2, 3, "#"},
        {4, 5, 6, 0},
        {7, 8, 9, "-"},
    }

    local dest=""
    t.setCursor(3, 1)
    print("Enter floor and press \'#\'")
    t.setCursor(7, 3)
    t.write("Selected floor: ")
    local done = false
    while done == false do
        local xx = 0
        local yy = -1
        _, _, x, y = e.pull("touch")
        for i=2,32,8 do
            xx = xx + 1
            for j=5, 13, 4 do
                yy = (yy + 1) % 3
                if x < i then break end
                if x >= i and x <= i+5 and y >=j and y <= j+3 then
                    com.beep(1100)
                    sel = items[yy+1][xx]
                    if sel == "#" then
                        sel = ""
                        if string.len(dest) > 0 then
                            done = true break
                        end
                    end
                    dest = dest..sel
                    t.write(sel)
                end
            end
        end
        os.sleep()
    end
    return dest
end

m.open(890)
r.setOutput(s.top, 0)
t.clear()
print(toggle)
e.listen("modem_message", door)

local valid = false
repeat
    toggle = getFloor()
    if tonumber(toggle) ~= nil then
        if tonumber(toggle) <= 0 then
            valid = true
            break
        else
            t.setCursor(8,4)
            print("Invalid floor.")
            os.sleep(0.3)
        end
    else
        t.setCursor(6,4)
        print("Invalid destination.")
        os.sleep(0.3)
    end
    os.sleep()
until valid == true
