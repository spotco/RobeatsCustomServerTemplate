local SettingsMenu = {}

local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local AudioManager = require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)

local UserInputService = game:GetService("UserInputService")

local SongSelectMenu = require(game.ReplicatedStorage.Menus.SongSelectMenu)

function SettingsMenu:new(_local_services)
	local self = MenuBase:new()
	
	local back_hit = false

	local _configuration = require(game.ReplicatedStorage.Configuration)

	local _input = _local_services._input

	local _settings_ui
	
	function self:cons()
		_settings_ui = EnvironmentSetup:get_menu_protos_folder().SettingsUI:Clone()
		local keybinds = _settings_ui.Keybinds
		local offset = _settings_ui.Offset
		local notespeed = _settings_ui.Notespeed
		local back = _settings_ui.Back

		local function updateNSMULT()
			notespeed.Display.Text = _configuration.preferences.NoteSpeedMultiplier
		end

		local function updateADOFFSET()
			offset.Display.Text = _configuration.preferences.AudioOffset
		end

		--TODO: CLEAN THIS UP

		--//NOTESPEED
		_input:bind_input_fire(notespeed.Minus, function()
			_configuration.preferences.NoteSpeedMultiplier -= 0.1
			updateNSMULT()
		end)

		_input:bind_input_fire(notespeed.Plus, function()
			_configuration.preferences.NoteSpeedMultiplier += 0.1
			updateNSMULT()
		end)

		--//OFFSET
		_input:bind_input_fire(offset.Minus, function()
			_configuration.preferences.AudioOffset -= 5
			updateADOFFSET()
		end)

		_input:bind_input_fire(offset.Plus, function()
			_configuration.preferences.AudioOffset += 5
			updateADOFFSET()
		end)

		_input:bind_input_fire(back, function()
			back_hit = true
		end)

		local itr_i = 0

		for _, v in pairs(keybinds:GetChildren()) do
			if v:IsA("TextButton") then
				itr_i += 1
				local p_i = itr_i
				-- GO AHEAD AND SET THE TEXT TO THE PROPER KEYCODE ON INITIALIZATION
				v.Text = _configuration.preferences.Keybinds[p_i].Name
				_input:bind_input_fire(v, function()
					local i = p_i
					local u = UserInputService.InputBegan:Wait()
					local k = u.KeyCode
					v.Text = k.Name
					_configuration.preferences.Keybinds[i] = k
				end)
			end
		end

		updateNSMULT()
		updateADOFFSET()
	end
	
	--[[Override--]] function self:update(dt_scale)
		
	end
	
	--[[Override--]] function self:should_remove()
		return back_hit
	end
	
	--[[Override--]] function self:do_remove()
		_local_services._menus:push_menu(SongSelectMenu:new(_local_services))
	end

	--[[Override--]] function self:set_is_top_element(val)
		if val then
			_settings_ui.Parent = EnvironmentSetup:get_player_gui_root()
		else
			_settings_ui.Parent = nil
		end
	end
	
	self:cons()
	return self
end

return SettingsMenu
