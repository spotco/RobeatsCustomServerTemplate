local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local MarketplaceService = game:GetService("MarketplaceService")

local LeaderboardDisplay = require(game.ReplicatedStorage.Menus.Utils.LeaderboardDisplay)
local SongStartMenu = require(game.ReplicatedStorage.Menus.SongStartMenu)
local ConfirmationPopupMenu = require(game.ReplicatedStorage.Menus.ConfirmationPopupMenu)
local SettingsMenu = require(game.ReplicatedStorage.Menus.SettingsMenu)
local Configuration	= require(game.ReplicatedStorage.Configuration)
local CustomServerSettings = require(game.Workspace.CustomServerSettings)

local SongSelectMenu = {}

function SongSelectMenu:new(_local_services)
	local self = MenuBase:new()

	local _song_select_ui
	local _selected_songkey = SongDatabase:invalid_songkey()
	local _is_supporter = false

	local _input = _local_services._input

	local _leaderboard_display
	
	function self:cons()
		_song_select_ui = EnvironmentSetup:get_menu_protos_folder().SongSelectUI:Clone()
		
		local song_list = _song_select_ui.SongList
		
		--Expand the scrolling list to fit contents
		song_list.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			song_list.CanvasSize = UDim2.new(0, 0, 0, song_list.UIListLayout.AbsoluteContentSize.Y)
		end)
		
		local song_list_element_proto = song_list.SongListElementProto
		song_list_element_proto.Parent = nil
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
			
			SPUtil:bind_input_fire(itr_list_element, function(input)
				self:select_songkey(itr_songkey)
			end)
		end
		
		_leaderboard_display = LeaderboardDisplay:new(
			_song_select_ui.LeaderboardSection, 
			_song_select_ui.LeaderboardSection.LeaderboardList.LeaderboardListElementProto
		)
		
		_song_select_ui.SongInfoSection.NoSongSelectedDisplay.Visible = true
		_song_select_ui.SongInfoSection.SongInfoDisplay.Visible = false
		_song_select_ui.PlayButton.Visible = false

		SPUtil:bind_input_fire(_song_select_ui.PlayButton, function()
			self:play_button_pressed()
		end)
		
		SPUtil:bind_input_fire(_song_select_ui.RobeatsLogo, function()
			_local_services._menus:push_menu(ConfirmationPopupMenu:new(_local_services, "Teleport to Robeats?", "Do you want to go to Robeats?", function()
				game:GetService("TeleportService"):Teleport(698448212)
			end))
		end)
		SPUtil:bind_input_fire(_song_select_ui.GamepassButton, function()
			self:show_gamepass_menu()
		end)
		SPUtil:bind_input_fire(_song_select_ui.SettingsButton, function()
			_local_services._menus:push_menu(SettingsMenu:new(_local_services))
		end)

		_song_select_ui.NameDisplay.Text = string.format("%s's Robeats Custom Server", CustomServerSettings.CreatorName)
		_song_select_ui.SongInfoSection.NoSongSelectedDisplay.Visible = true

		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, asset_id, is_purchased)
			if asset_id == CustomServerSettings.SupporterGamepassID and is_purchased == true then
				_is_supporter = true
				self:select_songkey(_selected_songkey)
				self:show_gamepass_menu()
			end
		end)
		
		spawn(function()
			_is_supporter = MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, CustomServerSettings.SupporterGamepassID)
			self:select_songkey(_selected_songkey)
		end)
	end
	
	function self:show_gamepass_menu()
		if _is_supporter then
			_local_services._menus:push_menu(ConfirmationPopupMenu:new(_local_services, 
				string.format("You are supporting %s!", CustomServerSettings.CreatorName), 
				"Thank you for supporting this creator!", 
				function() end):hide_back_button()
			)
		else
			_local_services._menus:push_menu(ConfirmationPopupMenu:new(
				_local_services, 
				string.format("Support %s!", CustomServerSettings.CreatorName), 
				"Roblox audios are expensive to upload!\nHelp this creator by buying the Supporter Game Pass.\nBy becoming a supporter, you will get access to every song they create!", 
				function()
					MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, CustomServerSettings.SupporterGamepassID)
				end)
			)
		end
	end
	
	function self:select_songkey(songkey)
		if SongDatabase:contains_key(songkey) ~= true then return end
		_song_select_ui.SongInfoSection.NoSongSelectedDisplay.Visible = false
		_selected_songkey = songkey
		
		SongDatabase:render_coverimage_for_key(_song_select_ui.SongInfoSection.SongInfoDisplay.SongCover, _song_select_ui.SongInfoSection.SongInfoDisplay.SongCoverOverlay, _selected_songkey)
		_song_select_ui.SongInfoSection.SongInfoDisplay.NameDisplay.Text = SongDatabase:get_title_for_key(_selected_songkey)
		_song_select_ui.SongInfoSection.SongInfoDisplay.DifficultyDisplay.Text = string.format("Difficulty: %d",SongDatabase:get_difficulty_for_key(_selected_songkey))
		_song_select_ui.SongInfoSection.SongInfoDisplay.ArtistDisplay.Text = SongDatabase:get_artist_for_key(_selected_songkey)
		_song_select_ui.SongInfoSection.SongInfoDisplay.DescriptionDisplay.Text = SongDatabase:get_description_for_key(_selected_songkey)
		
		_song_select_ui.SongInfoSection.SongInfoDisplay.Visible = true
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
		
		_leaderboard_display:refresh_leaderboard(songkey)
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
			self:select_songkey(_selected_songkey)
		else
			_song_select_ui.Parent = nil
		end
	end
	
	self:cons()
	
	return self
end

return SongSelectMenu