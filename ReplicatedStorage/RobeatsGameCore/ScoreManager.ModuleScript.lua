local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local InputUtil = require(game.ReplicatedStorage.Shared.InputUtil)
local NoteResultPopupEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.NoteResultPopupEffect)
local HoldingNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local DebugConfig = require(game.ReplicatedStorage.Shared.DebugConfig)

local ScoreManager = {}

function ScoreManager:new(_game)
	local self = {}
	
	local _chain = 0

	local _perfect_count = 0
	local _great_count = 0
	local _ok_count = 0
	local _miss_count = 0
	local _max_chain = 0
	function self:get_end_records() return _perfect_count,_great_count,_ok_count,_miss_count,_max_chain end
	function self:get_accuracy()
		local total_count = _game._audio_manager:get_note_count() + _miss_count
		return ((_perfect_count * 1.0) + (_great_count * 0.75) + (_ok_count * 0.25)) / total_count
	end

	local _raise_chain_broken = false
	local _raise_chain_broken_at = 0
	local _last_created_note_result_popup_info = {
		Slot = 0;
		Track = 0;
	}
	local _last_created_note_result_popup_effect = nil

	local _local_note_count = 0
	function self:get_local_note_count() return _local_note_count end

	local _frame_has_played_sfx = false

	function self:register_hit(
		note_result,
		slot_index,
		track_index,
		params
	)
		if params == nil then
			params = { }
		end
		if params.PlaySFX == nil then params.PlaySFX = true; end
		if params.PlayHoldEffect == nil then params.PlayHoldEffect = true; end
		if params.HoldEffectPosition == nil then params.HoldEffectPosition = _game:get_tracksystem(slot_index):get_track(track_index):get_end_position(); end

		if _last_created_note_result_popup_effect ~= nil then
			if slot_index == _last_created_note_result_popup_info.Slot and
				track_index == _last_created_note_result_popup_info.Track and
				note_result == NoteResult.Miss then

				_last_created_note_result_popup_effect._anim_t = 1
				_last_created_note_result_popup_effect = nil
			end
		end

		if slot_index ~= _game:get_local_game_slot() then
			return
		end

		if not params.WhiffMiss then
			_local_note_count = _local_note_count + 1
		end
		
		local track = _game:get_tracksystem(slot_index):get_track(track_index)
		_last_created_note_result_popup_effect = _game._effects:add_effect(NoteResultPopupEffect:new(
			_game,
			track:get_end_position() + Vector3.new(0,0.25,0),
			note_result
		))
		_last_created_note_result_popup_info.Slot = slot_index
		_last_created_note_result_popup_info.Track = track_index

		if params.PlaySFX == true then
			if _frame_has_played_sfx == false then
				if note_result == NoteResult.Perfect then
					if params.IsHeldNoteBegin == true then
						_game._audio_manager._hit_sfx_group:play_first()
					else
						_game._audio_manager._hit_sfx_group:play_alternating()
					end

				elseif note_result == NoteResult.Great then
					_game._audio_manager._hit_sfx_group:play_first()
				elseif note_result == NoteResult.Okay then
					_game._sfx_manager:play_sfx(SFXManager.SFX_DRUM_OKAY)
				else
					_game._sfx_manager:play_sfx(SFXManager.SFX_MISS)
				end
				_frame_has_played_sfx = true
			end

			if params.PlayHoldEffect then
				if note_result ~= NoteResult.Miss then
					_game._effects:add_effect(HoldingNoteEffect:new(
						_game,
						params.HoldEffectPosition,
						note_result
					))
				end
			end
		end

		_max_chain = math.max(_chain,_max_chain)

		if note_result == NoteResult.Perfect then
			_chain = _chain + 1
			_perfect_count = _perfect_count + 1

		elseif note_result == NoteResult.Great then
			_chain = _chain + 1
			_great_count = _great_count + 1

		elseif note_result == NoteResult.Okay then
			_ok_count = _ok_count + 1

		else
			if _chain > 0 then
				_raise_chain_broken = true
				_raise_chain_broken_at = _chain
				_chain = 0
				_miss_count = _miss_count + 1

			elseif params.TimeMiss == true then
				_miss_count = _miss_count + 1
			end
		end
		
	end

	function self:get_chain()
		return _chain
	end

	function self:post_update()
		_raise_chain_broken = false
		_frame_has_played_sfx = false
	end

	function self:get_chain_broken()
		return _raise_chain_broken, _raise_chain_broken_at
	end

	function self:update(dt_scale)
		if _last_created_note_result_popup_effect ~= nil then
			if _last_created_note_result_popup_effect:get_anim_t() > 0.25 then
				_last_created_note_result_popup_effect = nil
			end
		end
	end

	return self
end

return ScoreManager
