package.path = package.path .. ";data/scripts/lib/?.lua"

require("utility")
require("stringutility")
local playerTotalCrewBar;
local selfTotalCrewBar;

local playerCrewBars = {}
local playerCrewButtons = {}
local selfCrewBars = {}
local selfCrewButtons = {}

local playerTotalCargoBar;
local selfTotalCargoBar;

local playerCargoBars = {}
local playerCargoButtons = {}
local selfCargoBars = {}
local selfCargoButtons = {}

local crewmenByButton = {}
local cargosByButton = {}

local playerCrewIcons = {}
local playerCrewLevelIcons = {}
local selfCrewIcons = {}
local selfCrewLevelIcons = {}

local playerCargoIcons = {}
local playerCargoIllegalIcons = {}
local selfCargoIcons = {}
local selfCargoIllegalIcons = {}

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    local player = Player()
    local ship = Entity()
    local other = player.craft

    if ship.index == other.index then
        return false
    end

    -- interaction with drones does not work
    if ship.isDrone or other.isDrone then
        return false
    end

    if Faction().index ~= playerIndex then
        return false
    end

    return true, ""
end

--function initialize()
--
--end

-- create all required UI elements for the client side
function initUI()

    local res = getResolution();
    local size = vec2(1000, 800)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Transfer Crew/Cargo"%_t);

    window.caption = "Transfer Crew and Cargo"%_t
    window.showCloseButton = 1
    window.moveable = 1

    tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))
    local crewTab = tabbedWindow:createTab("Crew"%_t, "data/textures/icons/backup.png", "Exchange crew"%_t)

    local vSplit = UIVerticalSplitter(Rect(crewTab.size), 10, 0, 0.5)

--    crewTab:createFrame(vSplit.left);
--    crewTab:createFrame(vSplit.right);

    -- have to use "left" twice here since the coordinates are relative and the UI would be displaced to the right otherwise
    local leftLister = UIVerticalLister(vSplit.left, 10, 10)
    local rightLister = UIVerticalLister(vSplit.left, 10, 10)

    leftLister.marginRight = 30
    rightLister.marginRight = 30

    local leftFrame = crewTab:createScrollFrame(vSplit.left)
    local rightFrame = crewTab:createScrollFrame(vSplit.right)

    local TopBarRectLeft = vSplit.left
    TopBarRectLeft.height = 25

    local TopBarRectRight = vSplit.left
    TopBarRectRight.height = 25

    local playerStats = UIVerticalSplitter(TopBarRectRight, 10, 0, 0.70)

    local selfStats = UIVerticalSplitter(TopBarRectRight, 10, 0, 0.30)

    playerTotalCrewBar = leftFrame:createNumbersBar(playerStats.left)
    leftLister:placeElementLeft(playerTotalCrewBar)

    selfTotalCrewBar = rightFrame:createNumbersBar(selfStats.right)
    rightLister:placeElementRight(selfTotalCrewBar)


    for i = 1, CrewProfessionType.Number * 4 do

	    --Left transfer field Rect
        local row = leftLister:placeCenter(vec2(leftLister.inner.width, 25))
        local rowSplitter = UIVerticalSplitter(row, 10, 0, 0.75)
        local transferSplitter = UIVerticalMultiSplitter(rowSplitter.right, 10, 0, 2)
        local displaySplitter = UIVerticalSplitter(rowSplitter.left, 2, 0, 0.13)
        local crewManDisplay = UIVerticalSplitter(displaySplitter.left, 0, 0, 0.73)


        local buttonOne = leftFrame:createButton(transferSplitter:partition(0), ">", "onPlayerTransferCrewPressed")
        local buttonMulti = leftFrame:createButton(transferSplitter:partition(1), ">>", "onPlayerTransferCrewPressedMulti")
        local buttonAll = leftFrame:createButton(transferSplitter:partition(2), "*", "onPlayerTransferCrewPressedAll")

        local icon = leftFrame:createPicture(crewManDisplay.left, "")
        local level = leftFrame:createPicture(crewManDisplay.right, "")
        local bar = leftFrame:createStatisticsBar(displaySplitter.right, ColorRGB(1, 1, 1))

        icon.flipped = false
        icon.isIcon = true
        icon.color = ColorRGB(1,1,1)

        level.flipped = false
        level.isIcon = true
        level.height = level.height*0.5
        level.color = ColorRGB(1,1,1)

        buttonOne.textSize = 16
        buttonMulti.textSize = 16
        buttonAll.textSize = 16

        table.insert(playerCrewButtons, buttonOne)
        table.insert(playerCrewButtons, buttonMulti)
        table.insert(playerCrewButtons, buttonAll)
        table.insert(playerCrewBars, bar)
        table.insert(playerCrewIcons, icon)
        table.insert(playerCrewLevelIcons, level)

        crewmenByButton[buttonOne.index] = i
        crewmenByButton[buttonMulti.index] = i
        crewmenByButton[buttonAll.index] = i


	--Left transfer field Rect
        local row = rightLister:placeCenter(vec2(rightLister.inner.width, 25)) --right side of transfer 
        local rowSplitter = UIVerticalSplitter(row, 10, 0, 0.25) --splits for left: buttons right: displays
	    local transferSplitter =  UIVerticalMultiSplitter(rowSplitter.left, 10, 0, 2) --splits for different kinds of transfer buttons
        local displaySplitter = UIVerticalSplitter(rowSplitter.right, 2, 0, 0.87) --splits into left: Numberbar right: CrewIcons
        local crewManDisplay = UIVerticalSplitter(displaySplitter.right, 0, 0, 0.73) --splits into right: level left crewIcon

	    local buttonAll = rightFrame:createButton(transferSplitter:partition(0), "*", "onSelfTransferCrewPressedAll")
	    local buttonMulti = rightFrame:createButton(transferSplitter:partition(1), "<<", "onSelfTransferCrewPressedMulti")
        local buttonOne = rightFrame:createButton(transferSplitter:partition(2), "<", "onSelfTransferCrewPressed")

        local icon = rightFrame:createPicture(crewManDisplay.left, "")
        local level = rightFrame:createPicture(crewManDisplay.right, "")

        local bar = rightFrame:createStatisticsBar(displaySplitter.left, ColorRGB(1, 1, 1))

        icon.flipped = false
        icon.isIcon = true
        icon.color = ColorRGB(1,1,1)

        level.flipped = false
        level.isIcon = true
        level.height = level.height*0.5
        level.color = ColorRGB(1,1,1)

        buttonOne.textSize = 16
        buttonMulti.textSize = 16
        buttonAll.textSize = 16

        table.insert(selfCrewButtons, buttonOne)
        table.insert(selfCrewButtons, buttonMulti)
        table.insert(selfCrewButtons, buttonAll)
        table.insert(selfCrewBars, bar)
        table.insert(selfCrewIcons, icon)
        table.insert(selfCrewLevelIcons, level)

        crewmenByButton[buttonOne.index] = i
        crewmenByButton[buttonMulti.index] = i
        crewmenByButton[buttonAll.index] = i
        
    end

    local cargoTab = tabbedWindow:createTab("Cargo"%_t, "data/textures/icons/trade.png", "Exchange cargo"%_t)

    local leftLister = UIVerticalLister(vSplit.left, 10, 10)
    local rightLister = UIVerticalLister(vSplit.left, 10, 10)

    leftLister.marginRight = 30
    rightLister.marginRight = 30

    local leftFrame = cargoTab:createScrollFrame(vSplit.left)
    local rightFrame = cargoTab:createScrollFrame(vSplit.right)

    playerTotalCargoBar = leftFrame:createNumbersBar(Rect())
    leftLister:placeElementCenter(playerTotalCargoBar)

    selfTotalCargoBar = rightFrame:createNumbersBar(Rect())
    rightLister:placeElementCenter(selfTotalCargoBar)
    --Initially there was a 9 here, 9 is to low for me liking so up it goes ~NexusNull
    for i = 1, 90 do
        local row = leftLister:placeCenter(vec2(leftLister.inner.width, 25))
        local rowSplitter = UIVerticalSplitter(row, 10, 0, 0.75)-- left: display right:buttons

        local transferSplitter = UIVerticalMultiSplitter(rowSplitter.right, 10, 0, 2)
        local displaySplitter = UIVerticalSplitter(rowSplitter.left, 10, 0, 0.2)
        local IconSplitter = UIVerticalSplitter(displaySplitter.left, 10, 0, 0.5)

        local buttonOne = leftFrame:createButton(transferSplitter:partition(0), ">", "onPlayerTransferCargoPressed")
        local buttonMulti = leftFrame:createButton(transferSplitter:partition(1), ">>", "onPlayerTransferCargoPressedMulti")
        local buttonAll = leftFrame:createButton(transferSplitter:partition(2), "*", "onPlayerTransferCargoPressedAll")

        local icon = leftFrame:createPicture(IconSplitter.left, "")
        local illegalIcon = leftFrame:createPicture(IconSplitter.right, "")
        illegalIcon.isIcon = true
        illegalIcon.color = ColorRGB(1,0,0)

        icon.flipped = false
        icon.isIcon = true
        icon.color = ColorRGB(1,1,1)

        local bar = leftFrame:createStatisticsBar(displaySplitter.right, ColorRGB(1, 1, 1))

        buttonOne.textSize = 16
        buttonMulti.textSize = 16
        buttonAll.textSize = 16

        table.insert(playerCargoButtons, buttonOne)
        table.insert(playerCargoButtons, buttonMulti)
        table.insert(playerCargoButtons, buttonAll)
        table.insert(playerCargoBars, bar)
        table.insert(playerCargoIcons, icon)
        table.insert(playerCargoIllegalIcons, illegalIcon)

        cargosByButton[buttonOne.index] = i
        cargosByButton[buttonMulti.index] = i
        cargosByButton[buttonAll.index] = i


        local row = rightLister:placeCenter(vec2(rightLister.inner.width, 25))
        local rowSplitter = UIVerticalSplitter(row, 10, 0, 0.25)-- left: display right:buttons

        local transferSplitter = UIVerticalMultiSplitter(rowSplitter.left, 10, 0, 2)
        local displaySplitter = UIVerticalSplitter(rowSplitter.right, 10, 0, 0.8)
        local IconSplitter = UIVerticalSplitter(displaySplitter.right, 10, 0, 0.5)

        local buttonAll =   rightFrame:createButton(transferSplitter:partition(0), "*", "onSelfTransferCargoPressedAll")
        local buttonMulti = rightFrame:createButton(transferSplitter:partition(1), "<<", "onSelfTransferCargoPressedMulti")
        local buttonOne =   rightFrame:createButton(transferSplitter:partition(2), "<", "onSelfTransferCargoPressed")

        local icon = rightFrame:createPicture(IconSplitter.right, "")
        local illegalIcon = rightFrame:createPicture(IconSplitter.left, "modfiles/icons/icons/forbidden.png")
        illegalIcon.isIcon = true
        illegalIcon.color = ColorRGB(1,0,0)

        icon.flipped = false
        icon.isIcon = true
        icon.color = ColorRGB(1,1,1)

        local bar = rightFrame:createStatisticsBar(displaySplitter.left, ColorRGB(1, 1, 1))

        buttonOne.textSize   = 16
        buttonMulti.textSize = 16
        buttonAll.textSize   = 16

        table.insert(selfCargoButtons, buttonOne)
        table.insert(selfCargoButtons, buttonMulti)
        table.insert(selfCargoButtons, buttonAll)
        table.insert(selfCargoBars, bar)
        table.insert(selfCargoIcons, icon)
        table.insert(selfCargoIllegalIcons, illegalIcon)

        cargosByButton[buttonOne.index]   = i
        cargosByButton[buttonMulti.index] = i
        cargosByButton[buttonAll.index]   = i        

    end

end


function getPlayerCrewman(crewmanIndex)
    local playerShip = Player().craft
    
    local sorted = getSortedCrewmen(playerShip)

    local p = sorted[crewmanIndex]
    if not p then
        print("bad crewman")
        return
    end

    local crewman = p.crewman
    return playerShip.crew:getNumMembers(crewman)
end


function getSelfCrewman(crewmanIndex)
    local ship = Entity()
    
    local sorted = getSortedCrewmen(ship)

    local p = sorted[crewmanIndex]
    if not p then
        print("bad crewman")
        return
    end

    local crewman = p.crewman
    return ship.crew:getNumMembers(crewman)
end

function updateData()
    local playerShip = Player().craft
    local ship = Entity()

    -- update crew info
    playerTotalCrewBar:clear()
    selfTotalCrewBar:clear()

    playerTotalCrewBar:setRange(0, playerShip.maxCrewSize)
    selfTotalCrewBar:setRange(0, ship.maxCrewSize)

    for _, bar in pairs(playerCrewBars) do bar.visible = false end
    for _, bar in pairs(selfCrewBars) do bar.visible = false end

    for _, bar in pairs(playerCargoBars) do bar.visible = false end
    for _, bar in pairs(selfCargoBars) do bar.visible = false end

    for _, button in pairs(playerCrewButtons) do button.visible = false end
    for _, button in pairs(selfCrewButtons) do button.visible = false end

    for _, button in pairs(playerCargoButtons) do button.visible = false end
    for _, button in pairs(selfCargoButtons) do button.visible = false end

    for _, icon in pairs(playerCrewIcons) do icon.visible = false end
    for _, icon in pairs(selfCrewIcons) do icon.visible = false end

    for _, icon in pairs(playerCrewLevelIcons) do icon.visible = false end
    for _, icon in pairs(selfCrewLevelIcons) do icon.visible = false end

    for _, icon in pairs(playerCargoIcons) do icon.visible = false end
    for _, icon in pairs(playerCargoIllegalIcons) do icon.visible = false end

    for _, icon in pairs(selfCargoIcons) do icon.visible = false end
    for _, icon in pairs(selfCargoIllegalIcons) do icon.visible = false end

    local i = 1
    for _, p in pairs(getSortedCrewmen(playerShip)) do

        local crewman = p.crewman
        local num = p.num

        local caption = num .. " " .. crewman.profession.name

        playerTotalCrewBar:addEntry(num, caption, crewman.profession.color)

        local singleBar = playerCrewBars[i]
        singleBar.visible = true
        singleBar:setRange(0, playerShip.maxCrewSize)
        singleBar.value = num
        singleBar.name = caption
        singleBar.color = crewman.profession.color

        icon  = playerCrewIcons[i]
        level = playerCrewLevelIcons[i]

        icon.picture = "modfiles/icons/crew/"..crewman.profession.value..".png"
        icon.visible = true

        if crewman.specialist then
            level.picture = "modfiles/icons/level/"..crewman.level..".png"
            level.visible = true
        end


        for j=0,2 do
        local button = playerCrewButtons[1+(i-1)*3+j]
        button.visible = true
        end       
        i = i + 1
    end

    local i = 1
    for _, p in pairs(getSortedCrewmen(Entity())) do

        local crewman = p.crewman
        local num = p.num

        local caption = num .. " " .. crewman.profession.name

        selfTotalCrewBar:addEntry(num, caption, crewman.profession.color)

        local singleBar = selfCrewBars[i]
        singleBar.visible = true
        singleBar:setRange(0, ship.maxCrewSize)
        singleBar.value = num
        singleBar.name = caption
        singleBar.color = crewman.profession.color

        icon = selfCrewIcons[i]
        level = selfCrewLevelIcons[i]
        icon.picture = "modfiles/icons/crew/"..crewman.profession.value..".png"
        icon.visible = true
        if crewman.specialist then
            level.picture = "modfiles/icons/level/"..crewman.level..".png"
            level.visible = true
        end

        for j=0,2 do
            local button = selfCrewButtons[1+(i-1)*3+j]
            button.visible = true
        end        
        i = i + 1
    end
    

    -- update cargo info
    playerTotalCargoBar:clear()
    selfTotalCargoBar:clear()

    playerTotalCargoBar:setRange(0, playerShip.maxCargoSpace)
    selfTotalCargoBar:setRange(0, ship.maxCargoSpace)

    for i, v in pairs(playerCargoBars) do

        local bar = playerCargoBars[i]
        local button1 = playerCargoButtons[1+(i-1)*3]
        local button2 = playerCargoButtons[2+(i-1)*3]
        local button3 = playerCargoButtons[3+(i-1)*3]

        if i > playerShip.numCargos then
            bar:hide()
            button1:hide()
            button2:hide()
            button3:hide()
        else
            bar:show();
            button1:show()
            button2:show()
            button3:show()

            local good, amount = playerShip:getCargo(i - 1)
            local maxSpace = playerShip.maxCargoSpace
            bar:setRange(0, maxSpace)
            bar.value = amount * good.size

            icon = playerCargoIcons[i]
            icon.picture = good.icon
            icon.color = ColorRGB(1,1,1)
            icon.visible = true

            illegal = playerCargoIllegalIcons[i]
            
            if good.illegal or good.dangerous then
                illegal.picture = "modfiles/icons/icons/forbidden.png"
                illegal.color = ColorRGB(1,0,0)
                illegal.visible = true
            else
                illegal.visible = false
            end

            if amount > 1 then
                bar.name = amount .. " " .. good.plural
                playerTotalCargoBar:addEntry(amount * good.size, amount .. " " .. good.plural, ColorInt(0xffa0a0a0))
            else
                bar.name = amount .. " " .. good.name
                playerTotalCargoBar:addEntry(amount * good.size, amount .. " " .. good.name, ColorInt(0xffa0a0a0))
            end
        end

        local bar = selfCargoBars[i]
        local button1 = selfCargoButtons[1+(i-1)*3]
        local button2 = selfCargoButtons[2+(i-1)*3]
        local button3 = selfCargoButtons[3+(i-1)*3]

        if i > ship.numCargos then
            bar:hide();
            button1:hide();
            button2:hide();
            button3:hide();
        else
            bar:show();
            button1:show();
            button2:show();
            button3:show();

            local good, amount = ship:getCargo(i - 1)
            local maxSpace = ship.maxCargoSpace
            bar:setRange(0, maxSpace)
            bar.value = amount * good.size

            icon = selfCargoIcons[i]
            icon.picture = good.icon
            icon.color = ColorRGB(1,1,1)
            icon.visible = true

            illegal = selfCargoIllegalIcons[i]

            if good.illegal or good.dangerous then
                illegal.picture = "modfiles/icons/icons/forbidden.png"
                illegal.color = ColorRGB(1,0,0)
                illegal.visible = true
            else
                illegal.visible = false
            end

            if amount > 1 then
                bar.name = amount .. " " .. good.plural
                selfTotalCargoBar:addEntry(amount * good.size, amount .. " " .. good.plural, ColorInt(0xffa0a0a0))
            else
                bar.name = amount .. " " .. good.name
                selfTotalCargoBar:addEntry(amount * good.size, amount .. " " .. good.name, ColorInt(0xffa0a0a0))
            end
        end
    end

end

function onSelfTransferCrewPressed(button)
    -- transfer crew from self ship to player ship

    -- check which crew member type
    local crewmanIndex = crewmenByButton[button.index]
    if not crewmanIndex then return end

    invokeServerFunction("transferCrew", crewmanIndex, Player().craftIndex, true)
end

function onPlayerTransferCrewPressed(button)
    -- transfer crew from player ship to self

    -- check which crew member type
    local crewmanIndex = crewmenByButton[button.index]
    if not crewmanIndex then return end

    invokeServerFunction("transferCrew", crewmanIndex, Player().craftIndex, false)
end

function onSelfTransferCrewPressedMulti(button)
    local crewmanIndex = crewmenByButton[button.index]
    if not crewmanIndex then return end

    num = getSelfCrewman(crewmanIndex)

    if Entity():getNearestDistance(Entity(Player().selectedObject)) > 20 then
        amount = 1
    end

    for i=1,math.min(25,num) do
        invokeServerFunction("transferCrew", crewmanIndex, Player().craftIndex, true)
    end
end

function onPlayerTransferCrewPressedMulti(button)
    local crewmanIndex = crewmenByButton[button.index]
    if not crewmanIndex then return end

    num = getPlayerCrewman(crewmanIndex)

    if Entity():getNearestDistance(Entity(Player().selectedObject)) > 20 then
        amount = 1
    end

    for i=1,math.min(25,num) do
        invokeServerFunction("transferCrew", crewmanIndex, Player().craftIndex, false)
    end
end


function onSelfTransferCrewPressedAll(button)
    local crewmanIndex = crewmenByButton[button.index]
    if not crewmanIndex then return end

    num = getSelfCrewman(crewmanIndex)
    
    if Entity():getNearestDistance(Entity(Player().selectedObject)) > 20 then
        amount = 1
    end

    for i=1,math.min(1000,num) do
        invokeServerFunction("transferCrew", crewmanIndex, Player().craftIndex, true)
    end
end

function onPlayerTransferCrewPressedAll(button)
    local crewmanIndex = crewmenByButton[button.index]
    if not crewmanIndex then return end

    amount = getPlayerCrewman(crewmanIndex)

    if Entity():getNearestDistance(Entity(Player().selectedObject)) > 20 then
        amount = 1
    end

    for i=1,math.min(1000, amount) do
        invokeServerFunction("transferCrew", crewmanIndex, Player().craftIndex, false)
    end
end

function getSortedCrewmen(entity)

    function compareCrewmen(pa, pb)
        local a = pa.crewman
        local b = pb.crewman

        if a.profession.value == b.profession.value then
            if a.specialist == b.specialist then
                return a.level < b.level
            else
                return (a.specialist and 1 or 0) < (b.specialist and 1 or 0)
            end
        else
            return a.profession.value < b.profession.value
        end
    end

    local crew = entity.crew

    local sortedMembers = {}
    for crewman, num in pairs(crew:getMembers()) do
        table.insert(sortedMembers, {crewman = crewman, num = num})
    end

    table.sort(sortedMembers, compareCrewmen)
    for key, value in pairs(sortedMembers) do
        crewman = value.crewman
    end

    return sortedMembers
end


function transferCrew(crewmanIndex, otherIndex, selfToOther)
    local sender
    local receiver

    if selfToOther then
        sender = Entity()
        receiver = Entity(otherIndex)
    else
        sender = Entity(otherIndex)
        receiver = Entity()
    end

    if sender.factionIndex ~= callingPlayer then
        local player = Player(callingPlayer)
        if player then
            player:sendChatMessage("Server"%_t, 1, "You don't own this craft."%_t)
        end
        return
    end

    -- check distance
    if sender:getNearestDistance(receiver) > 20 then
        Player(callingPlayer):sendChatMessage("Server"%_t, 1, "You're too far away."%_t)
        return
    end

    local sorted = getSortedCrewmen(sender)

    local p = sorted[crewmanIndex]
    if not p then
        print("bad crewman")
        return
    end

    local crewman = p.crewman

    -- make sure sending ship has a member of this type
    if sender.crew:getNumMembers(crewman) == 0 then
        print("no crew of this type")
        return
    end

    -- transfer
    sender:removeCrew(1, crewman)
    receiver:addCrew(1, crewman)

    invokeClientFunction(Player(callingPlayer), "updateData")
end

function onPlayerTransferCargoPressed(button)
    -- transfer cargo from player ship to self

    -- check which cargo
    local cargo = cargosByButton[button.index]
    if cargo == nil then return end

    invokeServerFunction("transferCargo", cargo - 1, Player().craftIndex, false)
end

function onSelfTransferCargoPressed(button)
    -- transfer cargo from self to player ship

    -- check which cargo
    local cargo = cargosByButton[button.index]
    if cargo == nil then return end

    invokeServerFunction("transferCargo", cargo - 1, Player().craftIndex, true)
end

function onPlayerTransferCargoPressedMulti(button)

    local sender = Player().craft
    local receiver = Entity(Player().selectedObject)
    -- transfer cargo from player ship to self
    

    -- check which cargo
    local cargo = cargosByButton[button.index]
    if cargo == nil then return end
    
    local good, amount = sender:getCargo(cargo-1)

    -- make sure sending ship has the cargo
    if amount == nil then return end

    if sender:getNearestDistance(receiver) > 2 then
        amount=1
    end

    for i=1,math.min(25, amount, receiver.freeCargoSpace) do
        invokeServerFunction("transferCargo", cargo - 1, Player().craftIndex, false)
    end
end

function onSelfTransferCargoPressedMulti(button)

    local receiver = Player().craft
    local sender = Entity(Player().selectedObject)
    -- transfer cargo from self to player ship



    -- check which cargo
    local cargo = cargosByButton[button.index]
    if cargo == nil then return end
    
    local good, amount = sender:getCargo(cargo-1)

    -- make sure sending ship has the cargo
    if amount == nil then return end

    if sender:getNearestDistance(receiver) > 2 then
        amount=1
    end

    for i=1,math.min(25, amount, receiver.freeCargoSpace) do
        invokeServerFunction("transferCargo", cargo - 1, Player().craftIndex, true)
    end
end

function onPlayerTransferCargoPressedAll(button) 

    local sender = Player().craft
    local receiver = Entity(Player().selectedObject) 
    -- transfer cargo from player ship to self


    -- check which cargo
    local cargo = cargosByButton[button.index]
    if cargo == nil then return end
    
    local good, amount = sender:getCargo(cargo-1)

    -- make sure sending ship has the cargo
    if amount == nil then return end

    if sender:getNearestDistance(receiver) > 2 then
        amount=1
    end
    for i=1,math.min(1000, amount, receiver.freeCargoSpace) do
        invokeServerFunction("transferCargo", cargo - 1, Player().craftIndex, false)
    end
end

function onSelfTransferCargoPressedAll(button)

    local sender = Entity(Player().selectedObject)
    local receiver = Player().craft
    -- transfer cargo from self to player ship



    -- check which cargo
    local cargo = cargosByButton[button.index]
    if cargo == nil then return end
    
    local good, amount = sender:getCargo(cargo-1)

    -- make sure sending ship has the cargo
    if amount == nil then return end

    if sender:getNearestDistance(receiver) > 2 then
        amount=1
    end
    for i=1,math.min(1000, amount, receiver.freeCargoSpace) do
        invokeServerFunction("transferCargo", cargo - 1, Player().craftIndex, true)
    end
end



function transferCargo(cargoIndex, otherIndex, selfToOther)
    local sender
    local receiver

    if selfToOther then
        sender = Entity()
        receiver = Entity(otherIndex)
    else
        sender = Entity(otherIndex)
        receiver = Entity()
    end

    if sender.factionIndex ~= callingPlayer then
        local player = Player(callingPlayer)
        if player then
            player:sendChatMessage("Server"%_t, 1, "You don't own this craft."%_t)
        end
        return
    end

    -- check distance
    if sender:getNearestDistance(receiver) > 2 then
        Player(callingPlayer):sendChatMessage("Server"%_t, 1, "You're too far away."%_t)
        return
    end

    -- get the cargo
    local good, amount = sender:getCargo(cargoIndex)

    -- make sure sending ship has the cargo
    if amount == nil then return end
    if amount == 0 then return end

    -- make sure receiving ship has enough space
    if receiver.freeCargoSpace < good.size then
        Player(callingPlayer):sendChatMessage("Server"%_t, 1, "Not enough space on the other craft."%_t)
        return
    end

    -- transfer
    sender:removeCargo(good, 1)
    receiver:addCargo(good, 1)

    invokeClientFunction(Player(callingPlayer), "updateData")
end

---- this function gets called every time the window is shown on the client, ie. when a player presses F
function onShowWindow()
    updateData()
end
--
---- this function gets called every time the window is shown on the client, ie. when a player presses F
--function onCloseWindow()
--
--end

-- this function will be executed every frame both on the server and the client
--function update(timeStep)
--end
--
---- this function will be executed every frame on the client only
--function updateClient(timeStep)
--end
--
---- this function will be executed every frame on the server only
--function updateServer(timeStep)
--end
--
---- this function will be executed every frame on the client only
---- use this for rendering additional elements to the target indicator of the object
--function renderUIIndicator(px, py, size)
--end
--
---- this function will be executed every frame on the client only
---- use this for rendering additional elements to the interaction menu of the target craft
--function renderUI()
--end

