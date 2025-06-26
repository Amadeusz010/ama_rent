ESX = exports["es_extended"]:getSharedObject()
local isUIOpen = false
local rentedVehicle = nil
local timerActive = false

CreateThread(function()
    for _, loc in pairs(Config.RentalLocations) do
        RequestModel(loc.npcModel)
        while not HasModelLoaded(loc.npcModel) do Wait(0) end

        local ped = CreatePed(0, loc.npcModel, loc.coords.x, loc.coords.y, loc.coords.z - 1.0, loc.heading, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)

exports.ox_target:addLocalEntity(ped, {
    {
        label = 'Vehicle rental',
        icon = 'fa-solid fa-car',
        distance = 2.5,  
        onSelect = function()
            SetNuiFocus(true, true)
            SendNUIMessage({ action = 'open', vehicles = Config.Vehicles })
            isUIOpen = true
        end
    }
})

        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, loc.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, loc.blip.scale)
        SetBlipColour(blip, loc.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(loc.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb({})
end)

RegisterNUICallback("rentVehicle", function(data, cb)
    print("[DEBUG] rentVehicle triggered with model: " .. tostring(data.vehicle))
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    TriggerServerEvent("vehicleRental:rent", { vehicle = data.vehicle, coords = { x = coords.x, y = coords.y, z = coords.z } })
    SetNuiFocus(false, false)
    isUIOpen = false
    cb({})
end)

RegisterNetEvent("vehicleRental:spawnVehicle")
AddEventHandler("vehicleRental:spawnVehicle", function(model, coords, heading)
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(0) end

    ESX.Game.SpawnVehicle(model, coords, heading, function(vehicle)
        local playerPed = PlayerPedId()
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        rentedVehicle = vehicle
        Wait(500)

        DoScreenFadeIn(800)

 
        monitorVehicleExit()
    end)
end)

RegisterNetEvent('vehicleRental:checkSpawn')
AddEventHandler('vehicleRental:checkSpawn', function(requestId, spawnCoords)
    local isFree = true
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(veh)
        if #(vehCoords - spawnCoords) < 5.0 then
            isFree = false
            break
        end
    end
    TriggerServerEvent('vehicleRental:checkSpawnResponse', requestId, isFree)
end)

function monitorVehicleExit()
    timerActive = false

    CreateThread(function()
        while rentedVehicle and DoesEntityExist(rentedVehicle) do
            local playerPed = PlayerPedId()
            local isInVeh = IsPedInVehicle(playerPed, rentedVehicle, false)

            if not isInVeh then
                if not timerActive then
                    timerActive = true
                    TriggerEvent('chat:addMessage', { args = { '^Info!', 'Re-enter within 2 minutes or the vehicle will be deleted.' } })

                    local timePassed = 0
                    while timePassed < 120000 and timerActive do
                        Wait(1000)
                        if IsPedInVehicle(PlayerPedId(), rentedVehicle, false) then
                            timerActive = false
                            TriggerEvent('chat:addMessage', { args = { '^2Vehicle rental', 'You re-entered the vehicle, deletion cancelled.' } })
                            break
                        end
                        timePassed = timePassed + 1000
                    end

                    if timerActive then
                        if rentedVehicle and DoesEntityExist(rentedVehicle) then
                            DeleteVehicle(rentedVehicle)
                            TriggerEvent('chat:addMessage', { args = { '^1Vehicle rental', 'Time expired – vehicle deleted.' } })
                            rentedVehicle = nil
                        end
                        timerActive = false
                    end
                end
            else
                timerActive = false
            end

            Wait(1000)
        end
    end)
end
