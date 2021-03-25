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

local withSongList = require(script.withSongList)

local SongSelectMenu = {}

function SongSelectMenu:new(_local_services)
	local self = MenuBase:new()

	local _song_select_ui
	local _selected_songkey = SongDatabase:invalid_songkey()
	local _is_supporter = false
	
	local song_list

	local _leaderboard_display
	
	function self:cons()
		_song_select_ui = EnvironmentSetup:get_menu_protos_folder().SongSelectUI:Clone()
		
		_leaderboard_display = LeaderboardDisplay:new(
			_song_select_ui.LeaderboardSection, 
			_song_select_ui.LeaderboardSection.LeaderboardList.LeaderboardListElementProto
		)

		local function on_song_key_selected(key)
			self:select_songkey(key)		
		end

		song_list = withSongList(_song_select_ui.SongList, on_song_key_selected)		
		
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

		_song_select_ui.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			song_list:filter_song_buttons(_song_select_ui.SearchBox.Text)
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
		
		-- SongDatabase:render_coverimage_for_key(_song_select_ui.SongInfoSection.SongInfoDisplay.SongCover, _song_select_ui.SongInfoSection.SongInfoDisplay.SongCoverOverlay, _selected_songkey)
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
			if val then
				EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
				_song_select_ui.Parent = EnvironmentSetup:get_player_gui_root()
				self:select_songkey(_selected_songkey)
			else
				_song_select_ui.Parent = nil
			end
		end
	end
	
	self:cons()
	
	return self
end

return SongSelectMenu