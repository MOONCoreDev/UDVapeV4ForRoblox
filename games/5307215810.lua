local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
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

local isnetworkowner = identifyexecutor and table.find({'Volt', 'Synapse Z', 'Seliware'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
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

local function notif(...)
	vape:CreateNotification(...)
end

local getgc = getgc or function() end
local rawget = rawget or function(table, index) return table[index] end
local hookfunction = hookfunction or function(old, new) 
	local func = debug.getinfo(old, 'f')
	if func then
		getfenv()[debug.getinfo(old, 'n').name] = new
	end
end
local getinfo = getinfo or debug.getinfo
local setthreadidentity = setthreadidentity or function(id) end
local getthreadidentity = getthreadidentity or function() return 7 end
local debugmode = true -- debug mode
local detected, kill

local flags = {}

local oldthreadidentity = getthreadidentity()
setthreadidentity(2)

for i,v in getgc(true) do
	if type(v) == 'table' and rawget(v, 'Detected') then
		local rawgets = {
			-- Anti-Cheat
			AntiCoreGui	= rawget(v, 'AntiCoreGui'),
			AntiAntiIdle = rawget(v, 'AntiAntiIdle'),
			HumanoidState = rawget(v, 'HumanoidState'),
			Speed = rawget(v, 'Speed'),
			MainDetection = rawget(v, 'MainDetection'),
			-- babajay
			Detected = rawget(v, 'Detected'),
			Kill = rawget(v, 'Kill'),
			KillClient = rawget(v, 'KillClient'),
			Disconnect = rawget(v , 'Disconnect'),
			Crash = {
				Normal = rawget(v, 'Crash'),
				GPU = rawget(v, 'GPUCrash'),
				RAM = rawget(v, 'RAMCrash'),
				Hard = rawget(v, 'HardCrash')
			},
			SetFPS = rawget(v, 'SetFPS'),
			RestoreFPS = rawget(v, 'RestoreFPS')
		}

		if type(rawgets.Detected) == 'function' then
			detected = rawgets.Detected
			local detectedhook

			detectedhook = hookfunction(detected, function(a, b, c)
				if not checkcaller() and a ~= '_' then
					if debugmode then
						warn(`\nFlagged!\nMethod: {a}\nInfo: {b}`)
					end
				end

				return true
			end)

			table.insert(flags, detected)
		end

		--[[if type(rawgets.AntiCoreGui) == 'function' then
			local old
			hookfunction(rawgets.AntiCoreGui, function(...)
				for _, tab in getgc(true) do
					if typeof(tab) == 'table' and table.find(tab, 'rbxassetid://10066921516') then
						setthreadidentity(8)
						for i,v in cloneref(game:GetService('CoreGui')):GetDescendants() do
							local property = (v:IsA('ImageLabel') or v:IsA('ImageButton')) and 'Image'
							if property then
								table.insert(tab, v[property])
							end
						end
						setthreadidentity(2)
					end--> yes
				end
				return old(...)
			end)
		end]]

		if type(rawgets.Speed) == 'function' then
			local old

			old = hookfunction(rawgets.Speed, function(data)
				data.Speed = math.huge 
				if debugmode then
					table.foreach(data, print)
				end

				return old(data)
			end)
		end

		if rawget(v, 'Variables') and rawget(v, 'Process') and type(rawgets.Kill) == 'function' then
			local killhook

			killhook = hookfunction(rawgets.Kill, function(fallback)
				if not checkcaller() and debugmode then
					warn(`Adonis tried to kill (fallback): {fallback}`)
				end
			end)

			table.insert(flags, rawgets.Kill)
		end

		table.foreach(rawgets.Crash, function(a, b)
			if type(b) == 'function' then
				local crashhook

				crashhook = hookfunction(b, function()
					if debugmode then
						warn(`Attempt to crash!\nMethod: {getinfo(b).name}`)
					end
				end)

				table.insert(flags, b)
			end
		end)

		if type(rawgets.SetFPS) == 'function' then
			local fpshook

			fpshook = hookfunction(rawgets.SetFPS, function(value)
				if debugmode then
					warn(`Adonis tried to change FPS: {value}`)
				end

				if type(rawgets.RestoreFPS) then
					rawgets.RestoreFPS()
				end
			end)

			table.insert(flags, rawgets.SetFPS)
		end
	end
end

local idkwhattocall

idkwhattocall = hookfunction(getrenv().debug.info, newcclosure(function(...)
	local action, fallback = ...

	if detected and action == detected then
		if debugmode then
			warn('successfully bypassed!')
		end

		return coroutine.yield(coroutine.running())
	end

	return idkwhattocall(...)
end))

setthreadidentity(oldthreadidentity)