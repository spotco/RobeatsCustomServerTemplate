local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SongErrorParser = require(game.ReplicatedStorage.RobeatsGameCore.SongErrorParser)

local SongMapList = require(game.Workspace.SongMapList)

local SongDatabase = {}

SongDatabase.SongMode = {
    Normal = 0;
    SupporterOnly = 1;
}

local function shallow_copy(data)
    local copy = {}
    for key, value in pairs(data) do
        copy[key] = value
    end
    return copy
end

local function require_module_clone(moduleScript)
    local moduleClone = moduleScript:Clone()
    local ok, result = pcall(require, moduleClone)
    moduleClone:Destroy()
    if ok ~= true then
        error(result)
    end
    return result
end

local function calculate_hit_count(hitObjects)
    local hitCount = 0
    for i = 1, #hitObjects do
        if hitObjects[i].Type == 2 then
            hitCount = hitCount + 2
        else
            hitCount = hitCount + 1
        end
    end
    return hitCount
end

local function calculate_last_note_time(hitObjects)
    if #hitObjects == 0 then
        return 0
    end
    return hitObjects[#hitObjects].Time or 0
end

local function calculate_bpm(timingPoints)
    if timingPoints == nil or timingPoints[1] == nil or timingPoints[1].BeatLength == nil or timingPoints[1].BeatLength == 0 then
        return nil
    end
    return math.floor((60000 / timingPoints[1].BeatLength) + 0.5)
end

local function build_header_from_songdata(songdata)
    local header = shallow_copy(songdata)
    local hitObjects = songdata.HitObjects or {}
    local timingPoints = songdata.TimingPoints or {}

    header.HitCount = songdata.HitCount or calculate_hit_count(hitObjects)
    header.HitObjectsCount = songdata.HitObjectsCount or #hitObjects
    header.LastNoteTime = songdata.LastNoteTime or calculate_last_note_time(hitObjects)
    header.BPM = songdata.BPM or calculate_bpm(timingPoints)
    header.HitObjects = nil
    header.TimingPoints = nil
    header.Loaded = false

    return header
end

local function load_songmodule_clone(songModule)
    local loadedSongData = require_module_clone(songModule)
    SongErrorParser:scan_audiodata_for_errors(loadedSongData)
    return loadedSongData
end

function SongDatabase:new()
    local self = {}
    self.SongMode = SongDatabase.SongMode

    local _all_keys = SPDict:new()
    local _key_list = SPList:new()
    local _name_to_key = SPDict:new()
    local _key_to_modulescript = SPDict:new()

    local function get_or_build_header(songModule)
        return build_header_from_songdata(load_songmodule_clone(songModule))
    end

    local function load_chart_data_for_key(key)
        local data = _all_keys:get(key)
        local songModule = _key_to_modulescript:get(key)
        if data == nil or songModule == nil then
            return nil
        end

        local loadedSongData = load_songmodule_clone(songModule)
        data.Loaded = true
        data.HitObjects = loadedSongData.HitObjects or {}
        data.TimingPoints = loadedSongData.TimingPoints or {}
        data.HitCount = loadedSongData.HitCount or data.HitCount or calculate_hit_count(data.HitObjects)
        data.HitObjectsCount = loadedSongData.HitObjectsCount or data.HitObjectsCount or #data.HitObjects
        data.LastNoteTime = loadedSongData.LastNoteTime or data.LastNoteTime or calculate_last_note_time(data.HitObjects)
        data.BPM = loadedSongData.BPM or data.BPM or calculate_bpm(data.TimingPoints)
        return data
    end

    function self:cons()
        for key = 1, #SongMapList do
            local songModule = SongMapList[key]
            local songHeader = get_or_build_header(songModule)
            self:add_key_to_data(key, songModule, songHeader)
            _name_to_key:add(songModule.Name, key)
        end
    end

    function self:add_key_to_data(key, songModule, songHeader)
        if _all_keys:contains(key) then
            error(string.format("SongDatabase:add_key_to_data duplicate(%s)", tostring(key)))
        end

        local data = shallow_copy(songHeader)
        data.__key = key
        data.Loaded = false
        data.HitObjects = {}
        data.TimingPoints = {}

        _key_to_modulescript:add(key, songModule)
        _all_keys:add(key, data)
        _key_list:push_back(key)
    end

    function self:key_itr()
        local index = 0
        return function()
            index = index + 1
            local key = _key_list:get(index)
            if key == nil then
                return nil
            end
            return key, _all_keys:get(key)
        end
    end

    function self:get_data_for_key(key)
        local data = _all_keys:get(key)
        if data == nil then
            return nil
        end
        if data.Loaded ~= true then
            data = load_chart_data_for_key(key)
        end
        return data
    end

    function self:is_key_data_loaded(key)
        local data = _all_keys:get(key)
        return data ~= nil and data.Loaded == true
    end

    function self:release_data_for_key(key)
        local data = _all_keys:get(key)
        if data == nil then
            return
        end
        data.HitObjects = {}
        data.TimingPoints = {}
        data.Loaded = false
    end

    function self:contains_key(key)
        return _all_keys:contains(key)
    end

    function self:name_to_key(name)
        return _name_to_key:get(name)
    end

    function self:name_to_key_itr()
        return _name_to_key:key_itr()
    end

    function self:key_to_name(key)
        local songModule = _key_to_modulescript:get(key)
        if songModule == nil then
            return nil
        end
        return songModule.Name
    end

    function self:key_get_audiomod(key)
        local data = _all_keys:get(key)
        if data == nil then
            return SongDatabase.SongMode.Normal
        end
        if data.AudioMod == 1 then
            return SongDatabase.SongMode.SupporterOnly
        end
        return SongDatabase.SongMode.Normal
    end

    function self:render_coverimage_for_key(coverImage, overlayImage, key)
        local songdata = _all_keys:get(key)
        if songdata == nil then
            coverImage.Image = ""
            overlayImage.Visible = false
            return
        end

        coverImage.Image = songdata.AudioCoverImageAssetId or ""
        if self:key_get_audiomod(key) == SongDatabase.SongMode.SupporterOnly then
            overlayImage.Image = "rbxassetid://837274453"
            overlayImage.Visible = true
        else
            overlayImage.Visible = false
        end
    end

    function self:get_title_for_key(key)
        local songdata = _all_keys:get(key)
        return songdata == nil and "" or songdata.AudioFilename
    end

    function self:get_artist_for_key(key)
        local songdata = _all_keys:get(key)
        return songdata == nil and "" or songdata.AudioArtist
    end

    function self:get_difficulty_for_key(key)
        local songdata = _all_keys:get(key)
        return songdata == nil and -1 or songdata.AudioDifficulty
    end

    function self:get_description_for_key(key)
        local songdata = _all_keys:get(key)
        return songdata == nil and "" or songdata.AudioDescription
    end

    function self:invalid_songkey()
        return -1
    end

    self:cons()
    return self
end

return SongDatabase:new()
