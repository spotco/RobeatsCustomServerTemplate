local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local SPList = require(game.ReplicatedStorage.Shared.SPList)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)

local MenuSystem = {}

function MenuSystem:new()
	local self = {}
	
	local _menu_stack = SPList:new()
	
	function self:push_menu(tar_menu)
		AssertType:is_classname(tar_menu, MenuBase.Type)
		if _menu_stack:count() > 0 then
			_menu_stack:get(_menu_stack:count()):set_is_top_element(false)
		end
		_menu_stack:push_back(tar_menu)
		tar_menu:set_is_top_element(true)
	end
	
	function self:update(dt_scale)
		if _menu_stack:count() > 0 then
			local menu_top = _menu_stack:get(_menu_stack:count())
			menu_top:update(dt_scale)
			if menu_top:should_remove() then
				menu_top:do_remove()
				_menu_stack:remove(menu_top)
				if _menu_stack:count() > 0 then
					menu_top = _menu_stack:get(_menu_stack:count())
					menu_top:set_is_top_element(true)
				end
			end
		end
	end
	
	return self
end

return MenuSystem