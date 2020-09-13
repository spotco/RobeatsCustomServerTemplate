local SPDict = require(game.ReplicatedStorage.Shared.SPDict)

local ServerGameInstancePlayer = {}

function ServerGameInstancePlayer:new(user_id, name)
	local self = {}

	----- SHARED ------

	self._id = user_id
	self._name = name
	self._requested_song_key = nil

	------ GAME ------

	self._score = 0
	self._chain = 0
	self._power_bar_active = false
	self._finished = false

	-- non-replicated
	self._perfect_count = 0
	self._great_count = 0
	self._okay_count = 0
	self._miss_count = 0

	------ JOIN ------

	self._ready = false
	self._matchmaking_time = 0

	------ VOTEPICK ------

	self._votepick_song_key = nil
	self._timeout = 0

	------ SOUNDLOAD ------

	self._loaded = false

	------------------

	function self:set_requested_song_key(val)
		self._requested_song_key = val
	end

	return self
end

return ServerGameInstancePlayer
