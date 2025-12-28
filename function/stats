local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        print("REMOTE:", self:GetFullName())
        print("METHOD:", method)
        print("ARGS:", ...)
    end
    return old(self, ...)
end)
