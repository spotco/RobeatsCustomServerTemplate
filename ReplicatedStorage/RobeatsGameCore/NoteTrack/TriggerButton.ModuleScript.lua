local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local GameSlot = require(game.ReplicatedStorage.Shared.GameSlot)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local TriggerButton = {}

function TriggerButton:new(_game, position, track_system, track_index)
	local self = {}

	local _triggerbutton_obj = nil
	local _tar_glow_transparency = 1
	local _parent_track_system = track_system

	function self:cons()
		_triggerbutton_obj = EnvironmentSetup:get_element_protos_folder().TriggerButtonProto:Clone()
		_triggerbutton_obj:SetPrimaryPartCFrame(
			CFrame.new(
				Vector3.new(position.X, _game:get_game_environment_center_position().Y, position.Z)) *
				SPUtil:part_cframe_rotation(_triggerbutton_obj.PrimaryPart)
		)

		_triggerbutton_obj.Outer.InteriorGlow.Transparency = 1
		_triggerbutton_obj.Parent = EnvironmentSetup:get_local_elements_folder()
	end

	function self:teardown()
		_triggerbutton_obj:Destroy()
		_triggerbutton_obj = nil
		_parent_track_system = nil
		_game = nil
		track_system = nil
		self = nil
	end

	function self:press()
		_tar_glow_transparency = 0
	end

	function self:release()
		_tar_glow_transparency = 1
	end

	function self:update_brick_color(_game)
		if _game._players._slots:contains(_parent_track_system._game_slot) == false then
			return
		end

		_triggerbutton_obj.Outer.BrickColor, _triggerbutton_obj.Outer.Transparency =
			GameSlot:slot_to_color_and_transparency(
				_parent_track_system._game_slot,
				_game._players._slots:get(_parent_track_system._game_slot)._power_bar_active
			)

	end

	function self:update(dt_scale, _game)
		_triggerbutton_obj.Outer.InteriorGlow.Transparency = CurveUtil:Expt(
			_triggerbutton_obj.Outer.InteriorGlow.Transparency,
			_tar_glow_transparency,
			CurveUtil:NormalizedDefaultExptValueInSeconds(0.45),
			dt_scale
		)

		self:update_brick_color(_game)
	end

	self:cons()
	return self
end

return TriggerButton
