local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local NoteResultPopupEffect = {}
NoteResultPopupEffect.Type = "NoteResultPopupEffect"

local INITIAL_FRAME_Y = 125
local FINAL_FRAME_Y = 190

function NoteResultPopupEffect:new(_game, _position, _result)
	local self = EffectSystem:EffectBase()
	self.ClassName = NoteResultPopupEffect.Type

	local _effect_obj
	local _anim_t = 0
	
	local _frame
	local _image
	
	function self:cons()
		_anim_t = 0
	
		_effect_obj = _game._object_pool:depool(self.ClassName)
		if _effect_obj == nil then
			_effect_obj = EnvironmentSetup:get_element_protos_folder().PopupScoreEffectProto:Clone()
		end
		
		_frame = _effect_obj.Panel.SurfaceGui.Frame
		_image = _frame.ImageLabel

		if _result == NoteResult.Miss then
			_image.Image = "rbxassetid://662861662"

		elseif _result == NoteResult.Okay then
			_image.Image = "rbxassetid://662861666"

		elseif _result == NoteResult.Great then
			_image.Image = "rbxassetid://662861665"

		elseif _result == NoteResult.Perfect then
			_image.Image = "rbxassetid://662861671"

		else
			_image.Image = ""
			
		end
		
		_effect_obj:SetPrimaryPartCFrame(
			SPUtil:lookat_camera_cframe(_position)
		)
		
		_anim_t = 0
	end
	
	function self:get_anim_t() return _anim_t end
	function self:set_anim_t(val) _anim_t = val end

	local _alpha_min = Vector3.new(0,0.65)
	local _alpha_max = Vector3.new(1,0)
	function self:update_visual()
		_frame.Position = UDim2.new(0,0,0, CurveUtil:Lerp(INITIAL_FRAME_Y, FINAL_FRAME_Y, _anim_t))
		
		local alpha = CurveUtil:YForPointOf2PtLine(
			_alpha_min,
			_alpha_max,
			_anim_t
		)
		local transparency = SPUtil:tra(alpha)
		_image.ImageTransparency = transparency
	end

	--[[Override--]] function self:add_to_parent(parent)
		_effect_obj.Parent = parent
	end

	--[[Override--]] function self:update(dt_scale)
		--This animation completes in 0.55 seconds (_anim_t goes from 0 to 1)
		_anim_t = _anim_t + CurveUtil:SecondsToTick(0.55) * dt_scale
		self:update_visual()
	end
	--[[Override--]] function self:should_remove()
		return _anim_t >= 1
	end
	--[[Override--]] function self:do_remove()
		_game._object_pool:repool(self.ClassName,_effect_obj)
	end

	self:cons()
	return self
end

return NoteResultPopupEffect
