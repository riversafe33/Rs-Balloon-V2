local Core = exports.vorp_core:GetCore()
local T = Translation.Langs[Config.Lang]
local NPCss = {}
local balloon
local lockZ = false
local useCameraRelativeControls = true
local spawn_balloon = nil
local current_balloon_id = nil

local balloonPrompts = UipromptGroup:new(T.Prompts.Ballon)
local nsPrompt = Uiprompt:new({`INPUT_VEH_MOVE_UP_ONLY`, `INPUT_VEH_MOVE_DOWN_ONLY` }, T.Prompts.NorthSouth, balloonPrompts)
local wePrompt = Uiprompt:new({`INPUT_VEH_MOVE_LEFT_ONLY`, `INPUT_VEH_MOVE_RIGHT_ONLY`}, T.Prompts.WestEast, balloonPrompts)
local brakePrompt = Uiprompt:new(`INPUT_CONTEXT_X`, T.Prompts.DownBalloon, balloonPrompts)
local lockZPrompt = Uiprompt:new(`INPUT_CONTEXT_A`, T.Prompts.LockInAltitude, balloonPrompts)
local throttlePrompt = Uiprompt:new(`INPUT_VEH_FLY_THROTTLE_UP`, T.Prompts.UpBalloon, balloonPrompts)
local deleteBalloonPrompt = Uiprompt:new(`INPUT_VEH_HORN`, T.Prompts.RemoveBalloon, balloonPrompts)

Citizen.CreateThread(function()
    while true do
        if balloon and deleteBalloonPrompt then
            local isRental = (balloon == spawn_balloon)
            deleteBalloonPrompt:setEnabledAndVisible(not isRental)
        end
        Citizen.Wait(100)
    end
end)

Citizen.CreateThread(function()
    while true do
        if balloon == spawn_balloon then
            DisableControlAction(0, `INPUT_VEH_HORN`, true)
        end
        Citizen.Wait(0)
    end
end)

local function GetCameraRelativeVectors()
    local camRot = GetGameplayCamRot(2)
    local camHeading = math.rad(camRot.z)
    local forwardVector = vector3(-math.sin(camHeading), math.cos(camHeading), 0.0)
    local rightVector = vector3(math.cos(camHeading), math.sin(camHeading), 0.0)
    return forwardVector, rightVector
end

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local vehiclePedIsIn = GetVehiclePedIsIn(playerPed, false)

        if vehiclePedIsIn ~= 0 and GetEntityModel(vehiclePedIsIn) == `hotairballoon01` then
            if not balloon then
                balloon = vehiclePedIsIn
            end
        else
            if balloon then
                balloon = nil
            end
        end

        Citizen.Wait(500)
    end
end)

Citizen.CreateThread(function()
    local bv
    while true do
        if balloon then
            balloonPrompts:handleEvents()

            local speed = IsControlPressed(0, `INPUT_VEH_TRAVERSAL`) and 0.15 or 0.05
            local v1 = GetEntityVelocity(balloon)
            local v2 = v1

            if useCameraRelativeControls then
                local forwardVec, rightVec = GetCameraRelativeVectors()
                if IsControlPressed(0, `INPUT_VEH_MOVE_UP_ONLY`) then
                    v2 = v2 + forwardVec * speed
                end
                if IsControlPressed(0, `INPUT_VEH_MOVE_DOWN_ONLY`) then
                    v2 = v2 - forwardVec * speed
                end
                if IsControlPressed(0, `INPUT_VEH_MOVE_LEFT_ONLY`) then
                    v2 = v2 - rightVec * speed
                end
                if IsControlPressed(0, `INPUT_VEH_MOVE_RIGHT_ONLY`) then
                    v2 = v2 + rightVec * speed
                end
            else
                if IsControlPressed(0, `INPUT_VEH_MOVE_UP_ONLY`) then
                    v2 = v2 + vector3(0, speed, 0)
                end
                if IsControlPressed(0, `INPUT_VEH_MOVE_DOWN_ONLY`) then
                    v2 = v2 - vector3(0, speed, 0)
                end
                if IsControlPressed(0, `INPUT_VEH_MOVE_LEFT_ONLY`) then
                    v2 = v2 - vector3(speed, 0, 0)
                end
                if IsControlPressed(0, `INPUT_VEH_MOVE_RIGHT_ONLY`) then
                    v2 = v2 + vector3(speed, 0, 0)
                end
            end

            if IsControlPressed(0, `INPUT_CONTEXT_X`) then
                if bv then
                    local x = bv.x > 0 and bv.x - speed or bv.x + speed
                    local y = bv.y > 0 and bv.y - speed or bv.y + speed
                    v2 = vector3(x, y, v2.z)
                end
                bv = v2.xy
            else
                bv = nil
            end

            if IsControlJustPressed(0, `INPUT_CONTEXT_A`) then
                lockZ = not lockZ
                if lockZ then
                    lockZPrompt:setText(T.Prompts.UnlockInAltitude)
                else
                    lockZPrompt:setText(T.Prompts.LockInAltitude)
                end
            end

            if lockZ and not IsControlPressed(0, `INPUT_VEH_FLY_THROTTLE_UP`) then
                SetEntityVelocity(balloon, vector3(v2.x, v2.y, 0.0))
            elseif v2 ~= v1 then
                SetEntityVelocity(balloon, v2)
            end

            if IsControlJustPressed(0, `INPUT_VEH_HORN`) then
                if DoesEntityExist(balloon) then
                    local balloonHeight = GetEntityHeightAboveGround(balloon)
                    if balloonHeight <= 0.5 then
                        DeleteEntity(balloon)
                        balloon = nil
                    end
                end
            end

            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

local BalloonGroup = GetRandomIntInRange(0, 0xffffff)
local OwnedBallons = {}
local near = 1000
local stand = { x = 0, y = 0, z = 0 }
local T = Translation.Langs[Config.Lang]
local _BalloonPrompt

function BalloonPrompt()
    Citizen.CreateThread(function()
        local str = T.Shop
        _BalloonPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(_BalloonPrompt, 0x760A9C6F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(_BalloonPrompt, str)
        PromptSetEnabled(_BalloonPrompt, true)
        PromptSetVisible(_BalloonPrompt, true)
        PromptSetStandardMode(_BalloonPrompt, true)
        PromptSetGroup(_BalloonPrompt, BalloonGroup)
        PromptRegisterEnd(_BalloonPrompt)
        PromptSetPriority(_BalloonPrompt , true)
    end)
end

TriggerEvent("vorp_menu:getData",function(call)
    MenuData = call
end)

local balloons = Config.Globo

Citizen.CreateThread(function()
	BalloonPrompt()

	while true do
		local playerCoords = GetEntityCoords(PlayerPedId())
		local inZone = false

		for i, zone in pairs(Config.Marker) do
			local dist = GetDistanceBetweenCoords(zone.x, zone.y, zone.z, playerCoords, false)
			if dist < 2 then
				inZone = true
				stand = zone
				near = 5

				local BalloonGroupName  = CreateVarString(10, 'LITERAL_STRING', T.Shop7)
				PromptSetActiveGroupThisFrame(BalloonGroup, BalloonGroupName)
				PromptSetEnabled(_BalloonPrompt, true)
				PromptSetVisible(_BalloonPrompt, true)

				if PromptHasStandardModeCompleted(_BalloonPrompt) then
					PromptSetEnabled(_BalloonPrompt, false)
					PromptSetVisible(_BalloonPrompt, false)
					TriggerServerEvent('rs_balloon:checkOwned')
					Citizen.Wait(500)
				end
			end
		end

		if not inZone and stand then
			MenuData.Close('default', GetCurrentResourceName(), 'vorp_menu')
			PromptSetEnabled(_BalloonPrompt, false)
			PromptSetVisible(_BalloonPrompt, false)
			stand = nil
			near = 1000
		end

		Citizen.Wait(near)
	end
end)

local datosVenta = {
    Model = "hotairballoon01"
}

RegisterNetEvent('rs_balloon:openMenu')
AddEventHandler('rs_balloon:openMenu', function(hasBalloon)
    MenuData.CloseAll()

    local elements = {}

    if not hasBalloon then
        table.insert(elements, { label = T.Buyballon, value = 'buy', desc = T.Desc1 })
    else
        table.insert(elements, { label = T.Property, value = 'own', desc = T.Property1 })
        table.insert(elements, { label = T.SellBalloon, value = 'sell', desc = T.Sell })
        table.insert(elements, { label = T.TransferBalloon, value = 'transfer', desc = T.TransferDesc })
    end

    MenuData.Open('default', GetCurrentResourceName(), 'vorp_menu',
    {
        title    = T.Shop1,
        subtext  = T.Shop2,
        align    = 'top-right',
        elements = elements,
    },
    function(data, menu)
        if data.current.value == "buy" then
            OpenBuyBallonsMenu()

        elseif data.current.value == "own" then
            TriggerServerEvent('rs_balloon:loadownedBallons')
            menu.close()

        elseif data.current.value == "sell" then
            TriggerServerEvent('rs_balloon:sellballoon', datosVenta)
            menu.close()

        elseif data.current.value == "transfer" then
            if not hasBalloon then
                Core.NotifyLeft(T.Tittle, T.Youdonthave, "menu_textures", "cross", 4000, "COLOR_RED")
                return
            end

            local myInput = {
                type = "enableinput",
                inputType = "input",
                button = "Confirm",
                placeholder = "PLAYER ID",
                style = "block",
                attributes = {
                    inputHeader = "TRANSFER BALLOON",
                    type = "text",
                    pattern = "[0-9]+",
                    title = "Only numbers allowed",
                    style = "border-radius: 10px; background-color: ; border:none;"
                }
            }

            local result = exports.vorp_inputs:advancedInput(myInput)
            if result and result ~= "" then
                local playerId = tonumber(result)
                if playerId then
                    TriggerServerEvent('rs_balloon:transferBalloon', playerId)
                    menu.close()
                else
                    Core.NotifyLeft(T.Tittle, T.Invalid, "menu_textures", "cross", 4000, "COLOR_RED")
                end
            end
        end
    end,
    function(data, menu)
        menu.close()
    end)
end)

function OpenOwnBallonMenu()
    MenuData.CloseAll()
    local elements = {}

    local playerCoords = GetEntityCoords(PlayerPedId())

    for k, boot in pairs(OwnedBallons) do
        local closestLocation = nil

        for locName, locData in pairs(Config.Marker) do
            if #(playerCoords - vector3(locData.x, locData.y, locData.z)) < 2.0 then
                closestLocation = locName
                break
            end
        end

        elements[#elements + 1] = {
            label = boot['name'],
            value = k,
            desc  = boot['name'],
            info  = closestLocation
        }
    end

    MenuData.Open('default', GetCurrentResourceName(), 'vorp_menu',
    {
        title    = T.Shop3,
        subtext  = T.Shop4,
        align    = 'top-right',
        elements = elements,
    },
    function(data, menu)
        if data.current.value then
            if spawn_ballon and DoesEntityExist(spawn_ballon) then
                menu.close()
                return
            end

            local locationName = data.current.info
            TriggerEvent('rs_balloon:spawnBalloon', locationName)
            menu.close()
        end
    end,
    function(data, menu)
        menu.close()
    end)
end

function OpenBuyBallonsMenu()
    MenuData.CloseAll()
	local elements = {}
	for k, boot in pairs(balloons) do
		elements[#elements + 1] = {
			label = balloons[k]['Text'],
            value = k,
			desc = '<span style=color:MediumSeaGreen;>'..balloons[k]['Param']['Price']..'$</span>',
			info = balloons[k]['Param']
		}
	end
    MenuData.Open('default', GetCurrentResourceName(), 'vorp_menu',
	{
		title    = T.Shop5,
		subtext  = T.Shop6,
		align    = 'top-right',
		elements = elements,
	},
	function(data, menu)
		if data.current.value then
			local balloonbuy = data.current.info
			TriggerServerEvent('rs_balloon:buyballoon', balloonbuy)
			menu.close()
		end
	end,
	function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent("rs_balloon:loadBallonMenu")
AddEventHandler("rs_balloon:loadBallonMenu", function(result)
	OwnedBallons = result
	OpenOwnBallonMenu()
end)

Citizen.CreateThread(function()
    for _,marker in pairs(Config.Marker) do
        local blip = N_0x554d9d53f696d002(1664425300, marker.x, marker.y, marker.z)
        SetBlipSprite(blip, marker.sprite, 1)
        SetBlipScale(blip, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, marker.name)
    end  
end)

Citizen.CreateThread(function()
    for _, coords in pairs(Config.NPC.coords) do
        TriggerEvent("rs_balloon:CreateNPC", coords)
    end
end)

RegisterNetEvent("rs_balloon:CreateNPC")
AddEventHandler("rs_balloon:CreateNPC", function(zone)
    if not zone then return end

    local model = GetHashKey(Config.NPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(500) end

    local npc = CreatePed(model, zone.x, zone.y, zone.z, zone.w, false, true)
    Citizen.InvokeNative(0x283978A15512B2FE , npc, true)
    SetEntityNoCollisionEntity(PlayerPedId(), npc, true)
    SetEntityCanBeDamaged(npc, false)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(model)

    table.insert(NPCss, npc)
end)

RegisterNetEvent('rs_balloon:spawnBalloon1')
AddEventHandler('rs_balloon:spawnBalloon1', function(balloonId, locationIndex)
    if not Config.BalloonLocations[locationIndex] then
        return
    end

    local balloonModel = GetHashKey('hotAirBalloon01')

    RequestModel(balloonModel)
    while not HasModelLoaded(balloonModel) do
        Wait(10)
    end

    if spawn_balloon and DoesEntityExist(spawn_balloon) then
        SetEntityAsMissionEntity(spawn_balloon, true, true)
        DeleteVehicle(spawn_balloon)
        spawn_balloon = nil
        current_balloon_id = nil
    end
   
    local spawnCoords = Config.BalloonLocations[locationIndex].spawn
    spawn_balloon = CreateVehicle(balloonModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    if not DoesEntityExist(spawn_balloon) then return end

    local netId = NetworkGetNetworkIdFromEntity(spawn_balloon)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetEntityAsMissionEntity(spawn_balloon, true, true)
    SetModelAsNoLongerNeeded(balloonModel)

    current_balloon_id = balloonId
end)

RegisterNetEvent("rs_balloon:deleteTemporaryBalloon")
AddEventHandler("rs_balloon:deleteTemporaryBalloon", function()
    if spawn_balloon ~= nil and DoesEntityExist(spawn_balloon) then
        SetEntityAsMissionEntity(spawn_balloon, true, true)
        DeleteVehicle(spawn_balloon)
        spawn_balloon = nil
        TriggerServerEvent("rs_balloon:removeBalloonFromSQL")
    end
end)

RegisterNetEvent("rs_balloon:balloonWarning")
AddEventHandler("rs_balloon:balloonWarning", function(secondsLeft)
    local message = ""

    if secondsLeft == 0 then
        Core.NotifyLeft(T.Tittle, T.BalloonExpired, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    if secondsLeft >= 60 then
        local minutes = math.floor(secondsLeft / 60)
        local seconds = secondsLeft % 60

        if seconds > 0 then
            message = T.BalloonExpiresPrefix .. minutes .. (minutes > 1 and T.Minutes or T.Minute) .. T.And .. seconds .. T.Seconds
        else
            message = T.BalloonExpiresPrefix .. minutes .. (minutes > 1 and T.Minutes or T.Minute)
        end
    else
        message = T.BalloonExpiresPrefix .. secondsLeft .. T.Seconds
    end

    Core.NotifyLeft(T.Tittle, message, "generic_textures", "tick", 4000, "COLOR_GREEN")
end)

local spawn_ballon = nil
local current_ballon_id = nil

RegisterNetEvent('rs_balloon:spawnBalloon')
AddEventHandler('rs_balloon:spawnBalloon', function(locationName)
    if not locationName then
        return
    end

    if spawn_ballon and DoesEntityExist(spawn_ballon) then
        Core.NotifyLeft(T.Tittle, T.Youhave, "menu_textures", "cross", 4000, "COLOR_RED")
        return
    end

    local markerData = Config.Marker[locationName]
    if not markerData or not markerData.spawn then
        return
    end

    local spawnCoords = markerData.spawn
    local ballonModel = GetHashKey('hotAirBalloon01')

    RequestModel(ballonModel)
    while not HasModelLoaded(ballonModel) do
        Wait(10)
    end

    spawn_ballon = CreateVehicle(ballonModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    if not DoesEntityExist(spawn_ballon) then return end

    local netId = NetworkGetNetworkIdFromEntity(spawn_ballon)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetEntityAsMissionEntity(spawn_ballon, true, true)

    SetModelAsNoLongerNeeded(ballonModel)

    current_ballon_id = locationName
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, npc in pairs(NPCss) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
end)
