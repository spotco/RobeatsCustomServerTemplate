local DataStoreService = game:GetService("DataStoreService")
local SettingsDatabase = DataStoreService:GetDataStore("ScoreDatabase")
local HttpService = game:GetService("HttpService")

local DatastoreSerializer = require(game.ReplicatedStorage.Serialization.Datastore)

local SettingsTemplate = require(game.ReplicatedStorage.Templates.General.SettingsTemplate)

local Networking = require(game.ReplicatedStorage.Networking)

--[[
    SIGH...

    TO BE HONEST I HAVE NO IDEA HOW I'M GOING TO DO THIS, WE NEED A ROBLOX CLASS SERIALIZER/DESERIALIZER BECAUSE
    IT'S A PAIN TO MANUALLY CHANGE THE SAVING PROCEDURE, BUT JUST TO GET THIS OFF THE GROUND IT MIGHT BE A GOOD IDEA TO JUST GET IT TO WORK.
]]--

local function saveSettings(player, settings)
    local playerID = player.UserId
    local toSave = SettingsTemplate:new(settings or {})

    local saveName = "settings_"..playerID

    local suc, err = pcall(function()
        local d = DatastoreSerializer:serialize_table(toSave)
        print(HttpService:JSONEncode(d))
        SettingsDatabase:UpdateAsync(saveName, function(oldValue)
            return d
        end)
    end)

    if not suc then
        warn(err)
    end
end

local function retrieveSettings(player)
    local toReturn = {}
    local playerID = player.UserId
    local saveName = "settings_"..playerID
    local suc, err = pcall(function()
        toReturn = SettingsDatabase:GetAsync(saveName)
    end)

    return toReturn
end

Networking.Server:Register("SaveSettings", saveSettings)
Networking.Server:Register("RetrieveSettings", retrieveSettings)
