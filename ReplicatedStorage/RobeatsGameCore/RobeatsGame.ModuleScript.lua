local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local InputUtil = require(game.ReplicatedStorage.Shared.InputUtil)
local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local AudioManager = require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local ScoreManager = require(game.ReplicatedStorage.RobeatsGameCore.ScoreManager)
local TrackSystem = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.TrackSystem)
local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local GameSlot = require(game.ReplicatedStorage.Shared.GameSlot)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local RemoteInstancePlayerInfoManager = require(game.ReplicatedStorage.RobeatsGameCore.RemoteInstancePlayerInfoManager)
local ServerGameInstancePlayer = require(game.ReplicatedStorage.Shared.ServerGameInstancePlayer)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)

local RobeatsGame = {}
RobeatsGame.Mode = {
	Setup = 1;
	Game = 2;
	GameEnded = 3;
}

function RobeatsGame:new(local_services, _game_environment_center_position)
	local self = {
		_tracksystems = SPDict:new();
		_audio_manager = nil;
		_score_manager = nil;
		_effects = EffectSystem:new();
		_players = RemoteInstancePlayerInfoManager:new();
		_input = local_services._input;
		_sfx_manager = local_services._sfx_manager;
		_object_pool = local_services._object_pool;
	}
	self._audio_manager = AudioManager:new(self)
	self._score_manager = ScoreManager:new(self)
	
	local _local_game_slot = 0
	function self:get_local_game_slot() return _local_game_slot end
	
	local _current_mode = RobeatsGame.Mode.Setup
	function self:get_mode() return _current_mode end
	function self:set_mode(val) 
		AssertType:is_enum_member(val, RobeatsGame.Mode)
		_current_mode = val 
	end

	function self:get_game_environment_center_position()
		return _game_environment_center_position
	end

	function self:setup_world(game_slot)
		_local_game_slot = game_slot
		GameSlot:set_world_center_position(self:get_game_environment_center_position())
		workspace.CurrentCamera.CFrame = GameSlot:slot_to_camera_cframe(self:get_local_game_slot())
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		workspace.CurrentCamera.CameraSubject = nil
	end

	function self:start_game()
		self._players._slots:add(1, ServerGameInstancePlayer:new(1,"Test"))
		self._tracksystems:add(1,TrackSystem:new(self,1))
		self._audio_manager:start_play()
		_current_mode = RobeatsGame.Mode.Game
	end

	function self:get_tracksystem(index)
		return self._tracksystems:get(index)
	end
	function self:get_local_tracksystem()
		return self:get_tracksystem(self:get_local_game_slot())
	end
	function self:tracksystems_itr()
		return self._tracksystems:key_itr()
	end

	local _key_to_track_index = SPDict:new():add_table({
		[InputUtil.KEY_TRACK1] = 1;
		[InputUtil.KEY_TRACK2] = 2;
		[InputUtil.KEY_TRACK3] = 3;
		[InputUtil.KEY_TRACK4] = 4;
	})

	function self:update(dt_scale)
		if _current_mode == RobeatsGame.Mode.Game then
			self._audio_manager:update(dt_scale,self)
			for itr_key,itr_index in _key_to_track_index:key_itr() do
				if self._input:control_just_pressed(itr_key) then
					self:get_local_tracksystem():press_track_index(self,itr_index)
				end
				if self._input:control_just_released(itr_key) then
					self:get_local_tracksystem():release_track_index(self,itr_index)
				end
			end
			
			for slot,itr in self._tracksystems:key_itr() do
				itr:update(dt_scale,self)
			end
			
			self._effects:update(dt_scale,self)
			self._score_manager:update(dt_scale,self)
			
			self._score_manager:post_update()
		end
	end
	
	function self:teardown()
		for key,val in self:tracksystems_itr() do
			val:teardown()
		end
		self._audio_manager:teardown()
		self._effects:teardown()
	end

	return self
end

return RobeatsGame
