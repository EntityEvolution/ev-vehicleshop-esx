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
        MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
            ['@plate'] = plate
        }, function(result)
            if result[1] == nil then
                local xMoney = xPlayer.getAccount(type).money
                if xMoney > tonumber(price) then
                    MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
                        ['@owner']   = xPlayer.getIdentifier(),
                        ['@plate']   = plate,
                        ['@vehicle'] = json.encode(properties)
                    }, function(result)
                        xPlayer.removeAccountMoney(type, tonumber(price))
                        xPlayer.showNotification('Paid $' .. price .. '. Money left $' .. xMoney - tonumber(price) .. '\nGo check it out at your garage')
                    end)
                else
                    xPlayer.showNotification('You need ' .. tostring('$' .. tonumber(price) - xMoney))
                end
            else
                xPlayer.showNotification('The plate already exists. Try again or change the plate')
            end
        end)
    end
end)
