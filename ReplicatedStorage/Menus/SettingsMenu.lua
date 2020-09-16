local SettingsMenu = {}

local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local AudioManager = require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)

local SongSelectMenu = require(game.ReplicatedStorage.Menus.SongSelectMenu)

function SettingsMenu:new(_local_services)
	local self = MenuBase:new()
	
	local back_hit = false

	local settings = workspace.Settings

	local _settings_ui
	
	function self:cons()
		_settings_ui = EnvironmentSetup:get_menu_protos_folder().SettingsUI:Clone()
		local keybinds = _settings_ui.Keybinds
		local offset = _settings_ui.Offset
		local notespeed = _settings_ui.Notespeed
		local back = _settings_ui.Back

		local function updateNSMULT()
			notespeed.Display.Text = 1/settings.NoteSpeedMultiplier.Value
		end

		local function updateADOFFSET()
			offset.Display.Text = settings.AudioOffset.Value
		end

		--TODO: CLEAN THIS UP

		--//NOTESPEED
		notespeed.Minus.MouseButton1Click:Connect(function()
			settings.NoteSpeedMultiplier.Value = settings.NoteSpeedMultiplier.Value + 0.1
			updateNSMULT()
		end)

		notespeed.Plus.MouseButton1Click:Connect(function()
			settings.NoteSpeedMultiplier.Value = settings.NoteSpeedMultiplier.Value - 0.1
			updateNSMULT()
		end)

		--//OFFSET
		offset.Minus.MouseButton1Click:Connect(function()
			settings.AudioOffset.Value = settings.AudioOffset.Value - 5
			updateADOFFSET()
		end)

		offset.Plus.MouseButton1Click:Connect(function()
			settings.AudioOffset.Value = settings.AudioOffset.Value + 5
			updateADOFFSET()
		end)

		back.MouseButton1Click:Connect(function()
			back_hit = true
		end)

		for i, v in pairs(keybinds:GetChildren()) do
			if v:IsA("TextButton") then
				v.MouseButton1Click:Connect(function()
					print("CRINGE ASS MOTHERFUCKER")
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
