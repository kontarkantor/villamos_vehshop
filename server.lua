local vehicles = {}


AddEventHandler('onResourceStart', function(res)
	if res == GetCurrentResourceName() then
        Wait(3000)
        UpdateCars()
	end
end)
	
function UpdateCars() 
    MySQL.Async.fetchAll('SELECT * FROM vehicles', {}, function (veh)
        vehicles = {}

        for i=1, #veh, 1 do
            local vehicle = veh[i]
    
            table.insert(vehicles, {
                img = vehicle.image or Config.UNKpng,
                label = vehicle.name,
                model = vehicle.model,
                price = vehicle.price,
                category = vehicle.category
            })
        end
    
        TriggerClientEvent('villamos_vehshop:SetCars', -1, vehicles)
    end)
end 

RegisterCommand('vsphoto', function(src, args, raw)
    if isAdmin(src) then 
        MySQL.Async.fetchAll('SELECT model FROM vehicles WHERE image IS NULL', {}, function (veh)
            TriggerClientEvent('villamos_vehshop:TakePhotos', src, veh)
        end)
    else 
        TriggerClientEvent('villamos_vehshop:Notify', src, "Nincs ehhez jogosultságod!")
    end 
end)
RegisterCommand('vsadd', function(src, args, raw)
    if isAdmin(src) then 
        local model = args[1]
        local price = tonumber(args[2])
        local category = args[3]
        local name 
        local n = args
        table.remove(n, 3)
        table.remove(n, 2)
        table.remove(n, 1)
        if n[1] then
            name = table.concat(n, " ")
        end
        if model and price and category and name then 
            MySQL.Async.execute('INSERT INTO vehicles (name, model, price, category) VALUES (@name, @model, @price, @category)', {
                ['@name'] = name, 
                ['@model'] = model, 
                ['@price'] = price, 
                ['@category'] = category, 
            }, function(p)
                UpdateCars()
                TriggerClientEvent('villamos_vehshop:Notify', src, "Sikeresen beraktál egy új autót!")
            end)
        else 
            TriggerClientEvent('villamos_vehshop:Notify', src, "Érvénytelen paraméterek!")
        end 
    else 
        TriggerClientEvent('villamos_vehshop:Notify', src, "Nincs ehhez jogosultságod!")
    end 
end)
RegisterCommand('vsdel', function(src, args, raw)
    if isAdmin(src) then 
        local model = args[1]
        if model then 
            MySQL.Async.execute('DELETE FROM vehicles WHERE model = @model', {
                ['@model'] = model
            }, function(p)
                UpdateCars()
                TriggerClientEvent('villamos_vehshop:Notify', src, "Sikeresen kivettél egy autót!")
            end)
        else 
            TriggerClientEvent('villamos_vehshop:Notify', src, "Érvénytelen paraméterek!")
        end 
    else 
        TriggerClientEvent('villamos_vehshop:Notify', src, "Nincs ehhez jogosultságod!")
    end 
end)

RegisterNetEvent('villamos_vehshop:SavePhoto')
AddEventHandler('villamos_vehshop:SavePhoto', function(model, link)
    local src = source 
    if isAdmin(src) then 
        MySQL.Async.execute('UPDATE vehicles SET image = @image WHERE model = @model', {
            ['@model'] = model,
            ['@image'] = link
        })
    end 
end)

RegisterNetEvent('villamos_vehshop:ReqUpdate')
AddEventHandler('villamos_vehshop:ReqUpdate', function()
    local src = source 
    if isAdmin(src) then 
        UpdateCars()
    end 
end)

RegisterNetEvent('villamos_vehshop:BuyVehicle')
AddEventHandler('villamos_vehshop:BuyVehicle', function(model, account)
    local src = source 
    local xPlayer = ESX.GetPlayerFromId(src)
    local price 

    for i=1, #vehicles, 1 do
        if vehicles[i].model == model then 
            price = vehicles[i].price
            break 
        end 
    end 

    if price and account == 'money' or Config.EnableBank then 
        if xPlayer.getAccount(account).money > price then 
            xPlayer.removeAccountMoney(account, price)
            local plate = GeneratePlate()
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
                ['@owner'] = xPlayer.identifier,
                ['@plate'] = plate,
                ['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate})
            }, function(p)
                TriggerClientEvent('villamos_vehshop:Notify', xPlayer.source, "Sikeresen megvásároltad új autódat, a rendszáma: "..plate.."!")
                TriggerClientEvent('villamos_vehshop:SpawnCar', xPlayer.source, model, plate)
            end)
        else 
            TriggerClientEvent('villamos_vehshop:Notify', xPlayer.source, "Nincs ehhez elég pénzed!")
        end 
    end 
end)

RegisterNetEvent('villamos_vehshop:BuyVehicleFaction')
AddEventHandler('villamos_vehshop:BuyVehicleFaction', function(model)
    if Config.EnableFaction then
        local src = source 
        local xPlayer = ESX.GetPlayerFromId(src)
        local faction
        local price 

        for i=1, #Config.Factions, 1 do
            if Config.Factions[i] == xPlayer.getJob().name then 
                faction = xPlayer.getJob().name
            end 
        end 

        for i=1, #vehicles, 1 do
            if vehicles[i].model == model then 
                price = vehicles[i].price
                break 
            end 
        end 

        if faction then 
            if price then
                if xPlayer.getAccount('money').money > price then 
                    xPlayer.removeAccountMoney('money', price)
                    local plate = GeneratePlate()
                    MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, job) VALUES (@owner, @plate, @vehicle, @job)', {
                        ['@owner'] = xPlayer.identifier,
                        ['@plate'] = plate,
                        ['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate}),
                        ['@job'] = faction
                    }, function(p)
                        TriggerClientEvent('villamos_vehshop:Notify', xPlayer.source, "Sikeresen megvásároltad új autódat, a rendszáma: "..plate.."!")
                        TriggerClientEvent('villamos_vehshop:SpawnCar', xPlayer.source, model, plate)
                    end)
                else 
                    TriggerClientEvent('villamos_vehshop:Notify', xPlayer.source, "Nincs ehhez elég pénzed!")
                end 
            end
        else 
            TriggerClientEvent('villamos_vehshop:Notify', xPlayer.source, "Ebbe a frakcióba nem vehetsz autót!")
        end 
    end 
end)

RegisterNetEvent('villamos_vehshop:Login')
AddEventHandler('villamos_vehshop:Login', function()
    local src = source 
    TriggerClientEvent('villamos_vehshop:SetCars', src, vehicles)
end)

function isAdmin(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local group = xPlayer.getGroup()

    for _, g in pairs(Config.AdminGroups) do 
        if g == group then 
            return true 
        end 
    end 

    return false
end 

--PLATE--      thank you esx_vehicleshop <3
local Nums = {}
local Chars = {}

for i = 48,  57 do table.insert(Nums, string.char(i)) end
for i = 65,  90 do table.insert(Chars, string.char(i)) end
for i = 97, 122 do table.insert(Chars, string.char(i)) end

function palteTaken(plate, cb)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function (result)
		cb(result[1] ~= nil)
	end)
end
function GeneratePlate()
	local generatedPlate
	local done = false

	while true do
		Citizen.Wait(0)

        generatedPlate = ''
        for c=1, Config.PlateChars do 
            generatedPlate = generatedPlate .. Chars[math.random(1, #Chars)]
        end 
        generatedPlate = generatedPlate .. ' '
        for c=1, Config.PlateNums do 
            generatedPlate = generatedPlate .. Nums[math.random(1, #Nums)]
        end 
        generatedPlate = string.upper(generatedPlate)

		palteTaken(generatedPlate, function(taken)
			if not taken then
				done = true
			end
		end)

		if done then
			break
		end
	end

	return generatedPlate
end

ESX.RegisterServerCallback('villamos_vehshop:GeneratePlate', function(source, cb)
    cb(GeneratePlate())
end)

--for esx jobs--
ESX.RegisterServerCallback('esx_vehicleshop:retrieveJobVehicles', function(source, cb, type)
	local xPlayer = ESX.GetPlayerFromId(source)

    local sqlstring = 'SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type AND job = @job'

    if Config.SharedJobVehicles then 
        sqlstring = 'SELECT * FROM owned_vehicles WHERE type = @type AND job = @job'
    end 

	MySQL.Async.fetchAll(sqlstring, {
		['@owner'] = xPlayer.identifier,
		['@type'] = type,
		['@job'] = xPlayer.job.name
	}, function (result)
		cb(result)
	end)
end)

RegisterServerEvent('esx_vehicleshop:setJobVehicleState')
AddEventHandler('esx_vehicleshop:setJobVehicleState', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate AND job = @job', {
		['@stored'] = state,
		['@plate'] = plate,
		['@job'] = xPlayer.job.name
	})
end)

ESX.RegisterServerCallback('esx_vehicleshop:isPlateTaken', function (source, cb, plate)
    palteTaken(plate, function(taken)
	cb(taken)
    end)
end)
