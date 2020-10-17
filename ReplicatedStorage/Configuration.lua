local DatastoreSerializer = require(game.ReplicatedStorage.Serialization.Datastore)
local Networking = require(game.ReplicatedStorage.Networking)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

--[[
Use this class to access player settings. Example:
local Configuration = require(game.ReplicatedStorage.Configuration)
print(Configuration.Preferences.NoteSpeedMultiplier) --To access player NoteSpeedMultiplier
]]--

local Configuration = {
		Preferences = SPUtil:copy_table(require(game.ReplicatedStorage.DefaultSettings))
}

function Configuration:modify(key, value)
		self.Preferences[key] = value
end

function Configuration:load_from_save()
		local suc, err = pcall(function()
				local settings = Networking.Client:Execute("RetrieveSettings")
				local deserialized = DatastoreSerializer:deserialize_table(settings or {})
				if settings ~= nil then
						for i, v in pairs(deserialized) do
								self.Preferences[i] = v
						end
				end
		end)
		
		if not suc then
				warn(err)
		end
end

return Configuration