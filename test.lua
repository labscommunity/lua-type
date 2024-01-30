local Type = require("type")

local address = Type:number()
local address2 = address:extend():odd()

address:assert(2)
address2:assert(3)

local test = Type:boolean()

test:assert(false)

local user = Type:object({
  name = Type:string(),
  age = Type:number():integer(),
  social = Type:object({
    twitter = Type:string()
  })
}):set_name("User")

user:assert({
  name = "test",
  age = 20,
  social = {
    twitter = "martonlederer"
  }
})

local table1 = { "test", "haha", "test" }
local tabl_assert = Type:keys(Type:number()):values(Type:string())

tabl_assert:assert(table1)

local opt_type = Type:optional(Type:string())
local opt = "test"
opt_type:assert(opt)
opt = nil
opt_type:assert(opt)

local eithertest = Type:set_name("EitherTest"):either(Type:number(), Type:string(), Type:table())

eithertest:assert("true")

local nottest = Type:is_not(Type:string():length(2))

nottest:assert(2)
nottest:assert(2)
