local EnumHandler = require(script.Parent.Parent.System.EnumHandler)
local EnumItemHandler = EnumHandler:new()

function EnumItemHandler:serialize(item)
    return self:new_object("EnumItem", {name = item.Name, enum_type = tostring(item.EnumType), value = item.Value})
end

function EnumItemHandler:deserialize(item)
    local type = item.enum_type
    local value = item.value

    for i, v in pairs(Enum:GetEnums()) do
        if v.EnumType == type and v.Value == value then
            return v
        end
    end
end

return EnumItemHandler