local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))

local isnetworkowner = identifyexecutor and table.find({'Volt', 'Synapse Z', 'Seliware','Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local store = {
	coins = {},
	infectors = {}
}

local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local cleanFunc = function(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end

run(function()
	store.coins = collection('SmileCoin', vape)

	for _, v in workspace.Map:GetDescendants() do
		if v:FindFirstChild('InfectScript', true) then
			table.insert(store.infectors, v:FindFirstChild('InfectScript', true).Parent)
		end
	end

	vape:Clean(workspace.Map.DescendantAdded:Connect(function(v)
		if v:FindFirstChild('InfectScript', true) then
			table.insert(store.infectors, v:FindFirstChild('InfectScript', true).Parent)
		end
	end))
	vape:Clean(workspace.Map.DescendantRemoving:Connect(function(v)
		if v:FindFirstChild('InfectScript', true) then
			local idx = table.find(store.infectors, v:FindFirstChild('InfectScript', true).Parent)
			if idx then
				table.remove(store.infectors, idx)
			end
		end
	end))
end)

sethiddenproperty(lplr, 'MaximumSimulationRadius', 9e9)
sethiddenproperty(lplr, 'MaxSimulationRadius', 9e9)
sethiddenproperty(lplr, 'SimulationRadius', 9e9)

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('newvapeud/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

for _, v in {'Disabler', 'MurderMystery', 'Invisible'} do
	vape:Remove(v)
end

run(function()
	local AntiInfect
	local Infector = {}

	AntiInfect = vape.Categories.Utility:CreateModule({
		Name = 'AntiInfect',
		Function = function(callback)
			if callback then
				repeat
					for _, v in store.infectors do
						print(v:GetFullName())
						v.CanTouch = false
					end

					task.wait(0.1)
				until not AntiInfect.Enabled
			else
				for _, v in store.infectors do
					v.CanTouch = true
				end
			end
		end,
		Tooltip = 'Disables the infector parts.'
	})
end)

run(function()
	local Disabler
	
	local function characterAdded(char)
		for _, v in getconnections(char.RootPart:GetPropertyChangedSignal('CFrame')) do
			hookfunction(v.Function, function() end)
		end
		for _, v in getconnections(char.RootPart:GetPropertyChangedSignal('Velocity')) do
			hookfunction(v.Function, function() end)
		end
	end
	
	Disabler = vape.Categories.Utility:CreateModule({
		Name = 'Disabler',
		Function = function(callback)
			if callback then
				Disabler:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
				Disabler:Clean(workspace.Map.AntiHack.ChildAdded:Connect(function(v)
					if v:IsA('BasePart') and v:FindFirstChild('TouchInterest', true) then
						v.CanCollide = false
					end
				end))
				if entitylib.isAlive then
					characterAdded(entitylib.character)
				end
				for _, v in workspace.Map.AntiHack:GetChildren() do
					if v:IsA('BasePart') and v:FindFirstChild('TouchInterest', true) then
						v.CanCollide = false
					end
				end
			end
		end,
		Tooltip = 'Disables GetPropertyChangedSignal detections for movement'
	})
end)

run(function()
	local AutoCoin

	AutoCoin = vape.Categories.Minigames:CreateModule({
		Name = 'AutoCoin',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive then
						for _, v in store.coins do
							if v:IsA('BasePart') and v.Name == 'SmileCoin' then
								firetouchinterest(v, entitylib.character.RootPart, 0)
								firetouchinterest(v, entitylib.character.RootPart, 1)
								--entitylib.character.HumanoidRootPart.CFrame = v.CFrame
							end
						end
					end

					task.wait()
				until not AutoCoin.Enabled
			end
		end,
		Tooltip = 'Teleport you to the coins.'
	})
end)