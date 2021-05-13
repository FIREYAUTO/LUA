--[[

AI Network Basis:

{
    Nodes={
        [0]={
            0,
        },
    },
    Data={
        Success=0,
        Generation=0,
        MutationChance=0,
        NodeChangeChance=0,
    }
}

]]

local AI = {}
AI.__index = AI

function AI.populate(Table)
    Table.Nodes = {}
    Table.Data = {
        Success=0,
        Generation=0,
        MutationChance=1/10,
        NodeChangeChance=1/2,
    }
end

function AI.new(Data)
    if not Data then
        Data = {}
        AI.populate(Data)
    end
    Data.__Memory = {
        Nodes={},
        NodeInput=nil,
    }
    Data.Simulation = false
    Data.Random = 0
    Data.LastFailedNode = -1
    Data.LastAdded = {}
    return setmetatable(Data,AI)
end

-- // Memory Handling \\ --

function AI:CreateAttribute(Key)
    self.__Memory.Nodes[Key] = {}
end

function AI:InsertAttribute(Key,Value)
    local Node = self.__Memory.Nodes[Key]
    Node[#Node+1] = Value
    return #Node
end

function AI:EditAttribute(Key,Index,Value)
    self.__Memory.Nodes[Key][Index] = Value
end

function AI:AddNodeInput(Value)
    self.__Memory.NodeInput = Value
end

function AI:GetAttribute(Key)
    return self.__Memory.Nodes[Key]
end

-- // Node Handling \\ --

function AI:GetFreeNodeNumber()
    return #self.Nodes
end

function AI:AddNode()
    local NodeNumber = self:GetFreeNodeNumber()
    self:CreateAttribute(NodeNumber)
    self.Nodes[NodeNumber] = {}
    return NodeNumber
end

function AI:RandomNumber()
    math.randomseed((os.time()-os.clock())+self.Random)
    self.Random = self.Random + 1
    local RN = math.random()
    return RN
end

function AI:TryMutation()
    local RN = self:RandomNumber()
    if RN <= self.Data.MutationChance then
        return true
    end
    return false
end

function AI:FireNode(NodeNumber)
    if not self.Simulation then return end
    local Node = self.Nodes[NodeNumber]
    local Attribute = self:GetAttribute(NodeNumber)
    if Node then
        for k,v in pairs(Node) do
            local Success,Result = pcall(Attribute[v],NodeNumber,v)
            if not Success then Result = false end
            if self:TryMutation() then Result = not Result end
            if not Result then
                self.LastFailedNode = NodeNumber
                self.Data.Success = self.Data.Success - 1
                break
            else
                self.Data.Success = self.Data.Success + 1
            end
        end
    end
end

-- // Input Handling \\ --

function AI:AddInput(Node,Callback)
    local R = self:InsertAttribute(Node,Callback)
    local N = self.Nodes[Node]
    table.insert(N,R)
end

function AI:SetInput(Node,Key,Callback)
    self:EditAttribute(Node,Key,Callback)
end

-- // Main \\ --

function AI:Start()
    if self.Simulation then return end
    self.Simulation = true
    if self.__Memory.NodeInput then
        self.__Memory.NodeInput()
    end
end

function AI:Stop()
    if not self.Simulation then return end
    self.Simulation = false
end

function AI:Copy(t)
    local nt = {}
    for k,v in pairs(t) do
        nt[k] = v
    end
    return nt
end

function AI:RearrangeNodeKeys(Node,Diff)
    if self:TryMutation() then return end
    local RN = self:RandomNumber()
    if RN <= self.Data.NodeChangeChance then
        local LastNode = self.LastAdded[Node]
        local Attribute = self:GetAttribute(Node)
        if LastNode then
            if LastNode[1] < Diff then
                local RN2 = math.floor(self:RandomNumber()*2)+1
                for i=1,RN2 do
                    if RN2 > #Attribute then break end
                    self:AddInput(Node,Attribute[#Attribute-(i-1)])
                end
                if RN2 > #Attribute then
                    self:AddInput(Node,Attribute[#Attribute])
                end
            elseif LastNode[1] == Diff then
                self:AddInput(Node,Attribute[#Attribute])
            elseif LastNode[1] < Diff then
                self:EditAttribute(Node,Attribute[#Attribute],Attribute[1])
            end
        end
        self.LastAdded[Node] = {Diff,self:Copy(self.Nodes[Node])}
    end
end

-- // {{ --~=~-- }} \\ Everything below is an example // {{ --~=~-- }} \\ --

-- // Testing \\ --

local num = 0
local a = AI.new()

a:AddNodeInput(function()
    local Rounds = 0
    while a.Simulation do
        print("----- ROUND STARTED -----")
        for k,v in pairs(a.Nodes) do
            local Success = a.Data.Success
            a:FireNode(k)
            local Diff = a.Data.Success - Success
            a:RearrangeNodeKeys(k,Diff)
            print(num,Diff)
        end
        Rounds = Rounds + 1
        if Rounds > 20 then
            a:Stop()
        end
        print("----- ROUND ENDED -----")
    end
end)

-- // NODE 0 \\ --

local n = a:AddNode()

a:AddInput(n,function(v,k)
    if num > 10 then return false end
    num = num + 1
    return true
end)
a:AddInput(n,function(v,k)
    if num > 10 then return false end
    num = num + 1
    return true
end)

-- // NODE 1 \\ --

local n2 = a:AddNode()

a:AddInput(n2,function(v,k)
    if num > 10 then return false end
    num = num + 1
    return true
end)

a:AddInput(n2,function(v,k)
    if num > 10 then return false end
    if a:TryMutation() then
        num = 0
    end
    return true
end)

a:Start()
