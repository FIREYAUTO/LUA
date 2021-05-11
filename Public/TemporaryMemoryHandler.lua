--[[

Temporary Memory handler
This will allow you to allocate memory inside of the "Temp" table, and then you can unload it (Temp:Unload()) to flush out the table
You are allowed to define your own type removal callbacks

]]

local Temp = setmetatable({
    Memory=setmetatable({},{__metatable="locked"}),
    TypeHandlers=setmetatable({},{__metatable="locked"}),    
    Unload=function(self)
        local Memory = self.Memory
        for k,v in pairs(Memory) do
            self:Handle(v)
            Memory[k] = nil
        end
    end,
    AddTypeHandler=function(self,Type,Callback)
        self.TypeHandlers[Type] = Callback
    end,
    Handle=function(self,Value)
        local Type = type(Value)
        if not self.TypeHandlers[Type] then return end
        self.TypeHandlers[Type](Value)
    end,
},{
    __index=function(self,Name)
        return rawget(rawget(self,"Memory"),Name)
    end,
    __newindex=function(self,Name,Value)
        rawset(rawget(self,"Memory"),Name,Value)
    end,
    __eq=function(self,Value)
        return rawequal(self,Value) or rawequal(rawget(self,"Memory"),Value)
    end,
    __metatable="locked",
})

Temp[1] = {"Hello, world!"}

Temp:AddTypeHandler("table",function(t)
    for k,v in pairs(t) do
        Temp:Handle(v)
        t[k] = nil
    end
end)
Temp:Unload()
