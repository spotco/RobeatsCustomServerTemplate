local DataStoreService = game:GetService("DataStoreService")
local ScoreDatabase = DataStoreService:GetDataStore("ScoreDatabase")

local HttpService = game:GetService("HttpService")

local scoreTemplate = require(game.ReplicatedStorage.Templates.Gameplay.ScoreTemplate)

local Networking = require(game.ReplicatedStorage.Networking)

function submitScore(player, sentData)
		local playerID = player.UserId

		sentData.userid = playerID
		sentData.playername = player.Name

		local data = scoreTemplate:new(sentData)

		local submitScore = false

		local name = "map_"..data.mapid
		-- GET THE OLD LEADERBOARD
		local suc, err = pcall(function()
				ScoreDatabase:UpdateAsync(name, function(leaderboard)
						leaderboard = leaderboard or {}

						local oldScore = nil

						for i, v in pairs(leaderboard) do
								if v.userid == playerID then
										oldScore = v
								end
						end

						oldScore = oldScore or data

						if (oldScore.accuracy <= data.accuracy) then
								submitScore = true
						end

						if submitScore then
								for i, v in pairs(leaderboard) do
										if v.userid == playerID then
												leaderboard[i] = nil
										end
								end
								leaderboard[#leaderboard+1] = data
						end

						return leaderboard
				end)
		end)

		if not suc then
				warn(err)
		end
end

function getLeaderboard(player, request)
		local name = "map_"..request.mapid

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
