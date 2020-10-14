local SettingsTemplate = require(game.ReplicatedStorage.Templates.General.SettingsTemplate)

local Networking = require(game.ReplicatedStorage.Networking)

local config = SettingsTemplate:new()

local Configuration = {
    preferences = config
}

function Configuration:modify(key, value)
    self.preferences[key] = value
end

function Configuration:load_from_save()
    local settings = Networking.Client:Execute("RetrieveSettings")

    
end

return Configuration