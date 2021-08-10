--[[

FIREYAUTO's printtable function

How to use:

    printtable(Table) --Prints the given table
    
    Globals:Update("CheckCyclic",<true | false>) --Will determine whether or not cyclic tables will be detected (Recommened to be true)
    
    Globals:Update("DoReduction",<true | false>) --Will determine whether or not it will print a string in front of keys (For bigger tables, set to false)

]]

-- {{ Globals Setup }} --

local Globals = {
    _Globals={},
    IsGlobal=function(self,Name)
        return self._Globals[Name]~=nil
    end,
    New=function(self,Name,Value,Settings)
        if self:IsGlobal(Name) then return end
        self._Globals[Name] = {
            Value=Value,
            Settings=Settings or {},
        }
    end,
    Update=function(self,Name,Value)
        if not self:IsGlobal(Name) then return end
        local Global = self._Globals[Name]
        local Settings = Global.Settings
        if not Settings.CanSet then return end
        Global.Value = Value
    end,
    Get=function(self,Name)
        if not self:IsGlobal(Name) then return end
        return self._Globals[Name].Value
    end,
    Is=function(self,Name,Value)
        if not self:IsGlobal(Name) then return end
        return self._Globals[Name].Value==Value
    end,
}

-- {{ Globals }} --

Globals:New("CheckCyclic",true,{
    CanSet=true,
})

Globals:New("DoReduction",true,{
    CanSet=true,
})

-- {{ Required Assets }} --

local function IsCyclic(Table,Cyclic)
    for k,v in pairs(Cyclic) do
        if rawequal(Table,v) then
            return true
        end
    end
    return false
end

local function AddToCyclic(Table,Cyclic)
    if IsCyclic(Table,Cyclic) then return end
    table.insert(Cyclic,Table)
end

local function ReduceString(String,Add)
    local New = Add
    local Type = type(Add)
    if Type == "string" then
        if Add:match("%s") then
            New = ("[%q]"):format(Add)
        else
            New = (".%s"):format(Add)
        end
    else
        New = ("[%s]"):format(tostring(Add))
    end
    return String..New
end

local function NonReduceString(Add)
    local New = Add
    local Type = type(Add)
    if Type == "string" then
        if Add:match("%s") then
            New = ("[%q]"):format(Add)
        else
            New = ("%s"):format(Add)
        end
    else
        New = ("[%s]"):format(tostring(Add))
    end
    return New
end

local function ReduceValue(Value)
    local Type = type(Value)
    if Type == "string" then
        return ("%q"):format(Value)
    else
        return ("%s"):format(tostring(Value))
    end
end

local function GetTabs(Count)
    return ("\t"):rep(Count)
end

-- {{ Main }} --

function printtable(Table,String,Cyclic,Tabs)
    local Cycle = Cyclic or {}
    local TabCount = Tabs or 0
    local DoReduction = Globals:Get("DoReduction")
    if Globals:Is("CheckCyclic",true) then
        if IsCyclic(Table,Cycle) then
            return print(GetTabs(TabCount).."<Cyclic Table>")
        end
        AddToCyclic(Table,Cycle)
    end
    for k,v in pairs(Table) do
        if type(v) == "table" then
            local Reduction = ""
            if DoReduction then
                Reduction = ReduceString(String or "Table",k) 
            else
                Reduction = NonReduceString(k)
            end
            print(GetTabs(TabCount)..("%s = {"):format(Reduction))
            printtable(v,Reduction,Cycle,TabCount+1)
            print(GetTabs(TabCount)..("}"))
        else
            local Reduction = ""
            if DoReduction then
                Reduction = ReduceString(String or "Table",k) 
            else
                Reduction = NonReduceString(k)
            end
            print(GetTabs(TabCount)..("%s = %s"):format(Reduction,ReduceValue(v)))
        end
    end
end

-- {{ Example }} --

local Table = {
    ["hello world"]="Hello, world!",
    a=true,
    b=100,
    c=1.2e3,
    inner={
        "Hello",
        "World!",
        inside={
            works=true,
            hello="world",
        }
    },
}
Table.cyclic = Table
Table.inner.anotherCyclic = Table

printtable(Table)
