local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if method == "FireServer" or method == "InvokeServer" then
        print("Remote Fired:", self)

        for i, v in ipairs(args) do
            print("Arg " .. i .. " =", v)

            if typeof(v) == "table" then
                print("---- TABLE CONTENT ----")
                for k2, v2 in pairs(v) do
                    print(k2, "=", v2)
                end
                print("-----------------------")
            end
        end
    end

    return old(self, ...)
end)


=====================================================================================


=====================================================================================

local mt = getrawmetatable(game)
setreadonly(mt, false)

local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if method == "FireServer" and tostring(self) == "Reliable" then
        print("================================")
        print("REMOTE:", self:GetFullName())
        print("METHOD:", method)

        for i, v in ipairs(args) do
            print("ARG", i, v, typeof(v))
            if typeof(v) == "table" then
                for k, val in pairs(v) do
                    print("   ", k, val)
                end
            end
        end
        print("================================")
    end

    return old(self, ...)
end)
