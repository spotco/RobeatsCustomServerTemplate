--[[
1. Convert your .osu files into a lua file.
	Do this in your browser at: [https://spotco.github.io/RobeatsWebConvert2/]
	
2. Place the converted lua into [game.Workspace.SongMap]

3. Fill in the value for [rtv.AudioAssetId]

4. Set [game.Workspace.AutoPlay.Value] to true if you want the song to be auto-played

5. Set rtv.AudioNotePrebufferTime in game.Workspace.SongMap to set note speed.

]]--
return nil