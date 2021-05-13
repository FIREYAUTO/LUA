local Cache = {}

function GetFromCache(Type,Item)
    for k,v in pairs(Cache) do
        if rawequal(v[Type],Item) then
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
            Parent={nil,true,true,nil,function(self,Value)
                local Proxy = GetFromCache("Proxy",self)
                if not Proxy then return false end
                if Proxy.ExtraData.CantParent then return false end
                if Value == nil then return true end
                if Value == self then return false end
                local FProxy = GetFromCache("Proxy",Value)
                if not FProxy then return false end
                return true
            end},
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
            GetChildren={
                function(self)
                    local Proxy = GetFromCache("Proxy",self)
                    if not Proxy then return end
                    local Children = {}
                    for k,v in pairs(Cache) do
                        if v.Proxy.Parent == self then
                            table.insert(Children,v.Proxy) 
                        end
                    end
                    return Children
                end,true,false
            },
            Destroy={
                function(self)
                    local Proxy = GetFromCache("Proxy",self)
                    if not Proxy then return end
                    if Proxy.ExtraData.CantParent then return error(("Cannot destroy %q"):format(self.Name),999) end
                    for k,v in pairs(self:GetChildren()) do
                        pcall(v.Destroy,v)
                    end
                    self.Parent = nil
                    Proxy.ExtraData.CantParent = true
                end,true,false
            },
            FindFirstChild={
                function(self,Name)
                    for k,v in pairs(self:GetChildren()) do
                        if v.Name == Name then
                            return v
                        end
                    end
                end,true,false
            },
            FindFirstChildOfClass={
                function(self,Name)
                    for k,v in pairs(self:GetChildren()) do
                        if v:IsA(Name) then
                            return v
                        end
                    end
                end,true,false
            },
            FindFirstChildOfClassName={
                function(self,Name)
                    for k,v in pairs(self:GetChildren()) do
                        if v.ClassName == Name then
                            return v
                        end
                    end
                end,true,false
            },
        },
        CanCreate=false,
        Extends={},
        ExtraData={
            OnCreation=function(self)
                local Proxy = GetFromCache("Proxy",self)
                if not Proxy then return end
            end,
        },
    },
    Test={
        Properties={},
        CanCreate=true,
        Extends={"Proxy"},
        ExtraData={
            CantParent=true,
        },
    },
    Part={
        Properties={
            Test={"Hi",true,false},
        },
        CanCreate=true,
        Extends={"Proxy"},
    },
}

function IsValidType(Type)
    return not not ClassData[Type]
end

function DeepCopy(Table)
    local NT = {}
    for k,v in pairs(Table) do
        NT[k] = (type(v) == "table" and DeepCopy(v)) or v
    end
    return NT
end

function Includes(Table,Key)
    for k,v in pairs(Table) do
        if k == Key then
            return true
        end
    end
    return false
end

function GetTypeData(Type)
    local Properties={}
    local BannedGets={}
    local BannedSets={}
    local ExtraData={}
    local PropNames={}
    local OnGet={}
    local OnSet={}
    local function Append(Table)
        for k,v in pairs(Table) do
            local prop = v[1]
            if type(prop) == "table" then
                prop = DeepCopy(prop)
            end
            Properties[k] = prop
            if not Find(Properties,k) then
                table.insert(PropNames,k)
            end
            if not v[2] and not Find(BannedGets,k) then
                table.insert(BannedGets,k)
            end
            if not v[3] and not Find(BannedSets,k) then
                table.insert(BannedSets,k)
            end
            if v[4] and not Includes(OnGet,k) then
                OnGet[k] = v[4]
            end
            if v[5] and not Includes(OnSet,k) then
                OnSet[k] = v[5]
            end
        end
    end
    local function AppendExtraData(Table)
        if not Table then return end
        for k,v in pairs(Table) do
            if not ExtraData[k] then ExtraData[k] = {} end
            table.insert(ExtraData[k],v)
        end
    end
    for k,v in pairs(ClassData) do
        if k == Type then
            Append(v.Properties)
            AppendExtraData(v.ExtraData)
            for kk,vv in pairs(v.Extends or {}) do
                Append(ClassData[vv].Properties)
                AppendExtraData(ClassData[vv].ExtraData)
            end 
        end
    end
    return Properties,BannedGets,BannedSets,ExtraData,PropNames,OnGet,OnSet
end

local MainMetatable = {
    __index=function(self,Name)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return end
        if Find(Proxy.BannedGets,Name) then return error(("%q is not a valid member of %q"):format(Name,tostring(self)),999) end
        if not Find(Proxy.PropNames,Name) then return error(("%q is not a valid member of %q"):format(Name,tostring(self)),999) end
        local Get = Proxy.OnGet[Name]
        if Get then
            return Get(self)
        end
        return Proxy.Properties[Name]
    end,
    __newindex=function(self,Name,Value)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return end
        if Find(Proxy.BannedSets,Name) then return end
        if not Find(Proxy.PropNames,Name) then return error(("Cannot set %q in %q"):format(Name,tostring(self)),999) end
        local Set = Proxy.OnSet[Name]
        if Set then
            local Returned = Set(self,Value)
            if not Returned then
                return error(("Cannot set %q in %q"):format(Name,tostring(self)),999)
            end
        end
        Proxy.Properties[Name] = Value
    end,
    __tostring = function(self)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return false end
        return self.Name
    end,
    __eq = function(self,Value)
        local Proxy = GetFromCache("Proxy",self)
        if not Proxy then return false end
        return rawequal(Proxy.Proxy,Value) or rawequal(self,Value)
    end,
    __metatable = "Locked",
}

function NewProxy(Type)
    if not IsValidType(Type) then return error(("%q is not a valid type"):format(Type),999) end
    if not ClassData[Type].CanCreate then return error(("Cannot create type %q"):format(Type),999) end
    Proxy = {}
    local Properties,BannedGets,BannedSets,ExtraData,PropNames,OnGet,OnSet = GetTypeData(Type)
    Properties.ClassName = Type
    Properties.Name = Type
    table.insert(Cache,{Proxy=Proxy,Type=Type,Properties=Properties,OnGet=OnGet,OnSet=OnSet,PropNames=PropNames,ExtraData=ExtraData,BannedGets=BannedGets,BannedSets=BannedSets})
    setmetatable(Proxy,MainMetatable)
    for k,v in pairs(ExtraData.OnCreation or {}) do
        v(Proxy)
    end
    return Proxy
end

local v = NewProxy("Test")
v.Name = "TestProxy"
local t = NewProxy("Part")
t.Parent = v
t.Name = "TestPart"
print(v:FindFirstChildOfClass("Proxy"))
