--[[

Proxy signals in lua

Allows for Connections to be made to custom signals. The example below should clear up information

local MySignalMain = SignalBase.new("Test")
local MySignal = MySignalMain.Public

MySignal:Connect(function(String)
    print(String .. " (CONNECT)")
end)

coroutine.wrap(function()
    local Results = MySignal:Wait()
    print(tostring(Results) .. " (WAIT)")
end)()

MySignalMain.Fire("Hello!")

--If you're a dev and need users to write their own code, if you need them to interact with a Signal please use the code below

return MySignal --This will return the public signal, which only allows access to :Wait() and :Connect()

]]

local ConnectionBase = {}

function ConnectionBase.newpublic(Parent,Name)
    local Raw = {
        Disconnect = function(self)
            if self ~= Raw and self ~= Parent then return end
            Parent.Signal.Remove(Parent)
        end,
    }
    setmetatable(Raw,{
        __newindex = function(self)
            return error("Cannot modify or assign properties!",999)
        end,
        __tostring = function(self)
            return "Connection_" .. Name
        end,
        __metatable = "Locked",
    })
    return Raw
end

function ConnectionBase.new(Signal,Callback,Name)
    local Raw = {
        Callback = Callback,
        Signal = Signal,
    }
    Raw.Public = ConnectionBase.newpublic(Raw,Name)
    return Raw
end

local SignalBase = {}

function SignalBase.newpublic(Parent,Name)
    local Raw = {}
    Raw.Connect = function(self,Callback)
        if self ~= Raw and self ~= Parent then return end
        local Connection = ConnectionBase.new(Parent,Callback,Name)
        table.insert(Parent.Connections,Connection)
        return Connection.Public
    end
    Raw.Wait = function(self)
        if self ~= Raw and self ~= Parent then return end
        local Cache = {Thread=coroutine.running(),Results={}}
        table.insert(Parent.Waiting,Cache)
        coroutine.yield()
        return table.unpack(Cache.Results)
    end
    setmetatable(Raw,{
        __newindex = function(self)
            return error("Cannot modify or assign properties!",999)
        end,
        __tostring = function(self)
            return "Signal_" .. Name
        end,
        __metatable = "Locked",
    })
    return Raw
end

function SignalBase.new(Name)
    local Raw = {
        Waiting={},
        Connections={},
    }
    Raw.Remove = function(Connection)
        for k,v in pairs(Raw.Connections) do
            if Connection == v then
                table.remove(Raw.Connections,k)
                return
            end
        end
    end
    Raw.Fire = function(...)
        local Args = {...}
        for _,v in pairs(Raw.Waiting) do
            v.Results = Args
            coroutine.resume(v.Thread)
        end
        Raw.Waiting = {}
        for _,v in pairs(Raw.Connections) do
            v.Callback(table.unpack(Args))
        end
    end
    Raw.Public = SignalBase.newpublic(Raw,Name)
    return Raw
end

return SignalBase.new --Return if not a module
