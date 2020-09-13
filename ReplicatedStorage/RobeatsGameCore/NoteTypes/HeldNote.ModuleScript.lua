local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteBase = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.NoteBase)
local NoteResult = require(game.ReplicatedStorage.Shared.NoteResult)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local TriggerNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.TriggerNoteEffect)
local HoldingNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local FlashEvery = require(game.ReplicatedStorage.Shared.FlashEvery)

local SPList = require(game.ReplicatedStorage.Shared.SPList)

local HeldNote = {}
HeldNote.Type = "HeldNote"

HeldNote.State = {
	Pre = 0;
	Holding = 1;
	HoldMissedActive = 2;
	Passed = 3;
	DoRemove = 4;
}

function HeldNote:new(
	_game,
	track_index,
	slot_index,
	creation_time_ms,
	hit_time_ms,
	duration_time_ms
)
	local self = NoteBase:NoteBase()
	self.ClassName = HeldNote.Type

	local _note_obj = nil

	local _body = nil
	local _head = nil
	local _tail = nil
	local _head_outline = nil
	local _tail_outline = nil
	local _body_outline_left = nil
	local _body_outline_right = nil
	local _body_adorn, _head_adorn, _tail_adorn, _head_outline_adorn, _tail_outline_adorn, _body_outline_left_adorn, _body_outline_right_adorn

	local _game_audio_manager_get_current_time_ms = 0

	local _track_index = track_index

	local _state = HeldNote.State.Pre
	local _did_trigger_head = false
	local _did_trigger_tail = false

	local function is_local_slot()
		return slot_index == _game:get_local_game_slot()
	end

	local __get_start_position = nil
	local function get_start_position()
		if __get_start_position == nil then
			__get_start_position = _game:get_tracksystem(slot_index):get_track(track_index):get_start_position()
		end
		return __get_start_position
	end
	local __get_end_position = nil
	local function get_end_position()
		if __get_end_position == nil then
			__get_end_position = _game:get_tracksystem(slot_index):get_track(track_index):get_end_position()
		end
		return __get_end_position
	end
	local function get_head_position()
		return SPUtil:vec3_lerp(
			get_start_position(),
			get_end_position(),
			(_game_audio_manager_get_current_time_ms - creation_time_ms) / (hit_time_ms - creation_time_ms)
		)
	end
	local function get_tail_hit_time()
		return hit_time_ms + duration_time_ms
	end
	local function tail_visible()
		return not (get_tail_hit_time() > _game_audio_manager_get_current_time_ms + _game._audio_manager:get_note_prebuffer_time_ms())
	end
	local function get_tail_t()
		local tail_show_time = _game_audio_manager_get_current_time_ms - get_tail_hit_time() + _game._audio_manager:get_note_prebuffer_time_ms()
		return tail_show_time / _game._audio_manager:get_note_prebuffer_time_ms()
	end
	local function get_tail_position()
		if not tail_visible() then
			return get_start_position()
		else
			local tail_t = get_tail_t()
			return SPUtil:vec3_lerp(
				get_start_position(),
				get_end_position(),
				tail_t
			)
		end
	end

	local _i_update_visual = -1
	local function update_visual(dt_scale)
		local tar_color3 = self:color3_for_slot(slot_index)
		_body_adorn.Color3 = tar_color3
		_head_adorn.Color3 = tar_color3
		_tail_adorn.Color3 = tar_color3

		local head_pos = get_head_position()
		local tail_pos = get_tail_position()

		_head_adorn.CFrame = CFrame.new(_head.CFrame:vectorToObjectSpace(head_pos)) + Vector3.new(0,-0.35,0)
		_tail_adorn.CFrame = CFrame.new(_tail.CFrame:vectorToObjectSpace(tail_pos)) + Vector3.new(0,-0.35,0)

		_head_outline_adorn.CFrame = CFrame.new(_head_outline.CFrame:vectorToObjectSpace(head_pos + Vector3.new(0,-0.65)))
		_tail_outline_adorn.CFrame = CFrame.new(_tail_outline.CFrame:vectorToObjectSpace(tail_pos + Vector3.new(0,-0.65)))

		if _did_trigger_head then
			if _game_audio_manager_get_current_time_ms > hit_time_ms then
				head_pos = get_end_position()
			end
		end

		local tail_to_head = head_pos - tail_pos

		if _state == HeldNote.State.Pre then
			_head_adorn.Transparency = 0
			_head_outline_adorn.Transparency = 0
		else
			_head_adorn.Transparency = 1
			_head_outline_adorn.Transparency = 1
		end

		if _state == HeldNote.State.Passed and _did_trigger_tail then
			_tail_adorn.Transparency = 1
			_tail_outline_adorn.Transparency = 1
		else
			if tail_visible() then
				_tail_adorn.Transparency = 0
				_tail_outline_adorn.Transparency = 0
			else
				_tail_adorn.Transparency = 1
				_tail_outline_adorn.Transparency = 1
			end
		end

		local head_t = (_game_audio_manager_get_current_time_ms - creation_time_ms) / (hit_time_ms - creation_time_ms)

		do
			_note_obj.Body:SetPrimaryPartCFrame(
				CFrame.Angles(0, SPUtil:deg_to_rad(SPUtil:dir_ang_deg(tail_to_head.x,-tail_to_head.z) + 90), 0)
			)

			local body_pos = (tail_to_head * 0.5) + tail_pos
			_body_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(body_pos) + Vector3.new(0,-0.35,0))

			local body_size = CurveUtil:YForPointOf2PtLine(
				Vector2.new(0,0.25),
				Vector2.new(1,0.65),
				SPUtil:clamp(head_t,0,1)
			)
			local body_radius = body_size * 0.75

			_body_adorn.Height = tail_to_head.magnitude
			_body_adorn.Radius = body_radius

			_body_outline_left_adorn.CFrame = CFrame.new(_body_outline_left.CFrame:vectorToObjectSpace(
				body_pos
			) + Vector3.new(-body_radius * 1.15,-0.5,0))
			_body_outline_right_adorn.CFrame = CFrame.new(_body_outline_right.CFrame:vectorToObjectSpace(
				body_pos
			) + Vector3.new(body_radius * 1.15,-0.5,0))

			_body_outline_left_adorn.Height = _body_adorn.Height
			_body_outline_right_adorn.Height = _body_adorn.Height
			_body_outline_left_adorn.Radius = body_size * 0.1
			_body_outline_right_adorn.Radius = body_size * 0.1
		end

		do
			local head_size = CurveUtil:YForPointOf2PtLine(
				Vector2.new(0,1.15 / 3.0),
				Vector2.new(1,2.55 / 3.0),
				SPUtil:clamp(head_t,0,1)
			)
			local tail_size = CurveUtil:YForPointOf2PtLine(
				Vector2.new(0,1.15 / 3.0),
				Vector2.new(1,2.55 / 3.0),
				SPUtil:clamp(get_tail_t(),0,1)
			)

			_head_adorn.Radius = 1.450 * head_size
			_tail_adorn.Radius = 1.450 * tail_size

			_head_outline_adorn.Radius = 1.65 * head_size
			_tail_outline_adorn.Radius = 1.65 * tail_size
		end

		_i_update_visual = _i_update_visual + 1
		if _i_update_visual > 3 then
			_i_update_visual = 0
		end

		local target_transparency = 0
		local imm = false
		if _state == HeldNote.State.HoldMissedActive then
			target_transparency = 0.9
			_body_outline_left_adorn.Transparency = 1
			_body_outline_right_adorn.Transparency = 1

		elseif _state == HeldNote.State.Passed and _did_trigger_tail then
			target_transparency = 1
			imm = true
			_body_outline_left_adorn.Transparency = 1
			_body_outline_right_adorn.Transparency = 1

		else
			target_transparency = 0
			_body_outline_left_adorn.Transparency = 0
			_body_outline_right_adorn.Transparency = 0
		end

		if imm then
			_body_adorn.Transparency = target_transparency
		else
			_body_adorn.Transparency = CurveUtil:Expt(
				_body_adorn.Transparency,
				target_transparency,
				CurveUtil:NormalizedDefaultExptValueInSeconds(0.15),
				dt_scale
			)
		end

	end

	function self:cons()
		_game_audio_manager_get_current_time_ms = _game._audio_manager:get_current_time_ms()
		_note_obj = _game._object_pool:depool(self.ClassName)
		if _note_obj == nil then
			_note_obj = EnvironmentSetup:get_element_protos_folder().HeldNoteAdornProto:Clone()
			_note_obj.Body:SetPrimaryPartCFrame(CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Body.PrimaryPart))
			_note_obj.Body.BodyOutlineLeft.CFrame = _note_obj.Body.PrimaryPart.CFrame
			_note_obj.Body.BodyOutlineRight.CFrame = _note_obj.Body.PrimaryPart.CFrame
			_note_obj.Head:SetPrimaryPartCFrame(CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Head.PrimaryPart))
			_note_obj.Tail:SetPrimaryPartCFrame(CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Tail.PrimaryPart))
		end

		_body = _note_obj.Body.Body
		_body_adorn = _body.Adorn
		_head = _note_obj.Head.Head
		_head_adorn = _head.Adorn
		_tail = _note_obj.Tail.Tail
		_tail_adorn = _tail.Adorn
		_head_outline = _note_obj.Head.HeadOutline
		_head_outline_adorn = _head_outline.Adorn
		_tail_outline = _note_obj.Tail.TailOutline
		_tail_outline_adorn = _tail_outline.Adorn
		_body_outline_left = _note_obj.Body.BodyOutlineLeft
		_body_outline_left_adorn = _body_outline_left.Adorn
		_body_outline_right = _note_obj.Body.BodyOutlineRight
		_body_outline_right_adorn = _body_outline_right.Adorn

		_state = HeldNote.State.Pre
		update_visual(1)
		_note_obj.Parent = EnvironmentSetup:get_local_elements_folder()
	end

	local _hold_flash = FlashEvery:new(0.15)
	_hold_flash:flash_now()
	local _dt_scale_sum = 0
	local _has_notified_held_note_begin = false

	--[[Override--]] function self:update(dt_scale)
		_game_audio_manager_get_current_time_ms = _game._audio_manager:get_current_time_ms()
		
		if slot_index == _game:get_local_game_slot() then
			update_visual(dt_scale)
		else
			_dt_scale_sum = _dt_scale_sum + dt_scale
			if _game:get_frame_count() % 4 == (slot_index - 1) % 4 then
				update_visual(_dt_scale_sum)
				_dt_scale_sum = 0
			end
		end

		if _has_notified_held_note_begin == false then
			if hit_time_ms < _game_audio_manager_get_current_time_ms then
				_game._audio_manager:notify_held_note_begin(hit_time_ms)
				_has_notified_held_note_begin = true
			end
		end

		if _state == HeldNote.State.Pre then
			if _game_audio_manager_get_current_time_ms > (hit_time_ms - _game._audio_manager.NOTE_REMOVE_TIME) then
				_game._score_manager:register_hit(
					NoteResult.Miss,
					slot_index,
					_track_index,
					{ PlaySFX = false; PlayHoldEffect = false; TimeMiss = true; }
				)

				if is_local_slot() then
					_game._effects:add_effect(HoldingNoteEffect:new(
						_game,
						get_head_position(),
						NoteResult.Okay
					))
				end

				_state = HeldNote.State.HoldMissedActive

			end

		elseif _state == HeldNote.State.Holding or
			_state == HeldNote.State.HoldMissedActive or
			_state == HeldNote.State.Passed then

			if _state == HeldNote.State.Holding then
				_hold_flash:update(dt_scale)
				if _hold_flash:do_flash() then
					if is_local_slot() then
						_game._effects:add_effect(HoldingNoteEffect:new(
							_game,
							_game:get_tracksystem(slot_index):get_track(track_index):get_end_position(),
							NoteResult.Perfect
						))
					end
				end
			end

			if _game_audio_manager_get_current_time_ms > (get_tail_hit_time() - _game._audio_manager.NOTE_REMOVE_TIME) then

				if _state == HeldNote.State.Holding or
					_state == HeldNote.State.HoldMissedActive then

					if is_local_slot() then
						_game._effects:add_effect(HoldingNoteEffect:new(
							_game,
							get_tail_position(),
							NoteResult.Okay
						))
					end

					_game._score_manager:register_hit(
						NoteResult.Miss,
						slot_index,
						_track_index,
						{ PlaySFX = false; PlayHoldEffect = false; TimeMiss = true; }
					)

				end

				_state = HeldNote.State.DoRemove
			end
		end
	end

	--[[Override--]] function self:should_remove()
		return _state == HeldNote.State.DoRemove
	end

	--[[Override--]] function self:do_remove()
		_game._object_pool:repool(self.ClassName,_note_obj)
	end

	--[[Override--]] function self:test_hit()
		if _state == HeldNote.State.Pre then
			local time_to_end = _game_audio_manager_get_current_time_ms - hit_time_ms
			local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result
			end

			return false, NoteResult.Miss

		elseif _state == HeldNote.State.HoldMissedActive then
			local time_to_end = _game_audio_manager_get_current_time_ms - get_tail_hit_time()
			local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result
			end

			return false, NoteResult.Miss

		end

		return false, NoteResult.Miss
	end

	--[[Override--]] function self:on_hit(note_result, i_notes)
		if _state == HeldNote.State.Pre then
			_game._effects:add_effect(TriggerNoteEffect:new(
				_game,
				get_head_position(),
				note_result,
				is_local_slot()
			))

			_game._score_manager:register_hit(
				note_result, slot_index, _track_index, { PlaySFX = true; PlayHoldEffect = false; IsHeldNoteBegin = true; }
			)

			_did_trigger_head = true
			_state = HeldNote.State.Holding

		elseif _state == HeldNote.State.HoldMissedActive then
			_game._effects:add_effect(TriggerNoteEffect:new(
				_game,
				get_tail_position(),
				note_result
			))

			_game._score_manager:register_hit(
				note_result,
				slot_index,
				_track_index,
				{ PlaySFX = true; PlayHoldEffect = true; HoldEffectPosition = get_tail_position() }
			)

			_did_trigger_tail = true
			_state = HeldNote.State.Passed
		end
	end

	--[[Override--]] function self:test_release()
		if _state == HeldNote.State.Holding or _state == HeldNote.State.HoldMissedActive then
			local time_to_end = _game_audio_manager_get_current_time_ms - get_tail_hit_time()
			local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result
			end

			if _state == HeldNote.State.HoldMissedActive then
				return false, NoteResult.Miss
			else
				return true, NoteResult.Miss
			end
		end

		return false, NoteResult.Miss
	end
	--[[Override--]] function self:on_release(note_result, i_notes)
		if _state == HeldNote.State.Holding or _state == HeldNote.State.HoldMissedActive then
			if note_result == NoteResult.Miss then
				_game._score_manager:register_hit(
					note_result, slot_index, _track_index,  { PlaySFX = true; PlayHoldEffect = false; }
				)
				_state = HeldNote.State.HoldMissedActive
			else
				_game._effects:add_effect(TriggerNoteEffect:new(
					_game,
					get_tail_position(),
					note_result,
					is_local_slot()
				))
				_game._score_manager:register_hit(
					note_result,
					slot_index,
					_track_index,
					{ PlaySFX = true; PlayHoldEffect = true; HoldEffectPosition = get_tail_position(); }
				)
				_did_trigger_tail = true
				_state = HeldNote.State.Passed
			end
		end

	end

	--[[Override--]] function self:get_track_index()
		return _track_index
	end


	self:cons()
	return self
end

return HeldNote
