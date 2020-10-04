local Template = require(game.ReplicatedStorage.Templates.Template)
local ScoreTemplate = Template:new({
    mapid = 0;
    score = 0;
    accuracy = 0;
    maxcombo = 0;
    perfects = 0;
    greats = 0;
    okays = 0;
    misses = 0;
})

return ScoreTemplate
