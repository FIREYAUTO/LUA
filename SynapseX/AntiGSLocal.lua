--[[
Anti-GlobalSound
]]

local SoundCache = {}
local SoundBypass = "SoundBypass"
local EditProperties = {
    Volume=0.5,
    MaxDistance=200,
    EmitterSize=10,
    PlayOnRemove=false,
}

function ToCache(Sound,Old)
    local Cache = {}
    for k,v in pairs(EditProperties) do
        Cache[k] = Sound[k]
    end
    Cache.Old = Old
    SoundCache[Sound] = Cache
end

function CheckSound(Sound)
    if not Sound:IsA("Sound") then return end
    if not Sound.Parent then return end
    if not Sound.Parent:IsA("BasePart") then
        return Sound:Destroy()
    end
    local C = {}
    local Old = {}
    for k,v in pairs(EditProperties) do
        Old[k] = Sound[k]
        Sound[k] = v
    end
    ToCache(Sound,Old)
    local function ClearC()
        for k,v in pairs(C) do
            v:Disconnect()
        end
        table.clear(C)
    end
    local function ChildCheck(Child)
        if Child.Name == SoundBypass then
            SoundCache[Sound] = nil
            ClearC()
            for k,v in pairs(Old) do
                Sound[k] = v
            end
        end
    end
    table.insert(C,Sound.ChildAdded:Connect(ChildCheck))
    table.insert(C,Sound.AncestryChanged:Connect(function(_,Parent)
        if not Parent then
            ClearC()
            SoundCache[Sound] = nil
        end
    end))
    for k,v in pairs(Sound:GetChildren()) do
        ChildCheck(v)
    end
end

game.DescendantAdded:Connect(CheckSound)
for k,v in pairs(game:GetDescendants()) do
    pcall(CheckSound,v)
end
