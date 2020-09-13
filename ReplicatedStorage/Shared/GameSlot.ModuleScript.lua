local GameSlot = {
	SLOT_1 = 1;
	SLOT_2 = 2;
	SLOT_3 = 3;
	SLOT_4 = 4;	
}

GameSlot._world_center_position = Vector3.new()

function GameSlot:set_world_center_position(pos)
	GameSlot._world_center_position = pos
end

function GameSlot:slot_to_world_position(slot)
	local DIST = 50
	if slot == GameSlot.SLOT_1 then
		return Vector3.new(-DIST,0,DIST) + GameSlot._world_center_position	
		
	elseif slot == GameSlot.SLOT_2 then
		return Vector3.new(-DIST,0,-DIST) + GameSlot._world_center_position	
		
	elseif slot == GameSlot.SLOT_3 then
		return Vector3.new(DIST,0,-DIST) + GameSlot._world_center_position		
		
	else
		return Vector3.new(DIST,0,DIST) + GameSlot._world_center_position	
		
	end
end

local DEFAULT_HORIZ_DISTANCE = 36.5
local DEFAULT_UP_DISTANCE = 14
local DEFAULT_LOOKAT_HORIZ_DISTANCE = 17.5
function GameSlot:slot_to_camera_cframe(slot, horiz_distance, up_distance, lookat_distance)
	if horiz_distance == nil then horiz_distance = DEFAULT_HORIZ_DISTANCE end
	if up_distance == nil then up_distance = DEFAULT_UP_DISTANCE end
	if lookat_distance == nil then lookat_distance = DEFAULT_LOOKAT_HORIZ_DISTANCE end
	
	if slot == GameSlot.SLOT_1 then	
		return 	CFrame.new(
			Vector3.new(-horiz_distance, up_distance, horiz_distance) + GameSlot._world_center_position,
			Vector3.new(-lookat_distance, 0, lookat_distance) + GameSlot._world_center_position
		)		
		
	elseif slot == GameSlot.SLOT_2 then
		return 	CFrame.new(
			Vector3.new(-horiz_distance, up_distance, -horiz_distance) + GameSlot._world_center_position,
			Vector3.new(-lookat_distance, 0, -lookat_distance) + GameSlot._world_center_position
		)		
		
	elseif slot == GameSlot.SLOT_3 then
		return 	CFrame.new(
			Vector3.new(horiz_distance, up_distance, -horiz_distance) + GameSlot._world_center_position,
			Vector3.new(lookat_distance, 0, -lookat_distance) + GameSlot._world_center_position
		)			
		
	else
		return 	CFrame.new(
			Vector3.new(horiz_distance, up_distance, horiz_distance) + GameSlot._world_center_position,
			Vector3.new(lookat_distance, 0, lookat_distance) + GameSlot._world_center_position
		)			
		
	end
end

function GameSlot:slot_to_color_and_transparency(slot)
	return BrickColor.new(226), 0.65
end

return GameSlot
