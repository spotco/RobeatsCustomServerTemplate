local DataStoreService = game:GetService("DataStoreService")
local ScoreDatabase = DataStoreService:GetDataStore("ScoreDatabase")

local PubSub = require(game.ReplicatedStorage.PubSub)

PubSub.subscribe("SubmitScore", function(player, data)
    local playerID = player.UserId
    data = data or {}

    local submitScore = false
    -- GET THE OLD LEADERBOARD

    local oldLeaderboard = ScoreDatabase:GetAsync("map_"..data.mapid)
    local oldScore = nil

    for i, v in pairs(oldLeaderboard) do
        if v.userid == playerID then
            oldScore = v
        end
    end

    oldScore = oldScore or data

    if oldScore.score < data.score then
        submitScore = true
    end

    if submitScore then
        
    end
end, "ScoreSubmissionServerSubscription")