local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local AudioManager = require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)

local Networking = require(game.ReplicatedStorage.Networking)

local InGameMenu = {}

function InGameMenu:new(_game, _song_key)
	local self = MenuBase:new()
	
	local _stat_display_ui
	
	function self:cons()
		_stat_display_ui = EnvironmentSetup:get_menu_protos_folder().InGameMenuStatDisplayUI:Clone()
		_stat_display_ui.Parent = EnvironmentSetup:get_player_gui_root()
		
		_stat_display_ui.ExitButton.Activated:Connect(function()
			if _game._audio_manager:get_mode() == AudioManager.Mode.Playing then
				_game:set_mode(RobeatsGame.Mode.GameEnded)
			end
		end)
	end
	
	--[[Override--]] function self:update(dt_scale)
		_game:update(dt_scale)
		
		if _game._audio_manager:get_mode() == AudioManager.Mode.PreStart then
			local did_raise_pre_start_trigger, raise_pre_start_trigger_val, raise_pre_start_trigger_duration = _game._audio_manager:raise_pre_start_trigger()
			if did_raise_pre_start_trigger == true then
				_stat_display_ui.ExitButton.Text = string.format("Starting in %d...", raise_pre_start_trigger_val)
			end
		elseif _game._audio_manager:get_mode() == AudioManager.Mode.Playing then
			_stat_display_ui.ExitButton.Text = "Exit"
		end
		
		if _game._audio_manager:is_finished() then
			_game:set_mode(RobeatsGame.Mode.GameEnded)
		end
		
		_stat_display_ui.ChainDisplay.Text = tostring(_game._score_manager:get_chain())
		_stat_display_ui.GradeDisplay.Text = string.format("%.2f",_game._score_manager:get_accuracy()*100) .. "%"

		local song_length = _game._audio_manager:get_song_length_ms()
		local song_time = _game._audio_manager:get_current_time_ms()

		local ms_remaining = song_length - song_time
		_stat_display_ui.TimeLeftDisplay.Text = SPUtil:format_ms_time(ms_remaining)
	end
	
	--[[Override--]] function self:should_remove()
		return _game:get_mode() == RobeatsGame.Mode.GameEnded
	end
	
	--[[Override--]] function self:do_remove()
		_stat_display_ui:Destroy()
		
		local perf_count, great_count, okay_count, miss_count, max_combo = _game._score_manager:get_end_records()
		local accuracy = _game._score_manager:get_accuracy()


		local data = {
			mapid = _song_key;
			accuracy = accuracy;
			maxcombo = max_combo;
			perfects = perf_count;
			greats = great_count;
			okays = okay_count;
			misses = miss_count;
		}

		spawn(function()
			Networking.Client:Execute("SubmitScore", data)
		end)

		_game:teardown()
	end
	
	self:cons()
	return self
end

return InGameMenu