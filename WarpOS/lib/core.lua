-- loadfile function from init.lua
local raw_loadfile = ...

local computer = computer
local component = component

-- set version.
_G._VERSION = "WarpOS 0.8"

-- get monitor in order.
local gpu = component.list("gpu", true)()
local screen = component.list("screen", true)()

if gpu == nil or screen == nil then
    computer.shutdown()
end

local screen = component.proxy(screen)
local gpu = component.proxy(gpu)

if gpu.maxDepth() < 4 then
    computer.shutdown()
end

local w, h
if not gpu.getScreen() then
    gpu.bind(screen.address)
end

w, h = gpu.maxResolution()
gpu.setResolution(w, h)
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")

function require(modname)
    return raw_loadfile("/lib/" .. modname .. ".lua")()
end

-- init component list.

function reloadComponents()
    _G.gpu = component.proxy(component.list("gpu")())
    _G.screen = component.proxy(component.list("screen")())
    _G.core = component.proxy(component.list("warpdriveShipCore")())
end

reloadComponents()

local t = require("terminal")

computer.beep()
t.printMap(t.logo, true)
t.setCursor(1, 8)
t.print("Booting " .. _G._VERSION .. "...")
t.print("> Library loader functional.")
t.print("> Looking for warpdrive core.")

local core = component.list("warpdriveShipCore", true)()
if core == nil then
    gpu.setForeground(0xFF0000)
    t.print("Could not find core. Shutting down!")
    sleep(1)
    computer.shutdown()
else
    t.print("> Found warpdrive core.")
end

t.print("Loading done. Initializing main program.")

raw_loadfile("/main.lua")()
