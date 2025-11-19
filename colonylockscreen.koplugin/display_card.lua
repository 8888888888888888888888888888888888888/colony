local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local CenterContainer = require("ui/widget/container/centercontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local Font = require("ui/font")
local Device = require("device")
local Screen = Device.screen

local ColonySimulator = {}

-- Load/save
local function loadGame()
    local f = io.open("colony_save.txt", "r")
    if f then
        local line1 = f:read("*l")
        local line2 = f:read("*l")
        local line3 = f:read("*l")
        local line4 = f:read("*l")
        local line5 = f:read("*l")
        local line6 = f:read("*l")
        f:close()
        if line1 and line2 and line3 and line4 and line5 and line6 then
            return {
                turn = tonumber(line1),
                population = tonumber(line2),
                food = tonumber(line3),
                wood = tonumber(line4),
                stone = tonumber(line5),
                morale = tonumber(line6)
            }
        end
    end
    return nil
end

local function saveGame(state)
    local f = io.open("colony_save.txt", "w")
    if f then
        f:write(tostring(state.turn) .. "\n")
        f:write(tostring(state.population) .. "\n")
        f:write(tostring(state.food) .. "\n")
        f:write(tostring(state.wood) .. "\n")
        f:write(tostring(state.stone) .. "\n")
        f:write(tostring(state.morale) .. "\n")
        f:close()
    end
end

--new save file stats if there's not one available

if not ColonySimulator.state then
    local saved = loadGame()
    if saved and saved.population then
        ColonySimulator.state = saved
    else
        ColonySimulator.state = { turn = 1, population = 5, food = 20, wood = 15, stone = 10, morale = 75 }
    end
end

-- Game logic
local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function simulateTurn(state)
    -- Food consumption
    local food_needed = state.population * 2
    state.food = state.food - food_needed

    -- Gather resources
    local workers = math.floor(state.population * 0.6)
    state.food = state.food + math.random(4, 7) * workers
    state.wood = state.wood + math.random(1, 3) * workers
    state.stone = state.stone + math.random(0, 2) * workers

    -- Morale effects
    if state.food < 0 then
        state.morale = state.morale - 15
        state.population = math.max(1, state.population - 1)
        state.food = 0
    elseif state.food > 50 then
        state.morale = state.morale + 3
    end

    -- Population growth
    if state.morale > 80 and state.food > 30 then
        if math.random(1, 100) < 30 then state.population = state.population + 1 end
    elseif state.morale < 30 then
        if math.random(1, 100) < 20 then state.population = math.max(1, state.population - 1) end
    end

    -- Clamp morale
    state.morale = clamp(state.morale, 0, 100)

    --random event
    local event_msg = ""
    local event_roll = math.random(1, 100)
    if event_roll < 8 then
        state.population = state.population + math.random(1, 2)
        event_msg = "oyem some new schmuckkers came over"
    elseif event_roll < 15 then
        local loss = math.floor(state.food * 0.25)
        state.food = state.food - loss
        event_msg = "fuck some food spoiled"
    elseif event_roll < 22 then
        state.wood = state.wood + math.random(8, 15)
        event_msg = "ayesyes we got some lumber"
    end

    state.turn = state.turn + 1
    return event_msg
end

function ColonySimulator:create()
    local state = ColonySimulator.state

    -- Simulate turn
    local event = simulateTurn(state)
    saveGame(state)

    -- Build display
    local lines = {}
    lines[1] = ""
    lines[2] = "colony survival alpha"
    lines[3] = ""
    lines[4] = string.format(" day %-23d", state.turn)
    lines[5] = "------------------------------"

    -- Resources
    lines[6] = string.format("colonists:%2d", state.population)
    lines[7] = string.format("food:%3d", state.food)
    lines[8] = string.format("wood:%3d", state.wood)
    lines[9] = string.format("stone:%3d", state.stone)
    lines[10] = string.format("morale:%2d%%", state.morale)
    lines[11] = "------------------------------"

    -- Status
    local status = "OK"
    if state.morale < 30 then status = "BAD"
    elseif state.morale > 80 then status = "GREAT" end
    lines[12] = string.format("colony status is %-20s ", status)
    if event ~= "" then
        lines[13] = string.format(" %-28s ", event)
    else
        lines[13] = "                            "
    end
    lines[14] = "------------------------------"
    lines[15] = ""
    lines[16] = ""

    -- Create widgets
    local widgets = {}
    for _, line in ipairs(lines) do
        table.insert(widgets, TextWidget:new{
            text = line,
            face = Font:getFace("cfont", 16),
        })
    end

    local group = VerticalGroup:new{ align = "center", table.unpack(widgets) }
    local container = CenterContainer:new{ dimen = Screen:getSize(), group, }

    return OverlapGroup:new{ dimen = Screen:getSize(), container, }
end

return ColonySimulator
