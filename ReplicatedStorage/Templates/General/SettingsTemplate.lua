local Template = require(game.ReplicatedStorage.Templates.Template)
local ScoreTemplate = Template:new({
    AudioOffset = 0;
    CreatorName = "<your name here>";
    NoteGreatMaxMS = 140;
    NoteGreatMinMS = -70;
    NoteOkayMaxMS = 260;
    NoteOkayMinMS = -140;
    NotePerfectMaxMS = 40;
    NotePerfectMinMS = -20;
    NoteRemoveTimeMS = -200;
    NoteSpeedMultiplier = 1;
    PostFinishWaitTimeMS = 300;
    PreStartCountdownTimeMS = 3000;
    SupporterGamepassID = 11742318;
    Keybinds = {
        Enum.KeyCode.Q,
        Enum.KeyCode.W,
        Enum.KeyCode.O,
        Enum.KeyCode.P
    };
    NoteColor = Color3.new(0,0,0)
})

return ScoreTemplate
