local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteBase = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.NoteBase)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local HoldingNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local TriggerNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.TriggerNoteEffect)

local NOTE_HEIGHT = 1.5

local SingleNote = {}
SingleNote.Type = "SingleNote"

SingleNote.State = {
	Pre = 0;
	DoRemove = 1;
}

local _outline_top_position_offset = Vector3.new()
local _outline_bottom_position_offset = Vector3.new()

function SingleNote:new(_game, track_index, slot_index, creation_time_ms, hit_time_ms)
	local self = NoteBase:NoteBase()
	self.ClassName = SingleNote.Type

	self._state = SingleNote.State.Pre

	local _note_obj = nil
	local _body = nil
	local _outline_top = nil
	local _outline_bottom = nil
	local _outline_top_initial_size = nil
	local _outline_bottom_initial_size = nil
	local _t = 0
	local _track_index = track_index
	local _position = Vector3.new()

	local _body_adorn, _outline_top_adorn, _outline_bottom_adorn

	local function is_local_slot()
		return slot_index == _game:get_local_game_slot()
	end

	local function get_start_position()
		return _game:get_tracksystem(slot_index):get_track(track_index):get_start_position()
	end
	local function get_end_position()
		return _game:get_tracksystem(slot_index):get_track(track_index):get_end_position()
	end

	local function update_visual_for_t(t)
		_position = SPUtil:vec3_lerp(
			get_start_position(),
			get_end_position(),
			t
		)
		_position = Vector3.new(
			_position.X,
			0.25 + _game:get_game_environment_center_position().Y,
			_position.Z
		)

		local size = CurveUtil:YForPointOf2PtLine(
			Vector2.new(0,0.25),
			Vector2.new(1,0.925),
			SPUtil:clamp(t,0,1)
		)

		_body_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(_position))
		_body_adorn.Height = size * 1.5
		_body_adorn.Radius = size * 1.5

		_outline_bottom_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(
			_position + (_outline_bottom_position_offset * size)
		))
		_outline_bottom_adorn.Height = size * 0.5
		_outline_bottom_adorn.Radius = size * 1.6

		_outline_top_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(
			_position + (_outline_top_position_offset * size)
		))
		_outline_top_adorn.Height = size * 0.25
		_outline_top_adorn.Radius = size * 1.6

		_body_adorn.Color3 = self:color3_for_slot(slot_index)
	end

	function self:cons()
		_note_obj = _game._object_pool:depool(self.ClassName)
		if _note_obj == nil then
			_note_obj = EnvironmentSetup:get_element_protos_folder().NoteAdornProto:Clone()
			_outline_top_position_offset = _note_obj.OutlineTop.Position - _note_obj.PrimaryPart.Position
			_outline_bottom_position_offset = _note_obj.OutlineBottom.Position - _note_obj.PrimaryPart.Position

			_note_obj.Body.CFrame = (CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Body))
			_note_obj.OutlineTop.CFrame = (CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.OutlineTop))
			_note_obj.OutlineBottom.CFrame = (CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.OutlineBottom))
		end

		_body = _note_obj.Body
		_outline_top = _note_obj.OutlineTop
		_outline_bottom = _note_obj.OutlineBottom
		_body_adorn = _body.Adorn
		_outline_top_adorn = _outline_top.Adorn
		_outline_bottom_adorn = _outline_bottom.Adorn

		_outline_top_initial_size = _outline_top.Size
		_outline_bottom_initial_size = _outline_bottom.Size

		_t = 0
		update_visual_for_t(_t)

		_note_obj.Parent = EnvironmentSetup:get_local_elements_folder()
	end

	local _dt_scale_sum = 0
	--[[Override--]] function self:update(dt_scale)
		if self._state == SingleNote.State.Pre then
			_t = (_game._audio_manager:get_current_time_ms() - creation_time_ms) / (hit_time_ms - creation_time_ms)

			if slot_index == _game:get_local_game_slot() then
				update_visual_for_t(_t)
			else
				_dt_scale_sum = _dt_scale_sum + dt_scale
				if _game:get_frame_count() % 4 == (slot_index - 1) % 4 then
					update_visual_for_t(_t)
					_dt_scale_sum = 0
				end
			end

			if self:should_remove(_game) then
				_game._score_manager:register_hit(
					NoteResult.Miss,
					slot_index,
					track_index,
					{ PlaySFX = false; PlayHoldEffect = false; TimeMiss = true; }
				)
			end
		end
	end

	--[[Override--]] function self:should_remove()
		return self._state == SingleNote.State.DoRemove or self:get_time_to_end() < _game._audio_manager.NOTE_REMOVE_TIME
	end

	--[[Override--]] function self:do_remove()
		if is_local_slot() then
			_game._effects:add_effect(HoldingNoteEffect:new(
				_game,
				_note_obj.PrimaryPart.Position,
				NoteResult.Okay
			))
		end
		_game._object_pool:repool(self.ClassName,_note_obj)
		_note_obj = nil
	end

	--[[Override--]] function self:test_hit()
		local time_to_end = self:get_time_to_end()
		local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

		if did_hit then
			return did_hit, note_result
		end

		return false, NoteResult.Miss
	end

	--[[Override--]] function self:on_hit(note_result, i_notes)
		_game._effects:add_effect(TriggerNoteEffect:new(
			_game,
			self:get_position(),
			note_result,
			is_local_slot()
		))

		_game._score_manager:register_hit(
			note_result,
			slot_index,
			track_index,
			{ PlaySFX = true; PlayHoldEffect = true; HoldEffectPosition = self:get_position(); }
		)

		self._state = SingleNote.State.DoRemove
	end

	--[[Override--]] function self:test_release()
		return false, NoteResult.Miss
	end
	--[[Override--]] function self:on_release(note_result,i_notes)
	end
	--[[Override--]] function self:get_track_index()
		return _track_index
	end

	function self:get_time_to_end()
		return (hit_time_ms - creation_time_ms) * (1 - _t)
	end

	function self:get_position()
		return _position
	end

	self:cons()
	return self
end

return SingleNote
