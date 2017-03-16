package.path = package.path .. ";data/scripts/lib/?.lua"

require("utility")
require("stringutility")

local playerCombo = nil
local playerList = nil
local buildingPlayerIndicesByName = {}

function getIcon()
    return "data/textures/icons/shaking-hands.png"
end

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    if Entity().factionIndex == playerIndex then
        return true, ""
    end

    return false
end

-- create all required UI elements for the client side
function initUI()

    local res = getResolution()
    local size = vec2(600, 400)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Permissions"%_t)

    window.caption = "Permissions"%_t
    window.showCloseButton = 1
    window.moveable = 1

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    local buildTab = tabbedWindow:createTab("Build"%_t, "data/textures/icons/brick-pile.png", "Manage Building Permissions"%_t)

    local hsplit = UIHorizontalSplitter(Rect(vec2(0, 0), tabbedWindow.size - vec2(0, 55)), 10, 0, 0.5)
    hsplit.bottomSize = 35

    local vsplit = UIVerticalSplitter(hsplit.top, 10, 0, 0.5)

    playerList = buildTab:createListBox(vsplit.left)

    playerCombo = buildTab:createListBox(vsplit.right, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)

    addScriptButton = buildTab:createButton(vsplit.left, "Add"%_t, "onAddBuildingPermissionPressed")
    removeScriptButton = buildTab:createButton(vsplit.right, "Remove"%_t, "onRemoveBuildingPermissionPressed")
end

function onShowWindow()

    buildingPlayerIndicesByName = {}
    playerCombo:clear()
    playerList:clear()

    local player = Player()

    --sort the names
    local playerNames = Galaxy():getPlayerNames()
    local sortList = {}
    for index, name in pairs(playerNames) do
        if player.name:lower() ~= name:lower() then
            buildingPlayerIndicesByName[name] = index
            table.insert(sortList, name)
        end
    end
    table.sort(sortList)
    -- fill combo box
    for index, name in pairs(sortList) do
        if player.name:lower() ~= name:lower() then
            playerCombo:addEntry(name);
        end
    end



    -- fill and sort
    local entity = Entity()
    local allowedPlayerNames = {}
    for _, index in pairs({entity:getBuildingPermissions()}) do
        local other = Faction(index)
        if other then
            table.insert(allowedPlayerNames, other.name)
        else
            print("Building collaboration: Removed player " .. index .. " as it was not a valid faction or player")
            invokeServerFunction("removePermission", index)
        end
    end
    table.sort(allowedPlayerNames)
    
    --display the list
    for _, name in pairs(allowedPlayerNames) do
        playerList:addEntry(name);
    end

end

function onAddBuildingPermissionPressed()

    local name = playerCombo:getSelectedEntry()
    local index = buildingPlayerIndicesByName[name]

    if index then
        invokeServerFunction("addPermission", index)
    end

end

function onRemoveBuildingPermissionPressed()

    local name = playerList:getSelectedEntry()
    local index = buildingPlayerIndicesByName[name]

    if index then
        invokeServerFunction("removePermission", index)
    end
end

function addPermission(playerIndex)
    local entity = Entity()
    if entity.factionIndex and entity.factionIndex ~= callingPlayer then return end

    entity:addBuildingPermission(playerIndex)

    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

function removePermission(playerIndex)
    local entity = Entity()
    if entity.factionIndex and entity.factionIndex ~= callingPlayer then return end

    entity:removeBuildingPermission(playerIndex)

    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','.."\n"
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

