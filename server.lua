ESX = exports["es_extended"]:getSharedObject()

local callbackRequests = {}
local callbackCounter = 0

RegisterServerEvent("vehicleRental:rent")
AddEventHandler("vehicleRental:rent", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local vehicleModel = data.vehicle
    local playerCoords = vector3(data.coords.x, data.coords.y, data.coords.z)
    local price = nil

    for _, v in pairs(Config.Vehicles) do
        if v.model == vehicleModel then
            price = v.price
            break
        end
    end

    if not price then
        TriggerClientEvent('esx:showNotification', src, 'Invalid Vehicle!')
        return
    end

    if xPlayer.getMoney() < price then
        TriggerClientEvent('esx:showNotification', src, 'Not enough money!')
        return
    end

    local closest = nil
    local minDist = 9999.0
    for _, loc in pairs(Config.RentalLocations) do
        local dist = #(playerCoords - loc.coords)
        if dist < minDist then
            minDist = dist
            closest = loc
        end
    end

    if not closest then
        TriggerClientEvent('esx:showNotification', src, 'Spawn point not found!')
        return
    end

    callbackCounter = callbackCounter + 1
    local requestId = callbackCounter

    callbackRequests[requestId] = function(isFree)
        if isFree then
            xPlayer.removeMoney(price)
            TriggerClientEvent("vehicleRental:spawnVehicle", src, vehicleModel, closest.spawnCoords, closest.spawnHeading)
        else
            TriggerClientEvent('esx:showNotification', src, 'Spawn location is occupied, please try again later!')
        end
    end

    TriggerClientEvent('vehicleRental:checkSpawn', src, requestId, closest.spawnCoords)
end)

RegisterServerEvent('vehicleRental:checkSpawnResponse')
AddEventHandler('vehicleRental:checkSpawnResponse', function(requestId, isFree)
    if callbackRequests[requestId] then
        callbackRequests[requestId](isFree)
        callbackRequests[requestId] = nil
    end
end)
