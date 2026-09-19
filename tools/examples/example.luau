local function sum(a: number, b: number)
    return a + b
end

local x = 5
local y = 10

if x < y then
    print("sum:", sum(x, y))
else
    print("unexpected")
end
