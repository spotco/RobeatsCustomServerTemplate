local DataStoreService = game:GetService("DataStoreService")
local ScoreDatabase = DataStoreService:GetDataStore("ScoreDatabase")
local HttpService = game:GetService("HttpService")
local Networking = require(game.ReplicatedStorage.Networking)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local CustomServerSettings = require(game.Workspace.CustomServerSettings)

local function getLeaderboardKey(mapid)
	return string.format("leaderboard_songkey(%s)", tostring(mapid))
end

Networking.Server:Register("SubmitScore", function(player, sentData)
		AssertType:is_true(SongDatabase:contains_key(sentData.mapid))
		AssertType:is_number(sentData.accuracy)
		AssertType:is_int(sentData.maxcombo)
		AssertType:is_int(sentData.perfects)
		AssertType:is_int(sentData.greats)
		AssertType:is_int(sentData.okays)
		AssertType:is_int(sentData.misses)
		
		local playerID = player.UserId

		sentData.userid = playerID
		sentData.playername = player.Name
		sentData.time = os.time()
		
		local name = getLeaderboardKey(sentData.mapid)
		local suc, err = pcall(function()
				ScoreDatabase:UpdateAsync(name, function(leaderboard)
						leaderboard = leaderboard or {}
						
						--Sort by time: most new first, oldest last
						table.sort(leaderboard, function(a,b)
							return a.time > b.time
						end)
						
						--Insert play as newsest
						table.insert(leaderboard, 1, sentData)
						
						--Remove oldest play
						if #leaderboard > CustomServerSettings.LeaderboardSettings.TrackedPlayCount then
							table.remove(leaderboard, #leaderboard)
						end
						
						--If displaying leaderboard by accuracy, sort it by accuracy before saving
						if CustomServerSettings.LeaderboardSettings.SortByAccuracy then
							table.sort(leaderboard, function(a,b)
								return a.accuracy > b.accuracy
							end)
						end
						
						return leaderboard
				end)
		end)

		if not suc then
				warn(err)
		end
end)

Networking.Server:Register("GetLeaderboard", function(player, request)
		AssertType:is_true(SongDatabase:contains_key(request.mapid))
		
		local name = getLeaderboardKey(request.mapid)

		local lb = {}
		local suc, err = pcall(function()
				lb = ScoreDatabase:GetAsync(name)
		end)

		if not suc then
				warn(err)
		end

		return lb
end)
