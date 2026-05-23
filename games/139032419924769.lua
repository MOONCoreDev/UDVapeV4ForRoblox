local run = function(func)
	func()
end
local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local virtualInputManager = cloneref(game:GetService('VirtualInputManager'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'Volt', 'Synapse Z', 'Seliware','Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local tween = vape.Libraries.tween
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local store = {
	map = 'test',
	matchState = 0
}

local forsaken

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('newvape/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function calculateMoveVector(vec)
	local c, s
	local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
	if R12 < 1 and R12 > -1 then
		c = R22
		s = R02
	else
		c = R00
		s = -R01 * math.sign(R12)
	end
	vec = Vector3.new((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
	return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function canClick()
	local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
	for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	return (not vape.gui.ScaledGui.ClickGui.Visible) and (not inputService:GetFocusedTextBox())
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil
end

local function notif(...)
	return vape:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local visited, attempted, tpSwitch = {}, {}, false
local cacheExpire, cache = tick()
local function serverHop(pointer, filter)
	visited = shared.vapeserverhoplist and shared.vapeserverhoplist:split('/') or {}
	if not table.find(visited, game.JobId) then
		table.insert(visited, game.JobId)
	end
	if not pointer then
		notif('Vape', 'Searching for an available server.', 2)
	end

	local suc, httpdata = pcall(function()
		return cacheExpire < tick() and game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder='..(filter == 'Ascending' and 1 or 2)..'&excludeFullGames=true&limit=100'..(pointer and '&cursor='..pointer or '')) or cache
	end)
	local data = suc and httpService:JSONDecode(httpdata) or nil
	if data and data.data then
		for _, v in data.data do
			if tonumber(v.playing) < playersService.MaxPlayers and not table.find(visited, v.id) and not table.find(attempted, v.id) then
				cacheExpire, cache = tick() + 60, httpdata
				table.insert(attempted, v.id)

				notif('Vape', 'Found! Teleporting.', 5)
				teleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
				return
			end
		end

		if data.nextPageCursor then
			serverHop(data.nextPageCursor, filter)
		else
			notif('Vape', 'Failed to find an available server.', 5, 'warning')
		end
	else
		notif('Vape', 'Failed to grab servers. ('..(data and data.errors[1].message or 'no data')..')', 5, 'warning')
	end
end

local frictionTable, oldfrict, entitylib = {}, {}
local function updateVelocity()
	if getTableSize(frictionTable) > 0 then
		if entitylib.isAlive then
			for _, v in entitylib.character.Character:GetChildren() do
				if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
					oldfrict[v] = v.CustomPhysicalProperties or 'none'
					v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
				end
			end
		end
	else
		for i, v in oldfrict do
			i.CustomPhysicalProperties = v ~= 'none' and v or nil
		end
		table.clear(oldfrict)
	end
end

local function motorMove(target, cf)
	local part = Instance.new('Part')
	part.Anchored = true
	part.Parent = workspace
	local motor = Instance.new('Motor6D')
	motor.Part0 = target
	motor.Part1 = part
	motor.C1 = cf
	motor.Parent = part
	task.delay(0, part.Destroy, part)
end

run(function()
	forsaken = {
		SprintController = require(replicatedStorage.Systems.Character.Game.Sprinting)
	}

	local games = sessioninfo:AddItem('Games')

	local mapname = 'Unknown'
	sessioninfo:AddItem('Map', 0, function()
		return mapname
	end, false)

	sessioninfo:AddItem('Killer Chance', lplr.leaderstats.KillerChance.Value, function()
		return lplr.leaderstats.KillerChance.Value
	end)

	if workspace.Map.Ingame:FindFirstChild('Config', true) then
		mapname = require(workspace.Map.Ingame:FindFirstChild('Config', true)).DisplayName
	end

	vape:Clean(workspace.Map.Ingame.ChildAdded:Connect(function(v)
		if v:IsA('Model') and v.Name == 'Map' then
			games:Increment()
			mapname = require(v:WaitForChild('Config', 10)).DisplayName
		end
	end))
end)

vape:Clean(replicatedStorage.RoundTimer:GetAttributeChangedSignal('TimeLeft'):Connect(function()
	if replicatedStorage.RoundTimer:GetAttribute('TimeLeft') ~= '' and replicatedStorage.RoundTimer:GetAttribute('TimeLeft') > 0 then
		store.matchState = replicatedStorage.RoundTimer:GetAttribute('TimeLeft')
	else
		store.matchState = 0
	end
end))

local prediction = vape.Libraries.prediction
local entitylib = vape.Libraries.entity

for _, v in {'FOV', 'MurderMystery', 'Chat', 'Invisible', 'AntiRagdoll'} do
	vape:Remove(v)
end

run(function()
	local InfiniteStamina
	local old, old2

	InfiniteStamina = vape.Categories.Blatant:CreateModule({
		Name = 'InfiniteStamina',
		Function = function(callback)
			if callback then
				old = forsaken.SprintController.StaminaLossDisabled
				old2 = forsaken.SprintController.MaxStamina

				InfiniteStamina:Clean(lplr.CharacterAdded:Connect(function()
					task.wait()
					forsaken.SprintController.MaxStamina = math.huge
					forsaken.SprintController.Stamina = math.huge
					forsaken.SprintController.StaminaLossDisabled = function(...) end
				end))

				repeat
					forsaken.SprintController.MaxStamina = math.huge
					forsaken.SprintController.Stamina = math.huge
					forsaken.SprintController.StaminaLossDisabled = function(...) end
					task.wait()
				until not InfiniteStamina.Enabled
			else
				forsaken.SprintController.StaminaLossDisabled = old
				forsaken.SprintController.MaxStamina = old2
			end
		end,
		Tooltip = 'Tiredless simulator.'
	})
end)

run(function()
	local Invisible
	local clone, oldroot, hip, valid
	local animtrack
	local proper = true
	
	local function doClone()
		if entitylib.isAlive and entitylib.character.Humanoid.Health > 0 then
			hip = entitylib.character.Humanoid.HipHeight
			oldroot = entitylib.character.HumanoidRootPart
			if not lplr.Character.Parent then
				return false
			end
	
			lplr.Character.Parent = game
			clone = oldroot:Clone()
			clone.Parent = lplr.Character
			oldroot.Parent = gameCamera
			clone.CFrame = oldroot.CFrame
	
			lplr.Character.PrimaryPart = clone
			entitylib.character.HumanoidRootPart = clone
			entitylib.character.RootPart = clone
			lplr.Character.Parent = workspace
	
			for _, v in lplr.Character:GetDescendants() do
				if v:IsA('Weld') or v:IsA('Motor6D') then
					if v.Part0 == oldroot then
						v.Part0 = clone
					end
					if v.Part1 == oldroot then
						v.Part1 = clone
					end
				end
			end
	
			return true
		end
	
		return false
	end
	
	local function revertClone()
		if not oldroot or not oldroot:IsDescendantOf(workspace) or not entitylib.isAlive then
			return false
		end
	
		lplr.Character.Parent = game
		oldroot.Parent = lplr.Character
		lplr.Character.PrimaryPart = oldroot
		entitylib.character.HumanoidRootPart = oldroot
		entitylib.character.RootPart = oldroot
		lplr.Character.Parent = workspace
		oldroot.CanCollide = true
	
		for _, v in lplr.Character:GetDescendants() do
			if v:IsA('Weld') or v:IsA('Motor6D') then
				if v.Part0 == clone then
					v.Part0 = oldroot
				end
				if v.Part1 == clone then
					v.Part1 = oldroot
				end
			end
		end
	
		local oldpos = clone.CFrame
		if clone then
			clone:Destroy()
			clone = nil
		end
	
		oldroot.CFrame = oldpos
		oldroot = nil
		entitylib.character.Humanoid.HipHeight = hip or 2
	end
	
	local function animationTrickery()
		if entitylib.isAlive then
			local anim = Instance.new('Animation')
			anim.AnimationId = 'http://www.roblox.com/asset/?id=75804462760596'
			animtrack = entitylib.character.Humanoid.Animator:LoadAnimation(anim)
			animtrack.Priority = Enum.AnimationPriority.Action4
			animtrack:Play(0, 1, 0)
			anim:Destroy()
			animtrack.Stopped:Connect(function()
				if Invisible.Enabled then
					animationTrickery()
				end
			end)
	
			task.delay(0, function()
				animtrack.TimePosition = 0.77
				task.delay(1, function()
					animtrack:AdjustSpeed(math.huge)
				end)
			end)
		end
	end
	
	Invisible = vape.Categories.Blatant:CreateModule({
		Name = 'Invisible',
		Function = function(callback)
			if callback then
				if not proper then
					notif('Invisible', 'Broken state detected', 3, 'alert')
					Invisible:Toggle()
					return
				end
	
				success = doClone()
				if not success then
					Invisible:Toggle()
					return
				end
	
				animationTrickery()
				Invisible:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and oldroot then
						local root = entitylib.character.RootPart
						local cf = root.CFrame - Vector3.new(0, entitylib.character.Humanoid.HipHeight + (root.Size.Y / 2) - 1, 0)
	
						if not isnetworkowner(oldroot) then
							root.CFrame = oldroot.CFrame
							root.Velocity = oldroot.Velocity
							return
						end

						oldroot.Velocity = root.Velocity
						oldroot.CanCollide = false
					end
				end))
	
				Invisible:Clean(entitylib.Events.LocalAdded:Connect(function(char)
					local animator = char.Humanoid:WaitForChild('Animator', 1)
					if animator and Invisible.Enabled then
						oldroot = nil
						Invisible:Toggle()
						Invisible:Toggle()
					end
				end))
			else
				if animtrack then
					animtrack:Stop()
					animtrack:Destroy()
				end
	
				if success and clone and oldroot and proper then
					proper = true
					if oldroot and clone then
						revertClone()
					end
				end
			end
		end,
		Tooltip = 'Turns you invisible.'
	})
end)

run(function()
	local NoSlowdown
	local Effects = {'SlowedStatus', 'DrinkingCola', 'EatingGhostburger', 'DrinkingSlateskin', 'SlateskinStatus', 'Medkit', 'FallSlowness', 'HinderedMovement', 'WeaknessStatus', 'MassInfection', 'Entanglement', 'UnstableEye', 'RejuvenateTheRotten', 'Stunned', 'BloxyColaItem'}

	NoSlowdown = vape.Categories.Blatant:CreateModule({
		Name = 'NoSlowdown',
		Function = function(callback)
			if callback then
				NoSlowdown:Clean(lplr.CharacterAdded:Connect(function(v)
					NoSlowdown:Clean(v:WaitForChild('SpeedMultipliers', 5).ChildAdded:Connect(function(v)
						if table.find(Effects, v.Name) then
							v:Destroy()
						end
					end))
					NoSlowdown:Clean(v:WaitForChild('ResistanceMultipliers', 5).ChildAdded:Connect(function(v)
						if table.find(Effects, v.Name) then
							v:Destroy()
						end
					end))
					NoSlowdown:Clean(v:WaitForChild('FOVMultipliers', 5).ChildAdded:Connect(function(v)
						if table.find(Effects, v.Name) then
							v:Destroy()
						end
					end))
				end))

				NoSlowdown:Clean(lightingService.ChildAdded:Connect(function(v)
					if v.Name == 'BlindnessBlur' or v.Name == 'SubspaceVFXBlur' or v.Name == 'SubspaceVFXColorCorrection' then
						v:Destroy()
					end
				end))

				if entitylib.isAlive then
					NoSlowdown:Clean(lplr.Character.SpeedMultipliers.ChildAdded:Connect(function(v)
						if table.find(Effects, v.Name) then
							v:Destroy()
						end
					end))
					NoSlowdown:Clean(lplr.Character.ResistanceMultipliers.ChildAdded:Connect(function(v)
						if table.find(Effects, v.Name) then
							v:Destroy()
						end
					end))
					NoSlowdown:Clean(lplr.Character.FOVMultipliers.ChildAdded:Connect(function(v)
						if table.find(Effects, v.Name) then
							v:Destroy()
						end
					end))
				end
			end
		end,
		Tooltip = 'Prevents from effects/using item.'
	})
end)

-- 126830014841198
-- 136252471123500
-- 126355327951215

run(function()
	local GeneratorESP
	local FillColor
	local OutlineColor
	local FillTransparency
	local OutlineTransparency
	local Walls
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui

	local function genAdd(v)
		if v:IsA('Model') and v.Name == 'Generator' and v:WaitForChild('Progress', 5) and v.Progress:IsA('NumberValue') then
			local cham = Instance.new('Highlight')
			cham.Adornee = v
			cham.DepthMode = Enum.HighlightDepthMode[Walls.Enabled and 'AlwaysOnTop' or 'Occluded']
			cham.FillColor = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
			cham.OutlineColor = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
			cham.FillTransparency = FillTransparency.Value
			cham.OutlineTransparency = OutlineTransparency.Value
			cham.Parent = Folder
			Reference[v] = cham
		end
	end

	GeneratorESP = vape.Categories.Render:CreateModule({
		Name = 'GeneratorESP',
		Function = function(callback)
			if callback then
				GeneratorESP:Clean(workspace.DescendantAdded:Connect(function(v)
					genAdd(v)
				end))
				GeneratorESP:Clean(workspace.DescendantRemoving:Connect(function(v)
					if Reference[v] then
						Reference[v]:Destroy()
						Reference[v] = nil
					end
				end))

				if #workspace.Map.Ingame:GetChildren() ~= 0 then
					for _, v in workspace.Map.Ingame.Map:GetChildren() do
						genAdd(v)
					end
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'Display generators through walls.'
	})
	FillColor = GeneratorESP:CreateColorSlider({
		Name = 'Color',
		Function = function(hue, sat, val)
			for i, v in Reference do
				local color = Color3.fromHSV(hue, sat, val)
				if type(v) == 'table' then
					for _, v2 in v do v2.Color3 = color end
				else
					v.FillColor = color
				end
			end
		end
	})
	OutlineColor = GeneratorESP:CreateColorSlider({
		Name = 'Outline Color',
		DefaultSat = 0,
		Function = function(hue, sat, val)
			for i, v in Reference do
				if type(v) ~= 'table' then
					v.OutlineColor = Color3.fromHSV(hue, sat, val)
				end
			end
		end,
		Darker = true
	})
	FillTransparency = GeneratorESP:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5,
		Function = function(val)
			for _, v in Reference do
				if type(v) == 'table' then
					for _, v2 in v do v2.Transparency = val end
				else
					v.FillTransparency = val
				end
			end
		end,
		Decimal = 10
	})
	OutlineTransparency = GeneratorESP:CreateSlider({
		Name = 'Outline Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5,
		Function = function(val)
			for _, v in Reference do
				if type(v) ~= 'table' then
					v.OutlineTransparency = val
				end
			end
		end,
		Decimal = 10,
		Darker = true
	})
	Walls = GeneratorESP:CreateToggle({
		Name = 'Render Walls',
		Function = function(callback)
			for _, v in Reference do
				if type(v) == 'table' then
					for _, v2 in v do
						v2.AlwaysOnTop = callback
					end
				else
					v.DepthMode = Enum.HighlightDepthMode[callback and 'AlwaysOnTop' or 'Occluded']
				end
			end
		end,
		Default = true
	})
end)

run(function()
	local ItemESP
	local FillColor
	local OutlineColor
	local FillTransparency
	local OutlineTransparency
	local List
	local Walls
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui

	local function itemAdd(v)
		if v:IsA('Tool') then
			local cham = Instance.new('Highlight')
			cham.Adornee = v
			cham.DepthMode = Enum.HighlightDepthMode[Walls.Enabled and 'AlwaysOnTop' or 'Occluded']
			cham.FillColor = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
			cham.OutlineColor = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
			cham.FillTransparency = FillTransparency.Value
			cham.OutlineTransparency = OutlineTransparency.Value
			cham.Parent = Folder
			Reference[v] = cham
		end
	end

	ItemESP = vape.Categories.Render:CreateModule({
		Name = 'ItemESP',
		Function = function(callback)
			if callback then
				ItemESP:Clean(workspace.Map.Ingame.ChildAdded:Connect(function(v)
					itemAdd(v)
				end))
				ItemESP:Clean(workspace.Map.Ingame.ChildRemoved:Connect(function(v)
					if Reference[v] then
						Reference[v]:Destroy()
						Reference[v] = nil
					end
				end))

				for _, v in workspace.Map.Ingame:GetChildren() do
					itemAdd(v)
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'Display items through walls.'
	})
	FillColor = ItemESP:CreateColorSlider({
		Name = 'Color',
		Function = function(hue, sat, val)
			for i, v in Reference do
				local color = Color3.fromHSV(hue, sat, val)
				if type(v) == 'table' then
					for _, v2 in v do v2.Color3 = color end
				else
					v.FillColor = color
				end
			end
		end
	})
	OutlineColor = ItemESP:CreateColorSlider({
		Name = 'Outline Color',
		DefaultSat = 0,
		Function = function(hue, sat, val)
			for i, v in Reference do
				if type(v) ~= 'table' then
					v.OutlineColor = Color3.fromHSV(hue, sat, val)
				end
			end
		end,
		Darker = true
	})
	FillTransparency = ItemESP:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5,
		Function = function(val)
			for _, v in Reference do
				if type(v) == 'table' then
					for _, v2 in v do v2.Transparency = val end
				else
					v.FillTransparency = val
				end
			end
		end,
		Decimal = 10
	})
	OutlineTransparency = ItemESP:CreateSlider({
		Name = 'Outline Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5,
		Function = function(val)
			for _, v in Reference do
				if type(v) ~= 'table' then
					v.OutlineTransparency = val
				end
			end
		end,
		Decimal = 10,
		Darker = true
	})
	Walls = ItemESP:CreateToggle({
		Name = 'Render Walls',
		Function = function(callback)
			for _, v in Reference do
				if type(v) == 'table' then
					for _, v2 in v do
						v2.AlwaysOnTop = callback
					end
				else
					v.DepthMode = Enum.HighlightDepthMode[callback and 'AlwaysOnTop' or 'Occluded']
				end
			end
		end,
		Default = true
	})
end)

run(function()
	local FOV
	local Value
	local oldfov

	FOV = vape.Legit:CreateModule({
		Name = 'FOV',
		Function = function(callback)
			if callback then
				oldfov = lplr.PlayerData.Settings.Game.FieldOfView.Value
				repeat
					lplr.PlayerData.Settings.Game.FieldOfView.Value = Value.Value
					task.wait()
				until not FOV.Enabled
			else
				lplr.PlayerData.Settings.Game.FieldOfView.Value = oldfov
			end
		end,
		Tooltip = 'Adjusts camera vision'
	})
	Value = FOV:CreateSlider({
		Name = 'FOV',
		Min = 30,
		Max = 120
	})
end)

run(function()
	local AutoSolve
	local Value
	local Instant

	AutoSolve = vape.Categories.Minigames:CreateModule({
		Name = 'AutoSolve',
		Function = function(callback)
			if callback then
				AutoSolve:Clean(lplr.CharacterAdded:Connect(function(v)
					AutoSolve:Clean(v:WaitForChild('SpeedMultipliers', 5).ChildAdded:Connect(function(v)
						if v.Name:find('FixingGenerator') then
							for _, v in workspace.Map.Ingame:GetDescendants() do
								if v:IsA('Model') and v.Name:find('Generator') and v.Progress and v.Progress:IsA('NumberValue') and v.Progress.Value <= 100 then
									if (v:GetPivot().Position - lplr.Character.HumanoidRootPart.Position).Magnitude <= 8 then
										if Instant.Enabled then
											for i = 1, 10 do
												v:FindFirstChild('Remotes', true):FindFirstChild('RE', true):FireServer()
											end
										else
											repeat
												task.wait(Value.Value)
												v:FindFirstChild('Remotes', true):FindFirstChild('RE', true):FireServer()
											until not AutoSolve.Enabled
										end
									end
								end
							end
						end
					end))
				end))
				AutoSolve:Clean(lplr.Character.SpeedMultipliers.ChildAdded:Connect(function(v)
					if v.Name:find('FixingGenerator') then
						for _, v in workspace.Map.Ingame:GetDescendants() do
							if v:IsA('Model') and v.Name:find('Generator') and v.Progress and v.Progress:IsA('NumberValue') and v.Progress.Value <= 100 then
								if (v:GetPivot().Position - lplr.Character.HumanoidRootPart.Position).Magnitude <= 8 then
									if Instant.Enabled then
										for i = 1, 10 do
											v:FindFirstChild('Remotes', true):FindFirstChild('RE', true):FireServer()
										end
									else
										repeat
											v:FindFirstChild('Remotes', true):FindFirstChild('RE', true):FireServer()
											task.wait(Value.Value)
										until not AutoSolve.Enabled
									end
								end
							end
						end
					end
				end))
			end
		end,
		Tooltip = 'Automatically solves generator puzzle.'
	})
	Value = AutoSolve:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 5,
		Decimal = 10
	})
	Instant = AutoSolve:CreateToggle({
		Name = 'Instant Fix',
		Default = false
	})
end)

run(function()
	local Chat

	Chat = vape.Legit:CreateModule({
		Name = 'Chat',
		Function = function(callback)
			if callback then
				if not textChatService.ChatWindowConfiguration.Enabled then
					textChatService.ChatWindowConfiguration.Enabled = true
				end

				Chat:Clean(textChatService.ChatWindowConfiguration:GetPropertyChangedSignal('Enabled'):Connect(function()
					if not textChatService.ChatWindowConfiguration.Enabled then
						textChatService.ChatWindowConfiguration.Enabled = true
					end
				end))
			end
		end,
		Tooltip = 'Enables chat in game.'
	})
end)