local Networking = require(game.ReplicatedStorage.Networking)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local LeaderboardDisplay = {}

function LeaderboardDisplay:new(_leaderboard_ui_root, _leaderboard_proto)
	local self = {}
	_leaderboard_proto.Parent = nil
	local _leaderboard_list_root = _leaderboard_ui_root.LeaderboardList
	local _leaderboard_loading_display = _leaderboard_ui_root.LoadingDisplay
	_leaderboard_loading_display.Visible = false
	
	local function get_formatted_data(data)
		local str = "%.2f%% | %0d / %0d / %0d / %0d"
		return string.format(str, data.accuracy*100, data.perfects, data.greats, data.okays, data.misses)
	end
	
	local _last_load_start_time
	function self:refresh_leaderboard(songkey)
		_last_load_start_time = os.time()
		local load_start_time = _last_load_start_time
		_leaderboard_loading_display.Visible = true
		spawn(function()
			--// CLEAR LEADERBOARD LIST
			for i, v in pairs(_leaderboard_list_root:GetChildren()) do
				if v:IsA("Frame") then
					v:Destroy()
				end
			end

			--// GET NEW LEADERBOARD
			local leaderboardData = Networking.Client:Execute("GetLeaderboard", {
				mapid = songkey
			}) or {}
			if load_start_time ~= _last_load_start_time then
				return --loaded another leaderboard since when this load was begun, do not display info
			end
			
			--// RENDER NEW LEADERBOARD
			for itr, itr_data in pairs(leaderboardData) do
				local itr_leaderboard_proto = _leaderboard_proto:Clone()

				itr_leaderboard_proto.Player.Text = string.format("%s - %s", itr_data.playername, SPUtil:time_to_str(itr_data.time))
				itr_leaderboard_proto.Data.Text = get_formatted_data(itr_data)
				itr_leaderboard_proto.UserThumbnail.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", itr_data.userid)

				itr_leaderboard_proto.Parent = _leaderboard_list_root
			end
			_leaderboard_loading_display.Visible = false
		end)
	end
	return self
end
return LeaderboardDisplay