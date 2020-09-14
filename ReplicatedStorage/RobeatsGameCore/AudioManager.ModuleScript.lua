local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local RandomLua = require(game.ReplicatedStorage.Shared.RandomLua)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local Constants = require(game.ReplicatedStorage.Shared.Constants)
local HitSFXGroup = require(game.ReplicatedStorage.RobeatsGameCore.HitSFXGroup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)

local SingleNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.SingleNote)
local HeldNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.HeldNote)

local AudioManager = {}
AudioManager.Mode = {
	NotLoaded = 0;
	Loading = 1;
	PreStart = 3;
	Playing = 4;
	PostPlaying = 5;
	Finished = 6;
}

function AudioManager:new(_game)
	local self = {}

	self.NOTE_PREBUFFER_TIME = 500
	self.NOTE_OKAY_MAX = 150
	self.NOTE_GREAT_MAX = 90
	self.NOTE_PERFECT_MAX = 40
	self.NOTE_PERFECT_MIN = -20
	self.NOTE_GREAT_MIN = -45
	self.NOTE_OKAY_MIN = -85
	self.NOTE_REMOVE_TIME = -200

	local PRE_START_TIME_MS_MAX = Constants.PRE_START_TIME_MS_MAX
	local POST_TIME_PLAYING_MS_MAX = Constants.POST_TIME_PLAYING_MS_MAX

	self._audio_time_offset = 0

	self._bgm = Instance.new("Sound", EnvironmentSetup:get_local_elements_folder())
	self._bgm.Name = "BGM"
	self._bgm_time_position = 0
	self._current_audio_data = nil
	self._audio_data_index = 1
	self._hit_sfx_group = nil

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
		self._audio_data_index = 1
		self._current_audio_data = SongDatabase:singleton():get_data_for_key(_song_key)
		for i=1,#self._current_audio_data.HitObjects do
			local itr = self._current_audio_data.HitObjects[i]
			if itr.Type == 1 then
				_note_count = _note_count + 1
			else
				_note_count = _note_count + 2
			end
		end

		local sfxg_id = self._current_audio_data.AudioHitSFXGroup
		self._hit_sfx_group = HitSFXGroup:new(_game,sfxg_id)
		self._hit_sfx_group:preload()

		self._audio_time_offset = self._current_audio_data.AudioTimeOffset

		self._bgm.SoundId = self._current_audio_data.AudioAssetId
		self._bgm.Playing = true
		self._bgm.Volume = 0
		self._bgm.PlaybackSpeed = 0
		self._bgm_time_position = 0

		if self._current_audio_data.AudioVolume ~= nil then
			_audio_volume = self._current_audio_data.AudioVolume
		end

		if self._current_audio_data.AudioNotePrebufferTime == nil then
			self.NOTE_PREBUFFER_TIME = 1500
		else
			self.NOTE_PREBUFFER_TIME = self._current_audio_data.AudioNotePrebufferTime
		end

		if self._current_audio_data.RandomSeed == nil then
			self._note_gen_rand = RandomLua.mwc(0)
		else
			self._note_gen_rand = RandomLua.mwc(self._current_audio_data.RandomSeed)
		end
	end

	function self:teardown()
		self._bgm:Destroy()
	end

	function self:is_ready_to_play()
		return self._current_audio_data ~= nil and self._bgm.IsLoaded == true
	end

	function self:is_prestart() return _current_mode == AudioManager.Mode.PreStart end
	function self:is_playing() return _current_mode == AudioManager.Mode.Playing end
	function self:is_finished() return _current_mode == AudioManager.Mode.Finished end

	function self:get_note_prebuffer_time_ms()
		return self.NOTE_PREBUFFER_TIME
	end

	local function push_back_single_note(
		i,
		itr_hitobj,
		current_time_ms,
		hit_time)

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
		hit_time,duration)

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
		if _current_mode == AudioManager.Mode.PreStart then
			local pre_start_time_pre = _pre_start_time_ms
			local pre_start_time_post = _pre_start_time_ms + CurveUtil:TimescaleToDeltaTime(dt_scale) * 1000
			_pre_start_time_ms = pre_start_time_post

			local PCT_3 = PRE_START_TIME_MS_MAX * 0.2
			local PCT_2 = PRE_START_TIME_MS_MAX * 0.4
			local PCT_1 = PRE_START_TIME_MS_MAX * 0.6
			local PCT_START = PRE_START_TIME_MS_MAX * 0.8

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
				_raise_pre_start_trigger_duration = PRE_START_TIME_MS_MAX - PCT_START

			end

			if _pre_start_time_ms >= PRE_START_TIME_MS_MAX then
				self._bgm.TimePosition = 0
				self._bgm.Volume = _audio_volume
				self._bgm.PlaybackSpeed = 1
				self._bgm_time_position = 0
				_ended_connection = self._bgm.Ended:Connect(function()
					_raise_ended_trigger = true
					_ended_connection:Disconnect()
					_ended_connection = nil
				end)

				_current_mode = AudioManager.Mode.Playing
			end

			self:update_spawn_notes(dt_scale)

		elseif _current_mode == AudioManager.Mode.Playing then
			self:update_spawn_notes(dt_scale)
			self._bgm_time_position = math.min(
				self._bgm_time_position + CurveUtil:TimescaleToDeltaTime(dt_scale),
				self._bgm.TimeLength
			)

			if _raise_ended_trigger == true then
				_current_mode = AudioManager.Mode.PostPlaying
			end

		elseif _current_mode == AudioManager.Mode.PostPlaying then
			_post_playing_time_ms = _post_playing_time_ms + CurveUtil:TimescaleToDeltaTime(dt_scale) * 1000
			if _post_playing_time_ms > POST_TIME_PLAYING_MS_MAX then
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

		local test_time = current_time_ms + note_prebuffer_time_ms - PRE_START_TIME_MS_MAX

		for i=self._audio_data_index,#self._current_audio_data.HitObjects do
			local itr_hitobj = self._current_audio_data.HitObjects[i]
			if test_time >= itr_hitobj.Time then
				if itr_hitobj.Type == 1 then
					push_back_single_note(
						i,
						itr_hitobj,
						current_time_ms,
						itr_hitobj.Time + PRE_START_TIME_MS_MAX
					)

				elseif itr_hitobj.Type == 2 then
					push_back_heldnote(
						i,
						itr_hitobj,
						current_time_ms,
						itr_hitobj.Time + PRE_START_TIME_MS_MAX,
						itr_hitobj.Duration
					)

				end

				self._audio_data_index = self._audio_data_index + 1
			else
				break
			end
		end
	end

	local _i_beat_data = 1
	function self:get_beat_duration()
		local beat_duration = self._current_audio_data.TimingPoints[1].BeatLength
		local current_time = self:get_current_time_ms()
		for i=_i_beat_data,#self._current_audio_data.TimingPoints do
			local itr = self._current_audio_data.TimingPoints[i]
			if current_time >= itr.Time then
				beat_duration = itr.BeatLength
				_i_beat_data = i
			else
				break
			end

		end
		return beat_duration
	end

	function self:get_current_time_ms()
		return self._bgm_time_position * 1000 + self._audio_time_offset + _pre_start_time_ms
	end

	function self:get_current_time_bgm_ms()
		-- Does not update at 60fps
		return self._bgm.TimePosition * 1000 + self._audio_time_offset + _pre_start_time_ms
	end

	function self:get_song_length_ms()
		return self._bgm.TimeLength * 1000 + PRE_START_TIME_MS_MAX
	end

	return self
end

return AudioManager
