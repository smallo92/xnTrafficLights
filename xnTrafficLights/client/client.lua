local trafficLight = nil
local stopPointRadius = 4.5

Citizen.CreateThread(function()
	JayMenu.CreateMenu('trafficLights', Config.Text.MenuTitle, function()
		return CloseMenu()
	end)
	JayMenu.SetSubTitle('trafficLights', Config.Text.MenuSubtitle)
	while true do
		Citizen.Wait(0)		
		if JayMenu.IsMenuOpened('trafficLights') then
			local playerPed = PlayerPedId()
			local coords = GetEntityCoords(playerPed)
			if JayMenu.Button("Place Traffic Light") then
				local heading = GetEntityHeading(playerPed)
				if not DoesEntityExist(trafficLight) then
					ReqModel(Config.TrafficLightProp)
					local offsetCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 3.0, 0.0)
					trafficLight = CreateObjectNoOffset(Config.TrafficLightProp, offsetCoords, false, true, false)
					SetEntityHeading(trafficLight, heading)
					PlaceObjectOnGroundProperly(trafficLight)
					SetEntityCollision(trafficLight, false, true)
					SetEntityAlpha(trafficLight, 100)
					FreezeEntityPosition(trafficLight, true)
					SetModelAsNoLongerNeeded(Config.TrafficLightProp)
					objectPlaced = false
					placeTrafficLight = true
				else
					SendTheFeedPost(Config.Text.TrafficLightExists)
				end
			end
			if JayMenu.Button("Remove Traffic Light") then
				TriggerServerEvent('xnTrafficLights:UpdateTrafficLight', ObjToNet(trafficLight), 0, speedZonePoint, stopPointRadius) -- Green
				DeleteEntity(trafficLight)
				speedZonePoint = nil
			end
			if JayMenu.Button("Set Stopping Point") then
				if DoesEntityExist(trafficLight) then
					TriggerServerEvent('xnTrafficLights:UpdateTrafficLight', ObjToNet(trafficLight), 0, speedZonePoint, stopPointRadius) -- Green
					speedZonePoint = nil
					placeStoppingPoint = true
				else
					SendTheFeedPost(Config.Text.PlaceLightFirst)
				end
			end
			if JayMenu.Button("Set Light Green") then
				if speedZonePoint ~= nil then
					TriggerServerEvent('xnTrafficLights:UpdateTrafficLight', ObjToNet(trafficLight), 0, speedZonePoint, stopPointRadius) -- Green
				else
					SendTheFeedPost(Config.Text.PlaceStopPoint)
				end
			end
			if JayMenu.Button("Set Light Red") then
				if speedZonePoint ~= nil then
					Citizen.CreateThread(function()
						TriggerServerEvent('xnTrafficLights:UpdateTrafficLight', ObjToNet(trafficLight), 2, speedZonePoint, stopPointRadius) -- Yellow
						Citizen.Wait(3000)
						TriggerServerEvent('xnTrafficLights:UpdateTrafficLight', ObjToNet(trafficLight), 1, speedZonePoint, stopPointRadius) -- Red
					end)
				else
					SendTheFeedPost(Config.Text.PlaceStopPoint)
				end
			end
			JayMenu.Display()
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local ped = PlayerPedId()
		if placeStoppingPoint then
			local scaleButtons = { [Config.ConfirmButton] = Config.Text.PlaceStopInstruction, [Config.CancelButton] = Config.Text.CancelInstruction, [Config.StopPointBigger .. "." .. Config.StopPointSmaller] = Config.Text.ChangeSizeInstruction } -- Table key is the button ID, The last one is multiple buttons separated by a .
			local scaleF = setupScaleform("instructional_buttons", scaleButtons)
			DrawScaleformMovieFullscreen(scaleF, 255, 255, 255, 255, 0)
			local offsetMark = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -0.9)
			DrawMarker(25, offsetMark, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, stopPointRadius, stopPointRadius, 1.0, 255, 0, 0, 255, false, false)
			if IsDisabledControlJustPressed(1, Config.ConfirmButton) then
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
				speedZonePoint = offsetMark
				SendTheFeedPost(Config.Text.PositionSaved)
				placeStoppingPoint = false
			elseif IsDisabledControlJustPressed(1, Config.StopPointBigger) then
				stopPointRadius = stopPointRadius + 0.5
			elseif IsDisabledControlJustPressed(1, Config.StopPointSmaller) then
				stopPointRadius = stopPointRadius - 0.5
			elseif IsDisabledControlJustPressed(1, Config.CancelButton) then
				placeStoppingPoint = false
			end
		end
		if placeTrafficLight then
			local scaleButtons = { [Config.ConfirmButton] = Config.Text.PlaceLightInstruction, [Config.CancelButton] = Config.Text.CancelInstruction }
			local scaleF = setupScaleform("instructional_buttons", scaleButtons)
			DrawScaleformMovieFullscreen(scaleF, 255, 255, 255, 255, 0)
			local offsetCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
			local heading = GetEntityHeading(ped)
			SetEntityCoordsNoOffset(trafficLight, offsetCoords)
			SetEntityHeading(trafficLight, heading)
			PlaceObjectOnGroundProperly(trafficLight)
			if IsDisabledControlJustPressed(1, Config.ConfirmButton) then
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
				local newCoords = GetEntityCoords(trafficLight)
				local newHeading = GetEntityHeading(trafficLight)
				DeleteEntity(trafficLight)
				ReqModel(Config.TrafficLightProp)
				trafficLight = CreateObjectNoOffset(Config.TrafficLightProp, newCoords, true, true, false)
				SetEntityHeading(trafficLight, newHeading)
				PlaceObjectOnGroundProperly(trafficLight)
				FreezeEntityPosition(trafficLight, true)
				SetEntityInvincible(trafficLight, true)
				FreezeEntityPosition(trafficLight, true)
				SetEntityDynamic(trafficLight, true)
				SetModelAsNoLongerNeeded(Config.TrafficLightProp)
				TriggerServerEvent('xnTrafficLights:UpdateTrafficLight', ObjToNet(trafficLight), 0, nil, stopPointRadius) -- Green
				objectPlaced = true
				placeTrafficLight = false
			elseif IsDisabledControlJustPressed(1, Config.CancelButton) then
				placeStoppingPoint = false
				placeTrafficLight = false
				if not objectPlaced then
					DeleteEntity(trafficLight)
				end
			end
		end
	end
end)

local playerLights = {}
RegisterNetEvent('xnTrafficLights:UpdateTrafficLightSetting')
AddEventHandler('xnTrafficLights:UpdateTrafficLightSetting', function(object, light, speedZoneCoords, playerName, radius)
	if light == 0 then -- Green
		RemoveSpeedZone(playerLights[playerName]) -- Make them go
		SetEntityTrafficlightOverride(NetToObj(object), light)
	elseif light == 1 then -- Red
		playerLights[playerName] = AddSpeedZoneForCoord(speedZoneCoords, radius, 0.0, false) -- Make them stop
		SetEntityTrafficlightOverride(NetToObj(object), light)
	else -- Yellow
		SetEntityTrafficlightOverride(NetToObj(object), light)
	end
end)

RegisterNetEvent('xnTrafficLights:OpenMenu')
AddEventHandler('xnTrafficLights:OpenMenu', function()
	JayMenu.OpenMenu('trafficLights')
end)

function CloseMenu()
	placeStoppingPoint = false
	placeTrafficLight = false
	if not objectPlaced then
		DeleteEntity(trafficLight)
	end
	return true
end

function SendTheFeedPost(message)
	BeginTextCommandThefeedPost("STRING")
	AddTextComponentSubstringPlayerName(message)
	EndTextCommandThefeedPostTicker(true, true)
end

function ReqModel(model)
	RequestModel(model)
	while not HasModelLoaded(model) do
		Citizen.Wait(0)
	end
end

function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(ControlButton)
    PushScaleformMovieMethodParameterButtonName(ControlButton)
end

function setupScaleform(scaleform, buttons)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()
	
	local placement = 0
	for button, message in pairs(buttons) do
		PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
		PushScaleformMovieFunctionParameterInt(placement)
		if string.match(button, "%.") then
			for i in string.gmatch(button, "[^.]+") do
				Button(GetControlInstructionalButton(2, tonumber(i), true))
			end
		else
			Button(GetControlInstructionalButton(2, button, true))
		end
		ButtonMessage(message)
		PopScaleformMovieFunctionVoid()
		placement = placement + 1
	end
	
    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end