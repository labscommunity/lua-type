---@class Type
local Type = {
  conditions = nil
}

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

-- Add an assertion for built in types
---@param t "nil"|"number"|"string"|"boolean"|"table"|"function"|"thread"|"userdata" Type to assert for
function Type:type(t)
  return self:add_condition(t, function (val) return type(val) == t end)
end

-- Type must be userdata
function Type:userdata()
  return self:type("userdata")
end

-- Type must be thread
function Type:thread()
  return self:type("thread")
end

-- Type must be table
function Type:table()
  return self:type("table")
end

-- Type must be boolean
function Type:boolean()
  return self:type("boolean")
end

-- Type must be function
function Type:_function()
  return self:type("function")
end

-- Type must be boolean
function Type:_nil()
  return self:type("boolean")
end

-- Value must be the same
---@param val any The value the assertion must be made with
function Type:is(val)
  return self:add_condition("is", function (v) return v == val end)
end

-- Type must be string
function Type:string()
  return self:type("string")
end

function Type:match(pattern)
  return self:add_condition(
    "match",
    function (val) return string.match(val, pattern) ~= nil end
  )
end

-- Type must be a number
function Type:number()
  return self:type("number")
end

-- Number must be an integer (chain after "number()")
function Type:integer()
  return self:add_condition("integer", function (val) return val % 1 == 0 end)
end

-- Number must be even (chain after "number()")
function Type:even()
  return self:add_condition("even", function (val) return val % 2 == 0 end)
end

-- Number must be odd (chain after "number()")
function Type:odd()
  return self:add_condition("odd", function (val) return val % 2 == 1 end)
end

-- Number must be less than the number "n" (chain after "number()")
---@param n number Number to compare with
function Type:less_than(n)
  return self:add_condition("less", function (val) return val < n end)
end

-- Number must be greater than the number "n" (chain after "number()")
---@param n number Number to compare with
function Type:greater_than(n)
  return self:add_condition("less", function (val) return val > n end)
end

-- Table must be of structure
---@param struct { [any]: Type }
---@param name? string Name of the structure
---@param strict? boolean Only allow the defined keys from the structure, throw error on other keys (false by default)
function Type:structure(struct, name, strict)
  if type(struct) ~= "table" then
    error(name .. " is not a valid structure:\n" .. tostring(struct))
  end

  return self:add_condition(
    name or "structure",
    function (val)
      if type(val) ~= "table" then
        print("Not a valid structure:\n" .. tostring(val))
        return false
      end

      -- for each value, validate
      for key, assertion in pairs(struct) do
        if val[key] == nil then
          print("Missing key \"" .. key .. "\"")
          return false
        end

        -- check if the assertion throws any errors
        local success, err = pcall(function () return assertion:assert(val[key]) end)

        if not success then
          print(err);
          return false
        end
      end

      -- in strict mode, we do not allow any other keys
      if strict then
        for key, _ in pairs(val) do
          if struct[key] == nil then
            print("Invalid key in value: \"" .. key .. "\" (strict mode)");
            return false
          end
        end
      end

      return true
    end
  )
end

-- Execute an assertion for a given value
---@param val any Value to assert for
function Type:assert(val)
  for i, condition in ipairs(self.conditions) do
    if not condition.validate(val) then
      error("Failed assertion at #" .. i .. ": " .. tostring(val) .. " is not " .. condition.name)
    end
  end
end

return Type
