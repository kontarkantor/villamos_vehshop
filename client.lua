local openedShop = false
local testing = false
local shops = {}
local blips = {}

CreateThread(function()
    while not ESX or not ESX.PlayerData or not ESX.PlayerData.job do 
        Wait(10)
    end 

    TriggerEvent('chat:addSuggestion', '/vsadd', _U("command_vsadd"), {
        { name="shop", help=_U("command_shop") },
        { name="model", help=_U("command_model") },
        { name="price", help=_U("command_price") },
        { name="category", help=_U("command_category") },
        { name="name", help=_U("command_name") },
    })
    TriggerEvent('chat:addSuggestion', '/vsdel', _U("command_vsdel"), {
        { name="shop", help=_U("command_shop") },
        { name="model", help=_U("command_model") }
    })
    TriggerEvent('chat:addSuggestion', '/vsphoto', _U("command_vsphoto"), {
        { name="shop", help=_U("command_shop") }
    })
    TriggerEvent('chat:addSuggestion', '/vsrefresh', _U("command_vsrefresh"), {})
    TriggerEvent('chat:addSuggestion', '/vsget', _U("command_vsget"), {})
    
    RefreshShops()

    while true do 
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        if not openedShop then 
            for shop, data in pairs(shops) do 
                local dis = #(coords - data.coords)
                if dis < 20 then 
                    sleep = 1
                    DrawMarker(6, data.coords, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0, 2.0, 2.0, 2.0, 0, 155, 20, 100, false, true, 2, false, false, false, false)
                    DrawMarker(36, data.coords+vector3(0.0, 0.0, 0.6), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 155, 20, 100, false, true, 2, false, false, false, false)
                    if dis < 2.0 then 
                        AddTextEntry('vehshop_open_msg', _U("open_msg", data.label))
                        DisplayHelpTextThisFrame('vehshop_open_msg')
                        if IsControlJustReleased(0, 38) then
                            OpenShop(shop)
                        end
                    end 
                end 
            end
        end  
        Wait(sleep)
    end 
end)

RegisterNetEvent("esx:setJob", function()
    RefreshShops()
end)

function RefreshShops()
    for _, blip in pairs(blips) do 
        RemoveBlip(blip)
    end 
    blips = {}
    shops = {}
    for shop, data in pairs(Config.Shops) do 
        if HaveJob(data.job) then 
            shops[shop] = { coords = data.coords, label = data.label }
            if data.blip then 
                local blip = AddBlipForCoord(data.coords)
                SetBlipSprite(blip, data.blip.sprite)
                SetBlipScale(blip, 1.0)
                SetBlipColour(blip, data.blip.color)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(data.label)
                EndTextCommandSetBlipName(blip)
                blips[#blips+1] = blip
            end 
        end 
    end 
end 

function HaveJob(jobobj)
    if not jobobj then return true end 
    if not jobobj[ESX.PlayerData.job.name] then return false end 
    for i=1, #jobobj[ESX.PlayerData.job.name], 1 do
        if jobobj[ESX.PlayerData.job.name][i] == ESX.PlayerData.job.grade_name then 
            return true 
        end 
    end 
    return false 
end 


function OpenShop(shop)
    if not Config.Shops[shop] then return end 
    openedShop = shop
    ESX.TriggerServerCallback("villamos_vehshop:openShop", function(cars, money) 
        if not cars then 
            openedShop = false 
            return 
        end 
        money.test = Config.Shops[shop].testcoords and true or false
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "show",
            enable = true,
            shopdata = money,
            cars = cars,
            name = Config.Shops[shop].label
        })
    end, shop)
end 

function CloseShop()
    SetNuiFocus(false, false)
    openedShop = false
    SendNUIMessage({
        type = "show",
        enable = false
    })
end 


RegisterNUICallback('locales', function(data, cb)
    local nuilocales = {}
    if not Config.Locale or not Locales[Config.Locale] then return print("^1SCRIPT ERROR: Invilaid locales configuartion") end
    for k, v in pairs(Locales[Config.Locale]) do 
        if string.find(k, "nui") then 
            nuilocales[k] = v
        end 
    end 
    cb(nuilocales)
end)

RegisterNUICallback('exit', function(data, cb)
    CloseShop()
    cb(1)
end)

RegisterNUICallback('buy', function(data, cb)
    if not openedShop then 
        CloseShop()
        return cb(1)
    end 
    TriggerServerEvent('villamos_vehshop:buyVehicle', openedShop, data.model, 'money')
    CloseShop()
    cb(1)
end)

RegisterNUICallback('buybank', function(data, cb)
    if not openedShop then 
        CloseShop()
        return cb(1)
    end 
    TriggerServerEvent('villamos_vehshop:buyVehicle', openedShop, data.model, 'bank')
    CloseShop()
    cb(1)
end)

RegisterNUICallback('buyfaction', function(data, cb)
    if not openedShop then 
        CloseShop()
        return cb(1)
    end 
    TriggerServerEvent('villamos_vehshop:buyVehicleFaction', openedShop, data.model)
    CloseShop()
    cb(1)
end)

RegisterNUICallback('test', function(data, cb)
    if not openedShop then 
        CloseShop()
        return cb(1)
    end 
    local testcoords = Config.Shops[openedShop].testcoords
    if not testcoords then 
        return cb(1)
    end 
    local testtime = Config.Shops[openedShop].testtime
    local shopcoords = Config.Shops[openedShop].coords
    CloseShop()
    cb(1)
    local hash = GetHashKey(data.model)
    if not IsModelInCdimage(hash) then 
        return print("^1SCRIPT ERROR: Invalid model: "..data.model)
    end 
    while not HasModelLoaded(hash) do 
        RequestModel(hash)
        Wait(10)
    end 
    local vehicle = CreateVehicle(hash, testcoords, false, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetModelAsNoLongerNeeded(hash)
    local start = GetGameTimer()
    testing = true 
    CreateThread(function()
        while testing do 
            Wait(0)
            local rem = testtime - (GetGameTimer() - start)
            if rem <= 0 or GetVehiclePedIsIn(PlayerPedId(), false) ~= vehicle then 
                testing = false 
            end 
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(1)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentString(_U("test_msg", math.floor(rem/1000)))
            EndTextCommandDisplayText(0.5, 0.9)
        end 
        DeleteVehicle(vehicle)
        SetEntityCoords(PlayerPedId(), shopcoords, false, false, false, false)
    end)
end)

RegisterNetEvent('villamos_vehshop:spawnCar', function(coords, model, plate)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then 
        return print("^1SCRIPT ERROR: Invalid model: "..model)
    end 
    while not HasModelLoaded(hash) do 
        RequestModel(hash)
        Wait(10)
    end 
    local vehicle = CreateVehicle(hash, coords, true, true)
    SetVehicleNumberPlateText(vehicle, plate)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterCommand("vsget", function(s, a, r)
    local coords = GetEntityCoords(PlayerPedId())
    local closestshop, closestdis = false, 20
    for shop, data in pairs(Config.Shops) do 
        local dis = #(coords - data.coords)
        if dis < closestdis then 
            closestshop = shop 
            closestdis = dis
        end 
    end 
    if not closestshop then 
        return Config.Notify(_U("no_shop_near"))
    end 
    Config.Notify(_U("closest_shop", closestshop))
end)

RegisterNetEvent("villamos_vehshop:takePhotos", function(shop, webhook, cars) 
    Config.Notify(_U("taking_photos"))
    DisplayHud(false)
    DisplayRadar(false)
    FreezeEntityPosition(PlayerPedId(), true)

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, Config.Shops[shop].showroomcam)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    for i=1, #cars, 1 do 
        local model = cars[i].model
        local hash = GetHashKey(model)
        if IsModelInCdimage(hash) and IsModelValid(hash) then 
            if not HasModelLoaded(hash) then
                RequestModel(hash)
                while not HasModelLoaded(hash) do
                    Wait(0)
                end
            end

            local vehicle = CreateVehicle(hash, Config.Shops[shop].showroom, false, true)
            SetModelAsNoLongerNeeded(hash)
            FreezeEntityPosition(vehicle, true)
            PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
            SetFocusEntity(vehicle)

            local p = promise.new()
            Wait(500)

            exports['screenshot-basic']:requestScreenshotUpload(webhook, "files[]", function(data)
                if not data then 
                    print("^1SCRIPT ERROR: Error while uploadin image to discord")
                    return p:resolve(false)
                end 
                local resp = json.decode(data)
                if not resp or not resp.attachments then 
                    print("^1SCRIPT ERROR: Error while uploadin image to discord")
                    return p:resolve(false)
                end 
                local img = resp.attachments[1].proxy_url
                if not img then 
                    print("^1SCRIPT ERROR: Error while uploadin image to discord")
                    return p:resolve(false)
                end 
                p:resolve(img)
            end)

            local image = Citizen.Await(p)
            if image then 
                TriggerServerEvent("villamos_vehshop:savePhoto", shop, model, image)
            end 
            DeleteEntity(vehicle)
            SetModelAsNoLongerNeeded(hash)
        else 
            print("^1SCRIPT ERROR: Invalid model: "..model)
        end 
    end 

    Wait(2000)

    ClearFocus()
    DisplayHud(true)
    DisplayRadar(true)
    FreezeEntityPosition(PlayerPedId(), false)
    RenderScriptCams(false)
    DestroyCam(cam, true)
    SetCamActive(cam, false)
    Config.Notify(_U("photos_done"))
    TriggerServerEvent("villamos_vehshop:refresh")
end)

exports("GeneratePlate", function()
    local p = promise.new()
    ESX.TriggerServerCallback('villamos_vehshop:GeneratePlate', function(plate) 
        p:resolve(plate)
    end)
    local plate = Citizen.Await(p)
    return plate
end)