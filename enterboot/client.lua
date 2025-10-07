local sittingInBoot, currentVehicle, showingPrompt, nearbyBoot = false, nil, false, nil

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

local function getVehicleInFront(ped)
    local pos = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local rayEnd = pos + (fwd * 3.0)
    local ray = StartShapeTestRay(pos.x, pos.y, pos.z, rayEnd.x, rayEnd.y, rayEnd.z, 10, ped, 0)
    local _, _, _, _, veh = GetShapeTestResult(ray)
    return veh
end

local function EnterBoot()
    local ped = PlayerPedId()
    local veh = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    if not veh or veh == 0 then
        lib.notify({ title = 'No nearby vehicle.', type = 'error' })
        return
    end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if not NetworkGetEntityIsNetworked(veh) then
        NetworkRegisterEntityAsNetworked(veh)
    end
    lib.callback('enterboot:canEnterBoot', false, function(canEnter)
        if not canEnter then
            lib.notify({ title = 'The boot is full (max 2).', type = 'error' })
            return
        end
        SetVehicleDoorOpen(veh, 5, false, false)
        Wait(400)
        SetEntityVisible(ped, false, false)
        FreezeEntityPosition(ped, true)
        ClearPedTasksImmediately(ped)
        local offset = vector3(0.0, -1.2, 0.25)
        AttachEntityToEntity(ped, veh, 0, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        TaskLookAtEntity(ped, veh, -1, 2048, 3)
        sittingInBoot, currentVehicle = true, veh
        SetVehicleDoorShut(veh, 5, false)
        TriggerServerEvent('enterboot:hideInVehicle', netId)
        lib.notify({ title = 'You climbed into the boot.', type = 'success' })
    end, netId)
end

local function ExitBoot(force)
    local ped = PlayerPedId()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        sittingInBoot, currentVehicle = false, nil
        return
    end
    DetachEntity(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    ClearPedTasksImmediately(ped)
    local exitPos = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.6, -3.2, 0.0)
    SetVehicleDoorOpen(currentVehicle, 5, false, false)
    Wait(400)
    SetEntityCoords(ped, exitPos.x, exitPos.y, exitPos.z)
    SetVehicleDoorShut(currentVehicle, 5, false)
    TriggerServerEvent('enterboot:exitTrunk')
    sittingInBoot, currentVehicle = false, nil
    if force then
        loadAnimDict("random@arrests@busted")
        TaskPlayAnim(ped, "random@arrests@busted", "idle_c", 8.0, -8.0, 2500, 0, 0, false, false, false)
    end
end

RegisterCommand('enterboot', function()
    if sittingInBoot then ExitBoot() else EnterBoot() end
end, false)
RegisterKeyMapping('enterboot', 'Enter or Exit Vehicle Boot', 'keyboard', 'F6')

RegisterCommand('searchvboot', function()
    local ped = PlayerPedId()
    local veh = getVehicleInFront(ped)
    if veh == 0 or not DoesEntityExist(veh) then
        if lib and lib.notify then
            lib.notify({ title = 'No vehicle found', type = 'error' })
        else
            TriggerEvent('chat:addMessage', { args = { '^1No vehicle found.' } })
        end
        return
    end
    local animDict = "amb@prop_human_bum_bin@base"
    loadAnimDict(animDict)
    TaskPlayAnim(ped, animDict, "base", 1.0, -1.0, -1, 49, 0, false, false, false)
    PlaySoundFrontend(-1, "CLOTHES_MOVE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    local searchingComplete = false
    if lib and lib.progressCircle then
        searchingComplete = lib.progressCircle({
            duration = 4000,
            label = 'Searching boot...',
            position = 'bottom',
            disable = { move = true, car = true, combat = true },
        })
    else
        TriggerEvent('chat:addMessage', { args = { '^3Searching boot...' } })
        Wait(4000)
        searchingComplete = true
    end
    ClearPedTasks(ped)
    RemoveAnimDict(animDict)
    if not searchingComplete then
        if lib and lib.notify then
            lib.notify({ title = 'Search cancelled', type = 'inform' })
        else
            TriggerEvent('chat:addMessage', { args = { '^3Search cancelled.' } })
        end
        return
    end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if netId and netId > 0 then
        TriggerServerEvent('enterboot:searchVehicle', netId)
    else
        if lib and lib.notify then
            lib.notify({ title = 'Unable to identify vehicle.', type = 'error' })
        else
            TriggerEvent('chat:addMessage', { args = { '^1Could not identify vehicle.' } })
        end
    end
end, false)

RegisterNetEvent('enterboot:searchResult', function(found, vehNetId)
    local veh = NetToVeh(vehNetId)
    if found and DoesEntityExist(veh) then
        lib.notify({ title = 'You found someone hiding in the boot!', type = 'success' })
        nearbyBoot, showingPrompt = veh, true
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    else
        lib.notify({ title = 'The boot is empty.', type = 'inform' })
    end
end)

local function DrawText3D(x, y, z, text)
    local onScreen,_x,_y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end

CreateThread(function()
    while true do
        Wait(0)
        if showingPrompt and nearbyBoot and DoesEntityExist(nearbyBoot) then
            local coords = GetOffsetFromEntityInWorldCoords(nearbyBoot, 0.0, -2.0, 0.5)
            DrawText3D(coords.x, coords.y, coords.z, "~y~[Y]~w~ Pull player out of boot")
            if IsControlJustPressed(0, 246) then
                showingPrompt = false
                TriggerServerEvent('enterboot:pullOutPlayer', NetworkGetNetworkIdFromEntity(nearbyBoot))
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            end
        end
    end
end)

RegisterNetEvent('enterboot:forceExit', function()
    if sittingInBoot then ExitBoot(true) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if sittingInBoot then
            DisableControlAction(0, 23, true)
            if IsControlJustPressed(0, 22) then ExitBoot(false) end
        end
    end
end)

