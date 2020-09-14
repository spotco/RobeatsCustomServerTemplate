local SettingsMenu = {}

function InGameMenu:new(_game)
	local self = MenuBase:new()
	
	local _stat_display_ui
	
	function self:cons()
		_stat_display_ui = EnvironmentSetup:get_menu_protos_folder().InGameMenuStatDisplayUI:Clone()
	end
	
	--[[Override--]] function self:update(dt_scale)
		
	end
	
	--[[Override--]] function self:should_remove()
		
	end
	
	--[[Override--]] function self:do_remove()
		
	end
	
	self:cons()
	return self
end

return SettingsMenu
