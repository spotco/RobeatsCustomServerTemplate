local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local InGameMenu = require(game.ReplicatedStorage.Menus.InGameMenu)

local SongStartMenu = {}

function SongStartMenu:new(_local_services, _start_song_key, _local_player_slot)
	local self = MenuBase:new()
	
	local _game
	
	function self:cons()
		EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Game)
		
		_game = RobeatsGame:new(_local_services, EnvironmentSetup:get_game_environment_center_position(), self)
		_game._audio_manager:load_song(_start_song_key)
		_game:setup_world(_local_player_slot)
	end
	
	--[[Override--]] function self:update(dt_scale)
		_game:update(dt_scale)
	end
	
	--[[Override--]] function self:should_remove()
		return _game._audio_manager:is_ready_to_play() == true
	end
	
	--[[Override--]] function self:do_remove()
		_game:start_game()
		_local_services._menus:push_menu(InGameMenu:new(_game))
	end
	
	self:cons()
	return self
end

return SongStartMenu