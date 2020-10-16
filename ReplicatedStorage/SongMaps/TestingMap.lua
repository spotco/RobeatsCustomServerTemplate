local rtv = {}
rtv.AudioAssetId = "rbxassetid://5094154066"
rtv.AudioFilename = "Plasma Gun (Debug)"
rtv.AudioDescription = "Short map to test stuff like score submission."
rtv.AudioCoverImageAssetId = "rbxassetid://698514070"
rtv.AudioArtist = "Memme"
rtv.AudioDifficulty = 1
rtv.AudioTimeOffset = -75
rtv.AudioVolume = 0.5
rtv.AudioNotePrebufferTime = 1500
rtv.AudioMod = 0
rtv.FusionResult = "MondayNightMonsters2"
rtv.AudioHitSFXGroup = 0
rtv.HitObjects = {}
local function note(time,track) rtv.HitObjects[#rtv.HitObjects+1]={Time=time;Type=1;Track=track;} end
local function hold(time,track,duration) rtv.HitObjects[#rtv.HitObjects+1] = {Time=time;Type=2;Track=track;Duration=duration;}  end
--

local did_last = 1

for i = 0, 10000, 150 do
    for t = 1, 4 do
        if did_last ~= t then
            note(i, t)
        end
    end

    did_last = did_last == 4 and 1 or did_last + 1
end

--
rtv.TimingPoints = {
	[1] = { Time = -30; BeatLength = 600; };
};
return rtv
