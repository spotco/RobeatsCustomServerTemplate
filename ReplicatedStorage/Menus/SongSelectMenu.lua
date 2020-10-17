local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local MarketplaceService = game:GetService("MarketplaceService")

local SongStartMenu = require(game.ReplicatedStorage.Menus.SongStartMenu)
local ConfirmationPopupMenu = require(game.ReplicatedStorage.Menus.ConfirmationPopupMenu)

local Networking = require(game.ReplicatedStorage.Networking)

local SongSelectMenu = {}

function SongSelectMenu:new(_local_services)
	local self = MenuBase:new()
	
	local SettingsMenu = require(game.ReplicatedStorage.Menus.SettingsMenu)

	local _configuration	= require(game.ReplicatedStorage.Configuration).preferences

	local _song_select_ui
	local _selected_songkey = SongDatabase:invalid_songkey()
	local _is_supporter = false

	local _input = _local_services._input

	local leaderboard_proto
	
	local _leaderboard_is_refreshing = false
	
	function self:cons()
		_song_select_ui = EnvironmentSetup:get_menu_protos_folder().SongSelectUI:Clone()
		
		local song_list = _song_select_ui.SongList
		
		--Expand the scrolling list to fit contents
		song_list.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			song_list.CanvasSize = UDim2.new(0, 0, 0, song_list.UIListLayout.AbsoluteContentSize.Y)
		end)
		
		local song_list_element_proto = song_list.SongListElementProto
		song_list_element_proto.Parent = nil

		leaderboard_proto = _song_select_ui.Leaderboard.LeaderboardListElementProto
		leaderboard_proto.Parent = nil

		for itr_songkey, itr_songdata in SongDatabase:key_itr() do
			local itr_list_element = song_list_element_proto:Clone()
			itr_list_element.Parent = song_list
			itr_list_element.LayoutOrder = itr_songkey
			SongDatabase:render_coverimage_for_key(itr_list_element.SongCover, itr_list_element.SongCoverOverlay, itr_songkey)
			itr_list_element.NameDisplay.Text = SongDatabase:get_title_for_key(itr_songkey)
			itr_list_element.DifficultyDisplay.Text = string.format("Difficulty: %d",SongDatabase:get_difficulty_for_key(itr_songkey))
			if SongDatabase:key_get_audiomod(itr_songkey) == SongDatabase.SongMode.SupporterOnly then
				itr_list_element.DifficultyDisplay.Text = itr_list_element.DifficultyDisplay.Text .. " (Supporter Only)"
			end
			
			_input:bind_input_fire(itr_list_element, function(input)
				self:select_songkey(itr_songkey)
			end)
		end
		
		_song_select_ui.SongInfoSection.Visible = false
		_song_select_ui.PlayButton.Visible = false

		_input:bind_input_fire(_song_select_ui.PlayButton, function()
			self:play_button_pressed()
		end)
		
		_input:bind_input_fire(_song_select_ui.RobeatsLogo, function()
			_local_services._menus:push_menu(ConfirmationPopupMenu:new(_local_services, "Teleport to Robeats?", "Do you want to go to Robeats?", function()
				game:GetService("TeleportService"):Teleport(698448212)
			end))
		end)
		_input:bind_input_fire(_song_select_ui.GamepassButton, function()
			self:show_gamepass_menu()
		end)
		_input:bind_input_fire(_song_select_ui.SettingsButton, function()
			_local_services._menus:push_menu(SettingsMenu:new(_local_services))
		end)

		_song_select_ui.NameDisplay.Text = string.format("%s's Robeats Custom Server", _configuration.CreatorName)
		_song_select_ui.NoSongSelectedDisplay.Visible = true

		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, asset_id, is_purchased)
			if asset_id == _configuration.SupporterGamepassID and is_purchased == true then
				_is_supporter = true
				self:select_songkey(_selected_songkey)
				self:show_gamepass_menu()
			end
		end)
		
		spawn(function()
			_is_supporter = MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, _configuration.SupporterGamepassID)
			self:select_songkey(_selected_songkey)
		end)
	end
	
	function self:show_gamepass_menu()
		if _is_supporter then
			_local_services._menus:push_menu(ConfirmationPopupMenu:new(_local_services, 
				string.format("You are supporting %s!", _configuration.CreatorName), 
				"Thank you for supporting this creator!", 
				function() end):hide_back_button()
			)
		else
			_local_services._menus:push_menu(ConfirmationPopupMenu:new(
				_local_services, 
				string.format("Support %s!", _configuration.CreatorName), 
				"Roblox audios are expensive to upload!\nHelp this creator by buying the Supporter Game Pass.\nBy becoming a supporter, you will get access to every song they create!", 
				function()
					MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, _configuration.SupporterGamepassID)
				end)
			)
		end
	end

	function self:get_formatted_data(data)
		local str = "%.2f%% | %0d / %0d / %0d / %0d"
		return string.format(str, data.accuracy*100, data.perfects, data.greats, data.okays, data.misses)
	end

	function self:refresh_leaderboard(songkey)
		if _leaderboard_is_refreshing then return end
		spawn(function()
			_leaderboard_is_refreshing = true
			local leaderboard = _song_select_ui.Leaderboard
		
			--// CLEAR LEADERBOARD

			for i, v in pairs(leaderboard:GetChildren()) do
				if v:IsA("Frame") then
					v:Destroy()
				end
			end

			--// GET NEW LEADERBOARD

			local leaderboardData = Networking.Client:Execute("GetLeaderboard", {
				mapid = songkey
			}) or {}

			table.sort(leaderboardData, function(a, b)
				if a == nil or b == nil then
					return false
				end
				return a.accuracy > b.accuracy
			end)

			--// RENDER NEW LEADERBOARD
			
			for itr, itr_data in pairs(leaderboardData) do
				local itr_leaderboard_proto = leaderboard_proto:Clone()

				itr_leaderboard_proto.Player.Text = string.format("#%d: %s", itr, itr_data.playername)
				itr_leaderboard_proto.Data.Text = self:get_formatted_data(itr_data)
				itr_leaderboard_proto.UserThumbnail.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", itr_data.userid)

				itr_leaderboard_proto.Parent = leaderboard
			end
			_leaderboard_is_refreshing = false
		end)
	end
	
	function self:select_songkey(songkey)
		if SongDatabase:contains_key(songkey) ~= true then return end
		_song_select_ui.NoSongSelectedDisplay.Visible = false
		_selected_songkey = songkey
		
		SongDatabase:render_coverimage_for_key(_song_select_ui.SongInfoSection.SongCover, _song_select_ui.SongInfoSection.SongCoverOverlay, _selected_songkey)
		_song_select_ui.SongInfoSection.NameDisplay.Text = SongDatabase:get_title_for_key(_selected_songkey)
		_song_select_ui.SongInfoSection.DifficultyDisplay.Text = string.format("Difficulty: %d",SongDatabase:get_difficulty_for_key(_selected_songkey))
		_song_select_ui.SongInfoSection.ArtistDisplay.Text = SongDatabase:get_artist_for_key(_selected_songkey)
		_song_select_ui.SongInfoSection.DescriptionDisplay.Text = SongDatabase:get_description_for_key(_selected_songkey)
		
		_song_select_ui.SongInfoSection.Visible = true
		_song_select_ui.PlayButton.Visible = true
		
		if SongDatabase:key_get_audiomod(_selected_songkey) == SongDatabase.SongMode.SupporterOnly then
			if _is_supporter then
				_song_select_ui.PlayButton.Text = "Play!"
			else
				_song_select_ui.PlayButton.Text = "Become a Supporter to Play!"
			end
		else
			_song_select_ui.PlayButton.Text = "Play!"
		end
		
		self:refresh_leaderboard(songkey)
	end
	
	function self:play_button_pressed()
		if SongDatabase:contains_key(_selected_songkey) then
			if SongDatabase:key_get_audiomod(_selected_songkey) == SongDatabase.SongMode.Normal then
				_local_services._menus:push_menu(SongStartMenu:new(_local_services, _selected_songkey, GameSlot.SLOT_1))
			elseif SongDatabase:key_get_audiomod(_selected_songkey) == SongDatabase.SongMode.SupporterOnly then
				if _is_supporter then
					_local_services._menus:push_menu(SongStartMenu:new(_local_services, _selected_songkey, GameSlot.SLOT_1))
				else
					self:show_gamepass_menu()
				end
			end
		end
	end
	
	--[[Override--]] function self:do_remove()
		_song_select_ui:Destroy()
	end
	
	--[[Override--]] function self:set_is_top_element(val)
		if val then
			EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
			_song_select_ui.Parent = EnvironmentSetup:get_player_gui_root()
		else
			_song_select_ui.Parent = nil
		end
	end
	
	self:cons()
	
	return self
end

return SongSelectMenu