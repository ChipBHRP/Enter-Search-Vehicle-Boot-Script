local sittingInBoot, currentVehicle, showingPrompt, nearbyBoot = false, nil, false, nil
local nearbyVehicle = nil
local bootCam, camActive, camYaw, camPitch = nil, false, 0.0, 10.0
local camDist, camHeight = 2.5, 0.8
local camTargetOffset = vector3(0.0, -1.2, 0.5) 
local maxDistance = 2.0

if not Config then
    print("^1[enterboot] ERROR: config.lua not loaded. Please check your fxmanifest.lua file load order.^0")
    return
end

lib.callback.register('enterboot:getVehicleClass', function(vehNetId)
    local vehicle = NetToVeh(vehNetId)
    if DoesEntityExist(vehicle) and vehicle ~= 0 then
        return GetVehicleClass(vehicle)
    end
    return nil
end)

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

local function GetEnterBootKeybind()
    local keybindString = GetControlInstructionalButton(2, `enterboot` | 0x80000000, true)
    if keybindString and string.match(keybindString, '^t_') then
        local key = string.sub(keybindString, 3)
        return string.format("~%s~", string.upper(key))
    end
    return keybindString or ""
end


local function startBootCam(vehicle)
    if camActive or not DoesEntityExist(vehicle) then return end

    camActive = true
    bootCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    camYaw = GetEntityHeading(vehicle)
    camPitch = 10.0

    SetCamActive(bootCam, true)
    RenderScriptCams(true, false, 0, true, true)

    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)
    Citizen.InvokeNative(0x026FB97D0A425F84, true)  
    Citizen.InvokeNative(0xE72CDBA7F0A02DD6, bootCam, true)
    Citizen.InvokeNative(0xA200EB1EE790F448, true)  
    
    EnableControlAction(0, 1, true)   
    EnableControlAction(0, 2, true)   
    EnableControlAction(0, 22, true)  
end

local function stopBootCam()
    if not camActive then return end

    if DoesCamExist(bootCam) then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(bootCam, false)
    end

    Citizen.InvokeNative(0x026FB97D0A425F84, false)
    Citizen.InvokeNative(0xA200EB1EE790F448, false)
    Citizen.InvokeNative(0xE72CDBA7F0A02DD6, 0, false)

    EnableAllControlActions(0)

    bootCam = nil
    camActive = false
end

local function updateBootCam()
    if not camActive or not DoesCamExist(bootCam) or not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    local dt = GetFrameTime()
    local lookX = GetDisabledControlNormal(0, 1) 
    local lookY = GetDisabledControlNormal(0, 2) 
    local sens = 450.0

    camYaw = camYaw + lookX * sens * dt
    camPitch = camPitch + lookY * sens * dt

    if camPitch > 85.0 then camPitch = 85.0 end
    if camPitch < -85.0 then camPitch = -85.0 end

    local targetCoords = GetOffsetFromEntityInWorldCoords(currentVehicle, camTargetOffset.x, camTargetOffset.y, camTargetOffset.z)

    local radPitch = math.rad(camPitch)
    local radYaw = math.rad(camYaw)
    local distH = camDist * math.cos(radPitch)
    local distZ = camDist * math.sin(radPitch)

    local cx = targetCoords.x + distH * math.sin(radYaw)
    local cy = targetCoords.y + distH * math.cos(radYaw)
    local cz = targetCoords.z + distZ

    SetCamCoord(bootCam, cx, cy, cz)
    PointCamAtCoord(bootCam, targetCoords.x, targetCoords.y, targetCoords.z)
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

    lib.callback('enterboot:canEnterBoot', false, function(canEnter, reason)
        if not canEnter then
            lib.notify({ title = 'Cannot Enter Boot', description = reason or 'Boot is full or locked.', type = 'error' })
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
        startBootCam(veh)
        lib.notify({ title = 'You climbed into the boot.', type = 'success' })
    end, netId)
end

local function ExitBoot(force)
    local ped = PlayerPedId()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        sittingInBoot, currentVehicle = false, nil
        stopBootCam()
        return
    end

    DetachEntity(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    ClearPedTasksImmediately(ped)

    local exitPos = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.6, -3.2, 0.0)
    SetVehicleDoorOpen(currentVehicle, 5, false, false)
    Wait(400)
    SetEntityCoords(ped, exitPos.x, exitPos.y, exitPos.z)
    SetVehicleDoorShut(currentVehicle, 5, false)

    TriggerServerEvent('enterboot:exitTrunk')
    stopBootCam()
    sittingInBoot, currentVehicle = false, nil

    if force then
        loadAnimDict("random@arrests@busted")
        TaskPlayAnim(ped, "random@arrests@busted", "idle_c", 8.0, -8.0, 2500, 0, 0, false, false, false)
    end
end

local function handleBootLock(lock)
    local ped = PlayerPedId()
    local veh = getVehicleInFront(ped)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        lib.notify({ title = 'No vehicle found in front of you.', type = 'error' })
        return
    end
    local vehNetId = NetworkGetNetworkIdFromEntity(veh)
    if vehNetId == 0 then
        lib.notify({ title = 'Could not get Network ID for vehicle.', type = 'error' })
        return
    end
    TriggerServerEvent('enterboot:setBootLockState', vehNetId, lock)
end

local function handleEmergencyUnlock()
    local ped = PlayerPedId()
    local veh = getVehicleInFront(ped)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        lib.notify({ title = 'No vehicle found in front of you.', type = 'error' })
        return
    end
    local vehNetId = NetworkGetNetworkIdFromEntity(veh)
    local unlockDuration = lib.callback.await('enterboot:getUnlockSpeed', 0)
    if unlockDuration and unlockDuration > 0 then
        local durationSeconds = math.ceil(unlockDuration / 1000)
        lib.notify({
            title = 'Emergency Services Opening Boot',
            description = ('Unlock will take %s seconds.'):format(durationSeconds),
            type = 'warning',
            duration = 5000
        })
        local animDict = "random@mugging3"
        loadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, "c_gas_fal", 1.0, -1.0, -1, 49, 0, false, false, false)
        PlaySoundFrontend(-1, "CLOTHES_MOVE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        local actionLabel = 'Force unlocking boot...'
        if unlockDuration < 10000 then actionLabel = 'Rapidly unlocking boot...' end
        local unlockComplete = lib.progressCircle({
            duration = unlockDuration,
            label = actionLabel,
            position = 'bottom',
            disable = { move = true, car = true, combat = true },
        })
        ClearPedTasks(ped)
        RemoveAnimDict(animDict)
        if not unlockComplete then
            lib.notify({ title = 'Unlock cancelled', type = 'inform' })
            return
        end
        TriggerServerEvent('enterboot:forceUnlock', vehNetId)
        lib.notify({ title = 'Boot successfully forced open.', type = 'success' })
    end
end


RegisterNetEvent('lib:notify', function(data)
    if lib and lib.notify then
        lib.notify(data)
    else

        TriggerEvent('chat:addMessage', {
            args = { '[NOTIFICATION FAILED]', data.title .. (data.description and ': ' .. data.description or '') },
            color = { 255, 0, 0 }
        })
    end
end)

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

RegisterNetEvent('enterboot:physicalDoorToggle', function(vehNetId, shouldLock)
    local veh = NetToVeh(vehNetId)
    if DoesEntityExist(veh) then
        if shouldLock then
            SetVehicleDoorLock(veh, 2)
            SetVehicleDoorShut(veh, 5, false)
        else
            SetVehicleDoorLock(veh, 0)
            SetVehicleDoorOpen(veh, 5, false, false)
            Wait(1000)
            SetVehicleDoorShut(veh, 5, false)
        end
    end
end)

RegisterNetEvent('enterboot:forceExit', function()
    if sittingInBoot then ExitBoot(true) end
end)

CreateThread(function()
    while true do
        local waitTime = 500
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)

        if showingPrompt and nearbyBoot and DoesEntityExist(nearbyBoot) then
            local coords = GetOffsetFromEntityInWorldCoords(nearbyBoot, 0.0, -2.0, 0.5)
            DrawText3D(coords.x, coords.y, coords.z, "~y~[Y]~w~ Pull player out of boot")
            if IsControlJustPressed(0, 246) then 
                showingPrompt = false
                TriggerServerEvent('enterboot:pullOutPlayer', NetworkGetNetworkIdFromEntity(nearbyBoot))
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            end
            waitTime = 0

        elseif not sittingInBoot then
            local veh = GetClosestVehicle(playerCoords, maxDistance * 2, 0, 70)
            if veh and DoesEntityExist(veh) then
                local vehicleClass = GetVehicleClass(veh)
                if not Config.ExcludedVehicleTypes[vehicleClass] then
                    local bootCoords = GetOffsetFromEntityInWorldCoords(veh, 0.0, -3.0, 0.5)
                    if GetDistanceBetweenCoords(playerCoords, bootCoords, true) < maxDistance then
                        local keybindString = GetEnterBootKeybind()
                        DrawText3D(bootCoords.x, bootCoords.y, bootCoords.z + 0.2, keybindString .. " Enter Boot")
                        waitTime = 0
                    end
                end
            end
        end

        if camActive then
            DisableControlAction(0, 21, true) 
            DisableControlAction(0, 30, true) 
            DisableControlAction(0, 31, true) 
            DisableControlAction(0, 24, true) 
            DisableControlAction(0, 257, true) 
            DisableControlAction(0, 263, true) 
            DisableControlAction(0, 264, true) 
            
            updateBootCam()
            waitTime = 0 
        end

        Wait(waitTime)
    end
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


CreateThread(function()
    Wait(500)

    RegisterCommand('enterboot', function()
        if sittingInBoot then ExitBoot() else EnterBoot() end
    end, false)
    RegisterKeyMapping('enterboot', 'Enter or Exit Vehicle Boot', 'keyboard', 'F6')

    RegisterCommand('lockboot', function() handleBootLock(true) end, false)
    RegisterCommand('unlockboot', function() handleBootLock(false) end, false)
    RegisterKeyMapping('lockboot', 'Lock Vehicle Boot', 'keyboard', 'F7')
    RegisterKeyMapping('unlockboot', 'Unlock Vehicle Boot', 'keyboard', 'F8')

    RegisterCommand('emgunlockboot', handleEmergencyUnlock, false)
    RegisterCommand('searchvboot', function()
        local ped = PlayerPedId()
        local veh = getVehicleInFront(ped)
        if veh == 0 or not DoesEntityExist(veh) then
            lib.notify({ title = 'No vehicle found', type = 'error' })
            return
        end

        local animDict = "amb@prop_human_bum_bin@base"
        loadAnimDict(animDict)
        TaskPlayAnim(ped, animDict, "base", 1.0, -1.0, -1, 49, 0, false, false, false)
        PlaySoundFrontend(-1, "CLOTHES_MOVE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        SetVehicleDoorOpen(veh, 5, false, false)

        local searchingComplete = lib.progressCircle({
            duration = 4000,
            label = 'Searching boot...',
            position = 'bottom',
            disable = { move = true, car = true, combat = true },
        })
        ClearPedTasks(ped)
        RemoveAnimDict(animDict)
        SetVehicleDoorShut(veh, 5, false)

        if not searchingComplete then
            lib.notify({ title = 'Search cancelled', type = 'inform' })
            return
        end

        local netId = NetworkGetNetworkIdFromEntity(veh)
        if netId and netId > 0 then
            TriggerServerEvent('enterboot:searchVehicle', netId)
        else
            lib.notify({ title = 'Unable to identify vehicle.', type = 'error' })
        end
    end, false)
end)