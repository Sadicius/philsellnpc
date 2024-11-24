local RSGCore = exports['rsg-core']:GetCoreObject()
local sellableItems = {
    {
        item = "joint",
        label = "Offer Joint",
        minPrice = 1,
        maxPrice = 2,
        acceptChance = 0.6,  -- 60% chance to accept
        icon = 'fas fa-cannabis'
    },
    {
        item = "indiancigar",
        label = "Offer indiancigar",
        minPrice = 1,
        maxPrice = 2,
        acceptChance = 0.8,  -- 80% chance to accept
        icon = 'fas fa-smoking'
    },
    {
        item = "moonshine",
        label = "Offer Moonshine",
        minPrice = 2,
        maxPrice = 4,
        acceptChance = 0.7,  -- 70% chance to accept
        icon = 'fas fa-wine-bottle'
    }
}

-- Simplified function to check if entity is a valid human NPC
local function IsValidHumanNPC(entity)
    if not DoesEntityExist(entity) then return false end
    if IsPedAPlayer(entity) then return false end
    if IsEntityDead(entity) then return false end
    return IsPedHuman(entity)
end

local function HandleNPCInteraction(entity, accepted)
    -- Verify entity is still valid before proceeding
    if not IsValidHumanNPC(entity) then return end
    
    -- Clear PED tasks and make them stop
    ClearPedTasks(entity)
    FreezeEntityPosition(entity, true)
    
    -- Face the player
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local npcCoords = GetEntityCoords(entity)
    local direction = GetHeadingFromVector_2d(playerCoords.x - npcCoords.x, playerCoords.y - npcCoords.y)
    SetEntityHeading(entity, direction)
    
    -- Play animation based on whether they accepted or declined
    if accepted then
        -- Thinking/Accepting animation
        local animDict = "script_common@other@unapproved"
        local anim = "loop_0"
        
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(100)
        end
        
        TaskPlayAnim(entity, animDict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        Wait(2000)
    else
        -- Declining/Rejecting animation
        local animDict = "script_common@other@unapproved"
        local anim = "loop_0"
        
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(100)
        end
        
        TaskPlayAnim(entity, animDict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        Wait(2000)
    end
    
    -- Clear animation and unfreeze NPC
    ClearPedTasks(entity)
    FreezeEntityPosition(entity, false)
    -- Let NPC walk away
    TaskWanderStandard(entity, 10.0, 10)
    TriggerServerEvent('rsg-lawman:server:lawmanAlert', "Suspicious activity reported nearby!", GetEntityCoords(PlayerPedId()))
end

-- Create target options for each item
local targetOptions = {}
for _, itemData in ipairs(sellableItems) do
    table.insert(targetOptions, {
        name = 'sell_' .. itemData.item,
        label = itemData.label,
        icon = itemData.icon,
        canInteract = function(entity)
            -- Add check for valid human NPC
            if not IsValidHumanNPC(entity) then return false end
            local hasItem = RSGCore.Functions.HasItem(itemData.item)
            return hasItem
        end,
        onSelect = function(data)
            -- Double-check entity is still valid
            if not IsValidHumanNPC(data.entity) then 
                lib.notify({
                    title = 'Invalid Target',
                    description = 'You can only sell to people!',
                    type = 'error',
                    duration = 3000
                })
                return 
            end
            
            local accepted = math.random() < itemData.acceptChance
            
            -- Start interaction with NPC
            CreateThread(function()
                HandleNPCInteraction(data.entity, accepted)
            end)
            
            -- Handle the sale
            if accepted then
                Wait(2000) -- Wait for animation before showing success notification
                TriggerServerEvent('PhilSellToNPC:SellItem', itemData.item)
            else
                Wait(2000) -- Wait for animation before showing rejection notification
                lib.notify({
                    title = 'Not Interested',
                    description = 'The person declined your offer',
                    type = 'error',
                    duration = 3000
                })
            end
        end
    })
end

CreateThread(function()
    exports.ox_target:addGlobalPed(targetOptions, {
        distance = 2.5
    })
end)

