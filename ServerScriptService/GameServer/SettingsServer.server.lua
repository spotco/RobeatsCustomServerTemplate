local DataStoreService = game:GetService("DataStoreService")
local SettingsDatabase = DataStoreService:GetDataStore("ScoreDatabase")
local HttpService = game:GetService("HttpService")

local DatastoreSerializer = require(game.ReplicatedStorage.Serialization.Datastore)

local Networking = require(game.ReplicatedStorage.Networking)

local function getPlayerSettingsKey(playerID)
	return string.format("playerSettings_%s", tostring(playerID))
end

local function saveSettings(player, settings)
		local playerID = player.UserId

		local saveName = getPlayerSettingsKey(playerID)

		local suc, err = pcall(function()
				local d = DatastoreSerializer:serialize_table(settings)
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
		local saveName = getPlayerSettingsKey(playerID)
		local suc, err = pcall(function()
				toReturn = SettingsDatabase:GetAsync(saveName)
		end)

		return toReturn
end

Networking.Server:Register("SaveSettings", saveSettings)
Networking.Server:Register("RetrieveSettings", retrieveSettings)
