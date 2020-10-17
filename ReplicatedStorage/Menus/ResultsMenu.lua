local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local ResultsMenu = {}

function ResultsMenu:new(_local_services, _score_data)
	local self = MenuBase:new()
	local _configuration	= require(game.ReplicatedStorage.Configuration).preferences
	local _results_menu_ui
	local _input = _local_services._input

	local _back_pressed = false

	-- PLEASE SIMPLIFY!

	local _grade_images = {
		"http://www.roblox.com/asset/?id=5702584062",
		"http://www.roblox.com/asset/?id=5702584273",
		"http://www.roblox.com/asset/?id=5702584488",
		"http://www.roblox.com/asset/?id=5702584846",
		"http://www.roblox.com/asset/?id=5702585057",
		"http://www.roblox.com/asset/?id=5702585272"
	}

	local _accuracy_marks = {100,95,90,80,70,60,50}
	
	function self:cons()
		_results_menu_ui = EnvironmentSetup:get_menu_protos_folder().ResultsMenuUI:Clone()

		_input:bind_input_fire(_results_menu_ui.BackButton, function()
			_back_pressed = true
		end)

		self:set_data()
	end

	function self:set_data()
		local _song_key = _score_data.mapid
		local _key_data = SongDatabase:get_data_for_key(_song_key)

		local img = ""
		for i = 1, #_accuracy_marks do
			local accuracyGrade = _accuracy_marks[i]
			if _score_data.accuracy*100 >= accuracyGrade then
				img = _grade_images[i]
				break
			else
				img = _grade_images[#_grade_images]
			end
		end

		_results_menu_ui.Grade.Image = img or ""
		_results_menu_ui.Accuracy.Text = string.format("%0.2f%%", _score_data.accuracy*100)
		--_score_data.perfects, _score_data.greats, _score_data.okays, _score_data.misses

		--HANDLE SPREAD RENDERING

		local _spread_display = _results_menu_ui.SpreadDisplay

		local total_judges = #_key_data.HitObjects
		_spread_display.Perfects.Size = UDim2.new(_score_data.perfects/total_judges,0,0.25,0)
		_spread_display.PerfectCount.Text = _score_data.perfects

		_spread_display.Greats.Size = UDim2.new(_score_data.greats/total_judges,0,0.25,0)
		_spread_display.GreatCount.Text = _score_data.greats

		_spread_display.Okays.Size = UDim2.new(_score_data.okays/total_judges,0,0.25,0)
		_spread_display.OkayCount.Text = _score_data.okays

		_spread_display.Misses.Size = UDim2.new(_score_data.misses/total_judges,0,0.25,0)
		_spread_display.MissCount.Text = _score_data.misses

		local time = DateTime.now()

		local timeLocal = time:ToLocalTime()
		local _hour = (timeLocal.Hour % 12) == 0 and 12 or timeLocal.Hour % 12
		local ampm = timeLocal.Hour >= 12 and "PM" or "AM"

		_results_menu_ui.PlayerInfo.Text = string.format("Played by %s at %0d:%2d%s on %2d/%0d/%4d",
			game.Players.LocalPlayer.Name,
			_hour,
			timeLocal.Minute,
			ampm,
			timeLocal.Month,
			timeLocal.Day,
			timeLocal.Year
		);

		_results_menu_ui.MapInfo.Text = string.format("%s - %s [%0d]",
			SongDatabase:get_title_for_key(_song_key),
			SongDatabase:get_artist_for_key(_song_key),
			SongDatabase:get_difficulty_for_key(_song_key)
		)
	end

	function self:get_formatted_data(data)
		local str = "%.2f%% | %0d / %0d / %0d / %0d"
		return string.format(str, data.accuracy*100, data.perfects, data.greats, data.okays, data.misses)
	end

	function self:back_button_pressed()
		
	end
	
	--[[Override--]] function self:do_remove()
		_results_menu_ui:Destroy()
	end
	
	--[[Override--]] function self:set_is_top_element(val)
		if val then
			EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
			_results_menu_ui.Parent = EnvironmentSetup:get_player_gui_root()
		else
			_results_menu_ui.Parent = nil
		end
	end

	function self:should_remove()
		return _back_pressed
	end
	
	self:cons()
	
	return self
end

return ResultsMenu