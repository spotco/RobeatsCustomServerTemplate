local SPList = require(game.ReplicatedStorage.Shared.SPList)
local NoteTrack = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.NoteTrack)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local GameTrack = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameTrack)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local HitParams = require(game.ReplicatedStorage.RobeatsGameCore.HitParams)
local Configuration = require(game.ReplicatedStorage.Configuration)

local NoteTrackSystem = {}

function NoteTrackSystem:new(_game, _game_slot)
	local self = {}
	
	local _obj
	
	--List of all notes active for this system
	local _notes = SPList:new()
	
	--List of all tracks active for this system
	local _tracks = SPList:new()

	function self:cons()
		--Clone "NoteTrackSystemProto" and use the elements in-game
		_obj = EnvironmentSetup:get_element_protos_folder().NoteTrackSystemProto:Clone()
		_obj:SetPrimaryPartCFrame(SPUtil:look_at(
			_game:get_game_environment_center_position(),
			_game:get_game_environment_center_position() + GameSlot:slot_to_world_position_offset(_game_slot)
		))

		if SPUtil:is_mobile_like() == true and Configuration.Preferences.MobileFullScreenUI ~= false then
			local center = _game:get_game_environment_center_position()
			local target = center + GameSlot:slot_to_world_position_offset(_game_slot)
			local dirXZ = Vector3.new(target.X - center.X, 0, target.Z - center.Z)
			local mag = dirXZ.Magnitude
			if mag > 0 then
				local base_deg = SPUtil:dir_ang_deg(dirXZ.X, dirXZ.Z)
				local spread_deg = 8
				local multipliers = { 1.5, 0.5, -0.5, -1.5 }
				local base_dir2 = SPUtil:ang_deg_dir(base_deg)
				local base_dir = Vector3.new(base_dir2.X, 0, base_dir2.Y)
				for i = 1, 4 do
					local trackModel = _obj:FindFirstChild(string.format("Track%d", i))
					if trackModel ~= nil and trackModel:IsA("Model") then
						local offset_deg = spread_deg * multipliers[i]
						local pos_dir2 = SPUtil:ang_deg_dir(base_deg + offset_deg)
						local posXZ = Vector3.new(pos_dir2.X, 0, pos_dir2.Y) * (mag * 0.5) + center
						local track_center = Vector3.new(posXZ.X, center.Y + 0.5, posXZ.Z)

						local trackPart = trackModel:FindFirstChild("PlayerTrackProto")
						if trackPart ~= nil and trackPart:IsA("BasePart") then
							trackPart.Size = Vector3.new(0.5, mag, 0.25)
							trackPart.Transparency = 0.5
							trackPart.Position = track_center + Vector3.new(0, -0.85, 0)
							trackPart.Rotation = Vector3.new(0, -base_deg - 180, 90)
						end

						local startMarker = trackModel:FindFirstChild("StartPosition")
						if startMarker ~= nil and startMarker:IsA("BasePart") then
							startMarker.Position = track_center + base_dir * (-mag * 0.5)
						end

						local endMarker = trackModel:FindFirstChild("EndPosition")
						if endMarker ~= nil and endMarker:IsA("BasePart") then
							endMarker.Position = track_center + base_dir * (mag * 0.5 * 0.1)
						end
					end
				end
			end
		end

		_obj.Parent = EnvironmentSetup:get_local_elements_folder()
		
		--For every defined enum value in GameTrack, create a NoteTrack for it
		for track_enum_name,track_enum_value in GameTrack:track_itr() do
			local tar_track_obj = _obj:FindFirstChild(track_enum_name)
			if tar_track_obj == nil then
				return DebugOut:errf("%s (Enum member of GameTrack) not found as child under NoteTrackSystemProto", track_enum_name)
			end
			_tracks:push_back(NoteTrack:new(_game, self, tar_track_obj, track_enum_value))
		end
	end
	
	function self:get_game_slot() return _game_slot end
	function self:get_notes() return _notes end

	function self:teardown()
		for i=1,_notes:count() do
			_notes:get(i):do_remove()
		end
		for i=1,_tracks:count() do
			_tracks:get(i):teardown()
		end
		_obj:Destroy()
	end

	function self:update(dt_scale)
		for i=1, _tracks:count() do
			local itr_track = _tracks:get(i)
			itr_track:update(dt_scale)
		end

		for i=_notes:count(),1,-1	do
			local itr_note = _notes:get(i)

			itr_note:update(dt_scale)

			if itr_note:should_remove() then
				itr_note:do_remove()
				_notes:remove_at(i)
			end
		end
	end
	
	function self:get_game_slot()
		return _game_slot
	end
	function self:get_track(index)
		return _tracks:get(index)
	end

	function self:press_track_index(track_index)
		self:get_track(track_index):press()
		local hit_found = false

		for i=1,_notes:count() do
			local itr_note = _notes:get(i)
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
			--Ghost tapping, comment out to disable
			_game._score_manager:register_hit(
				NoteResult.Miss,
				_game_slot,
				track_index,
				HitParams:new():set_play_hold_effect(false):set_whiff_miss(true)
			)
		end
	end

	function self:release_track_index(track_index)
		self:get_track(track_index):release()

		for i=1,_notes:count() do
			local itr_note = _notes:get(i)
			if itr_note:get_track_index() == track_index then
				local did_release, note_result = itr_note:test_release()
				if did_release then
					itr_note:on_release(note_result,i)
					break
				end
			end
		end
	end

	self:cons()
	return self
end

return NoteTrackSystem
