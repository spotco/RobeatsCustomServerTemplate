local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local RandomLua = require(game.ReplicatedStorage.Shared.RandomLua)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local HitSFXGroup = require(game.ReplicatedStorage.RobeatsGameCore.HitSFXGroup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local Configuration = require(game.ReplicatedStorage.Configuration)

local SingleNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.SingleNote)
local HeldNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.HeldNote)

local AudioManager = {}
AudioManager.Mode = {
	NotLoaded = 0; --No audio is loaded (call AudioManager:load_song)
	Loading = 1; --Audio is loading
	PreStart = 3; --Doing the pre-start countdown
	Playing = 4; --Game is playing
	PostPlaying = 5; --Delay before ending game
	Finished = 6; --Game has finished
}

function AudioManager:new(_game)
	local self = {}

	local _rate = 1 --Rate multiplier, you may implement some sort of way to modify the rate at runtime.
	
	--Note speed in milliseconds, from time it takes to spawn the note to time the note is hit. Default value is 1500, or 1.5 seconds.
	--To add a multiplier to this, set Configuration.Preferences.NoteSpeedMultiplier
	local _note_prebuffer_time = 0
	function self:get_note_prebuffer_time_ms() return _note_prebuffer_time end
	
	--Note timings: millisecond offset (positive is early, negative is late) mapping to what the note result is
	local _note_okay_max = Configuration.Preferences.NoteOkayMaxMS * _rate --Default: 260
	local _note_great_max = Configuration.Preferences.NoteGreatMaxMS * _rate --Default: 140
	local _note_perfect_max = Configuration.Preferences.NotePerfectMaxMS * _rate --Default: 40
	local _note_perfect_min = Configuration.Preferences.NotePerfectMinMS * _rate --Default: -20
	local _note_great_min = Configuration.Preferences.NoteGreatMinMS * _rate --Default: -70
	local _note_okay_min = Configuration.Preferences.NoteOkayMinMS * _rate --Default: -140
	
	--Called in NoteResult:timedelta_to_result(time_to_end, _game)
	function self:get_note_result_timing()
		return _note_okay_max, _note_great_max, _note_perfect_max, _note_perfect_min, _note_great_min, _note_okay_min
	end
	
	--Time in milliseconds after note expected hit time to remove note (and do a Time miss)
	local _note_remove_time = Configuration.Preferences.NoteRemoveTimeMS * _rate --Default: -200
	function self:get_note_remove_time() return _note_remove_time end
	
	--Time in milliseconds countdown will take
	local _pre_countdown_time_ms = Configuration.Preferences.PreStartCountdownTimeMS --Default: 3000
	
	--Time in milliseconds to wait after game finishes to end
	local _post_finish_wait_time_ms = Configuration.Preferences.PostFinishWaitTimeMS --Default:300

	--Audio offset is milliseconds
	local _audio_time_offset = Configuration.Preferences.AudioOffset
	
	--The game audio
	local _bgm = Instance.new("Sound", EnvironmentSetup:get_local_elements_folder())
	_bgm.Name = "BGM"
	function self:get_bgm() return _bgm end
	
	--Keeping track of BGM TimePosition ourselves (Sound.TimePosition does not update at 60fps)
	local _bgm_time_position = 0
	local _current_audio_data
	
	--Index of _current_audio_data.HitObject we are currently at
	local _audio_data_index = 1
	
	--Hit sounds (group is determined by the song map)
	local _hit_sfx_group = nil
	function self:get_hit_sfx_group() return _hit_sfx_group end

	local _current_mode = AudioManager.Mode.NotLoaded
	function self:get_mode() return _current_mode end

	local _is_playing = false
	local _pre_start_time_ms = 0
	local _post_playing_time_ms = 0
	local _audio_volume = 0.5

	local _song_key = 0
	function self:get_song_key() return _song_key end

	local _note_count = 0
	function self:get_note_count() return _note_count end
	function self:load_song(song_key)

		_song_key = song_key
		_current_mode = AudioManager.Mode.Loading
		_audio_data_index = 1
		_current_audio_data = SongDatabase:get_data_for_key(_song_key)
		for i=1,#_current_audio_data.HitObjects do
			local itr = _current_audio_data.HitObjects[i]
			if itr.Type == 1 then
				_note_count = _note_count + 1
			else
				_note_count = _note_count + 2
			end
		end

		local sfxg_id = _current_audio_data.AudioHitSFXGroup
		_hit_sfx_group = HitSFXGroup:new(_game,sfxg_id)
		_hit_sfx_group:preload()

		_audio_time_offset = _audio_time_offset + _current_audio_data.AudioTimeOffset

		_bgm.SoundId = _current_audio_data.AudioAssetId
		_bgm.Playing = true
		_bgm.Volume = 0
		_bgm.PlaybackSpeed = 0
		_bgm_time_position = 0

		if _current_audio_data.AudioVolume ~= nil then
			_audio_volume = _current_audio_data.AudioVolume
		end
		
		--Apply note speed multiplier
		_note_prebuffer_time = (_current_audio_data.AudioNotePrebufferTime / Configuration.Preferences.NoteSpeedMultiplier)*_rate
	end

	function self:teardown()
		_bgm:Destroy()
	end

	function self:is_ready_to_play()
		return _current_audio_data ~= nil and _bgm.IsLoaded == true
	end

	function self:is_prestart() return _current_mode == AudioManager.Mode.PreStart end
	function self:is_playing() return _current_mode == AudioManager.Mode.Playing end
	function self:is_finished() return _current_mode == AudioManager.Mode.Finished end

	local function push_back_single_note(
		i,
		itr_hitobj,
		current_time_ms,
		hit_time
	)
		local track_number = itr_hitobj.Track
		AssertType:is_int(track_number)

		for slot_id,tracksystem in _game:tracksystems_itr() do
			tracksystem:get_notes():push_back(
				SingleNote:new(
					_game,
					track_number,
					tracksystem:get_game_slot(),
					current_time_ms,
					hit_time
				)
			)
		end
	end

	local function push_back_heldnote(
		i,
		itr_hitobj,
		current_time_ms,
		hit_time,duration
	)

		local track_number = itr_hitobj.Track
		AssertType:is_int(track_number)

		for slot_id,tracksystem in _game:tracksystems_itr() do
			tracksystem:get_notes():push_back(
				HeldNote:new(
					_game,
					track_number,
					tracksystem:get_game_slot(),
					current_time_ms,
					hit_time,
					duration
				)
			)
		end
	end

	function self:start_play()
		_current_mode = AudioManager.Mode.PreStart
		_pre_start_time_ms = 0
	end

	local _raise_pre_start_trigger = false
	local _raise_pre_start_trigger_val = 0
	local _raise_pre_start_trigger_duration = 0
	function self:raise_pre_start_trigger()
		local rtv = _raise_pre_start_trigger
		_raise_pre_start_trigger = false
		return rtv, _raise_pre_start_trigger_val, _raise_pre_start_trigger_duration
	end

	local _raise_ended_trigger = false
	local _raise_just_finished = false
	local _ended_connection = nil

	function self:update(dt_scale)
		dt_scale = dt_scale * _rate
		if _current_mode == AudioManager.Mode.PreStart then
			--Do pre-start countdown
			local pre_start_time_pre = _pre_start_time_ms
			local pre_start_time_post = _pre_start_time_ms + CurveUtil:TimescaleToDeltaTime(dt_scale) * 1000
			_pre_start_time_ms = pre_start_time_post

			local PCT_3 = _pre_countdown_time_ms * 0.2
			local PCT_2 = _pre_countdown_time_ms * 0.4
			local PCT_1 = _pre_countdown_time_ms * 0.6
			local PCT_START = _pre_countdown_time_ms * 0.8

			if pre_start_time_pre < PCT_3 and pre_start_time_post > PCT_3 then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 4
				_raise_pre_start_trigger_duration = PCT_2 - PCT_3

			elseif pre_start_time_pre < PCT_2 and pre_start_time_post > PCT_2 then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 3
				_raise_pre_start_trigger_duration = PCT_1 - PCT_2

			elseif pre_start_time_pre < PCT_1 and pre_start_time_post > PCT_1 then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 2
				_raise_pre_start_trigger_duration = PCT_START - PCT_1

			elseif pre_start_time_pre < PCT_START and pre_start_time_post > PCT_START then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 1
				_raise_pre_start_trigger_duration = _pre_countdown_time_ms - PCT_START

			end

			if _pre_start_time_ms >= _pre_countdown_time_ms then
				_bgm.TimePosition = 0
				_bgm.Volume = _audio_volume
				_bgm.PlaybackSpeed = _rate
				_bgm_time_position = 0
				_ended_connection = _bgm.Ended:Connect(function()
					_raise_ended_trigger = true
					_ended_connection:Disconnect()
					_ended_connection = nil
				end)

				_current_mode = AudioManager.Mode.Playing
			end

			self:update_spawn_notes(dt_scale)

		elseif _current_mode == AudioManager.Mode.Playing then
			self:update_spawn_notes(dt_scale)
			_bgm_time_position = math.min(
				_bgm_time_position + CurveUtil:TimescaleToDeltaTime(dt_scale),
				_bgm.TimeLength
			)

			if _raise_ended_trigger == true then
				_current_mode = AudioManager.Mode.PostPlaying
			end

		elseif _current_mode == AudioManager.Mode.PostPlaying then
			_post_playing_time_ms = _post_playing_time_ms + CurveUtil:TimescaleToDeltaTime(dt_scale) * 1000
			if _post_playing_time_ms > _post_finish_wait_time_ms then
				_current_mode = AudioManager.Mode.Finished
				_raise_just_finished = true
			end
		end
	end

	function self:get_just_finished()
		local rtv = _raise_just_finished
		_raise_just_finished = false
		return rtv
	end

	function self:update_spawn_notes(dt_scale)
		local current_time_ms = self:get_current_time_ms()
		local note_prebuffer_time_ms = self:get_note_prebuffer_time_ms()

		local test_time = current_time_ms + note_prebuffer_time_ms - _pre_countdown_time_ms

		for i=_audio_data_index,#_current_audio_data.HitObjects do
			local itr_hitobj = _current_audio_data.HitObjects[i]
			if test_time >= itr_hitobj.Time then
				if itr_hitobj.Type == 1 then
					push_back_single_note(
						i,
						itr_hitobj,
						current_time_ms,
						itr_hitobj.Time + _pre_countdown_time_ms
					)

				elseif itr_hitobj.Type == 2 then
					push_back_heldnote(
						i,
						itr_hitobj,
						current_time_ms,
						itr_hitobj.Time + _pre_countdown_time_ms,
						itr_hitobj.Duration
					)
				end
				_audio_data_index = _audio_data_index + 1
			else
				break
			end
		end
	end

	function self:get_current_time_ms()
		return _bgm_time_position * 1000 + _audio_time_offset + _pre_start_time_ms
	end

	function self:get_song_length_ms()
		return _bgm.TimeLength * 1000 + _pre_countdown_time_ms
	end

	return self
end

return AudioManager
