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
	
	function self:get_top_menu() return _menu_stack:get(_menu_stack:count()) end
	
	function self:update(dt_scale)
		local top_menu = self:get_top_menu()
		if top_menu then
			top_menu:update(dt_scale)
			if top_menu:should_remove() then
				self:remove_menu(top_menu)
			end
		end
	end
	
	function self:remove_menu(tar_menu)
		local top_menu_pre = self:get_top_menu()
		for i=1,_menu_stack:count() do
			local itr_menu = _menu_stack:get(i)
			if tar_menu == itr_menu then
				tar_menu:do_remove()
				_menu_stack:remove(itr_menu)
				break
			end
		end
		
		local top_menu_post = self:get_top_menu()
		if top_menu_post and top_menu_pre ~= top_menu_post then
			top_menu_post:set_is_top_element(true)
		end
	end
	
	return self
end

return MenuSystem