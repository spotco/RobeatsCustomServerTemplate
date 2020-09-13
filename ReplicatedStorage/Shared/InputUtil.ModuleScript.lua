local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)

local InputUtil = {}

InputUtil.KEY_TRACK1 = 0
InputUtil.KEY_TRACK2 = 1
InputUtil.KEY_TRACK3 = 2
InputUtil.KEY_TRACK4 = 3

InputUtil.KEY_UP = 10
InputUtil.KEY_DOWN = 11
InputUtil.KEY_LEFT = 12
InputUtil.KEY_RIGHT = 13

InputUtil.KEY_MOD1 = 21

InputUtil.KEY_MENU_OPEN = 31
InputUtil.KEY_MENU_ENTER = 32
InputUtil.KEY_MENU_BACK = 33

InputUtil.KEY_MENU_MATCHMAKING_CHAT_FOCUS = 34
InputUtil.KEY_MENU_SPUITEXTINPUT_ESC = 35

InputUtil.KEY_CLICK = 41

InputUtil.KEY_SCROLL_UP = 51
InputUtil.KEY_SCROLL_DOWN = 52

InputUtil.KEY_DEBUG_1 = -5
InputUtil.KEY_DEBUG_2 = -6

InputUtil.KEYCODE_TOUCH_TRACK1 = 10001
InputUtil.KEYCODE_TOUCH_TRACK2 = 10002
InputUtil.KEYCODE_TOUCH_TRACK3 = 10003
InputUtil.KEYCODE_TOUCH_TRACK4 = 10004

function InputUtil:new()
	local self = {}

	local _just_pressed_keys = SPDict:new()
	local _down_keys = SPDict:new()
	local _just_released_keys = SPDict:new()

	local _textbox_focused = false
	local _do_textbox_unfocus = false

	function self:cons()
		local userinput_service = game:GetService("UserInputService")

		userinput_service.TextBoxFocused:connect(function(textbox)
			_textbox_focused = true
		end)
		userinput_service.TextBoxFocusReleased:connect(function(textbox)
			_do_textbox_unfocus = true
		end)

		userinput_service.InputBegan:connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:input_began(input.KeyCode)

			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:input_began(InputUtil.KEY_CLICK)

			elseif input.UserInputType == Enum.UserInputType.Touch then
				self:input_began(InputUtil.KEY_CLICK)

				local csize = workspace.CurrentCamera.ViewportSize
				if input.Position.X > 0 and input.Position.X < (csize.X/4) then
					self:input_began(InputUtil.KEYCODE_TOUCH_TRACK1)
				elseif input.Position.X > (csize.X/4) and input.Position.X < (csize.X/4)*2 then
					self:input_began(InputUtil.KEYCODE_TOUCH_TRACK2)
				elseif input.Position.X > (csize.X/4)*2 and input.Position.X < (csize.X/4)*3 then
					self:input_began(InputUtil.KEYCODE_TOUCH_TRACK3)
				elseif input.Position.X > (csize.X/4)*3 and input.Position.X < (csize.X) then
					self:input_began(InputUtil.KEYCODE_TOUCH_TRACK4)
				end

			end
		end)
		userinput_service.InputEnded:connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:input_ended(input.KeyCode)

			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:input_ended(InputUtil.KEY_CLICK)

			elseif input.UserInputType == Enum.UserInputType.Touch then
				self:input_ended(InputUtil.KEY_CLICK)

				local csize = workspace.CurrentCamera.ViewportSize
				if input.Position.X > 0 and input.Position.X < (csize.X/4) then
					self:input_ended(InputUtil.KEYCODE_TOUCH_TRACK1)
				elseif input.Position.X > (csize.X/4) and input.Position.X < (csize.X/4)*2 then
					self:input_ended(InputUtil.KEYCODE_TOUCH_TRACK2)
				elseif input.Position.X > (csize.X/4)*2 and input.Position.X < (csize.X/4)*3 then
					self:input_ended(InputUtil.KEYCODE_TOUCH_TRACK3)
				elseif input.Position.X > (csize.X/4)*3 and input.Position.X < (csize.X) then
					self:input_ended(InputUtil.KEYCODE_TOUCH_TRACK4)
				end

			end
		end)
		game.Players.LocalPlayer:GetMouse().WheelForward:connect(function()
			self:input_began(InputUtil.KEY_SCROLL_UP)
		end)
		game.Players.LocalPlayer:GetMouse().WheelBackward:connect(function()
			self:input_began(InputUtil.KEY_SCROLL_DOWN)
		end)
	end

	function self:input_began(keycode)
		_down_keys:add(keycode, true)
		_just_pressed_keys:add(keycode, true)
	end

	function self:input_ended(keycode)
		_down_keys:remove(keycode)
		_just_released_keys:add(keycode, true)
	end

	function self:post_update()
		_just_pressed_keys:clear()
		_just_released_keys:clear()

		if _down_keys:contains(InputUtil.KEY_SCROLL_UP) then
			self:input_ended(InputUtil.KEY_SCROLL_UP)
		end
		if _down_keys:contains(InputUtil.KEY_SCROLL_DOWN) then
			self:input_ended(InputUtil.KEY_SCROLL_DOWN)
		end
		if _do_textbox_unfocus == true then
			_do_textbox_unfocus = false
			_textbox_focused = false
		end
	end

	local function is_control_active(control,active_dict)

		if control == InputUtil.KEY_CLICK then
			return active_dict:contains(InputUtil.KEY_CLICK)
		end

		if _textbox_focused == true then
			return false
		end

		if control == InputUtil.KEY_TRACK1 then
			return active_dict:contains(Enum.KeyCode.A) or
				active_dict:contains(Enum.KeyCode.Z) or
				active_dict:contains(Enum.KeyCode.J) or
				active_dict:contains(Enum.KeyCode.One) or
				active_dict:contains(Enum.KeyCode.Left) or
				active_dict:contains(Enum.KeyCode.Q) or
				active_dict:contains(Enum.KeyCode.U) or
				active_dict:contains(Enum.KeyCode.N) or
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK1)

		elseif control == InputUtil.KEY_TRACK2 then
			return active_dict:contains(Enum.KeyCode.S) or
				active_dict:contains(Enum.KeyCode.X) or
				active_dict:contains(Enum.KeyCode.K) or
				active_dict:contains(Enum.KeyCode.Two) or
				active_dict:contains(Enum.KeyCode.Down) or
				active_dict:contains(Enum.KeyCode.W) or
				active_dict:contains(Enum.KeyCode.I) or
				active_dict:contains(Enum.KeyCode.M) or
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK2)

		elseif control == InputUtil.KEY_TRACK3 then
			return active_dict:contains(Enum.KeyCode.D) or
				active_dict:contains(Enum.KeyCode.C) or
				active_dict:contains(Enum.KeyCode.L) or
				active_dict:contains(Enum.KeyCode.Three) or
				active_dict:contains(Enum.KeyCode.Up) or
				active_dict:contains(Enum.KeyCode.E) or
				active_dict:contains(Enum.KeyCode.O) or
				active_dict:contains(Enum.KeyCode.Comma) or
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK3)

		elseif control == InputUtil.KEY_TRACK4 then
			return active_dict:contains(Enum.KeyCode.F)	or
				active_dict:contains(Enum.KeyCode.V) or
				active_dict:contains(Enum.KeyCode.Semicolon) or
				active_dict:contains(Enum.KeyCode.Four) or
				active_dict:contains(Enum.KeyCode.Right) or
				active_dict:contains(Enum.KeyCode.R) or
				active_dict:contains(Enum.KeyCode.P) or
				active_dict:contains(Enum.KeyCode.Period) or
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK4)

		elseif control == InputUtil.KEY_DOWN then
			return active_dict:contains(Enum.KeyCode.Down) or
				active_dict:contains(Enum.KeyCode.S) or
				active_dict:contains(Enum.KeyCode.Tab)

		elseif control == InputUtil.KEY_UP then
			return active_dict:contains(Enum.KeyCode.Up) or
				active_dict:contains(Enum.KeyCode.W)

		elseif control == InputUtil.KEY_LEFT then
			return active_dict:contains(Enum.KeyCode.Left) or active_dict:contains(Enum.KeyCode.A)

		elseif control == InputUtil.KEY_RIGHT then
			return active_dict:contains(Enum.KeyCode.Right) or active_dict:contains(Enum.KeyCode.D)

		elseif control == InputUtil.KEY_MOD1 then
			return active_dict:contains(Enum.KeyCode.LeftShift)

		elseif control == InputUtil.KEY_MENU_OPEN then
			return active_dict:contains(Enum.KeyCode.Return)

		elseif control == InputUtil.KEY_MENU_ENTER then
			return (active_dict:contains(Enum.KeyCode.Return) and _textbox_focused == false)
				or active_dict:contains(Enum.KeyCode.Space)

		elseif control == InputUtil.KEY_MENU_BACK then
			return active_dict:contains(Enum.KeyCode.Backspace)

		elseif control == InputUtil.KEY_MENU_MATCHMAKING_CHAT_FOCUS then
			return active_dict:contains(Enum.KeyCode.Period)

		elseif control == InputUtil.KEY_MENU_SPUITEXTINPUT_ESC then
			return active_dict:contains(Enum.KeyCode.Escape)

		elseif control == InputUtil.KEY_SCROLL_UP then
			return active_dict:contains(InputUtil.KEY_SCROLL_UP)

		elseif control == InputUtil.KEY_SCROLL_DOWN then
			return active_dict:contains(InputUtil.KEY_SCROLL_DOWN)

		elseif control == InputUtil.KEY_DEBUG_1 then
			return false
			--return active_dict:contains(Enum.KeyCode.Q) and active_dict:contains(Enum.KeyCode.P)

		elseif control == InputUtil.KEY_DEBUG_2 then
			return false
			--active_dict:contains(Enum.KeyCode.Two)

		else
			error("INPUTKEY NOT FOUND ",control)
			return false

		end
	end

	function self:control_just_pressed(control)
		return is_control_active(control,_just_pressed_keys)
	end
	function self:control_pressed(control)
		return is_control_active(control,_down_keys)
	end
	function self:control_just_released(control)
		return is_control_active(control,_just_released_keys)
	end
	function self:clear_just_pressed_keys()
		_just_pressed_keys:clear()
	end
	function self:clear_just_released_keys()
		_just_released_keys:clear()
	end

	self:cons()
	return self
end


return InputUtil
