local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local MarketplaceService = game:GetService("MarketplaceService")

local SongStartMenu = require(game.ReplicatedStorage.Menus.SongStartMenu)
local ConfirmationPopupMenu = require(game.ReplicatedStorage.Menus.ConfirmationPopupMenu)

local Networking = require(game.ReplicatedStorage.Networking)

--local SettingsMenu = require(game.ReplicatedStorage.Menus.SettingsMenu)

local ResultsMenu = {}

function ResultsMenu:new(_local_services, _score_data)
	local self = MenuBase:new()
	
	local SettingsMenu = require(game.ReplicatedStorage.Menus.SettingsMenu)

	local _configuration  = require(game.ReplicatedStorage.Configuration).preferences

	local _results_menu_ui
	local _selected_songkey = SongDatabase:invalid_songkey()
	local _is_supporter = false

	local _input = _local_services._input  

	local leaderboard_proto
	
	local _leaderboard_is_refreshing = false

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
		self:set_data()
	end

	function self:set_data()
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
		print(img)
		_results_menu_ui.Grade.Image = img
		_results_menu_ui.Accuracy.Text = string.format("%0.2f%%", _score_data.accuracy*100)
		_results_menu_ui.Spread.Text = string.format("%0d | %0d | %0d | %0d", _score_data.perfects, _score_data.greats, _score_data.okays, _score_data.misses)

		local time = DateTime.now()

		local timeLocal = time:ToLocalTime()
		local _hour = (timeLocal.Hour % 12) == 0 and 12 or timeLocal.Hour % 12
		local ampm = timeLocal.Hour >= 12 and "PM" or "AM"

		_results_menu_ui.PlayerInfo.Text = string.format("Played by %s at %0d:%2d%s on %2d/%0d/%4d", game.Players.LocalPlayer.Name, _hour, timeLocal.Minute, ampm, timeLocal.Month, timeLocal.Day, timeLocal.Year);
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
	
	self:cons()
	
	return self
end

return ResultsMenu