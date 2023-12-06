local Type = require("type")

local address = Type:number()

address:assert(2)

local test = Type:boolean()

test:assert(false)

local user = Type:structure({
  name = Type:string(),
  age = Type:number():integer(),
  social = Type:structure({
    twitter = Type:string()
  })
}, "User")

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
