local playersInBoot = {}
local MAX_PEOPLE_IN_BOOT = 2


lib.callback.register('enterboot:canEnterBoot', function(source, vehNetId)
    local count = 0
    for _, v in pairs(playersInBoot) do
        if v == vehNetId then
            count = count + 1
        end
    end
    print(("[enterboot] Boot check: vehicle %s currently has %s occupant(s)"):format(vehNetId, count))
    return count < MAX_PEOPLE_IN_BOOT
end)


RegisterNetEvent('enterboot:hideInVehicle', function(vehNetId)
    local src = source
    vehNetId = tonumber(vehNetId)
    if vehNetId and vehNetId > 0 then
        playersInBoot[src] = vehNetId
        print(("[enterboot] Player %s is now hiding in vehicle NetID %s"):format(src, vehNetId))
    else
        print(("[enterboot] Invalid NetID from player %s"):format(src))
    end
end)


RegisterNetEvent('enterboot:exitTrunk', function()
    local src = source
    playersInBoot[src] = nil
    print(("[enterboot] Player %s exited the boot"):format(src))
end)


RegisterNetEvent('enterboot:searchVehicle', function(vehNetId)
    local src = source
    vehNetId = tonumber(vehNetId)
    print(("[enterboot] Player %s is searching vehicle NetID %s"):format(src, vehNetId))

    local foundPlayer = nil
    for player, vId in pairs(playersInBoot) do
        print(("[enterboot] Checking stored vehicle %s for player %s"):format(vId, player))
        if vId == vehNetId then
            foundPlayer = player
            break
        end
    end

    if foundPlayer then
        print(("[enterboot] Found player %s in that boot."):format(foundPlayer))
        TriggerClientEvent('enterboot:searchResult', src, true, vehNetId)
    else
        print("[enterboot] No one found in that boot.")
        TriggerClientEvent('enterboot:searchResult', src, false, vehNetId)
    end
end)


RegisterNetEvent('enterboot:pullOutPlayer', function(vehNetId)
    local src = source
    vehNetId = tonumber(vehNetId)
    print(("[enterboot] Player %s attempting to pull from vehicle %s"):format(src, vehNetId))

    for player, vId in pairs(playersInBoot) do
        if vId == vehNetId then
            playersInBoot[player] = nil
            TriggerClientEvent('enterboot:forceExit', player)
            TriggerClientEvent('chat:addMessage', src, {
                args = { '^2You pulled the player out of the boot!' }
            })
            print(("[enterboot] Player %s pulled out player %s"):format(src, player))
            return
        end
    end

    TriggerClientEvent('chat:addMessage', src, { args = { '^3No one was in there.' } })
    print(("[enterboot] No one found in vehicle %s for player %s"):format(vehNetId, src))
end)


AddEventHandler('playerDropped', function(src)
    if playersInBoot[src] then
        print(("[enterboot] Cleaning up player %s (disconnected while in boot)"):format(src))
        playersInBoot[src] = nil
    end
end)
