local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local AudioManager = require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)
local Networking = require(game.ReplicatedStorage.Networking)
local Configuration = require(game.ReplicatedStorage.Configuration)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local UserInputService = game:GetService("UserInputService")

local SettingsMenu = {}

function SettingsMenu:new(_local_services)
	local self = MenuBase:new()
	
	local _do_remove = false

	local _input = _local_services._input

	local _settings_ui
	
	function self:cons()
		_settings_ui = EnvironmentSetup:get_menu_protos_folder().SettingsUI:Clone()
		local keybinds = _settings_ui.Keybinds
		local offset = _settings_ui.Offset
		local notespeed = _settings_ui.Notespeed
		local back = _settings_ui.Back
		local keybind_buttons = {keybinds.Keybind1, keybinds.Keybind2, keybinds.Keybind3, keybinds.Keybind4}

		local function updateNSMULT()
			notespeed.Display.Text = string.format("x%.1f", Configuration.Preferences.NoteSpeedMultiplier)
		end

		local function updateADOFFSET()
			offset.Display.Text = string.format("%dms",Configuration.Preferences.AudioOffset)
		end
		
		local function updateKEYBINDS()
			for itr_i, v in pairs(keybind_buttons) do
				-- SET THE TEXT TO THE PROPER KEYCODE ON INITIALIZATION
				local itr_keybinds = Configuration.Preferences.Keybinds[itr_i]
				local str = ""
				for i_key,key in pairs(itr_keybinds) do
					str = str .. key.Name
					if i_key ~= #itr_keybinds then
						str = str .. "/"
					end
				end
				v.Text = str
				SPUtil:bind_input_fire(v, function()
					v.Text = "Press Key..."
					local u = UserInputService.InputBegan:Wait()
					Configuration.Preferences.Keybinds[itr_i] = {u.KeyCode}
				end)
			end
		end

		--//NOTESPEED
		SPUtil:bind_input_fire(notespeed.Minus, function()
			Configuration.Preferences.NoteSpeedMultiplier = Configuration.Preferences.NoteSpeedMultiplier - 0.1
			updateNSMULT()
		end)

		SPUtil:bind_input_fire(notespeed.Plus, function()
			Configuration.Preferences.NoteSpeedMultiplier = Configuration.Preferences.NoteSpeedMultiplier + 0.1
			updateNSMULT()
		end)

		--//OFFSET
		SPUtil:bind_input_fire(offset.Minus, function()
			Configuration.Preferences.AudioOffset = Configuration.Preferences.AudioOffset - 5
			updateADOFFSET()
		end)

		SPUtil:bind_input_fire(offset.Plus, function()
			Configuration.Preferences.AudioOffset = Configuration.Preferences.AudioOffset + 5
			updateADOFFSET()
		end)

		SPUtil:bind_input_fire(back, function()
			_do_remove = true
		end)

		--//KEYBINDS
		for itr_i, v in pairs(keybind_buttons) do
			SPUtil:bind_input_fire(v, function()
				v.Text = "Press Key..."
				local u = UserInputService.InputBegan:Wait()
				Configuration.Preferences.Keybinds[itr_i] = {u.KeyCode}
				updateKEYBINDS()
			end)
		end
		
		SPUtil:bind_input_fire(_settings_ui.Reset, function()
			Configuration.Preferences = SPUtil:copy_table(require(game.ReplicatedStorage.DefaultSettings))
			updateNSMULT()
			updateADOFFSET()
			updateKEYBINDS()
		end)

		updateNSMULT()
		updateADOFFSET()
		updateKEYBINDS()
	end

	function self:save_settings()
		spawn(function()
			DebugOut:puts("Saving settings...")
			Networking.Client:Execute("SaveSettings", Configuration.Preferences)
			DebugOut:puts("Settings have been saved!")
		end)
	end
	
	--[[Override--]] function self:update(dt_scale)
	end
	
	--[[Override--]] function self:should_remove()
		return _do_remove
	end
	
	--[[Override--]] function self:do_remove()
		self:save_settings()
		_settings_ui:Destroy()
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
