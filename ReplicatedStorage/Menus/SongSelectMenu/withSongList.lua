-- AstralKingdoms, kisperal

local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local function withSongList(_song_list_gui, _on_song_key_selected)
    local self = {}

    local _song_list_element_proto

    function self:cons()		
		--Expand the scrolling list to fit contents
		_song_list_gui.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			_song_list_gui.CanvasSize = UDim2.new(0, 0, 0, _song_list_gui.UIListLayout.AbsoluteContentSize.Y)
		end)
		
		_song_list_element_proto = _song_list_gui.SongListElementProto
		_song_list_element_proto.Parent = nil

        for itr_songkey, _ in SongDatabase:key_itr() do
			self:add_song_button(itr_songkey)
		end
    end

    function self:is_in_search(search, song_key)
		search = search or ""
		search = string.split(search, " ")
	
		local _to_search = SongDatabase:get_search_string_for_key(song_key)
		local found = 0
		for i = 1, #search do
			local search_term = search[i]
			if string.find(_to_search:lower(), search_term:lower()) ~= nil then
				found = found + 1
			end
		end
	
		return found == #search
	end

	function self:filter_song_buttons(search)
		for _, button in pairs(_song_list_gui:GetChildren()) do
			if button:IsA("Frame") then
				local song_key = button:GetAttribute("_key")
				button.Visible = self:is_in_search(search, song_key)
			end
		end
	end

    function self:add_song_button(song_key)
		local list_element = _song_list_element_proto:Clone()
		list_element.Parent = _song_list_gui
		list_element.LayoutOrder = song_key
		SongDatabase:render_coverimage_for_key(list_element.SongCover, list_element.SongCoverOverlay, song_key)
		list_element.NameDisplay.Text = SongDatabase:get_title_for_key(song_key)
		list_element.DifficultyDisplay.Text = string.format("Difficulty: %d",SongDatabase:get_difficulty_for_key(song_key))
		if SongDatabase:key_get_audiomod(song_key) == SongDatabase.SongMode.SupporterOnly then
			list_element.DifficultyDisplay.Text = list_element.DifficultyDisplay.Text .. " (Supporter Only)"
		end

		list_element.Name = string.format("SongKey%0d", song_key)
		list_element:SetAttribute("_key", song_key)
		list_element:SetAttribute("_searchstring", SongDatabase:get_search_string_for_key(song_key))
		
		SPUtil:bind_input_fire(list_element, function(_)
			_on_song_key_selected(song_key)
		end)
	end

    self:cons()

    return self
end

return withSongList
