local Cache = {}

function GetFromCache(Type,Item)
    for k,v in pairs(Cache) do
        if v[Type] == Item then
            return v,k
        end
    end
end

function Find(Table,Value)
    for k,v in pairs(Table) do
        if v == Value then
            return k
        end
    end
end
local ClassData
ClassData = {
    Proxy={
        Properties={
            Name={"Proxy",true,true},
            ClassName={"Proxy",true,false},
            IsA={
                function(self,Type)
                    local Proxy = GetFromCache("Proxy",self)
                    if not Proxy then return end
                    if Type == self.ClassName then return true end
                    local Extends = ClassData[self.ClassName]
                    if Find(Extends.Extends,Type) then return true end
                    return false
                end,true,false
            },
        },
        CanCreate=false,
        Extends={},
    },
    Part={
        Properties={
            Test={"Hi",true,false},
        },
        CanCreate=true,
        Extends={"Proxy"},
    }
}

function IsValidType(Type)
    return not not ClassData[Type]
end

function GetTypeData(Type)
    local Properties={}
    local BannedGets={}
    local BannedSets={}
    local function Append(Table)
        for k,v in pairs(Table) do
            Properties[k] = v[1]
            if not v[2] and not Find(BannedGets,k) then
                table.insert(BannedGets,k)
            end
            if not v[3] and not Find(BannedSets,k) then
                table.insert(BannedSets,k)
            end
        end
    end
    for k,v in pairs(ClassData) do
        if k == Type then
            Append(v.Properties)
            for kk,vv in pairs(v.Extends or {}) do
                Append(ClassData[vv].Properties)
            end 
        end
    end
    return Properties,BannedGets,BannedSets
end

function Includes(Table,Key)
    for k,v in pairs(Table) do
        if k == Key then
            return true
        end
    end
    return false
end

local MainMetatable = {
    __index=function(self,Name)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return end
        if Find(Proxy.BannedGets,Name) then return end
        return Proxy.Properties[Name]
    end,
    __newindex=function(self,Name,Value)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return end
        if Find(Proxy.BannedSets,Name) then return end
        if not Includes(Proxy.Properties,Name) then return end
        Proxy.Properties[Name] = Value
    end,
    __tostring = function(self)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return false end
        return "Proxy_" .. Proxy.Type
    end,
    __eq = function(self,Value)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return false end
        return rawequal(Proxy.Proxy,Value) or rawequal(self,Value)
    end,
    __metatable = "Locked",
}

function NewProxy(Type)
    if not IsValidType(Type) then return end
    if not ClassData[Type].CanCreate then return end
    Proxy = {}
    local Properties,BannedGets,BannedSets = GetTypeData(Type)
    Properties.ClassName = Type
    table.insert(Cache,{Proxy=Proxy,Type=Type,Properties=Properties,BannedGets=BannedGets,BannedSets=BannedSets})
    setmetatable(Proxy,MainMetatable)
    return Proxy
end

local t = NewProxy("Part")
print(t:IsA("Proxy"))
