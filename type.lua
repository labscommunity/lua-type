---@class Type
local Type = {
  -- custom name for the defined type
  ---@type string|nil
  name = nil,
  -- list of assertions to perform on any given value
  ---@type { name: string, validate: fun(val: any): boolean }[]
  conditions = nil
}

-- Execute an assertion for a given value
---@param val any Value to assert for
function Type:assert(val)
  for i, condition in ipairs(self.conditions) do
    if not condition.validate(val) then
      self:error("Failed assertion at #" .. i .. ": " .. tostring(val) .. " is not " .. condition.name)
    end
  end
end

-- Add a custom condition/assertion to assert for
---@param name string Name of the assertion
---@param assertion fun(val: any): boolean Custom assertion function that is asserted with the provided value
function Type:custom(name, assertion)
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
  return self:custom(t, function (val) return type(val) == t end)
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

-- Table's keys must be of type t
---@param t Type Type to assert the keys for
function Type:keys(t)
  return self:custom(
    "keys",
    function (val)
      if type(val) ~= "table" then
        self:log("Not a valid table:\n" .. tostring(val))
        return false
      end

      for key, _ in pairs(val) do
        -- check if the assertion throws any errors
        local success, err = pcall(function () return t:assert(key) end)

        if not success then
          self:log(err)
          return false
        end
      end

      return true
    end
  )
end

-- Type must be array
function Type:array()
  return self:table():keys(Type:number())
end

-- Table's values must be of type t
---@param t Type Type to assert the values for
function Type:values(t)
  return self:custom(
    "values",
    function (val)
      if type(val) ~= "table" then
        self:log("Not a valid table:\n" .. tostring(val))
        return false
      end

      for _, v in pairs(val) do
        -- check if the assertion throws any errors
        local success, err = pcall(function () return t:assert(v) end)

        if not success then
          self:log(err)
          return false
        end
      end

      return true
    end
  )
end

-- Type must be boolean
function Type:boolean()
  return self:type("boolean")
end

-- Type must be function
function Type:_function()
  return self:type("function")
end

-- Type must be nil
function Type:_nil()
  return self:type("nil")
end

-- Value must be the same
---@param val any The value the assertion must be made with
function Type:is(val)
  return self:custom("is", function (v) return v == val end)
end

-- Type must be string
function Type:string()
  return self:type("string")
end

-- String type must match pattern
---@param pattern string Pattern to match
function Type:match(pattern)
  return self:custom(
    "match",
    function (val) return string.match(val, pattern) ~= nil end
  )
end

-- String type must be of defined length
---@param len number Required length
---@param match_type? "less"|"greater" String length should be "less" than or "greater" than the defined length. Leave empty for exact match.
function Type:length(len, match_type)
  return self:custom(
    "length",
    function (val)
      local strlen = string.len(val)

      -- validate length
      if match_type == "less" then return strlen < len
      elseif match_type == "greater" then return strlen > len end

      return strlen == len
    end
  )
end

-- Type must be a number
function Type:number()
  return self:type("number")
end

-- Number must be an integer (chain after "number()")
function Type:integer()
  return self:custom("integer", function (val) return val % 1 == 0 end)
end

-- Number must be even (chain after "number()")
function Type:even()
  return self:custom("even", function (val) return val % 2 == 0 end)
end

-- Number must be odd (chain after "number()")
function Type:odd()
  return self:custom("odd", function (val) return val % 2 == 1 end)
end

-- Number must be less than the number "n" (chain after "number()")
---@param n number Number to compare with
function Type:less_than(n)
  return self:custom("less", function (val) return val < n end)
end

-- Number must be greater than the number "n" (chain after "number()")
---@param n number Number to compare with
function Type:greater_than(n)
  return self:custom("greater", function (val) return val > n end)
end

-- Make a type optional (allow them to be nil apart from the required type)
---@param t Type Type to assert for if the value is not nil
function Type:optional(t)
  return self:custom(
    "optional",
    function (val)
      if val == nil then return true end

      t:assert(val)
      return true
    end
  )
end

-- Table must be of object
---@param obj { [any]: Type }
---@param name? string Name of the object
---@param strict? boolean Only allow the defined keys from the object, throw error on other keys (false by default)
function Type:object(obj, name, strict)
  if type(obj) ~= "table" then
    self:error(name .. " is not a valid object:\n" .. tostring(obj))
  end

  return self:custom(
    name or "object",
    function (val)
      if type(val) ~= "table" then
        self:log("Not a valid object:\n" .. tostring(val))
        return false
      end

      -- for each value, validate
      for key, assertion in pairs(obj) do
        if val[key] == nil then
          self:log("Missing key \"" .. key .. "\"")
          return false
        end

        -- check if the assertion throws any errors
        local success, err = pcall(function () return assertion:assert(val[key]) end)

        if not success then
          self:log(err)
          return false
        end
      end

      -- in strict mode, we do not allow any other keys
      if strict then
        for key, _ in pairs(val) do
          if obj[key] == nil then
            self:log("Invalid key in value: \"" .. key .. "\" (strict mode)")
            return false
          end
        end
      end

      return true
    end
  )
end

-- Type has to be either one of the defined assertions
---@param ... Type Type(s) to assert for
function Type:either(...)
  ---@type Type[]
  local assertions = {...}

  return self:custom(
    "either",
    function (val)
      for _, assertion in ipairs(assertions) do
        if pcall(function () return assertion:assert(val) end) then
          return true
        end
      end

      self:log("Neither arguments matched")
      return false
    end
  )
end

-- Type cannot be the defined assertion (tip: for multiple negated assertions, use Type:either(...))
---@param t Type Type to NOT assert for
function Type:is_not(t)
  return self:custom(
    "is_not",
    function (val)
      local success = pcall(function () return t:assert(val) end)

      return not success
    end
  )
end

-- Set the name of the custom type
-- This will be used with error logs
---@param name string Name of the type definition
function Type:set_name(name)
  self.name = name
  return self
end

-- Log a message
---@param message any Message to log
---@private
function Type:log(message)
  print("[Type " .. (self.name or tostring(self.__index)) .. "] " .. tostring(message))
end

-- Throw an error
---@param message any Message to log
---@private
function Type:error(message)
  error("[Type " .. (self.name or tostring(self.__index)) .. "] " .. tostring(message))
end

return Type
