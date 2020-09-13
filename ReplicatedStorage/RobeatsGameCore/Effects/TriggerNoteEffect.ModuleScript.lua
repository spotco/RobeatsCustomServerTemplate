local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local TriggerNoteEffect = {}
TriggerNoteEffect.Type = "TriggerNoteEffect"

local STARTING_ALPHA = 0.1
local ENDING_ALPHA = 0

function TriggerNoteEffect:new(_game, position, result, is_local_slot)
	local self = EffectSystem:EffectBase()
	self.ClassName = TriggerNoteEffect.Type

	self._effect_obj = nil
	self._anim_t = 0
	self._result = result

	local _position = Vector3.new()

	local function update_visual()
		self._effect_obj.Body.Transparency = CurveUtil:YForPointOf2PtLine(
			Vector2.new(0,SPUtil:tra(STARTING_ALPHA)),
			Vector2.new(1,SPUtil:tra(ENDING_ALPHA)),
			self._anim_t
		)

		local size_val = CurveUtil:YForPointOf2PtLine(
			Vector2.new(0,2.25),
			Vector2.new(1,4.25),
			self._anim_t
		)

		if self._result == NoteResult.Okay then
			size_val = size_val * 0.25
		elseif self._result == NoteResult.Great then
			size_val = size_val * 0.5
		else
			size_val = size_val * 1
		end

		if is_local_slot then
			_position = _position + Vector3.new(0,0.01,0)
			self._effect_obj:SetPrimaryPartCFrame(
					CFrame.new(_position) *
					SPUtil:part_cframe_rotation(self._effect_obj.PrimaryPart)
			)
		end
		self._effect_obj.Body.Size = Vector3.new(70,size_val,size_val)

	end

	function self:cons()
		self._effect_obj = _game._object_pool:depool(self.ClassName)
		if self._effect_obj == nil then
			self._effect_obj = EnvironmentSetup:get_element_protos_folder().TriggerHitEffectProto:Clone()
		end

		if self._result == NoteResult.Okay then
			self._effect_obj.PrimaryPart.BrickColor = BrickColor.new(243,237,0)
		elseif self._result == NoteResult.Great then
			self._effect_obj.PrimaryPart.BrickColor = BrickColor.new(0,255,0)
		else
			self._effect_obj.PrimaryPart.BrickColor = BrickColor.new(0,207,256)
		end

		_position = Vector3.new(position.X, _game:get_game_environment_center_position().Y, position.Z)
		self._effect_obj:SetPrimaryPartCFrame(
				CFrame.new(_position) *
				SPUtil:part_cframe_rotation(self._effect_obj.PrimaryPart)
		)

		self._anim_t = 0
		update_visual()
	end

	--[[Override--]] function self:add_to_parent(parent)
		self._effect_obj.Parent = parent
	end

	--[[Override--]] function self:update(dt_scale)
		self._anim_t = self._anim_t + CurveUtil:SecondsToTick(0.25) * dt_scale
		update_visual()
	end
	--[[Override--]] function self:should_remove()
		return self._anim_t >= 1
	end
	--[[Override--]] function self:do_remove()
		_game._object_pool:repool(self.ClassName, self._effect_obj)
	end

	self:cons(_game)
	return self
end

return TriggerNoteEffect
