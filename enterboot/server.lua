if not Config then
    print("^1[enterboot] FATAL ERROR: config.lua not loaded on server. Check fxmanifest.lua load order.^0")
    return
end


local HiddenPlayers = {}
local LockedBoots = {}


local function getVehicleCapacity(source, vehicleNetId)   
    local vehicleClassId = lib.callback.await('enterboot:getVehicleClass', source, vehicleNetId)
    if not vehicleClassId or vehicleClassId < 0 then
        print('^1[BOOT ERROR] Failed to get vehicle class ID from client or entity was invalid. Defaulting to non-class capacity.^0')
        return -1, Config.VehicleClasses['non-class']
    end

    
    local customClass = Config.GTAClassToCustomMap[vehicleClassId] or 'non-class'
    
    local capacity = Config.VehicleClasses[customClass] or Config.VehicleClasses['non-class']
    return vehicleClassId, capacity 
end


lib.callback.register('enterboot:canEnterBoot', function(source, vehNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    
    if not DoesEntityExist(vehicle) then
        print(string.format('^3[BOOT DEBUG] Player %s: Vehicle (NetID: %s) not found on server.^0', source, vehNetId))
        return false, 'Vehicle not found or out of network range.'
    end
    
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    
    
    if LockedBoots[vehiclePlate] then
        print(string.format('^3[BOOT DEBUG] Player %s: Boot is locked for plate %s.^0', source, vehiclePlate))
        return false, 'The boot is locked.'
    end

   
    local vehicleClassId, maxCapacity = getVehicleCapacity(source, vehNetId) 
    
    if vehicleClassId == -1 then
         return false, 'Could not determine vehicle type.'
    end

    local currentOccupants = 0
    
    if HiddenPlayers[vehiclePlate] then
        currentOccupants = #HiddenPlayers[vehiclePlate]
    end
    
   
    print(string.format(
        '^2[BOOT CHECK OK] Player %s trying to enter vehicle %s. Class ID: %s, Max Cap: %s, Current: %s.^0',
        source, vehiclePlate, vehicleClassId, maxCapacity, currentOccupants
    ))
    
    if currentOccupants < maxCapacity then
        return true
    else
        return false, ('The boot is full (%s/%s).'):format(currentOccupants, maxCapacity)
    end
end)

lib.callback.register('enterboot:getUnlockSpeed', function(source)
    return 15000 
end)

RegisterNetEvent('enterboot:hideInVehicle', function(vehNetId)
    local source = source
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)

    if not HiddenPlayers[vehiclePlate] then
        HiddenPlayers[vehiclePlate] = {}
    end

    
    table.insert(HiddenPlayers[vehiclePlate], source)
    print(string.format('^5[BOOT STATE] Player %s is now hiding in %s. Total: %s^0', source, vehiclePlate, #HiddenPlayers[vehiclePlate]))
end)

RegisterNetEvent('enterboot:exitTrunk', function()
    local source = source
    local vehiclePlateToRemove = nil
    
    
    for plate, players in pairs(HiddenPlayers) do
        for i, playerId in ipairs(players) do
            if playerId == source then
                table.remove(players, i)
                vehiclePlateToRemove = plate
                break
            end
        end
        if vehiclePlateToRemove then break end
    end

   
    if vehiclePlateToRemove then
        print(string.format('^5[BOOT STATE] Player %s exited %s. Remaining: %s^0', source, vehiclePlateToRemove, #HiddenPlayers[vehiclePlateToRemove] or 0))
        if #HiddenPlayers[vehiclePlateToRemove] == 0 then
            HiddenPlayers[vehiclePlateToRemove] = nil
        end
    end
end)


AddEventHandler('playerDropped', function()
    local droppedPlayer = source
    local vehiclePlateToRemove = nil
    
    for plate, players in pairs(HiddenPlayers) do
        for i, playerId in ipairs(players) do
            if playerId == droppedPlayer then
                table.remove(players, i)
                vehiclePlateToRemove = plate
                break
            end
        end
        if vehiclePlateToRemove then break end
    end

    if vehiclePlateToRemove and #HiddenPlayers[vehiclePlateToRemove] == 0 then
        HiddenPlayers[vehiclePlateToRemove] = nil
    end
end)



RegisterNetEvent('enterboot:setBootLockState', function(vehNetId, lock)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    
    if lock then
        LockedBoots[vehiclePlate] = true
        TriggerClientEvent('lib:notify', source, { title = 'Boot Locked', description = 'The vehicle boot is now locked.', type = 'success' })
        print(string.format('^4[BOOT LOCK] Boot locked for %s^0', vehiclePlate))
    else
        LockedBoots[vehiclePlate] = nil
        TriggerClientEvent('lib:notify', source, { title = 'Boot Unlocked', description = 'The vehicle boot is now unlocked.', type = 'success' })
        print(string.format('^4[BOOT UNLOCK] Boot unlocked for %s^0', vehiclePlate))
    end
    
    TriggerClientEvent('enterboot:physicalDoorToggle', -1, vehNetId, lock)
end)

RegisterNetEvent('enterboot:forceUnlock', function(vehNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    LockedBoots[vehiclePlate] = nil
    TriggerClientEvent('enterboot:physicalDoorToggle', -1, vehNetId, false)
    print(string.format('^4[BOOT UNLOCK] Boot emergency unlocked for %s^0', vehiclePlate))
end)



RegisterNetEvent('enterboot:searchVehicle', function(vehNetId)
    local source = source
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    
    local found = false
    if HiddenPlayers[vehiclePlate] and #HiddenPlayers[vehiclePlate] > 0 then
        found = true
    end
    
    TriggerClientEvent('enterboot:searchResult', source, found, vehNetId)
end)

RegisterNetEvent('enterboot:pullOutPlayer', function(vehNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    
    if HiddenPlayers[vehiclePlate] and #HiddenPlayers[vehiclePlate] > 0 then
        
        local targetPlayer = HiddenPlayers[vehiclePlate][1]
        
        
        table.remove(HiddenPlayers[vehiclePlate], 1)
        if #HiddenPlayers[vehiclePlate] == 0 then
            HiddenPlayers[vehiclePlate] = nil
        end
        
        
        TriggerClientEvent('enterboot:forceExit', targetPlayer)
        TriggerClientEvent('lib:notify', source, { title = 'Success', description = 'Player pulled out of the boot.', type = 'success' })
    else
        TriggerClientEvent('lib:notify', source, { title = 'Error', description = 'No one was found in the boot.', type = 'error' })
    end
end)