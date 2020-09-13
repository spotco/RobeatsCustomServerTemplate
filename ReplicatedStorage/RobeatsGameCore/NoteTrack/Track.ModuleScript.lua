local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local TriggerButton = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.TriggerButton)
local GameSlot = require(game.ReplicatedStorage.Shared.GameSlot)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local Track = {}

function Track:new(track_system, offset_angle, name, _game, track_index)
	local self = {}
	
	local _offset_angle = offset_angle
	local _track_obj = nil
	local _trigger_button = nil
	local _parent_track_system = track_system
		
	local _rotation = 0
	local function get_rotation()
		return _rotation
	end
	local function set_rotation(rotation)
		_rotation = rotation		
		_track_obj.PrimaryPart.Rotation = Vector3.new(0,-rotation-180,90)
	end
	local _primary_part_size_y = 0
	local _primary_part_position = Vector3.new()
	
	local _world_to_player_dirn = Vector3.new()
	function self:world_to_player_dirn()
		return _world_to_player_dirn
	end
	
	function self:cons(player_info)
		local world_center = track_system:get_player_world_center()
		local player_position = track_system:get_player_world_position()		
		
		_track_obj = EnvironmentSetup:get_element_protos_folder().PlayerTrackProto:Clone()
		
		self:update_brick_color(1,_game)

		local world_to_player_dir = player_position-world_center
		_world_to_player_dirn = world_to_player_dir.unit
		local world_to_player_rotation = SPUtil:dir_ang_deg(
			world_to_player_dir.X,
			world_to_player_dir.Z
		)
		
		_track_obj.PrimaryPart.Size = Vector3.new(0.5,world_to_player_dir.Magnitude,0.25)
		_primary_part_size_y = _track_obj.PrimaryPart.Size.Y			
		
		do
			local offset_rotation = world_to_player_rotation + offset_angle
			local offset_dir = 0
			do
				local xy_dir = SPUtil:ang_deg_dir(offset_rotation)
				offset_dir = Vector3.new(
				  xy_dir.X,
				  0,					
				  xy_dir.Y
				) * world_to_player_dir.Magnitude
			end			
			
			local offset_mid = offset_dir * 0.5 + world_center

			_primary_part_position = Vector3.new(offset_mid.X, 0.5 + _game:get_game_environment_center_position().Y, offset_mid.Z)
			_track_obj.PrimaryPart.Position = _primary_part_position + Vector3.new(0,-0.85,0)		
			set_rotation(offset_rotation)		
		end	
			
		set_rotation(get_rotation() - offset_angle * 0.25)

		_track_obj.Name = name
		_track_obj.Parent = EnvironmentSetup:get_local_elements_folder()
		
		_trigger_button = TriggerButton:new(
			_game,
			self:get_end_position(), 
			_parent_track_system,
			track_index
		)
	end
	
	function self:teardown()
		_track_obj:Destroy()
		_parent_track_system = nil
		_trigger_button:teardown()
		_trigger_button = nil
		self = nil
		_game = nil
		track_system = nil
		
	end
	
	function self:update_brick_color(dt_scale, game)
		if _game._players._slots:contains(_parent_track_system._game_slot) == false then
			return
		end
		
		local target_transparency = 0
		_track_obj.PlayerTrackProto.BrickColor, target_transparency = GameSlot:slot_to_color_and_transparency(_parent_track_system._game_slot)
		_track_obj.PlayerTrackProto.Transparency = target_transparency
	end
	
	function self:update(dt_scale,game)
		_trigger_button:update(dt_scale,game)
		self:update_brick_color(dt_scale,game)
	end
	
	function self:get_start_position()
		local dir_xy = SPUtil:ang_deg_dir(get_rotation()).unit
		local dir = Vector3.new(dir_xy.x, 0, dir_xy.y)
		return _primary_part_position + (dir * -1 * _primary_part_size_y * 0.5)
	end
	function self:get_end_position()
	  --local END_PCT = 0.55		
	  local END_PCT = 0.1
	  local dir_xy = SPUtil:ang_deg_dir(get_rotation()).unit
	  local dir = Vector3.new(dir_xy.x, 0, dir_xy.y)
	  return _primary_part_position + (dir * 1 * _primary_part_size_y * 0.5 * END_PCT)
	end
	
	function self:press()
		_trigger_button:press()
	end
	function self:release()
		_trigger_button:release()
	end
	

	self:cons()
	return self
end

return Track
