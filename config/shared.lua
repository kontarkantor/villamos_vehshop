Config = {}

Config.Locale = "en" -- en, hu

Config.Shops = {
    ["carshop"] = {
        label = "Car dealership",
        coords = vector3(-57.54, -1097.01, 25.5),
        outsidecoords = vector4(-31.0, -1090.7, 26.42, 314.81),
        testcoords = vector4(-1735.94, -2926.65, 13.5, 314.81), -- set false to disable testing
        testtime = 60*1000, --in ms 
        showroom = vector4(-46.1, -1096.43, 25.71, 230.0),
        showroomcam = vector3(-45.54, -1100.37, 27.42),
        enablecash = true, 
        enablebank = true,
        enablefaction = false,
        blip = {sprite = 225, color = 0},
        job = false,
        vehtype = "car"
    },
    ["boatshop"] = {
        label = "Boat dealership",
        coords = vector3(-753.863708, -1511.775879, 4.016113),
        outsidecoords = vector4(-805.503296, -1504.958252, 0.912793, 104.881889),
        testcoords = vector4(-888.421997, -1565.841797, 0.112793, 144.566910), -- set false to disable testing
        testtime = 60*1000, --in ms 
        showroom = vector4(-816.843933, -1421.037354, 0.112793, 167.244080),
        showroomcam = vector3(-810.105469, -1428.474731, 5.268921),
        enablecash = true, 
        enablebank = true,
        enablefaction = false,
        blip = {sprite = 427, color = 3},
        job = false,
        vehtype = "boat"
    },
    ["gov_carshop"] = {
        label = "Car dealership for police",
        coords = vector3(457.239563, -1024.813232, 27.520532),
        outsidecoords = vector4(436.575836, -1022.531860, 28.673218, 85.039368),
        testcoords = false,
        testtime = 60*1000, --in ms 
        showroom = vector4(-46.1, -1096.43, 25.71, 230.0),
        showroomcam = vector3(-45.54, -1100.37, 27.42),        
        enablecash = false, 
        enablebank = false,
        enablefaction = {"police"}, --police and ambulance can pay from society balance
        blip = {sprite = 225, color = 3}, 
        job = {
            ["police"] = {
                "boss"
            }
        },
        vehtype = "car"
    },
}

if not IsDuplicityVersion() then 
    Config.Notify = function(msg)
        TriggerEvent("esx:showNotification", msg)
    end 
end 