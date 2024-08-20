local isPointing = false

Citizen.CreateThread(function()
    for i, v in pairs(NT.animations) do
        if v.commandenable then
            RegisterCommand(v.command, function()
                local playerPed = PlayerPedId()

                if v.name == "pointing" then
                    if not isPointing then
                        startPointing()
                    else
                        stopPointing()
                    end
                else
                    if not IsEntityPlayingAnim(playerPed, v.lib, v.anim, 3) then
                        if v.haveLib then
                            RequestAnimDict(v.lib)
                            while not HasAnimDictLoaded(v.lib) do
                                Citizen.Wait(0)
                            end

                            TaskPlayAnim(playerPed, v.lib, v.anim, 8.0, 8.0, -1, v.loop and 49 or 0, 0, false, false, false)
                        end

                        if v.name == "handsup" then
                            TaskPlayAnim(playerPed, v.lib, v.anim, 8.0, 8.0, -1, 50, 0, false, false, false)
                        elseif v.name == "ragdoll" then
                            if not IsPedRagdoll(playerPed) then
                                SetPedToRagdoll(playerPed, -1, -1, 0, 0, 0, 0)
                            else
                                ClearPedTasksImmediately(playerPed)
                            end
                        end
                    else
                        ClearPedTasks(playerPed)
                    end
                end
            end, false)
        end

        RegisterKeyMapping(v.command, v.name, 'keyboard', v.key)
    end
end)

function startPointing()
    local playerPed = PlayerPedId()
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Citizen.Wait(0)
    end

    SetPedCurrentWeaponVisible(playerPed, false, true, true, true)
    SetPedConfigFlag(playerPed, 36, true)
    TaskMoveNetworkByName(playerPed, "task_mp_pointing", 0.5, false, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")

    isPointing = true

    Citizen.CreateThread(function()
        while isPointing do
            Citizen.Wait(0)

            if not IsTaskMoveNetworkActive(playerPed) then
                stopPointing()
                break
            end

            local camPitch = GetGameplayCamRelativePitch()
            local camHeading = GetGameplayCamRelativeHeading()

            camPitch = math.clamp(camPitch, -70.0, 42.0)
            camPitch = (camPitch + 70.0) / 112.0

            camHeading = math.clamp(camHeading, -180.0, 180.0)
            camHeading = (camHeading + 180.0) / 360.0
            camHeading = 1.0 - camHeading

            SetTaskMoveNetworkSignalFloat(playerPed, "Pitch", camPitch)
            SetTaskMoveNetworkSignalFloat(playerPed, "Heading", camHeading)
            SetTaskMoveNetworkSignalBool(playerPed, "isBlocked", false)
            SetTaskMoveNetworkSignalBool(playerPed, "isFirstPerson", GetFollowPedCamViewMode() == 4)
        end
    end)
end

function stopPointing()
    local playerPed = PlayerPedId()
    ClearPedSecondaryTask(playerPed)
    SetPedConfigFlag(playerPed, 36, false)
    SetPedCurrentWeaponVisible(playerPed, true, true, true, true)
    isPointing = false
end

function math.clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end
