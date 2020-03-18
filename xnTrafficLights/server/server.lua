RegisterServerEvent('xnTrafficLights:UpdateTrafficLight')
AddEventHandler('xnTrafficLights:UpdateTrafficLight', function(object, light, speedZone, radius)
	local thisSource = source
	local myTrafficLight = object
	local myLightSetting = light
	local mySpeedZoneCoords = speedZone
	local myRadius = radius
	TriggerClientEvent('xnTrafficLights:UpdateTrafficLightSetting', -1, myTrafficLight, myLightSetting, mySpeedZoneCoords, GetPlayerName(thisSource), myRadius)
end)

-- If you want to add conditions for opening the menu, this is where you'd do it, or you could even use Ace Permissions
RegisterCommand("traffic", function(source, args)
	TriggerClientEvent('xnTrafficLights:OpenMenu', source)
end, false)