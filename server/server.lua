if Config.UseOldEsx then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end
local spawned = false

ESX.RegisterServerCallback('ev:refresh', function(source, cb)
	cb(spawned)
    if not spawned then
        spawned = true
    end
end)

RegisterNetEvent('ev:getVehicle', function(price, type, model, plate, properties)
    local source <const> = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local xMoney = xPlayer.getAccount(type).money
        if xMoney > tonumber(price) then
            setVehicle(plate, properties)
            xPlayer.removeAccountMoney(type, tonumber(price))
            xPlayer.showNotification('Paid $' .. price .. '. Money left $' .. xMoney - tonumber(price))
        else
            xPlayer.showNotification('You need ' .. tostring('$' .. tonumber(price) - xMoney))
        end
    end
end)

function setVehicle(plate, properties)
    local source <const> = source
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result[1] == nil then
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
                ['@owner']   = xPlayer.getIdentifier(),
                ['@plate']   = plate,
                ['@vehicle'] = json.encode(properties)
            }, function(result)
                print("veh urs")
            end)
        else
            print('Plate repeats')
        end
    end)
end