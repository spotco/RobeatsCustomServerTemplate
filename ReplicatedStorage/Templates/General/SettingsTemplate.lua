local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local Template = require(game.ReplicatedStorage.Templates.Template)
local SettingsTemplate = SPUtil:copy_table(require(workspace.InitialSettings))

return SettingsTemplate