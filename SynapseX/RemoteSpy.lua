--[[

Synapse X Remote Spy

Programmed by FIREYAUTO

Not tested yet, might not work

]]
function print_table(t,c)
    if not c then c = {} end
    for k,v in pairs(c) do
        if v == t then
            return print("cyclic reference detected: " .. tostring(t))    
        end
    end
    table.insert(c,t)
    for k,v in pairs(t) do
        if type(v) == "table" then
            print(("Opening table %q"):format(tostring(k)))
            print_table(v,c)
            print(("Closing table %q"):format(tostring(k)))
        else
            if type(k) ~= "number" then
                k = ("\"%s\""):format(tostring(k))
            end
            print(("[%s] = %s"):format(tostring(k),tostring(v)))
        end
    end
end

local RemoteSettings = {
    Connections={},
    Old={},
    Enabled=false,
}

RemoteSettings.NewOld = function(self,Name,Value)
    self.Old[Name] = Value
end

RemoteSettings.Connect = function(self,Connection)
    table.insert(self.Connections,Connection)
end

RemoteSettings.Unload = function(self)
    for _, Connection in pairs(self.Connections) do
        Connection:Disconnect()
    end
    table.clear(self.Connections)
end

RemoteSettings.NewHook = function(self,Name,Callback)
    local Old = RemoteSettings.Old[Name]
    hookfunction(Old,newcclosure(function(...)
        if not checkcaller() then
            local Caller = getcallingscript()
            local Success,Response = pcall(Callback,{Remote=nil,Name=Name,Caller=Caller,Args={...}})
            if not Success then
                warn(("[REMOTE SPY ERROR]: %s"):format(Response))
            end
        end
        return Old(...)
    end))
end

RemoteSettings.CheckInstance = function(Item)
    if not RemoteSettings.Enabled then return end
    if Item:IsA("RemoteEvent") then
        RemoteSettings:Connect(Item.OnClientEvent:Connect(function(...)
            RemoteSettings.ClientFired({Remote=Item,Name="OnClientEvent",Args={...}})
        end))
    elseif Item:IsA("BindableEvent") then
        RemoteSettings:Connect(Item.Event:Connect(function(...)
            RemoteSettings.ClientFired({Remote=Item,Name="Event",Args={...}})
        end))
    end
end

RemoteSettings.ToggleEnable = function()
    RemoteSettings.Enabled = not RemoteSettings.Enabled
    if RemoteSettings.Enabled then
        for k,v in pairs(game:GetDescendants()) do
            RemoteSettings.CheckInstance(v)
        end
    else
        RemoteSettings:Unload()
    end
end

RemoteSettings.MainHookCallback = function(Data)
    warn(("%s %q fired %q"):format(Data.Remote.ClassName,Data.Remote.Name,Data.Name))
    print_table(Data.Args)
end

RemoteSettings.ClientFired = function(Data)
    warn(("%s %q fired %q"):format(Data.Remote.ClassName,Data.Remote.Name,Data.Name))
    print_table(Data.Args)
end

-- Setup old functions

local re,rf,be,bf = Instance.new("RemoteEvent"),Instance.new("RemoteFunction"),Instance.new("BindableEvent"),Instance.new("BindableFunction")
RemoteSettings:NewOld("FireServer",re.FireServer)
RemoteSettings:NewOld("Fire",be.Fire)
RemoteSettings:NewOld("InvokeServer",rf.InvokeServer)
RemoteSettings:NewOld("Invoke",bf.Invoke)

--Setup hook functions

RemoteSettings:NewHook("FireServer",RemoteSettings.MainHookCallback)
RemoteSettings:NewHook("Fire",RemoteSettings.MainHookCallback)
RemoteSettings:NewHook("InvokeServer",RemoteSettings.MainHookCallback)
RemoteSettings:NewHook("Invoke",RemoteSettings.MainHookCallback)

--Start

game.DescendantAdded:Connect(RemoteSettings.CheckInstance)
RemoteSettings.ToggleEnable()
