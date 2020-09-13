local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local ServerGameInstancePlayer = require(game.ReplicatedStorage.Shared.ServerGameInstancePlayer)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local RemoteInstancePlayerInfoManager = {}

function RemoteInstancePlayerInfoManager:new()
	local self = {
		_slots = SPDict:new();
	}

	return self
end

return RemoteInstancePlayerInfoManager
