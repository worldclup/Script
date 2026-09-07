-- 1. Loading Screen
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local flySpeed = 50
local flyHeight = 15
local hoverY
local bodyVelocity
local bodyPosition
local bodyGyro

local speedEnabled = false
local walkSpeed = 50
local normalSpeed = humanoid.WalkSpeed
local antiAfkEnabled = false
local zombieClientEvent = ReplicatedStorage:WaitForChild("Zombie_Remotes"):WaitForChild("Zombie_ClientEvent")
local bufferCaptureUntil = 0
local killAuraEnabled = false
local killAuraRange = 80
local fireCooldown = 0.25
local lastFire = 0
local clientShotId = 0
local killAuraConnection
local protocolOk, ZombieProtocol = pcall(require, ReplicatedStorage.Shared.Zombies.ZombieProtocol)
local autoWeaponUpgradeEnabled = false
local autoHealthUpgradeEnabled = false
local autoUpgradeDelay = 1
local upgradeToken = 0
local healthUpgradeToken = 0
local weaponLabel
local shownWeaponName
local deployables = {}
local autoDeployEnabled = {}
local autoDeployDelay = 1
local deployTokens = {}

local function formatBuffer(value)
	if typeof(value) ~= "buffer" then return tostring(value) end
	local bytes = {}
	for index = 0, math.min(buffer.len(value), 128) - 1 do
		table.insert(bytes, string.format("%02X", buffer.readu8(value, index)))
	end
	return ("buffer (%d bytes): %s"):format(buffer.len(value), table.concat(bytes, " "))
end

local function getEquippedWeapon()
	return character:FindFirstChildWhichIsA("Tool")
end

local function updateWeaponLabel()
	local weapon = getEquippedWeapon()
	local name = weapon and weapon.Name or "No weapon equipped"
	if weaponLabel and name ~= shownWeaponName then
		shownWeaponName = name
		weaponLabel:SetDesc(name)
	end
end

local function setAutoWeaponUpgrade(enabled)
	autoWeaponUpgradeEnabled = enabled
	upgradeToken = upgradeToken + 1
	if not enabled then return end

	local token = upgradeToken
	task.spawn(function()
		while autoWeaponUpgradeEnabled and token == upgradeToken do
			local events = ReplicatedStorage:FindFirstChild("Events")
			local actions = events and events:FindFirstChild("Actions")
			local upgrade = actions and actions:FindFirstChild("PurchaseUpgrade")
			if upgrade then upgrade:InvokeServer("PurchaseWeaponTierUpgrade") end
			task.wait(autoUpgradeDelay)
		end
	end)
end

local function setAutoHealthUpgrade(enabled)
	autoHealthUpgradeEnabled = enabled
	healthUpgradeToken = healthUpgradeToken + 1
	if not enabled then return end

	local token = healthUpgradeToken
	task.spawn(function()
		while autoHealthUpgradeEnabled and token == healthUpgradeToken do
			local events = ReplicatedStorage:FindFirstChild("Events")
			local actions = events and events:FindFirstChild("Actions")
			local upgrade = actions and actions:FindFirstChild("PurchaseUpgrade")
			if upgrade then upgrade:InvokeServer("Health") end
			task.wait(autoUpgradeDelay)
		end
	end)
end

local function watchWeapon()
	character.ChildAdded:Connect(function(item)
		if item:IsA("Tool") then updateWeaponLabel() end
	end)
	character.ChildRemoved:Connect(function(item)
		if item:IsA("Tool") then updateWeaponLabel() end
	end)
end

watchWeapon()

local function getDeployables()
	local inside = player.PlayerGui:WaitForChild("Gameplay"):WaitForChild("Right")
		:WaitForChild("CenterAnchor"):WaitForChild("Deployables"):WaitForChild("Inside")
	local names = {}
	for _, item in ipairs(inside:GetChildren()) do
		if item:IsA("GuiObject") then table.insert(names, item.Name) end
	end
	return names
end

local function setAutoDeploy(deployable, enabled)
	autoDeployEnabled[deployable] = enabled
	deployTokens[deployable] = (deployTokens[deployable] or 0) + 1
	if not enabled then return end

	local token = deployTokens[deployable]
	task.spawn(function()
		while autoDeployEnabled[deployable] and token == deployTokens[deployable] do
			local remotes = ReplicatedStorage:FindFirstChild("DeployableSystem_Remotes")
			local place = remotes and remotes:FindFirstChild("Place")
			if place then
				pcall(function()
					place:InvokeServer(deployable, rootPart.Position, { Mode = "QuickFeet" })
				end)
			end
			task.wait(autoDeployDelay)
		end
	end)
end

local function getZombieId(zombie)
	return zombie:GetAttribute("ZombieId") or tonumber(zombie.Name:match("^Zombie_(%d+)"))
end

local function getZombiesInRange()
	local folder = workspace:FindFirstChild("Zombie_ClientVisuals")
	if not folder then return {} end

	local targets = {}
	for _, zombie in ipairs(folder:GetChildren()) do
		if zombie:IsA("Model") then
			local id = getZombieId(zombie)
			local part = zombie:FindFirstChild("HeadHitbox", true) or zombie:FindFirstChild("Head", true) or zombie.PrimaryPart
			if id and part and part:IsA("BasePart") then
				local distance = (rootPart.Position - part.Position).Magnitude
				if distance <= killAuraRange then
					table.insert(targets, { id = id, part = part, distance = distance })
				end
			end
		end
	end
	table.sort(targets, function(a, b) return a.distance < b.distance end)
	return targets
end

local function startKillAura()
	if killAuraConnection then return end
	killAuraConnection = RunService.Heartbeat:Connect(function()
		if not killAuraEnabled or os.clock() - lastFire < fireCooldown or not protocolOk then return end

		local weapon = getEquippedWeapon()
		local targets = weapon and getZombiesInRange() or {}
		if #targets == 0 then return end
		lastFire = os.clock()

		local info = weapon:FindFirstChild("Info")
		local clip = info and info:FindFirstChild("Clip")
		local origin = workspace.CurrentCamera.CFrame.Position

		for _, target in ipairs(targets) do
			local direction = target.part.Position - origin
			if direction.Magnitude > 0 then
				clientShotId = clientShotId + 1
				local packet = ZombieProtocol.MakeClientShotPacket({
					weaponId = weapon.Name,
					origin = origin,
					direction = direction.Unit,
					clientShotTime = workspace:GetServerTimeNow() - 0.08,
					clientShotId = clientShotId,
					range = 500,
					candidateZombieId = target.id,
					candidatePart = target.part.Name,
					candidateHitboxName = target.part.Name,
					candidatePosition = target.part.Position,
					highRateWeapon = false,
					clientClip = clip and clip.Value or 0,
					clientAmmoActionId = 0,
				})
				zombieClientEvent:FireServer(packet)
			end
		end
	end)
end

local function stopKillAura()
	if killAuraConnection then killAuraConnection:Disconnect() killAuraConnection = nil end
end

if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function" then
	local old
	old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if os.clock() < bufferCaptureUntil and self == zombieClientEvent and getnamecallmethod() == "FireServer" then
			local caller = type(getcallingscript) == "function" and getcallingscript()
			print("[Zombie Buffer] Caller:", caller and caller.Name or "unknown")
			for index, value in ipairs({ ... }) do print(("  [%d] = %s"):format(index, formatBuffer(value))) end
		end
		return old(self, ...)
	end))
end

local function startFly()
	if flying then return end
	flying = true
	hoverY = rootPart.Position.Y + flyHeight
	humanoid.AutoRotate = false

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	bodyVelocity.Parent = rootPart

	bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
	bodyPosition.P = 10000
	bodyPosition.D = 1500
	bodyPosition.Position = Vector3.new(0, hoverY, 0)
	bodyPosition.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 10000
	bodyGyro.Parent = rootPart
end

local function stopFly()
	if not flying then return end
	flying = false
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	if bodyPosition then bodyPosition:Destroy() bodyPosition = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	hoverY = nil
	humanoid.AutoRotate = true
end

RunService.Heartbeat:Connect(function()
	if not flying or not bodyVelocity or not bodyPosition or not bodyGyro then return end

	local direction = humanoid.MoveDirection
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude > 0 then direction = direction.Unit * flySpeed end
	bodyVelocity.Velocity = direction
	bodyPosition.Position = Vector3.new(0, hoverY, 0)

	local camera = workspace.CurrentCamera
	local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if look.Magnitude > 0 then
		bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + look)
	end
end)

player.Idled:Connect(function()
	if antiAfkEnabled then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end
end)

local function resetAll()
	killAuraEnabled = false
	stopKillAura()
	setAutoWeaponUpgrade(false)
	setAutoHealthUpgrade(false)
	for _, deployable in ipairs(deployables) do setAutoDeploy(deployable, false) end
	stopFly()
	speedEnabled = false
	humanoid.WalkSpeed = normalSpeed
	antiAfkEnabled = false
end

local Window = WindUI:CreateWindow({
	Title = "DEK DEV HUB",
	Author = "Zombie Rush Survivals",
	Folder = "Dek_Dev_Hub_Zombie_Rush",
	Icon = "swords",
	Theme = "Dark",
	Size = UDim2.fromOffset(580, 460),
	Resizable = true,
	OpenButton = {
		Title = "DEK",
		CornerRadius = UDim.new(0, 16),
		StrokeThickness = 2,
		Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#2f9fff")),
		Enabled = true,
		Draggable = true,
		OnlyMobile = false,
		Position = UDim2.new(0, 10, 0, 150),
	},
	Topbar = { Height = 44, ButtonsType = "Mac" },
})

Window:SetToggleKey(Enum.KeyCode.RightControl)

local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

MainTab:Toggle({
	Title = "Fly",
	Default = false,
	Callback = function(value)
		if value then startFly() else stopFly() end
	end,
})

MainTab:Slider({
	Title = "Fly Speed",
	Step = 1,
	Value = { Min = 10, Max = 150, Default = 50 },
	Callback = function(value) flySpeed = value end,
})

CombatTab:Button({
	Title = "Capture Zombie Buffer (10 seconds)",
	Icon = "radio",
	Callback = function()
		bufferCaptureUntil = os.clock() + 10
		WindUI:Notify({ Title = "Zombie Buffer", Content = "ยิงซอมบี้ปกติ 1 ครั้ง แล้วดู Console", Duration = 5 })
	end,
})

CombatTab:Toggle({
	Title = "KillAura",
	Default = false,
	Callback = function(value)
		killAuraEnabled = value
		if value then startKillAura() else stopKillAura() end
	end,
})

CombatTab:Slider({
	Title = "KillAura Range",
	Step = 1,
	Value = { Min = 20, Max = 250, Default = 80 },
	Callback = function(value) killAuraRange = value end,
})

CombatTab:Slider({
	Title = "Fire Rate (seconds)",
	Step = 0.05,
	Value = { Min = 0.1, Max = 2, Default = 0.25 },
	Callback = function(value) fireCooldown = value end,
})

CombatTab:Divider()

CombatTab:Toggle({
	Title = "Auto Upgrade Weapon",
	Default = false,
	Callback = setAutoWeaponUpgrade,
})

CombatTab:Toggle({
	Title = "Auto Upgrade Health",
	Default = false,
	Callback = setAutoHealthUpgrade,
})

CombatTab:Slider({
	Title = "Auto Upgrade Rate (seconds)",
	Step = 0.1,
	Value = { Min = 0.1, Max = 5, Default = 1 },
	Callback = function(value) autoUpgradeDelay = value end,
})

weaponLabel = CombatTab:Paragraph({ Title = "Weapon in Use", Desc = "No weapon equipped" })
updateWeaponLabel()

CombatTab:Divider()
deployables = getDeployables()
for _, deployable in ipairs(deployables) do
	CombatTab:Toggle({
		Title = "Auto Deploy " .. deployable,
		Default = false,
		Callback = function(value) setAutoDeploy(deployable, value) end,
	})
end

CombatTab:Slider({
	Title = "Auto Deploy Rate (seconds)",
	Step = 0.1,
	Value = { Min = 0.1, Max = 10, Default = 1 },
	Callback = function(value) autoDeployDelay = value end,
})

MainTab:Slider({
	Title = "Fly Height",
	Step = 1,
	Value = { Min = 5, Max = 200, Default = 15 },
	Callback = function(value)
		if flying and hoverY then hoverY += value - flyHeight end
		flyHeight = value
	end,
})

MainTab:Divider()

MainTab:Toggle({
	Title = "Speed",
	Default = false,
	Callback = function(value)
		speedEnabled = value
		humanoid.WalkSpeed = value and walkSpeed or normalSpeed
	end,
})

MainTab:Slider({
	Title = "Walk Speed",
	Step = 1,
	Value = { Min = 16, Max = 200, Default = 50 },
	Callback = function(value)
		walkSpeed = value
		if speedEnabled then humanoid.WalkSpeed = walkSpeed end
	end,
})

SettingsTab:Toggle({
	Title = "Anti AFK",
	Default = false,
	Callback = function(value) antiAfkEnabled = value end,
})

SettingsTab:Button({
	Title = "Boost FPS",
	Icon = "zap",
	Color = Color3.fromHex("#30FF6A"),
	Callback = function()
		_G.Settings = {
			Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true },
			Meshes = { NoMesh = false, NoTexture = false, Destroy = false },
			Images = { Invisible = true, Destroy = false },
			Explosions = { Smaller = true, Invisible = false, Destroy = false },
			Particles = { Invisible = true, Destroy = false },
			TextLabels = { LowerQuality = true, Invisible = false, Destroy = false },
			MeshParts = { LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false },
			Other = { ["FPS Cap"] = 360, ["No Camera Effects"] = true, ["No Clothes"] = true, ["Low Water Graphics"] = true, ["No Shadows"] = true, ["Low Rendering"] = true, ["Low Quality Parts"] = true, ["Low Quality Models"] = true, ["Reset Materials"] = true },
		}
		loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
	end,
})

SettingsTab:Button({
	Title = "Stop All & Close UI",
	Icon = "circle-x",
	Color = Color3.fromHex("#ff4830"),
	Callback = function()
		resetAll()
		Window:Destroy()
	end,
})

player.CharacterAdded:Connect(function(newCharacter)
	resetAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed = humanoid.WalkSpeed
	shownWeaponName = nil
	watchWeapon()
	updateWeaponLabel()
end)
