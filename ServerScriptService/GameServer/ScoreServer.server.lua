local DataStoreService = game:GetService("DataStoreService")
local ScoreDatabase = DataStoreService:GetDataStore("ScoreDatabase")

local HttpService = game:GetService("HttpService")

local Networking = require(game.ReplicatedStorage.Networking)

local function getLeaderboardKey(mapid)
	return string.format("map_%s", tostring(mapid))
end

function submitScore(player, sentData)
		local playerID = player.UserId

		sentData.userid = playerID
		sentData.playername = player.Name
		sentData.time = os.time()

		local submitScore = false

		local name = getLeaderboardKey(sentData.mapid)
		local suc, err = pcall(function()
				ScoreDatabase:UpdateAsync(name, function(leaderboard)
						leaderboard = leaderboard or {}
						table.insert(leaderboard, 1, sentData)
						local LEADERBOARD_TRACKED_PLAY_COUNT = 20
						--Keep track of last 20 plays
						if #leaderboard > LEADERBOARD_TRACKED_PLAY_COUNT then
							table.remove(leaderboard, #leaderboard)
						end
						return leaderboard
				end)
		end)

		if not suc then
				warn(err)
		end
end

function getLeaderboard(player, request)
		local name = getLeaderboardKey(request.mapid)

		local lb = {}
		local suc, err = pcall(function()
				lb = ScoreDatabase:GetAsync(name)
		end)

		if not suc then
				warn(err)
		end

		return lb
end

Networking.Server:Register("SubmitScore", submitScore)
Networking.Server:Register("GetLeaderboard", getLeaderboard)
