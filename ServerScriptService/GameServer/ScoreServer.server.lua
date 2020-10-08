local DataStoreService = game:GetService("DataStoreService")
local ScoreDatabase = DataStoreService:GetDataStore("ScoreDatabase")

local HttpService = game:GetService("HttpService")

local scoreTemplate = require(game.ReplicatedStorage.Templates.Gameplay.ScoreTemplate)

local PubSub = require(game.ReplicatedStorage.PubSub)

PubSub.subscribe("SubmitScore", function(player, sentData)
    local playerID = player.UserId

    sentData.userid = playerID

    local data = scoreTemplate:new(sentData)

    local submitScore = false

    local name = "map_"..data.mapid
    -- GET THE OLD LEADERBOARD
    local suc, err = pcall(function()
        ScoreDatabase:UpdateAsync(name, function(leaderboard)
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
end, "ScoreSubmissionServerSubscription")