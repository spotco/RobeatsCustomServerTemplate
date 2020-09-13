local RandomLua = require(game.ReplicatedStorage.Shared.RandomLua)

local SPUtil = {}

function SPUtil:rad_to_deg(rad)
	return rad * 180.0 / math.pi
end

function SPUtil:deg_to_rad(degrees)
	return degrees * math.pi / 180
end

function SPUtil:dir_ang_deg(x,y)
	return SPUtil:rad_to_deg(math.atan2(y,x))
end

function SPUtil:ang_deg_dir(deg)
	local rad = SPUtil:deg_to_rad(deg)
	return Vector2.new(
		math.cos(rad),
		math.sin(rad)
	)
end

function SPUtil:part_cframe_rotation(part)
	return CFrame.new(-part.CFrame.p) * (part.CFrame)
end

function SPUtil:table_clear(tab)
	for k,v in pairs(tab) do tab[k]=nil end
end

function SPUtil:vec3_lerp(a,b,t)
	return a:Lerp(b,t)
end

local _seed = tick() % 1000
local _rand = RandomLua.mwc(_seed)
function SPUtil:rand_rangef(min,max)
	return _rand:rand_rangef(min,max)
end

function SPUtil:rand_rangei(min,max)
	return _rand:rand_rangei(min,max)
end

function SPUtil:clamp(val,min,max)
	return math.min(max,math.max(min,val))
end

function SPUtil:tra(val)
	return 1 - val
end

function SPUtil:format_ms_time(ms_time)
	ms_time = math.floor(ms_time)
	return string.format(
		"%d:%d%d",
		ms_time/60000,
		(ms_time/10000)%6,
		(ms_time/1000)%10
	)
end

local __cached_camera = nil
local function get_camera()
	if __cached_camera == nil then __cached_camera = game.Workspace.Camera end
	return __cached_camera
end
function SPUtil:get_camera() return get_camera() end

function SPUtil:lookat_camera_cframe(position)
	local camera_cf = SPUtil:get_camera().CFrame
	local look_vector = camera_cf.LookVector.Unit
	local normal_dir = look_vector * -1
	return CFrame.new(position, position + normal_dir)
end

function SPUtil:try(call)
	return xpcall(function()
		call()
	end, function(err)
		return {
			Error = err;
			StackTrace = debug.traceback();
		}
	end)
end

return SPUtil
