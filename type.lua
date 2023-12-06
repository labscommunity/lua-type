local Type = {}

function Type:add_condition(name, assertion)
  -- condition to add
  local condition = {
    name = name,
    validate = assertion
  }

  -- new instance if there are no conditions yet
  if self.conditions == nil then
    local instance = {
      conditions = {}
    }

    table.insert(instance.conditions, condition)
    setmetatable(instance, self)
    self.__index = self

    return instance
  end

  table.insert(self.conditions, condition)
  return self
end

function Type:type(t)
  return self:add_condition(t, function (val) return type(val) == t end)
end

function Type:string()
  return self:type("string")
end

function Type:number()
  return self:type("number")
end

function Type:even()
  return self:add_condition("even", function (val) return val % 2 == 0 end)
end

function Type:odd()
  return self:add_condition("odd", function (val) return val % 2 == 1 end)
end

function Type:assert(val)
  for i, condition in ipairs(self.conditions) do
    if not condition.validate(val) then
      error("Failed validation at #" .. i .. ": not " .. condition.name)
    end
  end
end

return Type
