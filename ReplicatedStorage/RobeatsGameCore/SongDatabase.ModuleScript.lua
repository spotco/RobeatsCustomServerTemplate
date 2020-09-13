local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SongErrorParser = require(game.ReplicatedStorage.RobeatsGameCore.SongErrorParser)

local SongMapList = require(game.Workspace.SongMapList)

local SongDatabase = {}

SongDatabase.MOD_NORMAL = 0
SongDatabase.MOD_HARDMODE = 1

function SongDatabase:new()
	local self = {}

	local _all_keys = SPDict:new()
	local _key_list = SPList:new()
	local _name_to_key = SPDict:new()
	local _key_to_fusionresult = SPDict:new()

	function self:cons()
		for i=1,#SongMapList do
			local audio_data = require(SongMapList[i])
			SongErrorParser:scan_audiodata_for_errors(audio_data)
			self:add_key_to_data(i,audio_data)
			_name_to_key:add(SongMapList[i].Name,i)
		end
	end

	function self:add_key_to_data(key,data)
		if _all_keys:contains(key) then
			error("SongDatabase:add_key_to_data duplicate",key)
		end
		_all_keys:add(key,data)
		data.__key = key
		_key_list:push_back(key)
	end

	function self:all_keys()
		return _key_list
	end

	function self:get_data_for_key(key)
		return _all_keys:get(key)
	end

	function self:contains_key(key)
		return _all_keys:contains(key)
	end

	function self:key_get_audiomod(key)
		local data = self:get_data_for_key(key)
		if data.AudioMod == 1 then
			return SongDatabase.MOD_HARDMODE
		end
		return SongDatabase.MOD_NORMAL
	end

	function self:render_coverimage_for_key(cover_image, overlay_image, key)
		local songdata = self:get_data_for_key(key)
		cover_image.Image = songdata.AudioCoverImageAssetId

		local audiomod = self:key_get_audiomod(key)
		if audiomod == SongDatabase.MOD_HARDMODE then
			overlay_image.Image = "rbxgameasset://Images/COVER_hardmode_overlay"
			overlay_image.Visible = true
		else
			overlay_image.Image = "rbxgameasset://Images/COVER_hardmode_overlay"
			overlay_image.Visible = false
		end
	end

	function self:get_title_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioFilename
	end

	function self:get_artist_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioArtist
	end

	function self:get_difficulty_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioDifficulty
	end

	function self:get_description_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioDescription
	end

	self:cons()
	return self
end

local _singleton = SongDatabase:new()
function SongDatabase:singleton()
	return _singleton
end

return SongDatabase
