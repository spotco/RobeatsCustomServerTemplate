--[[
1. Convert your .osu files into a lua file.
	Do this in your browser at: [https://spotco.github.io/RobeatsWebConvert2/]
	
2. Fill in the value for [rtv.AudioAssetId] with assetid of the audio you used (format: rbxassetid://...)
	
3. Create a ModuleScript for your new song map (We recommend putting it in Workspace.SongMaps)

4. Link the ModuleScript for the map you created in Workspace.SongMapList

5. Set rtv.AudioNotePrebufferTime in your song map to set note speed (1500 is 1.5 seconds).

Next steps:
- Make this server your own! Fill in CreatorName and SupporterGamepassID in Workspace.CustomServerSettings
- Modify the menus! The menus are located under StarterGui.MenuProtos
- Check out the code! To get started, check StarterPlayer.StarterPlayerScripts.LocalMain. most of the code is in ReplicatedStorage.
- If you like using rojo, download the source code from github: https://github.com/spotco/RobeatsCustomServerTemplate
]]--
return nil