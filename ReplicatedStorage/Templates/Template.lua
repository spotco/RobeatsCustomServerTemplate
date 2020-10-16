local Template = {}

function Template:new(initValue)
    local template = {value = initValue or {}}

    function template:new(modTable)
        local copy = {}

        for i, v in pairs(self.value) do
            copy[i] = v            
        end

        for i, v in pairs(modTable or {}) do
            copy[i] = v
        end
        return copy
    end

    function template:setValue(value)
        self.value = value
        return self.value
    end

    function template:modifyValue(modTable)
        assert(modTable ~= nil, "Argument #1 must not be nil")
        for i, v in pairs(modTable) do
            self.value[i] = v
        end
        return self.value
    end

    return template
end

return Template