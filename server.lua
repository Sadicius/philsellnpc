local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterServerEvent('PhilSellToNPC:SellItem')
AddEventHandler('PhilSellToNPC:SellItem', function(itemName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then return end

    -- Get item configuration
    for _, itemData in ipairs(Config.sellableItems) do
        local config = itemData.item
        if not config then return end

        local AmountToSell = math.random(1, 3)

        -- Check if player has the item
        local count = Player.Functions.GetItemByName(itemName)

        if not count then
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = 'You don\'t have any ' .. RSGCore.Shared.Items[itemName].label .. ' to sell',
                duration = 3000
            })
            return
        end

        count = count.amount

        if count >= 1 then
            local amountToRemove = math.min(count, AmountToSell)
            local success = Player.Functions.RemoveItem(itemName, amountToRemove)

            if success then
                -- Calculate payment based on item-specific price range
                local pricePerItem = math.random(itemData.minPrice, itemData.maxPrice)
                local payment = pricePerItem * amountToRemove

                Player.Functions.AddMoney('cash', payment)
                TriggerClientEvent('ox_lib:notify', src, {
                    type = 'success',
                    description = 'You sold ' .. amountToRemove .. ' ' .. RSGCore.Shared.Items[itemName].label .. ' for $' .. payment,
                    duration = 3000
                })
                -- Trigger inventory sync
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], "remove", 1)
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = 'You don\'t have enough ' .. RSGCore.Shared.Items[itemName].label,
                duration = 3000
            })
        end
    end
end)