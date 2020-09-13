local SPList = require(game.ReplicatedStorage.Shared.SPList)
local Track = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.Track)
local GameSlot = require(game.ReplicatedStorage.Shared.GameSlot)
local AutoPlayer = require(game.ReplicatedStorage.RobeatsGameCore.Debug.AutoPlayer)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local NoteResult = require(game.ReplicatedStorage.Shared.NoteResult)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local DebugConfig = require(game.ReplicatedStorage.Shared.DebugConfig)

local TrackSystem = {}

function TrackSystem:new(_game, slot_id)
	local self = {
		_notes = SPList:new();
		_tracks = SPList:new();

		_game_slot = slot_id;

		_auto_player = AutoPlayer:new(_game, slot_id);
	}

	function self:cons()
		--By default, the game has 4 tracks (that are 5 degrees apart)
		local spacing = 5
		self._tracks:push_back(Track:new(self,spacing * 1.5,"Track1",_game,1))
		self._tracks:push_back(Track:new(self,spacing * 0.5,"Track2",_game,2))
		self._tracks:push_back(Track:new(self,spacing * -0.5,"Track3",_game,3))
		self._tracks:push_back(Track:new(self,spacing * -1.5,"Track4",_game,4))
	end

	function self:teardown()
		for i=1,self._notes:count() do
			self._notes:get(i):do_remove()
		end
		self._notes:clear()
		for i=1,self._tracks:count() do
			self._tracks:get(i):teardown()
		end
		self._tracks:clear()
	end

	function self:update(dt_scale,_game)
		if DebugConfig.LocalAutoPlay then
			self._auto_player:update(dt_scale,_game)
		end
		for i=1, self._tracks:count() do
			local itr_track = self._tracks:get(i)
			itr_track:update(dt_scale, _game)
		end

		for i=self._notes:count(),1,-1  do
			local itr_note = self._notes:get(i)

			itr_note:update(dt_scale)

			if itr_note:should_remove() then
				itr_note:do_remove()
				self._notes:remove_at(i)
			end
		end
	end

	function self:get_player_world_center()
		return _game:get_game_environment_center_position()
	end
	function self:get_player_world_position()
		return GameSlot:slot_to_world_position(self._game_slot)
	end
	function self:get_game_slot()
		return self._game_slot
	end
	function self:get_track(index)
		return self._tracks:get(index)
	end

	function self:remote_replicate_hit_result(note_result)
		if _game:get_local_game_slot() == self._game_slot then
			DebugOut:warnf("remote_replicate_hit_result on local track(!!)")
		end

		self._auto_player:enqueue_note_result(note_result)
	end

	function self:press_track_index(_game, track_index)
		self:get_track(track_index):press()
		local hit_found = false

		for i=1,self._notes:count() do
			local itr_note = self._notes:get(i)
			if itr_note:get_track_index() == track_index then
				local did_hit, note_result = itr_note:test_hit()
				if did_hit then
					itr_note:on_hit(note_result,i)
					hit_found = true
					break
				end
			end
		end

		if hit_found == false then
			_game._score_manager:register_hit(
				NoteResult.Miss,
				slot_id,
				track_index,
				{ PlaySFX = true; PlayHoldEffect = false; WhiffMiss = true; }
			)
		end
	end

	function self:release_track_index(_game, track_index)
		self:get_track(track_index):release()

		for i=1,self._notes:count() do
			local itr_note = self._notes:get(i)
			if itr_note:get_track_index() == track_index then
				local did_release, note_result = itr_note:test_release()
				if did_release then
					itr_note:on_release(note_result,i)
					break
				end
			end
		end
	end

	function self:notify_time_miss()
		self._auto_player:notify_time_miss()
	end

	self:cons()
	return self
end

return TrackSystem
