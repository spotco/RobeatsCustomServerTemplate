local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPList = require(game.ReplicatedStorage.Shared.SPList)
local NoteResult = require(game.ReplicatedStorage.Shared.NoteResult)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local DebugConfig = require(game.ReplicatedStorage.Shared.DebugConfig)

local SingleNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.SingleNote)
local HeldNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.HeldNote)

local AutoPlayer = {}

function AutoPlayer:new(_game, game_slot)
	local self = {}

	local _held_tracks = SPDict:new()
	local _enqueued_results = SPList:new()

	function self:cons()
		for i=1,4 do
			_held_tracks:add(i, false)
		end
	end

	function self:update(dt_scale,_game)
		if DebugConfig.LocalAutoPlay ~= true and _game:get_local_game_slot() == game_slot then
			return
		end

		local parent_tracksystem = _game:get_tracksystem(game_slot)
		local parent_tracksystem_notes = parent_tracksystem._notes

		for i=1,parent_tracksystem_notes:count() do
			local itr_note = parent_tracksystem_notes:get(i)
			local itr_note_track = itr_note:get_track_index(i)

			if _held_tracks:get(itr_note_track) == false then
				local did_hit, note_result = itr_note:test_hit(_game)

				if self:accept_note_result(did_hit, note_result) then
					parent_tracksystem:press_track_index(_game,itr_note_track)

					if itr_note.ClassName == HeldNote.Type then
						_held_tracks:add(itr_note_track,true)
					else
						parent_tracksystem:release_track_index(_game,itr_note_track)
					end
				end

			else
				local did_release, note_result = itr_note:test_release(_game)

				if self:accept_note_result(did_release, note_result) then
					_held_tracks:add(itr_note_track,false)
					parent_tracksystem:release_track_index(_game,itr_note_track)
				end
			end
		end
	end

	local __randomized_accept_rand = SPUtil:rand_rangei(1,4)
	local function update_accept_rand()
		__randomized_accept_rand = SPUtil:rand_rangei(0,4)
	end

	function self:randomized_accept_note(did_hit, note_result)
		local rtv = false
		if __randomized_accept_rand == 0 then
			rtv = false
		elseif __randomized_accept_rand == 1 then
			rtv = note_result == NoteResult.Okay
		elseif __randomized_accept_rand == 2 then
			rtv = note_result == NoteResult.Great
		else
			rtv = note_result == NoteResult.Perfect
		end
		if rtv == true then
			update_accept_rand()
		end
		return rtv
	end

	function self:notify_time_miss()
		if DebugConfig.LocalAutoPlay ~= true and _game:get_local_game_slot() == game_slot then
			return
		end

		update_accept_rand()

		if _enqueued_results:count() > 0 and _enqueued_results:get(1) == NoteResult.Miss then
			_enqueued_results:pop_front()
		end

		local parent_tracksystem = _game:get_tracksystem(game_slot)
		for i=1,4 do
			parent_tracksystem:release_track_index(_game,i)
			_held_tracks:add(i,false)
		end
	end

	function self:accept_note_result(did_hit, note_result)

		if DebugConfig.LocalAutoPlay == true and _game:get_local_game_slot() == game_slot then
			if DebugConfig.PerfectAutoPlay == true then
				return note_result == NoteResult.Perfect
			else
				return self:randomized_accept_note(did_hit, note_result)
			end

		end

		if _enqueued_results:count() == 0 then
			if _game._players._slots:contains(game_slot) then
				local player = _game._players._slots:get(game_slot)

				if player._chain > 10 then
					return note_result == NoteResult.Perfect
				elseif player._chain < 4 then
					return false
				else
					return self:randomized_accept_note(did_hit, note_result)
				end

			else
				DebugOut:warnf("AutoPlayer slot(%d) testing hit note for nonexistant player",game_slot)
				return note_result == NoteResult.Perfect
			end
		end

		local top_result = _enqueued_results:get(1)
		if top_result == NoteResult.Miss then
			return false
		else
			if note_result >= top_result then
				_enqueued_results:pop_front()
				return true
			else
				return false
			end
		end
	end

	function self:enqueue_note_result(note_result)
		_enqueued_results:push_back(note_result)
	end

	self:cons()
	return self
end

return AutoPlayer
