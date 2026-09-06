local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local flySpeed = 50
local flyHeight = 10
local hoverY
local bodyVelocity
local bodyGyro
local bodyPosition
local keys = { W = false, A = false, S = false, D = false }

local speedEnabled = false
local walkSpeed = 50
local normalSpeed = 16

local killAuraEnabled = false
local killAuraRange = 80
local fireCooldown = 0.1
local lastFire = 0
local killAuraConnection
local weaponLabel
local shownWeaponName

local antiAfkEnabled = false
local normalQualityLevel = settings().Rendering.QualityLevel
local autoWeaponUpgradeEnabled = false
local autoHealthUpgradeEnabled = false
local autoEquipWeaponEnabled = false
local autoUpgradeDelay = 1
local weaponUpgradeToken = 0
local healthUpgradeToken = 0
local autoWaveSkipEnabled = false
local waveSkipToken = 0

local function getGunHit()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local gunRemotes = remotes and remotes:FindFirstChild("GunRemotes")
	return gunRemotes and gunRemotes:FindFirstChild("GunHit")
end

local function getUpgradeRemote(name)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local upgradeRemotes = remotes and remotes:FindFirstChild("UpgradeRemotes")
	return upgradeRemotes and upgradeRemotes:FindFirstChild(name)
end

local function equipWeapon()
	if character:FindFirstChildWhichIsA("Tool") then return end
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

local function setAutoWeaponUpgrade(enabled)
	autoWeaponUpgradeEnabled = enabled
	weaponUpgradeToken = weaponUpgradeToken + 1
	if not enabled then return end

	local token = weaponUpgradeToken
	task.spawn(function()
		while autoWeaponUpgradeEnabled and token == weaponUpgradeToken do
			local remote = getUpgradeRemote("PurchaseWeaponUpgrade")
			if remote then
				remote:FireServer()
				if autoEquipWeaponEnabled then
					task.wait(0.1)
					equipWeapon()
				end
			end
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
			local remote = getUpgradeRemote("PurchaseHealthUpgrade")
			if remote then remote:FireServer() end
			task.wait(autoUpgradeDelay)
		end
	end)
end

local function setAutoWaveSkip(enabled)
	autoWaveSkipEnabled = enabled
	waveSkipToken = waveSkipToken + 1
	if not enabled then return end

	local token = waveSkipToken
	task.spawn(function()
		while autoWaveSkipEnabled and token == waveSkipToken do
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			local waveRemotes = remotes and remotes:FindFirstChild("WaveRemotes")
			local skipVote = waveRemotes and waveRemotes:FindFirstChild("SkipVote")
			if skipVote then skipVote:FireServer() end
			task.wait(1)
		end
	end)
end

local function startFly()
	if flying then return end
	flying = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = rootPart
	hoverY = rootPart.Position.Y + flyHeight

	bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
	bodyPosition.Position = Vector3.new(0, hoverY, 0)
	bodyPosition.P = 10000
	bodyPosition.D = 1500
	bodyPosition.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 10000
	bodyGyro.Parent = rootPart

	humanoid.PlatformStand = true
end

local function stopFly()
	if not flying then return end
	flying = false
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if bodyPosition then bodyPosition:Destroy() bodyPosition = nil end
	hoverY = nil
	humanoid.PlatformStand = false
end

local function getEquippedWeapon()
	return character:FindFirstChildWhichIsA("Tool")
end

local function getZombieId(zombie)
	return tonumber(zombie.Name:match("^Zombie_(%d+)$"))
end

local function updateWeaponLabel()
	local weapon = getEquippedWeapon()
	local name = weapon and weapon.Name or "ไม่พบอาวุธ"
	if weaponLabel and name ~= shownWeaponName then
		shownWeaponName = name
		weaponLabel:SetDesc(name)
	end
end

local function fireAtZombie(zombie)
	local weapon = getEquippedWeapon()
	local humanoidTarget = zombie:FindFirstChildWhichIsA("Humanoid")
	local targetRoot = zombie:FindFirstChild("HumanoidRootPart") or zombie.PrimaryPart
	local id = getZombieId(zombie)
	local gunHit = getGunHit()

	if gunHit and weapon and targetRoot and id and (not humanoidTarget or humanoidTarget.Health > 0) then
		gunHit:FireServer(weapon.Name, id, targetRoot.Position)
	end
end

local function startKillAura()
	if killAuraConnection then return end

	killAuraConnection = RunService.Heartbeat:Connect(function()
		if not killAuraEnabled or not rootPart then return end
		updateWeaponLabel()

		if os.clock() - lastFire < fireCooldown then return end
		lastFire = os.clock()

		local zombiesFolder = workspace:FindFirstChild("Zombies_Local")
		if not zombiesFolder then return end

		for _, zombie in ipairs(zombiesFolder:GetChildren()) do
			local targetRoot = zombie:FindFirstChild("HumanoidRootPart") or zombie.PrimaryPart
			if targetRoot and (rootPart.Position - targetRoot.Position).Magnitude <= killAuraRange then
				fireAtZombie(zombie)
			end
		end
	end)
end

local function stopKillAura()
	if killAuraConnection then
		killAuraConnection:Disconnect()
		killAuraConnection = nil
	end
end

local function resetAll()
	killAuraEnabled = false
	stopKillAura()
	stopFly()
	speedEnabled = false
	humanoid.WalkSpeed = normalSpeed
	antiAfkEnabled = false
	settings().Rendering.QualityLevel = normalQualityLevel
	setAutoWeaponUpgrade(false)
	setAutoHealthUpgrade(false)
	setAutoWaveSkip(false)
	autoEquipWeaponEnabled = false

	for key in pairs(keys) do
		keys[key] = false
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.W then keys.W = true end
	if input.KeyCode == Enum.KeyCode.A then keys.A = true end
	if input.KeyCode == Enum.KeyCode.S then keys.S = true end
	if input.KeyCode == Enum.KeyCode.D then keys.D = true end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then keys.W = false end
	if input.KeyCode == Enum.KeyCode.A then keys.A = false end
	if input.KeyCode == Enum.KeyCode.S then keys.S = false end
	if input.KeyCode == Enum.KeyCode.D then keys.D = false end
end)

player.Idled:Connect(function()
	if antiAfkEnabled then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end
end)

RunService.Heartbeat:Connect(function()
	if not flying or not bodyVelocity or not bodyGyro or not bodyPosition then return end
	local camera = workspace.CurrentCamera
	local direction = Vector3.zero

	if keys.W then direction += camera.CFrame.LookVector end
	if keys.S then direction -= camera.CFrame.LookVector end
	if keys.A then direction -= camera.CFrame.RightVector end
	if keys.D then direction += camera.CFrame.RightVector end

	direction = Vector3.new(direction.X, 0, direction.Z)
	direction = direction.Magnitude > 0 and direction.Unit * flySpeed or Vector3.zero
	bodyVelocity.Velocity = Vector3.new(direction.X, 0, direction.Z)
	bodyPosition.Position = Vector3.new(0, hoverY, 0)

	local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if look.Magnitude > 0 then
		bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + look)
	end
end)

local Window = WindUI:CreateWindow({
	Title = "DEK DEV HUB",
	Folder = "Dek_Dev_Hub_Zombie_Arena",
	Icon = "swords",
	NewElements = true,
	HideSearchBar = false,
	Size = UDim2.fromOffset(580, 460),
	Theme = "Dark",
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
	User = { Enabled = true, Anonymous = false },
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
	Title = "ความเร็วลอย",
	Step = 1,
	Value = { Min = 10, Max = 150, Default = 50 },
	Callback = function(value) flySpeed = value end,
})

MainTab:Slider({
	Title = "ความสูงที่ลอย",
	Step = 1,
	Value = { Min = 3, Max = 100, Default = 10 },
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
	Title = "ความเร็ววิ่ง",
	Step = 1,
	Value = { Min = 16, Max = 200, Default = 50 },
	Callback = function(value)
		walkSpeed = value
		if speedEnabled then humanoid.WalkSpeed = walkSpeed end
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

CombatTab:Toggle({
	Title = "Auto Wave Skip",
	Default = false,
	Callback = setAutoWaveSkip,
})

CombatTab:Slider({
	Title = "ระยะ KillAura",
	Step = 1,
	Value = { Min = 20, Max = 250, Default = 80 },
	Callback = function(value) killAuraRange = value end,
})

CombatTab:Slider({
	Title = "ความเร็วยิง (วินาที)",
	Step = 0.01,
	Value = { Min = 0.05, Max = 0.5, Default = 0.1 },
	Callback = function(value) fireCooldown = value end,
})

CombatTab:Divider()

CombatTab:Toggle({
	Title = "Auto Upgrade Weapon",
	Default = false,
	Callback = setAutoWeaponUpgrade,
})

CombatTab:Toggle({
	Title = "Auto Equip Weapon (1)",
	Desc = "กด 1 หลังอัปเกรดปืน",
	Default = false,
	Callback = function(value) autoEquipWeaponEnabled = value end,
})

CombatTab:Toggle({
	Title = "Auto Upgrade Health",
	Default = false,
	Callback = setAutoHealthUpgrade,
})

CombatTab:Slider({
	Title = "ความเร็ว Auto Upgrade (วินาที)",
	Step = 0.1,
	Value = { Min = 0.1, Max = 5, Default = 1 },
	Callback = function(value) autoUpgradeDelay = value end,
})

CombatTab:Divider()
weaponLabel = CombatTab:Paragraph({ Title = "อาวุธที่ใช้", Desc = "ไม่พบอาวุธ" })
updateWeaponLabel()

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
            Players = {
                ["Ignore Me"] = true,
                ["Ignore Others"] = true,
                ["Ignore Tools"] = true
            },
            Meshes = {NoMesh = false, NoTexture = false, Destroy = false},
            Images = {Invisible = true, Destroy = false},
            Explosions = {
                Smaller = true,
                Invisible = false,
                Destroy = false
            },
            Particles = {Invisible = true, Destroy = false},
            TextLabels = {
                LowerQuality = true,
                Invisible = false,
                Destroy = false
            },
            MeshParts = {
                LowerQuality = true,
                Invisible = false,
                NoTexture = false,
                NoMesh = false,
                Destroy = false
            },
            Other = {
                ["FPS Cap"] = 360,
                ["No Camera Effects"] = true,
                ["No Clothes"] = true,
                ["Low Water Graphics"] = true,
                ["No Shadows"] = true,
                ["Low Rendering"] = true,
                ["Low Quality Parts"] = true,
                ["Low Quality Models"] = true,
                ["Reset Materials"] = true
            }
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
	speedEnabled = false
	killAuraEnabled = false
	humanoid.WalkSpeed = normalSpeed
end)
