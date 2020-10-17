local rtv = {}
rtv.AudioAssetId = "rbxassetid://654442447"
rtv.AudioFilename = "Welcome to Monday Night (Debug)"
rtv.AudioDescription = "Short map to test stuff like score submission."
rtv.AudioCoverImageAssetId = "rbxasset://textures/ui/GuiImagePlaceholder.png"
rtv.AudioArtist = ""
rtv.AudioDifficulty = 1
rtv.AudioTimeOffset = -75
rtv.AudioVolume = 0.5
rtv.AudioNotePrebufferTime = 1500
rtv.AudioMod = 0
rtv.AudioHitSFXGroup = 0
rtv.HitObjects = {}
local function note(time,track) rtv.HitObjects[#rtv.HitObjects+1]={Time=time;Type=1;Track=track;} end
local function hold(time,track,duration) rtv.HitObjects[#rtv.HitObjects+1] = {Time=time;Type=2;Track=track;Duration=duration;}	end
do
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 0; Type = 1; Track = 1; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 0; Type = 1; Track = 2; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 500; Type = 1; Track = 1; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 500; Type = 1; Track = 3; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 1000; Type = 1; Track = 1; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 1000; Type = 1; Track = 3; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 1500; Type = 1; Track = 1; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 1500; Type = 1; Track = 4; } --#0
	rtv.HitObjects[#rtv.HitObjects + 1] = { Time = 12000; Type = 1; Track = 4; } --#0
end
rtv.TimingPoints = {
	[1] = { Time = 0; BeatLength = 500; };
};
return rtv
