local SettingsTemplate = require(game.ReplicatedStorage.Templates.General.SettingsTemplate)

local DatastoreSerializer = require(game.ReplicatedStorage.Serialization.Datastore)

local Networking = require(game.ReplicatedStorage.Networking)

local config = SettingsTemplate:new()

local Configuration = {
    preferences = config
}

function Configuration:modify(key, value)
    self.preferences[key] = value
end

function Configuration:load_from_save()
    local suc, err = pcall(function()
        local settings = Networking.Client:Execute("RetrieveSettings")

        local deserialized = DatastoreSerializer:deserialize_table(settings)

        self.preferences = deserialized
    end)
    
    if not suc then
        warn(err)
    end
end

return Configuration