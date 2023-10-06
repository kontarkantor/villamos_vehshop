local vehicles = {}

AddEventHandler('onResourceStart', function(res)
	if res ~= GetCurrentResourceName() then return end 
    Wait(3000)
    RefreshCars()
end)

function RefreshCars()
    for shop, data in pairs(Config.Shops) do 
        vehicles[shop] = {}
    end 
    local data = MySQL.Sync.fetchAll('SELECT * FROM vehicles', {})
    for i=1, #data, 1 do
        local veh = data[i]

        if veh.shop and Config.Shops[veh.shop] then 
            vehicles[veh.shop][#vehicles[veh.shop]+1] = {
                model = veh.model,
                label = veh.name,
                price = veh.price,
                category = veh.category,
                img = veh.image or Config.UnknowImage
            }
        end 
    end 
end

function IsJobAllowed(jobobj, playerjob)
    if not jobobj then return true end 
    if not jobobj[playerjob.name] then return false end 
    for i=1, #jobobj[playerjob.name], 1 do
        if jobobj[playerjob.name][i] == playerjob.grade_name then 
            return true 
        end 
    end 
    return false 
end 

function IsSocietyAllowed(societies, job)
    if not societies then return false end 
    for i=1, #societies, 1 do
        if societies[i] == job then 
            return true 
        end 
    end 
    return false 
end

function GetVehicleData(shop, model)
    for i=1, #vehicles[shop], 1 do
        if vehicles[shop][i].model == model then 
            return vehicles[shop][i]
        end 
    end 
    return false 
end

function LogToDiscord(name, identifier, id, model, plate, price, paidwith, image)
    if not Config.LogWebhook then return end 
    local connect = {
        {
            ["color"] = 27946,
            ["title"] = "**".. _U("vehicle_bought") .."**",
            ["description"] = _U("player_bought_vehicle", name),
            ["fields"] = {
                {
                    ["name"] = _U("player"),
                    ["value"] = id .. " | " .. name .. " | " .. identifier
                },
                {
                    ["name"] = _U("model"),
                    ["value"] = model
                },
                {
                    ["name"] = _U("plate"),
                    ["value"] = plate
                },
                {
                    ["name"] = _U("price"),
                    ["value"] = price
                },
                {
                    ["name"] = _U("paid_with"),
                    ["value"] = paidwith
                }
            },
            ["image"] = {
                ["url"] = image
            },
            ["author"] = {
                ["name"] = "Marvel Studios",
                ["url"] = "https://discord.gg/esnawXn5q5",
                ["icon_url"] = "https://cdn.discordapp.com/attachments/917181033626087454/954753156821188658/marvel1.png"
            },
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %X").." | villamos_vehshop :)",
            },
        }
    }
    PerformHttpRequest(Config.LogWebhook, function(err, text, headers) end, 'POST', json.encode({embeds = connect}), { ['Content-Type'] = 'application/json' })
end

function IsAdmin(group)
    for i=1, #Config.AdminGroups, 1 do
        if Config.AdminGroups[i] == group then 
            return true 
        end 
    end 

    return false
end 

ESX.RegisterServerCallback("villamos_vehshop:openShop", function(source, cb, shop)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not vehicles[shop] then 
        return cb(false)
    end 
    if not IsJobAllowed(Config.Shops[shop].job, xPlayer.job) then 
        return cb(false)
    end 
    if not IsSocietyAllowed(Config.Shops[shop].enablefaction, xPlayer.job.name) then 
        return cb(vehicles[shop], { money = (Config.Shops[shop].enablecash and xPlayer.getMoney() or false), bank = (Config.Shops[shop].enablebank and xPlayer.getAccount('bank').money or false), society = false })
    end 
    local societymoney
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..xPlayer.job.name, function(account)
		if not account then 
            societymoney = false 
            return print("^1SCRIPT ERROR: Invalid society account for job: "..xPlayer.job.name)
        end 
        societymoney = account.money
	end)
    while societymoney == nil do 
        Wait(10)
    end 
    cb(vehicles[shop], { money = (Config.Shops[shop].enablecash and xPlayer.getMoney() or false), bank = (Config.Shops[shop].enablebank and xPlayer.getAccount('bank').money or false), society = societymoney })
end)

RegisterNetEvent('villamos_vehshop:buyVehicle', function(shop, model, account)
    if not vehicles[shop] then return end 
    local xPlayer = ESX.GetPlayerFromId(source)

    if not IsJobAllowed(Config.Shops[shop].job, xPlayer.job) then return end 

    local vehdata = GetVehicleData(shop, model)
    if not vehdata then return end 

    if account ~= "money" and account ~= "bank" then return end
    if account == "money" and not Config.Shops[shop].enablecash or account == "bank" and not Config.Shops[shop].enablebank then return end

    if xPlayer.getAccount(account).money < vehdata.price then 
        return Config.Notify(xPlayer.source, _U("not_enough_money"))
    end 

    xPlayer.removeAccountMoney(account, vehdata.price)
    local plate = GeneratePlate()
    local res = MySQL.Sync.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, type) VALUES (@owner, @plate, @vehicle, @type)', {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = plate,
        ['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate}),
        ['@type'] = Config.Shops[shop].vehtype
    })
    if res then 
        Config.Notify(xPlayer.source, _U("new_vehicle", plate))
        TriggerClientEvent('villamos_vehshop:spawnCar', xPlayer.source, Config.Shops[shop].outsidecoords, model, plate)
        LogToDiscord(GetPlayerName(xPlayer.source), xPlayer.identifier, xPlayer.source, model, plate, vehdata.price, account, vehdata.img)
    end 
end)

RegisterNetEvent('villamos_vehshop:buyVehicleFaction', function(shop, model)
    if not vehicles[shop] then return end 
    local xPlayer = ESX.GetPlayerFromId(source)

    if not IsJobAllowed(Config.Shops[shop].job, xPlayer.job) then return end 
    if not IsSocietyAllowed(Config.Shops[shop].enablefaction, xPlayer.job.name) then return end 

    local vehdata = GetVehicleData(shop, model)
    if not vehdata then return end 

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..xPlayer.job.name, function(account)
		if not account then 
            Config.Notify(xPlayer.source, "Sikertelen vásárlás!")
            return print("^1SCRIPT ERROR: Invalid society account for job: "..xPlayer.job.name)
        end 
        if account.money < vehdata.price then 
            return Config.Notify(xPlayer.source, _U("not_enough_money_scoiety"))
        end 

        account.removeMoney(vehdata.price)
        local plate = GeneratePlate()
        local res = MySQL.Sync.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, type, job) VALUES (@owner, @plate, @vehicle, @type, @job)', {
            ['@owner'] = xPlayer.identifier,
            ['@plate'] = plate,
            ['@vehicle'] = json.encode({model = GetHashKey(model), plate = plate}),
            ['@type'] = Config.Shops[shop].vehtype,
            ['@job'] = xPlayer.job.name
        })
        if res then 
            Config.Notify(xPlayer.source, _U("new_vehicle_scoiety", plate))
            TriggerClientEvent('villamos_vehshop:spawnCar', xPlayer.source, Config.Shops[shop].outsidecoords, model, plate)
            LogToDiscord(GetPlayerName(xPlayer.source), xPlayer.identifier, xPlayer.source, model, plate, vehdata.price, 'society_'..xPlayer.job.name, vehdata.img)
        end 
	end)
end)

RegisterCommand("vsadd", function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not IsAdmin(xPlayer.getGroup()) then 
        return Config.Notify(xPlayer.source, _U("no_perm"))
    end 
    local shop = args[1]
    if not shop or not Config.Shops[shop] then 
        return Config.Notify(xPlayer.source, _U("invalid_shop"))
    end 
    local model = args[2]
    if not model then 
        return Config.Notify(xPlayer.source, _U("invalid_model"))
    end 
    if GetVehicleData(shop, model) then 
        return Config.Notify(xPlayer.source, _U("already_in_shop"))
    end 
    local price = args[3] and tonumber(args[3]) or nil 
    if not price then 
        return Config.Notify(xPlayer.source, _U("invalid_price"))
    end 
    local category = args[4]
    if not category then 
        return Config.Notify(xPlayer.source, _U("invalid_category"))
    end 
    local name = args 
    table.remove(name, 4)
    table.remove(name, 3)
    table.remove(name, 2)
    table.remove(name, 1)
    if not name[1] then 
        return Config.Notify(xPlayer.source, _U("invalid_name"))
    end 
    name = table.concat(name, " ")
    local res = MySQL.Sync.execute('INSERT INTO vehicles (model, shop, name, price, category) VALUES (@model, @shop, @name, @price, @category)', {
        ['@model'] = model, 
        ['@shop'] = shop, 
        ['@name'] = name, 
        ['@price'] = price, 
        ['@category'] = category 
    })
    if res then 
        RefreshCars()
        return Config.Notify(xPlayer.source, _U("success"))
    end 
    Config.Notify(xPlayer.source, _U("unsuccess"))
end)
RegisterCommand("vsdel", function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not IsAdmin(xPlayer.getGroup()) then 
        return Config.Notify(xPlayer.source, _U("no_perm"))
    end 
    local shop = args[1]
    if not shop or not Config.Shops[shop] then 
        return Config.Notify(xPlayer.source, _U("invalid_shop"))
    end 
    local model = args[2]
    if not model then 
        return Config.Notify(xPlayer.source, _U("invalid_model"))
    end 
    if not GetVehicleData(shop, model) then 
        return Config.Notify(xPlayer.source, _U("not_in_shop"))
    end 
    local res = MySQL.Sync.execute('DELETE FROM vehicles WHERE model = @model AND shop = @shop', {
        ['@model'] = model,
        ['@shop'] = shop
    })
    if res then 
        RefreshCars()
        return Config.Notify(xPlayer.source, _U("success"))
    end 
    Config.Notify(xPlayer.source, _U("unsuccess"))
end)
RegisterCommand("vsrefresh", function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not IsAdmin(xPlayer.getGroup()) then 
        return Config.Notify(xPlayer.source, _U("no_perm"))
    end 
    RefreshCars()
    Config.Notify(xPlayer.source, _U("success"))
end)
RegisterCommand("vsphoto", function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not IsAdmin(xPlayer.getGroup()) then 
        return Config.Notify(xPlayer.source, _U("no_perm"))
    end 
    local shop = args[1]
    if not shop or not Config.Shops[shop] then 
        return Config.Notify(xPlayer.source, _U("invalid_shop"))
    end 
    if not Config.ImageWebhook or Config.ImageWebhook == "" then 
        return print("^1SCRIPT ERROR: The Webhook is not setted up to take the pictures")
    end 
    if GetResourceState("screenshot-basic") ~= "started" then 
        return print("^1SCRIPT ERROR: screenshot-basic isn't running to take the pictures")
    end 
    local res = MySQL.Sync.fetchAll('SELECT model FROM vehicles WHERE image IS NULL AND shop = @shop', {
        ['@shop'] = shop
    })
    TriggerClientEvent("villamos_vehshop:takePhotos", xPlayer.source, shop, Config.ImageWebhook, res)
end)

RegisterNetEvent("villamos_vehshop:savePhoto", function(shop, model, img)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not IsAdmin(xPlayer.getGroup()) then 
        return 
    end 
    if not shop or not Config.Shops[shop] then 
        return 
    end
    MySQL.Sync.execute('UPDATE vehicles SET image = @image WHERE model = @model AND shop = @shop', {
        ['@model'] = model,
        ['@shop'] = shop,
        ['@image'] = img
    })
end)
RegisterNetEvent("villamos_vehshop:refresh", function(shop, model, img)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not IsAdmin(xPlayer.getGroup()) then 
        return 
    end 
    RefreshCars()
end)


--PLATE--      thank you esx_vehicleshop <3
local Nums = {}
local Chars = {}

for i = 48,  57 do table.insert(Nums, string.char(i)) end
for i = 65,  90 do table.insert(Chars, string.char(i)) end
for i = 97, 122 do table.insert(Chars, string.char(i)) end

function IsPalteTaken(plate)
	local res = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	})
    return res[1] ~= nil
end

function GeneratePlate()
	local generatedPlate = ""
	local done = false

    for c = 1, 3 do 
        generatedPlate = generatedPlate .. Chars[math.random(1, #Chars)]
    end 
    generatedPlate = generatedPlate .. ' '
    for c = 1, 3 do 
        generatedPlate = generatedPlate .. Nums[math.random(1, #Nums)]
    end 
    generatedPlate = string.upper(generatedPlate)

    if IsPalteTaken(generatedPlate) then 
        return GeneratePlate()
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

	local res = MySQL.Sync.fetchAll(sqlstring, {
		['@owner'] = xPlayer.identifier,
		['@type'] = type,
		['@job'] = xPlayer.job.name
	})

    cb(res)
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
    cb(IsPalteTaken(plate))
end)
