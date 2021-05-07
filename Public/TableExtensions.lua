--[[

Extended table functions that are directly applied to tables

Works with tables that have metatables and tables that don't have metatables

local Table = {"Hello","World"}
SetTableMethods(Table)
Table:push("Testing")
Table:each(print)
Table:reverse():each(print)

]]

local Extend = {
    TableFunctions = {
        push = function(self,a)
            table.insert(self,a)
        end,
        pop = function(self)
            table.remove(self,#self)
        end,
        unshift = function(self)
            table.remove(self,1)
        end,
        shift = function(self,a)
            table.insert(self,1,a)
        end,
        each = function(self,a)
            if type(a) == "function" then
                for k,v in pairs(self) do
                    a(k,v)
                end
            end
        end,
        includes = function(self,a)
            for k,v in pairs(self) do
                if v == a then
                    return true
                end
            end
            return false
        end,
        indexOf = function(self,a)
            for k,v in pairs(self) do
                if v == a then
                    return k
                end
            end
        end,
        map = function(self,a)
            local nself = {}
            for k,v in pairs(self) do
                nself[k] = a(v,k,self)
            end
            SetTableMethods(nself)
            return nself
        end,
        values = function(self)
            local t = {}
            for _,v in pairs(self) do
                table.insert(t,v)
            end
            SetTableMethods(t)
            return t
        end,
        keys = function(self)
            local t = {}
            for k,_ in pairs(self) do
                table.insert(t,k)
            end
            SetTableMethods(t)
            return t
        end,
        reverse = function(self)
            local vt = self:values()
            local kt = self:keys()
            for i=1,#kt do
                self[i] = vt[#kt-(i-1)]
            end
            return self
        end,
    },
}

function IsProtectedMetatable(Metatable)
    return type(Metatable) ~= "table"
end

function TryIndex(Index,self,Name)
    if type(Index) == "table" then
        return Index[Name]
    elseif type(Index) == "function" then
        return Index(self,Name)
    end
    return
end

function KeyExists(Table,Name)
    return Table[Name] ~= nil
end

function SetTableMethods(Table)
    local Metatable = getmetatable(Table)
    local H,P = false,false
    if Metatable then
        H = true
        if IsProtectedMetatable(Metatable) then
            P = true
        end
    end
    local Methods = Extend.TableFunctions
    if not H then
        setmetatable(Table,{
            __index=Methods
        })
    else
        if P then
            for Key,Value in pairs(Methods) do
                if not KeyExists(Table,Key) then
                    Table[Key] = Value
                end
            end
        else
            local Index = Metatable.__index
            if Index then
                Metatable.__index = function(self,Name)
                    local Result = TryIndex(Index,self,Name)
                    if Result then return Result end
                    return Methods[Name]
                end
            else
                Metatable.__index = Methods
            end
        end
    end
end

return SetTableMethods --Remove if not used as a module
