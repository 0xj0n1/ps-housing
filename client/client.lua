if Config.Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()
    PlayerData = QBCore.Functions.GetPlayerData()
elseif Config.Framework == 'ESX' then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    PlayerData = ESX.GetPlayerData()
end

local loaded = false

local function createProperty(property)
    PropertiesTable[property.property_id] = Property:new(property)
end

RegisterNetEvent('ps-housing:client:addProperty', createProperty)

RegisterNetEvent('ps-housing:client:removeProperty', function (property_id)
    local property = Property.Get(property_id)
    if property then
        property:RemoveProperty(true)
    end
    PropertiesTable[property_id] = nil
end)

function InitialiseProperties(properties)
    if loaded then return end
    Debug("Initialising properties")

    if Config.Framework == 'QBCore' then
        PlayerData = QBCore.Functions.GetPlayerData()
    elseif Config.Framework == 'ESX' then
        PlayerData = ESX.GetPlayerData()
    end

    for k, v in pairs(Config.Apartments) do
        ApartmentsTable[k] = Apartment:new(v)
    end

    if not properties then
        properties = lib.callback.await('ps-housing:server:requestProperties')
    end

    for k, v in pairs(properties) do
        createProperty(v.propertyData)
    end

    TriggerEvent("ps-housing:client:initialisedProperties")
    Debug("Initialised properties")
    loaded = true
end

AddEventHandler("QBCore:Client:OnPlayerLoaded", InitialiseProperties)
RegisterNetEvent('ps-housing:client:initialiseProperties', InitialiseProperties)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('ps-housing:client:setupSpawnUI', function(cData)
    DoScreenFadeOut(1000)
    local result = lib.callback.await('ps-housing:cb:GetOwnedApartment', source, cData.citizenid)
    if result then
        TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
        TriggerEvent('qb-spawn:client:openUI', true)
    else
        if Config.StartingApartment then
            TriggerEvent('qb-spawn:client:setupSpawns', cData, true, Config.Apartments)
            TriggerEvent('qb-spawn:client:openUI', true)
        else
            TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
            TriggerEvent('qb-spawn:client:openUI', true)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        if Modeler.IsMenuActive then
            Modeler:CloseMenu()
        end

        for k, v in pairs(PropertiesTable) do
            v:RemoveProperty()
        end

        for k, v in pairs(ApartmentsTable) do
            v:RemoveApartment()
        end
    end
end)

exports('GetProperties', function()
    return PropertiesTable
end)

exports('GetProperty', function(property_id)
    return Property.Get(property_id)
end)

exports('GetApartments', function()
    return ApartmentsTable
end)

exports('GetApartment', function(apartment)
    return Apartment.Get(apartment)
end)

exports('GetShells', function()
    return Config.Shells
end)
