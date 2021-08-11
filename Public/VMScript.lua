local VM = {}
VM.__index = VM

VM.DeepCopy = function(self,Table,c)
	if not Table then return end
	if c then
		if c[Table] then
			return c[Table]
		end
	else
		c = {}
	end
	local NT = {}
	c[Table] = NT
	for k,v in pairs(Table) do
		NT[k] = type(v) == "table" and self:DeepCopy(v,c) or v
	end
	return NT
end

VM.NewStack = function(self,Stack)
	local UpperFuncs = self.Functions
	if self.CStack and self.StackCurrent.Functions then
		UpperFuncs = self.StackCurrent.Functions
	end
	local NewStack = {
		Current = 0,
		PToken="",
		Token="",
		Tokens=Stack,
		CloneTokens = self:DeepCopy(Stack),
		NToken="",
		Functions=setmetatable({},{
			__index=UpperFuncs
		})
	}
	self.Stacks[Stack] = NewStack
end

VM.GetStack = function(self,Stack)
	return self.Stacks[Stack]
end

VM.Next = function(self,Stack)
	if not self.Stacks[Stack] then
		self:NewStack(Stack)
	end
	self.Stacks[Stack].Current += 1
	local StackCurrent = self.Stacks[Stack]
	StackCurrent.PToken = StackCurrent.Token
	StackCurrent.Token = StackCurrent.Tokens[StackCurrent.Current] or ""
	StackCurrent.NToken = StackCurrent.Tokens[StackCurrent.Current+1] or ""
	self.CStack = Stack
	if StackCurrent then
		self.StackCurrent = StackCurrent
	end
end

VM.GetCurrentVariables = function(self)
	local Variables = {}
	for k,v in pairs(self.Variables) do
		if v.Block <= self.Block then
			table.insert(Variables,v)
		end
	end
	return Variables
end

VM.GetLowestVariable = function(self,Name)
	local Variables = self:GetCurrentVariables()
	local Variable = nil
	for k,v in pairs(Variables) do
		if v.Name == Name and v.Block <= self.Block then
			if not Variable then
				Variable = v
			elseif v.Block < Variable.Block then
				Variable = v
			end
		end
	end
	return Variable
end

VM.GetHighestVariable = function(self,Name)
	local Variables = self:GetCurrentVariables()
	local Variable = nil
	for k,v in pairs(Variables) do
		if v.Name == Name and v.Block <= self.Block then
			if not Variable then
				Variable = v
			elseif v.Block > Variable.Block then
				Variable = v
			end
		end
	end
	return Variable
end

VM.GetVariableFromBlock = function(self,Name,Block)
	local Variables = self:GetCurrentVariables()
	for k,v in pairs(Variables) do
		if v.Name == Name and v.Block == Block then
			return v
		end
	end
end

VM.NewVariable = function(self,Name,Value,Block)
	return {
		Name = Name,
		Value = Value,
		Block = Block
	}
end

VM.SetVariable = function(self,Name,Value)
	local Variable = self:GetHighestVariable(Name)
	if Variable then
		Variable.Value = Value
		return
	end
end

VM.MakeVariable = function(self,Name,Value,Extra,ForceBlock)
	local Variable = self:GetHighestVariable(Name)
	if Variable and Variable.Block == self.Block and ForceBlock == nil then return end
	Variable = self:NewVariable(Name,Value,self.Block)
	if ForceBlock ~= nil then
		Variable.Block = ForceBlock
	end
	if Extra and type(Extra) == "table" then
		for k,v in pairs(Extra) do
			Variable[k] = v
		end
	end
	table.insert(self.Variables,Variable)
end

VM.ParseInnerToken = function(self,Token)
	return self:Parse(Token)
end

VM.ParseToken = function(self,Token)
	for k,v in pairs(Token) do
		if type(v) == "table" then
			local R = {self:ParseInnerToken(v)}
			if #R > 1 then --Multiple returns detection
				Token[k] = R[1]
				for kk,vv in pairs(R) do
					if kk > 1 then
						table.insert(Token,k+(kk-1),vv)	
					end
				end
			else
				Token[k] = 	R[1]
			end
		end
	end
end

VM.OpenBlock = function(self)
	self.Block += 1
end

VM.CloseBlock = function(self)
	local Variables = self:GetCurrentVariables()
	for k,v in pairs(Variables) do
		if v.Block >= self.Block then
			table.remove(self.Variables,table.find(self.Variables,v))
		end
	end
	self.Block -= 1
end

VM.SetState = function(self,Token)
	self:SetVariable(Token[2],Token[3])
end

VM.NewState = function(self,Token)
	self:MakeVariable(Token[2],Token[3])
end

VM.CallState = function(self,Token)
	local Name = Token[2]
	local Args = {select(3,table.unpack(Token))}
	return self.StackCurrent.Functions[Name](table.unpack(Args))
end

VM.DefState = function(self,Token)
	local Name = Token[2]
	local Args = Token[3]
	local Stack = Token[4]
	local VAR = {
		Name=Name.."_def",
		Block=self.Block,
		Value={
			Stack=Stack,
			Args=Args,
		},
	}
	local Block = self.Block
	self:NewStack(Stack)
	self.StackCurrent.Functions[Name] = function(...)
		self:OpenBlock()
		local Args = {...}
		local Variable = VAR --Get the function variable
		local Stack = self:GetStack(Variable.Value.Stack)
		for k,v in pairs(Variable.Value.Args) do
			if v == "..." then --Vararg callback
				self:MakeVariable(v,{select(k,unpack(Args))})
				break
			end
			self:MakeVariable(v,Args[k] or nil) --Create the arguments passed in the function
		end
		local Token = Variable.Value.Stack
		local Results = {}
		local PreBlock = self.InBlock
		local CStack = self.CStack --CStack check
		self.InBlock = true
		repeat --Parsing everything within the function
			self:Next(Stack.Tokens)
			if Stack.Token[1] == "return" then
				Results = {self:Parse(Stack.Token)}
				self.Results = nil
				break
			end
			self:Parse(Stack.Token)
			if self.Results then
				Results = self.Results
				self.Results = nil
				break
			end
		until Stack.Current >= #Stack.Tokens
		Stack.Tokens = self:DeepCopy(Stack.CloneTokens) --Preserving the state of the function before the call
		Stack.Current = 0
		Variable.Value.Stack = Stack.Tokens
		self.CStack = CStack --Set the CStack to the previous CStack
		self.Results = nil
		self.Stacks[Stack.Tokens] = nil
		self:NewStack(Stack.Tokens) --Create a new def stack that can be called again
		self:CloseBlock()
		self.InBlock = PreBlock
		return unpack(Results)
	end
end

VM.SkipIfState = function(self,Token) --If the given statement was true, skip over else and elif statements that follow.
	local Stack = self:GetStack(Token)
	if Stack.Token[1] ~= "elif" and Stack.Token[1] ~= "else" then
		return self:Parse(Stack.Token)
	end
	repeat
		self:Next(Token)
		if Stack.Current >= #Stack.Tokens then --Check if it's at the end of the current stack
			if Stack.Token[1] == "elif" or Stack.Token[1] == "else" then
				self:Next(Token)
			end
			break
		end
	until Stack.Token[1] ~= "elif" and Stack.Token[1] ~= "else"
	if Stack.Token[1] == "elif" or Stack.Token[1] == "else" then
		self:Next(Stack.Token)
	end
	return self:Parse(Stack.Token)
end

VM.CondState = function(self,Token) --CondState is the main function called by all conditional statements and loops
	self:OpenBlock()
	self:NewStack(Token)
	local Stack = self:GetStack(Token)
	repeat
		self:Next(Stack.Tokens)
		if Stack.Token[1] == "return" and self.InBlock then --If returned while in a block, make sure the block recieves the results
			self.Results = {self:Parse(Stack.Token)}
			break
		end
		if Stack.Token[1] == "break" and self.InLoop then
			self.InLoop = false
			break
		end
		self:Parse(Stack.Token)
	until Stack.Current >= #Stack.Tokens
	self.Stacks[Token] = nil --Remove the stack since if statements don't need to carry any data after called
	self:CloseBlock()
end

VM.IfState = function(self,Token) --If and elif statement checking
	local Comp = self:ParseInnerToken(Token[2]) --Parse the actual value we are checking
	local Stack = Token[3]
	local CStack = self.CStack
	if Comp then
		self:CondState(Stack)
		self:Next(CStack) --Jump over the if statement so we can skip correctly (will crash otherwise)
		self:SkipIfState(CStack)
		return
	else
		self:Next(CStack) --Get the next token
		local Stack = self:GetStack(CStack)
		if Stack.Token[1] == "elif" then --Call an elif statement
			return self:IfState(Stack.Token)
		elseif Stack.Token[1] == "else" then --Call an else statement
			return self:CondState(Stack.Token)
		end
		return self:Parse(Stack.Token)
	end
end

VM.WhileState = function(self,Token)
	local Comp = Token[2]
	local Stack = Token[3]
	local NewComp = self:DeepCopy(Comp)
	local PreLoop = self.InLoop
	self.InLoop = true
	while self:ParseInnerToken(NewComp) do
		local NewStack = self:DeepCopy(Stack)
		self:CondState(NewStack)
		NewComp = self:DeepCopy(Comp)
		if not self.InLoop then break end
	end
	self.InLoop = PreLoop
end

VM.RepeatState = function(self,Token)
	local Comp = Token[2]
	local Stack = Token[3]
	local NewComp = self:DeepCopy(Comp)
	local PreLoop = self.InLoop
	self.InLoop = true
	repeat
		local NewStack = self:DeepCopy(Stack)
		self:CondState(NewStack)
		NewComp = self:DeepCopy(Comp)
		if not self.InLoop then break end
	until self:ParseInnerToken(NewComp)
	self.InLoop = PreLoop
end

VM.ForNumState = function(self,Token)
	local VName = Token[2]
	local VValue = self:ParseInnerToken(Token[3])
	local Last = self:ParseInnerToken(Token[4])
	local Inc = self:ParseInnerToken(Token[5])
	local Stack = Token[6]
	local PreLoop = self.InLoop
	self.InLoop = true
	for i=VValue,Last,Inc do
		self:MakeVariable(VName,i,nil,self.Block+1)
		local NewStack = self:DeepCopy(Stack)
		self:CondState(NewStack)
		if not self.InLoop then break end
	end
	self.InLoop = PreLoop
end

VM.ForPairsState = function(self,Token)
	local VName1 = Token[2]
	local VName2 = Token[3]
	local Table = self:ParseInnerToken(Token[4])
	local Stack = Token[5]
	local PreLoop = self.InLoop
	self.InLoop = true
	for k,v in pairs(Table) do
		self:MakeVariable(VName1,k,nil,self.Block+1)
		self:MakeVariable(VName2,v,nil,self.Block+1)
		local NewStack = self:DeepCopy(Stack)
		self:CondState(NewStack)
		if not self.InLoop then break end
	end
	self.InLoop = PreLoop
end

VM.Parse = function(self,Token)
	if typeof(Token) ~= "table" then return Token end
	if Token[1] == "def" then --Don't parse internals
		return self:DefState(Token)
	elseif Token[1] == "if" then
		return self:IfState(Token)
	elseif Token[1] == "while" then
		return self:WhileState(Token)
	elseif Token[1] == "repeat" then
		return self:RepeatState(Token)
	elseif Token[1] == "fornum" then
		return self:ForNumState(Token)
	elseif Token[1] == "forpairs" then
		return self:ForPairsState(Token)
	elseif Token[1] == "skip" then --skip token to not parse internals inside another table (mainly used if you have variables that you don't want to parse)
		return select(2,unpack(Token))
	end
	self:ParseToken(Token)
	if Token[1] == "set" then
		self:SetState(Token)
	elseif Token[1] == "new" then
		self:NewState(Token)
	elseif Token[1] == "call" then
		return self:CallState(Token)
	elseif Token[1] == "inc" then
		local Variable = self:GetHighestVariable(Token[2])
		if not Variable then return end
		Variable.Value = Variable.Value + 1
		return Variable.Value
	elseif Token[1] == "get" then
		local Variable = self:GetHighestVariable(Token[2])
		if Variable then
			if Variable.Hidden then return end
			return Variable.Value
		end
		return nil
	elseif Token[1] == "add" then
		return Token[2] + Token[3]
	elseif Token[1] == "sub" then
		return Token[2] - Token[3]
	elseif Token[1] == "mul" then
		return Token[2] * Token[3]
	elseif Token[1] == "div" then
		return Token[2] / Token[3]
	elseif Token[1] == "pow" then
		return Token[2] ^ Token[3]
	elseif Token[1] == "mod" then
		return Token[2] % Token[3]
	elseif Token[1] == "and" then
		return Token[2] and Token[3]
	elseif Token[1] == "or" then
		return Token[2] or Token[3]
	elseif Token[1] == "not" then
		return not Token[2]
	elseif Token[1] == "eq" then
		return Token[2] == Token[3]
	elseif Token[1] == "lt" then
		return Token[2] < Token[3]
	elseif Token[1] == "gt" then
		return Token[2] > Token[3]
	elseif Token[1] == "leq" then
		return Token[2] <= Token[3]
	elseif Token[1] == "geq" then
		return Token[2] >= Token[3]
	elseif Token[1] == "neq" then
		return Token[2] ~= Token[3]
	elseif Token[1] == "return" then --Should only be used in def blocks
		if not self.InBlock then return end
		if not Token[2] then
			local Results = nil
			if self.InBlock then
				self.Results = {Results}
			end
			return Results
		end
		local Results = self:Parse(Token[2])
		if self.InBlock then
			self.Results = {Results}
		end
		return Results
	elseif Token[1] == "index" then
		return Token[2][Token[3]]
	elseif Token[1] == "setfunc" then
		if typeof(Token[3]) ~= "function" then
			return
		end
		self.StackCurrent.Functions[Token[2]] = Token[3]
	elseif Token[1] == "delfunc" then
		self.StackCurrent.Functions[Token[2]] = nil
	elseif Token[1] == "global" then
		local Variable = self.Globals[Token[2]]
		if Variable then
			return Variable
		end
		return nil
	elseif Token[1] == "setindex" then
		Token[2][Token[3]] = Token[4]
		return
	elseif Token[1] == "longindex" then
		local Value = Token[2]
		for k,v in pairs(Token) do
			if k > 2 then
				Value = Value[v]
			end
		end
		return Value
	elseif Token[1] == "rawcall" then
		return Token[2](select(3,table.unpack(Token)))
	elseif Token[1] == "getfunc" then
		return self.StackCurrent.Functions[Token[2]]
	elseif Token[1] == "selfcall" then
		return Token[2][Token[3]](Token[2],select(4,table.unpack(Token)))
	elseif Token[1] == "len" then
		return #Token[2]
	elseif Token[1] == "forcereturn" then --Used as a cond statement replacement for while loops and repeat loops (will return all of the internals inside the token but parsed)
		return select(2,unpack(Token))
	elseif Token[1] == "concat" then
		local Tokens = {select(2,unpack(Token))}
		local s = ""
		for _,v in pairs(Tokens) do
			s = s .. tostring(v)
		end
		return s
	elseif Token[1] == "unpack" then
		return unpack(Token[2])
	end
	return Token
end

VM.New = function(Tokens)
	local NVM = setmetatable({
		Stacks={},
		MainStack=Tokens,
		Variables={},
		Block=1,
		CStack={},
		InBlock=false,
		InLoop=false,
		Results=nil,
		StackCurrent={},
		Functions={
			print=print,
			warn=warn,
			error=error,
			reverse=string.reverse,
			newInst=Instance.new,
			wait=wait,
			format=string.format,
			color=Color3.new,
			vector=Vector3.new,
			cframe=CFrame.new,
			udim2=UDim2.new,
			udim=UDim.new,
			rawset=rawset,
			rawequal=rawequal,
			rawget=rawget,
			setmetatable=setmetatable,
			getmetatable=getmetatable,
			unpack=unpack,
			type=type,
			typeof=typeof,
			newproxy=newproxy,
			getfenv=getfenv,
		},
		Globals={
			game=game,
			workspace=workspace,
			string=string,
			table=table,
			env=getfenv(2),
		},
	},VM)
	NVM:NewStack(Tokens)
	return NVM
end

VM.Start = function(self)
	self.CStack = self.MainStack
	repeat
		self:Next(self.MainStack)
		self:Parse(self.Stacks[self.MainStack].Token)
	until self.Stacks[self.MainStack].Current >= #self.Stacks[self.MainStack].Tokens
end

return VM
