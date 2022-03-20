ESX = nil
local isInShop = false
local testing = false

RegisterNUICallback('exit', function(data, cb)
    SetNuiSate(false)
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    TriggerServerEvent('villamos_vehshop:BuyVehicle', data.model, 'money')
    SetNuiSate(false)
    cb('ok')
end)

RegisterNUICallback('buybank', function(data, cb)
    TriggerServerEvent('villamos_vehshop:BuyVehicle', data.model, 'bank')
    SetNuiSate(false)
    cb('ok')
end)

RegisterNUICallback('buyfaction', function(data, cb)
    TriggerServerEvent('villamos_vehshop:BuyVehicleFaction', data.model)
    SetNuiSate(false)
    cb('ok')
end)

RegisterNUICallback('test', function(data, cb)
    SetNuiSate(false)
    cb('ok')
    if Config.EnableTest and not testing then 
        local hash = GetHashKey(data.model)
        if not IsModelInCdimage(hash) then 
            return
        end 
        while not HasModelLoaded(hash) do 
            RequestModel(hash)
            Citizen.Wait(10)
        end 
        local vehicle = CreateVehicle(hash, Config.TestCoords.x, Config.TestCoords.y, Config.TestCoords.z, Config.TestCoords.h, false, false)
        Citizen.Wait(1000)
        TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)
        SetModelAsNoLongerNeeded(hash)
        local start = GetGameTimer()
        testing = true 
        Citizen.CreateThread(function()
            while testing do 
                Citizen.Wait(0)
                local rem = Config.TestTime - (GetGameTimer() - start)
                if rem <= 0 then 
                    testing = false 
                end 
                if GetVehiclePedIsIn(GetPlayerPed(-1), false) ~= vehicle then 
                    testing = false
                end 
                SetTextFont(4)
                SetTextScale(0.5, 0.5)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(1)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentString("Hátra van ~p~"..math.floor(rem/1000).." mp")
                EndTextCommandDisplayText(0.5, 0.9)
            end 
            ESX.Game.DeleteVehicle(vehicle)
            ESX.Game.Teleport(GetPlayerPed(-1), Config.ShopCoords)
        end)
    end 
end)

function SetNuiSate(state)
    SetNuiFocus(state, state)
	isInShop = state

	SendNUIMessage({
		type = "show",
		enable = state
	})
end

function Notify(msg)
    ESX.ShowNotification(msg)     
end 

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    
    while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

    AddTextEntry('vehshop_open_msg', '~INPUT_PICKUP~ az autókereskedés megnyitáshoz')

    TriggerServerEvent('villamos_vehshop:Login')

    TriggerEvent('chat:addSuggestion', '/vsadd', 'Kocsi berakása az autókerbe', {
        { name="model", help="A kocsi modelle" },
        { name="price", help="A kocsi ára" },
        { name="category", help="A kocsi kategóriája" },
        { name="name", help="A kocsi neve" },
    })
    TriggerEvent('chat:addSuggestion', '/vsdel', 'Kocsi kivétele az autókerből', {
        { name="model", help="A kocsi modelle" }
    })
    TriggerEvent('chat:addSuggestion', '/vsphoto', 'Képek készítése az autókerben lévő kocsikhoz', {})
    

    SendNUIMessage({
		type = "config",
		bank = Config.EnableBank,
		test = Config.EnableTest,
        faction = Config.EnableFaction,
        currency = Config.Currency
	})

    local blip = AddBlipForCoord(Config.ShopCoords.x, Config.ShopCoords.y, Config.ShopCoords.z)
	SetBlipSprite (blip, 326)
	SetBlipScale  (blip, 1.0)
	SetBlipColour (blip, 2)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName("Autókereskedés")
	EndTextCommandSetBlipName(blip)

    while true do 

        local coords = GetEntityCoords(GetPlayerPed(-1))
        local sleep = 500
        local dis = GetDistanceBetweenCoords(coords, Config.ShopCoords.x, Config.ShopCoords.y, Config.ShopCoords.z, true)

        if dis < 20 then 
            sleep = 1
            DrawMarker(6, Config.ShopCoords.x, Config.ShopCoords.y, Config.ShopCoords.z-0.6, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0, 2.0, 2.0, 2.0, 0, 155, 20, 100, false, true, 2, false, false, false, false)
            DrawMarker(36, Config.ShopCoords.x, Config.ShopCoords.y, Config.ShopCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 155, 20, 100, false, true, 2, false, false, false, false)
            if dis < 2.0 then 
                DisplayHelpTextThisFrame('vehshop_open_msg')
                if IsControlJustReleased(0, 38) then
                    SetNuiSate(true)
                end    
            elseif isInShop then 
                SetNuiSate(false)
            end 
        elseif isInShop then 
            SetNuiSate(false)
        end 

        Citizen.Wait(sleep)

    end 

end)

RegisterNetEvent('villamos_vehshop:SetCars')
AddEventHandler('villamos_vehshop:SetCars', function(data)
	SendNUIMessage({
		type = "set",
		cars = data,
	})
end)

RegisterNetEvent('villamos_vehshop:Notify')
AddEventHandler('villamos_vehshop:Notify', function(msg)
	Notify(msg)
end)

RegisterNetEvent('villamos_vehshop:SpawnCar')
AddEventHandler('villamos_vehshop:SpawnCar', function(model, plate)
	ESX.Game.SpawnVehicle(GetHashKey(model), Config.SpawnCarCoords, Config.SpawnCarCoords.h, function(vehicle)
        local ped = GetPlayerPed(-1)
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        SetVehicleNumberPlateText(vehicle, plate)
    end)
end)

RegisterNetEvent('villamos_vehshop:TakePhotos')
AddEventHandler('villamos_vehshop:TakePhotos', function(vehicles)
	if not Config.Webhook or Config.Webhook == "WEBHOOK" and GetResourceState("screenshot-basic") == "started" then 
        Notify("Nincs beállítva webhook vagy nincs bent screenshot-basic, így nem lehet fotókat készíteni!")
    else 
        Notify("Elkészítjük a fényképeket, kérlek ne csinálj most semmit!")
        DisplayHud(false)
        DisplayRadar(false)
        FreezeEntityPosition(GetPlayerPed(-1), true)

        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(cam, Config.ShoowRoomCam.x, Config.ShoowRoomCam.y, Config.ShoowRoomCam.z)
        SetCamRot(cam, Config.ShoowRoomCam.xr, Config.ShoowRoomCam.yr, Config.ShoowRoomCam.zr, 2)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, false)

        
        for _, veh in pairs(vehicles) do 
            local model = veh.model
            local hash = GetHashKey(model)

            if IsModelInCdimage(hash) then 
                if not HasModelLoaded(hash) then
                    RequestModel(hash)
                    while not HasModelLoaded(hash) do
                        Citizen.Wait(0)
                    end
                end

                local car = CreateVehicle(hash, Config.ShoowRoomCoords.x, Config.ShoowRoomCoords.y, Config.ShoowRoomCoords.z, Config.ShoowRoomCoords.h, false, true, false)
                while not DoesEntityExist(car) do 
                    Citizen.Wait(100)
                end 
                SetModelAsNoLongerNeeded(hash)
                FreezeEntityPosition(car, true)
                SetModelAsNoLongerNeeded(hash)

                local shoting = true 
                Citizen.Wait(1000)

                exports['screenshot-basic']:requestScreenshotUpload(Config.Webhook, "files[]", function(data)
                    local resp = json.decode(data)
                    local img = resp.attachments[1].proxy_url
                    if not img then 
                        Notify("Hiba feltöltés közben!")
                    else 
                        TriggerServerEvent('villamos_vehshop:SavePhoto', model, img)
                    end 
                    shoting = false
                end)

                while shoting do 
                    Citizen.Wait(100)
                end 
                Citizen.Wait(2000)
                DeleteEntity(car)
            else 
                Notify("Nem létező model: " .. model)
            end 
        end 

        DisplayHud(true)
        DisplayRadar(true)
        FreezeEntityPosition(GetPlayerPed(-1), false)
        RenderScriptCams(false)
        DestroyCam(cam, true)
        SetCamActive(cam, false)
        Notify("Elkészítettük a fényképeket!")
        TriggerServerEvent('villamos_vehshop:ReqUpdate')
    end 
end)

function GeneratePlate()
    local p 
    ESX.TriggerServerCallback('villamos_vehshop:GeneratePlate', function(plate) 
        p = plate
    end)
    while not p do 
        Citizen.Wait(10)
    end 
    return p
end 