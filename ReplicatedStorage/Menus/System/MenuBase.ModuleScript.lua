local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local MenuBase = {}
MenuBase.Type = "MenuBase"

function MenuBase:new()
	local self = {}
	self.ClassName = MenuBase.Type
	
	function self:set_is_top_element(val) end
	function self:update(dt_scale) end
	function self:should_remove() DebugOut:errf("MenuBase needs to implement should_remove") end
	function self:do_remove() DebugOut:errf("MenuBase needs to implement do_remove") end
	
	return self
end

return MenuBase