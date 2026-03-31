local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local InputUtil = require(game.ReplicatedStorage.Shared.InputUtil)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local Configuration = require(game.ReplicatedStorage.Configuration)

local UserInputService = game:GetService("UserInputService")

local TouchTrackDisplay = {}

local DEFAULT_TOUCH_ENDS = { 0.25, 0.5, 0.75 }
local TOUCH_IMAGE = "rbxassetid://1203531441"

local IDLE_ALPHA = 0.15
local PRESSED_ALPHA = 0.4
local IDLE_ALPHA_LERP_SEC = 0.25

local TRACK_KEYS = {
	InputUtil.KEYCODE_TOUCH_TRACK1,
	InputUtil.KEYCODE_TOUCH_TRACK2,
	InputUtil.KEYCODE_TOUCH_TRACK3,
	InputUtil.KEYCODE_TOUCH_TRACK4,
}

local function is_touch_mode_enabled()
	return UserInputService.TouchEnabled == true or SPUtil:is_mobile_like() == true
end

local function is_upclose_mode_enabled()
	-- Default to Upclose unless explicitly disabled.
	return Configuration.Preferences.MobileFullScreenUI ~= false
end

local function should_show_touch_controls()
	-- 0=Default, 1=On, 2=Off
	local setting = tonumber(Configuration.Preferences.MobileShowTouchControls) or 0
	return setting ~= 2
end

local function clamp_touch_ends(track1End, track2End, track3End)
	track1End = math.clamp(track1End, 0.05, 0.7)
	track2End = math.clamp(track2End, track1End + 0.05, 0.85)
	track3End = math.clamp(track3End, track2End + 0.05, 0.95)
	return track1End, track2End, track3End
end

function TouchTrackDisplay:new(robeatsGame)
	local self = {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "MobileTouchDisplay"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 0
	gui.Enabled = false
	gui.Parent = EnvironmentSetup:get_player_gui_root()

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromScale(1, 1)
	container.Parent = gui

	local panes = {}
	local pane_alphas = {}
	for index = 1, 4 do
		local pane = Instance.new("ImageLabel")
		pane.Name = string.format("Track%d", index)
		pane.Active = false
		pane.BorderSizePixel = 0
		pane.BackgroundTransparency = 1
		pane.Image = TOUCH_IMAGE
		pane.ScaleType = Enum.ScaleType.Stretch
		pane.ImageTransparency = SPUtil:tra(IDLE_ALPHA)
		pane.Size = UDim2.fromScale(0.25, 1)
		pane.Position = UDim2.fromScale((index - 1) * 0.25, 0)
		pane.ZIndex = 0
		pane.Parent = container
		panes[index] = pane
		pane_alphas[index] = IDLE_ALPHA
	end

	local function set_defaults()
		robeatsGame._input:set_touch_track_ends(DEFAULT_TOUCH_ENDS[1], DEFAULT_TOUCH_ENDS[2], DEFAULT_TOUCH_ENDS[3])
	end

	local function get_track_screen_x(trackIndex)
		local camera = workspace.CurrentCamera
		local trackSystem = robeatsGame:get_local_tracksystem()
		if camera == nil or trackSystem == nil then
			return nil
		end

		local viewportSize = camera.ViewportSize
		if viewportSize.X <= 0 then
			return nil
		end

		local track = trackSystem:get_track(trackIndex)
		if track == nil then
			return nil
		end

		local screenPoint = camera:WorldToViewportPoint(track:get_end_position())
		return screenPoint.X / viewportSize.X
	end

	local function compute_touch_ends()
		if is_upclose_mode_enabled() ~= true then
			return DEFAULT_TOUCH_ENDS[1], DEFAULT_TOUCH_ENDS[2], DEFAULT_TOUCH_ENDS[3]
		end

		local x1 = get_track_screen_x(1)
		local x2 = get_track_screen_x(2)
		local x3 = get_track_screen_x(3)
		local x4 = get_track_screen_x(4)
		if x1 == nil or x2 == nil or x3 == nil or x4 == nil then
			return DEFAULT_TOUCH_ENDS[1], DEFAULT_TOUCH_ENDS[2], DEFAULT_TOUCH_ENDS[3]
		end

		return clamp_touch_ends(
			(x1 + x2) * 0.5,
			(x2 + x3) * 0.5,
			(x3 + x4) * 0.5
		)
	end

	local function layout_panes(track1End, track2End, track3End)
		local edges = { 0, track1End, track2End, track3End, 1 }
		for index = 1, 4 do
			panes[index].Position = UDim2.fromScale(edges[index], 0)
			panes[index].Size = UDim2.fromScale(edges[index + 1] - edges[index], 1)
		end
	end

	function self:update(dt_scale)
		if is_touch_mode_enabled() ~= true then
			gui.Enabled = false
			set_defaults()
			return
		end

		local track1End, track2End, track3End = compute_touch_ends()
		robeatsGame._input:set_touch_track_ends(track1End, track2End, track3End)

		local show_controls = should_show_touch_controls()
		gui.Enabled = show_controls
		if show_controls ~= true then
			return
		end

		layout_panes(track1End, track2End, track3End)

		for index = 1, 4 do
			if robeatsGame._input:control_pressed(TRACK_KEYS[index]) then
				pane_alphas[index] = PRESSED_ALPHA
			else
				pane_alphas[index] = CurveUtil:expt_sec(pane_alphas[index], IDLE_ALPHA, IDLE_ALPHA_LERP_SEC, dt_scale)
			end
			panes[index].ImageTransparency = SPUtil:tra(pane_alphas[index])
		end
	end

	function self:teardown()
		set_defaults()
		gui:Destroy()
	end

	return self
end

return TouchTrackDisplay
