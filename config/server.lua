Config.fivemanageAPI = "" -- https://fivemanage.com/
Config.imgbbAPI = "" -- https://api.imgbb.com/
Config.LogWebhook = ""

Config.UnknowImage = "http://clipart-library.com/images/8TGb9bdzc.png"

Config.AdminGroups = {'owner','admin'}

Config.SharedJobVehicles = false

Config.Notify = function(src, msg)
    TriggerClientEvent("esx:showNotification", src, msg)
end 
