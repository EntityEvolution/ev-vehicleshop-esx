local CreateThread = CreateThread
local Wait = Wait
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local IsControlJustReleased = IsControlJustReleased
local TaskWarpPedIntoVehicle = TaskWarpPedIntoVehicle
local GetHashKey = GetHashKey

if Config.UseOldEsx then
	ESX = nil
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

local currentVehicles = {}
local currentPrimary = 0
local currentSecondary = 0

ESX.TriggerServerCallback('ev:refresh', function(spawned)
	if not spawned then
		for _, v in ipairs(Config.Cars) do
			RequestModel(GetHashKey(v.model))
			while not HasModelLoaded(GetHashKey(v.model)) do
				Wait(0)
			end
			local vehicle =  CreateVehicle(GetHashKey(v.model),  v.coords, false)
			table.insert(currentVehicles, {
				vehicle = vehicle,
				model = v.model,
				properties = ESX.Game.GetVehicleProperties(vehicle)
			})
			SetVehicleOnGroundProperly(vehicle)
			SetVehicleEngineOn(vehicle, false, false, false)
			SetVehicleUndriveable(vehicle, true)
			FreezeEntityPosition(vehicle, true)
			SetEntityAsMissionEntity(vehicle, true, true)
			SetModelAsNoLongerNeeded(vehicle)
			SetEntityInvincible(vehicle, true)
			SetVehicleLights(vehicle, 2)
			WashDecalsFromVehicle(vehicle, 1.0)
			SetVehicleDirtLevel(vehicle)
			SetVehicleDoorsLocked(vehicle, 2)
			SetVehicleNumberPlateText(vehicle, v.plate)
		end
	end
end)

CreateThread(function()
	while true do
		for _, v in pairs(Config.Cars) do
			local distance = #(GetEntityCoords(PlayerPedId()) - vec3(v.coords.x, v.coords.y, v.coords.z))
			if distance < Config.NotificationDistance then
				floatTxt(Config.Message:format(v.label, v.price), vec3(v.coords.x, v.coords.y, v.coords.z + 1.65))
				if IsControlJustReleased(0, 38) then
					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
						title    = 'Vehicle Shop Menu',
						align    = 'right',
						elements = {
							{label = "Test Drive", value = 'test_drive'},
							{label = "Pay With Credit Card", value = 'bank'},
							{label = "Pay with Cash", value = 'money'},
							{label = "Cambiar Color", value = "color"},
							{label = "Cambiar Color Secondario", value = "secondary_color"},
					}}, function(data, menu)
						local val = data.current.value
						if val == 'test_drive' then
							local pos = GetEntityCoords(PlayerPedId())
							ESX.Game.SpawnVehicle(v.model, Config.Testing.Coords, Config.Testing.Heading, function(veh) 
								TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
							end)
							ESX.ShowNotification("Tienes ~r~"  ..Config.Testing.Time..  " ~w~ segundos restantes")
							menu.close()
							Wait(Config.Testing.Time * 1000)
							ESX.Game.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
							SetEntityCoords(PlayerPedId(), pos)
						elseif val == 'bank' then
							if Config.AllowCustomPlate then
								ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'vehicle_plate', {
									title = 'Plate (6 chars) or random',
								}, function(data2, menu2)
									if string.len(tostring(data2.value)) < Config.MaxPlate + 1 then
										setPlate(v.model, data2.value)
										print(data2.value:upper())
										TriggerServerEvent('ev:getVehicle', v.price, val, v.model, data2.value, getProps(v.model))
										menu2.close()
									else
										ESX.ShowNotification('Maximum of 6 characters')
									end
								end, function(menu2, data2)
									menu2.close()
								end)
							else
								local currentPlate = generateString(Config.MaxPlate)
								setPlate(v.model, currentPlate)
								TriggerServerEvent('ev:getVehicle', v.price, val, v.model, currentPlate, getProps(v.model))
								menu.close()
							end
						elseif val == 'money' then 
							if Config.AllowCustomPlate then
								ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'vehicle_plate', {
									title = 'Plate (6 chars Max) or random',
								}, function(data2, menu2)
									if string.len(tostring(data2.value)) < Config.MaxPlate + 1 then 
										setPlate(v.model, data2.value)
										TriggerServerEvent('ev:getVehicle', v.price, val, v.model, data2.value, getProps(v.model))
										menu2.close()
									else
										ESX.ShowNotification('Maximum of 6 characters')
									end
									menu2.close()
								end, function(menu2, data2)
									menu2.close()
								end)
							else
								local currentPlate = generateString(Config.MaxPlate)
								setPlate(v.model, currentPlate)
								TriggerServerEvent('ev:getVehicle', v.price, val, v.model, currentPlate, getProps(v.model))
								menu.close()
							end
						elseif val == "color" then
							local colors = {}
							for i = 0, #Config.Colors, 1 do
								table.insert(colors, {
									label = Config.Colors[i],
									value = i
								})
							end
							ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_colors', {
								title    = 'Car Colors ',
								align    = 'right',
								elements = colors
							}, function(data2, menu2)
									local val = data2.current
									if val then	
										print(currentPrimary)
										print(currentSecondary)
										currentPrimary = tonumber(val.value)
										SetVehicleColours(getVehicle(v.model), tonumber(val.value), currentSecondary)
										setColor(v.model, tonumber(val.value))
									end
							end, function(data2, menu2)
								menu2.close()
							end)
						elseif val == "secondary_color" then
							local colors = {}
							for i = 0, #Config.Colors, 1 do
								table.insert(colors, {
									label = Config.Colors[i],
									value = i
								})
							end
							ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_colors', {
								title    = 'Car Colors',
								align    = 'right',
								elements = colors
							}, function(data2, menu2)
									local val = data2.current
									if val then	
										currentSecondary = tonumber(val.value)
										SetVehicleColours(getVehicle(v.model), currentPrimary, tonumber(val.value))
										setColor2(v.model, tonumber(val.value))
									end
							end, function(data2, menu2)
								menu2.close()
							end)
						end
					end, function(data, menu)
						menu.close()
					end)	
				end
			end
		end
		Wait(5)
	end
end)

function getVehicle(vehicle)
	for i = 1, #currentVehicles, 1 do
		if DoesEntityExist(currentVehicles[i].vehicle) then
			if vehicle == currentVehicles[i].model then
				return currentVehicles[i].vehicle
			end
		end
	end
end

function getProps(vehicle)
	for i = 1, #currentVehicles, 1 do
		if DoesEntityExist(currentVehicles[i].vehicle) then
			if vehicle == currentVehicles[i].model then
				return currentVehicles[i].properties
			end
		end
	end
end

function setPlate(vehicle, plate)
	for i = 1, #currentVehicles, 1 do
		if DoesEntityExist(currentVehicles[i].vehicle) then
			if vehicle == currentVehicles[i].model then
				currentVehicles[i].properties.plate = plate
			end
		end
	end
end

function setColor(vehicle, color)
	for i = 1, #currentVehicles, 1 do
		if DoesEntityExist(currentVehicles[i].vehicle) then
			if vehicle == currentVehicles[i].model then
				currentVehicles[i].properties.color1 = color
			end
		end
	end
end

function setColor2(vehicle, color)
	for i = 1, #currentVehicles, 1 do
		if DoesEntityExist(currentVehicles[i].vehicle) then
			if vehicle == currentVehicles[i].model then
				currentVehicles[i].properties.color2 = color
			end
		end
	end
end

function generateString(length)
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local numbers = "0123456789"
    local characterSet = letters .. numbers
    local output = ""
    for i=1, length do
        local random = math.random(#characterSet)
        output = output .. string.sub(characterSet, random, random)
    end
    return output
end

function floatTxt(message, coords)
	AddTextEntry('vehicleNotification', message)
	SetFloatingHelpTextWorldPosition(1, coords)
	SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
	BeginTextCommandDisplayHelp('vehicleNotification')
	EndTextCommandDisplayHelp(2, false, false, -1)
end

-- Handlers
AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName then 
		for i = 1, #currentVehicles, 1 do
			if DoesEntityExist(currentVehicles[i].vehicle) then
				DeleteVehicle(currentVehicles[i].vehicle)
				SetEntityAsNoLongerNeeded(currentVehicles[i].vehicle)
			end
		end
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
	if GetCurrentResourceName() == resourceName then
    	print("Vehicles Refreshed")
	end
end)
