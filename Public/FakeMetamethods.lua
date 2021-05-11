--[[

Metatable Extensions, allows you to create custom "fake" metamethods

How to use properly:
For every "fake" metamethod you add, you must define its extension (the originl metamethod name) and the new fake metamethod name
After that, you must define a check function on the fake metamethod to allow the metatable to determine whether or not that the fake or real metamethod will be called

Example below:

local Meta = Main.new()
Meta:NewExtension("__test",function(self,name)
    print("__test called!")
    print(name)
    return "Returned with __test"
end)
Meta:DefineExtension("__test","__index")
Meta:DefineCheck("__test",function(self,Name,Index)
    if Name == "__index" and Index == "Test" then
        return true
    end
    return false
end)
local t = {}
Meta:Apply(t,{
    __index=function(self,Index)
        print("__index called!")
        print(Index)
        return "Returned with __index"
    end,
})
print(t.test)
print(t.Test)

]]

local Main = {}
Main.__index = Main

function Main.new()
    local Proxy = setmetatable({
        Extensions={}
    },Main)
    return Proxy
end

function Main:NewExtension(Name,Value)
    self.Extensions[Name] = {Value=Value}
end
    
function Main:DefineExtension(Name,Precursor)
    self.Extensions[Name].Precursor = Precursor
end

function Main:DefineCheck(Name,Check)
    self.Extensions[Name].Check = Check
end

function Main:Apply(Table,Metatable)
    local This = self
    if getmetatable(Table) then return warn(tostring(Table) .. " already has a metatable!") end
    local Meta = {}
    for k,v in pairs(Metatable) do
        Meta[k] = function(self,...)
            for kk,vv in pairs(This.Extensions) do
                if vv.Precursor == k then
                    local Check = vv.Check(Table,k,...)
                    if Check then
                        return vv.Value(Table,...)
                    else
                        return v(Table,...)
                    end
                end
                return v(Table,...)
            end
        end
    end
    setmetatable(Table,Meta)
end

return Main --Remove if not a module
