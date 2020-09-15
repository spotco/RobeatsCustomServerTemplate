local SettingsMenu = {}

local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local AudioManager = require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)

function SettingsMenu:new()
	local self = MenuBase:new()
	
	local back_hit = false

	local _settings_ui
	
	function self:cons()
		_settings_ui = EnvironmentSetup:get_menu_protos_folder().SettingsUI:Clone()
	end
	
	--[[Override--]] function self:update(dt_scale)
		
	end
	
	--[[Override--]] function self:should_remove()
		return back_hit
	end
	
	--[[Override--]] function self:do_remove()
		
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
