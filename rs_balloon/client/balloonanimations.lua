local pilotActive = true
local currentSequence
local tether = nil
local balloonControl = false

local function isAnimationRunning(ped, sequence)
    return IsEntityPlayingAnim(ped, sequence.lib, sequence.clip, sequence.flags)
end

local function triggerAnimation(ped, sequence)
    if not DoesAnimDictExist(sequence.lib) then
        return
    end

    RequestAnimDict(sequence.lib)

    while not HasAnimDictLoaded(sequence.lib) do
        Citizen.Wait(0)
    end

    TaskPlayAnim(ped, sequence.lib, sequence.clip, 1.0, 1.0, -1, 29, 0.0, false, 0, false, "", false)

    RemoveAnimDict(sequence.lib)
end

local function haltAnimation(ped, sequence)
    StopAnimTask(ped, sequence.lib, sequence.clip, 1.0)
end

Citizen.CreateThread(function()
    while true do
        local waitAllowed = true

        if pilotActive then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped)
            local modelId = GetEntityModel(vehicle)

            if modelId == 1588640480 then
                local animName

                if IsControlPressed(0, 0x7232BAB3) then
                    animName = "base_burner_pull_arthur"
                else
                    animName = "idle_burner_line_arthur"
                end

                currentSequence = {
                    lib = "script_story@gng2@ig@ig_2_balloon_control",
                    clip = animName,
                    flags = 17
                }

                if currentSequence and not isAnimationRunning(ped, currentSequence) then
                    triggerAnimation(ped, currentSequence)
                end

                waitAllowed = false
            elseif currentSequence then
                haltAnimation(ped, currentSequence)
                currentSequence = nil
            end
        end

        Citizen.Wait(waitAllowed and 1000 or 100)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        local ped = PlayerPedId()
        local balloon = GetVehiclePedIsIn(ped, false)

        if balloon ~= 0 and GetEntityModel(balloon) == GetHashKey("hotairballoon01") then
            if not balloonControl then
                local pos = GetEntityCoords(ped)
                local length = 0.7

                if not tether then
                    tether = AddRope(
                        pos.x, pos.y, pos.z,
                        0.0, 0.0, 0.0,
                        length,
                        7,
                        length, length, length,
                        true,
                        false, false,
                        1.0, false, 0
                    )
                end

                local boneIndex = GetEntityBoneIndexByName(balloon, "engine")

                if boneIndex ~= -1 then
                    AttachEntitiesToRope(
                        tether,
                        ped,
                        balloon,
                        0.0, 0.05, 0.05,
                        0.0, 0.0, 0.0,
                        length,
                        0, 0,
                        "PH_L_HAND", "engine",
                        0, -1, -1,
                        0, 0, 1, 1
                    )

                    balloonControl = true
                end
            end
        else
            if balloonControl then
                if tether then
                    DeleteRope(tether)
                    tether = nil
                end
                balloonControl = false
            end
        end
    end
end)
