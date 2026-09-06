-- 1. Loading Screen
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
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
local camera = workspace.CurrentCamera

-- ======================
-- ตัวแปร
-- ======================
local flying = false
local flySpeed = 50
local flyHeight = 10
local hoverY = nil
local bodyVelocity = nil
local bodyGyro = nil
local bodyPosition = nil

local speedEnabled = false
local walkSpeed = 50
local normalSpeed = 16

local killAuraEnabled = false
local killAuraRange = 80
local killAuraConnection = nil
local fireCooldown = 0.1
local lastFire = 0
local weaponLabel
local shownWeaponName
local antiAfkEnabled = false
local autoUpgradeEnabled = false
local autoUpgradeDelay = 1
local autoUpgradeToken = 0

-- ======================
-- ระบบลอย
-- ======================
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

local keys = { W = false, A = false, S = false, D = false }

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
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

	local cam = workspace.CurrentCamera
	local dir = Vector3.zero

	if keys.W then dir = dir + cam.CFrame.LookVector end
	if keys.S then dir = dir - cam.CFrame.LookVector end
	if keys.A then dir = dir - cam.CFrame.RightVector end
	if keys.D then dir = dir + cam.CFrame.RightVector end

	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude > 0 then
		dir = dir.Unit * flySpeed
	else
		dir = Vector3.zero
	end

	bodyVelocity.Velocity = Vector3.new(dir.X, 0, dir.Z)
	bodyPosition.Position = Vector3.new(0, hoverY, 0)

	local flatLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
	if flatLook.Magnitude > 0 then
		bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + flatLook)
	end
end)

-- ======================
-- KillAura (BufferUtil)
-- ======================
local WeaponEvent = ReplicatedStorage:WaitForChild("Main"):WaitForChild("Remotes"):WaitForChild("WeaponEvent")

-- Tool ที่อยู่ใน Character คืออาวุธที่ผู้เล่นกำลังถือ (equipped)
local function getEquippedWeapon()
	return character:FindFirstChildWhichIsA("Tool")
end

local function updateWeaponLabel()
	local weapon = getEquippedWeapon()
	local name = weapon and weapon.Name or "ไม่พบอาวุธ"
	if weaponLabel and name ~= shownWeaponName then
		shownWeaponName = name
		weaponLabel:SetDesc(name)
	end
end

local function encodeBatchedHits(ids, flags)
	local count = #ids
	local buf = buffer.create(count * 5 + 1)
	buffer.writeu8(buf, 0, count)

	local offset = 1
	for i = 1, count do
		buffer.writeu32(buf, offset, ids[i])
		offset = offset + 4
		buffer.writeu8(buf, offset, flags[i] and 1 or 0)
		offset = offset + 1
	end
	return buf
end

local function encodeFire(origin, directions)
	local count = #directions
	local buf = buffer.create(count * 2 + 7)

	buffer.writei16(buf, 0, math.round(origin.X * 10))
	buffer.writei16(buf, 2, math.round(origin.Y * 10))
	buffer.writei16(buf, 4, math.round(origin.Z * 10))
	buffer.writeu8(buf, 6, count)

	local offset = 7
	for _, dir in ipairs(directions) do
		local yaw = math.atan2(dir.X, dir.Z)
		local pitch = math.asin(math.clamp(dir.Y, -1, 1))

		buffer.writei8(buf, offset, math.round(yaw * 40.42535554534142))
		buffer.writei8(buf, offset + 1, math.round(pitch * 80.85071109068284))
		offset = offset + 2
	end
	return buf
end

local function getNPCsInRange()
	local result = {}
	local folder = workspace:FindFirstChild("Game")
		and workspace.Game:FindFirstChild("Active")
		and workspace.Game.Active:FindFirstChild("ActiveNPCs")

	if not folder then return result end

	for _, npc in pairs(folder:GetChildren()) do
		local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
		local id = npc:GetAttribute("ID")

		if hrp and typeof(id) == "number" then
			local dist = (rootPart.Position - hrp.Position).Magnitude
			if dist <= killAuraRange then
				table.insert(result, {
					HRP = hrp,
					ID = id
				})
			end
		end
	end
	return result
end

local function fireAtTargets(targets)
	if #targets == 0 then return end

	local weapon = getEquippedWeapon()
	if not weapon then return end

	local ids = {}
	local flags = {}
	local directions = {}
	local origin = camera.CFrame.Position

	for _, data in ipairs(targets) do
		table.insert(ids, data.ID)
		table.insert(flags, true)

		local dir = (data.HRP.Position - origin)
		if dir.Magnitude > 0 then
			table.insert(directions, dir.Unit)
		else
			table.insert(directions, camera.CFrame.LookVector)
		end
	end

	local fireBuf = encodeFire(origin, directions)
	WeaponEvent:FireServer("Fire", fireBuf, weapon.Name)

	local hitBuf = encodeBatchedHits(ids, flags)
	WeaponEvent:FireServer("BatchedHits", hitBuf, weapon.Name)
end

local function startKillAura()
	if killAuraConnection then return end

	killAuraConnection = RunService.Heartbeat:Connect(function()
		if not killAuraEnabled then return end
		if not character or not rootPart then return end
		updateWeaponLabel()

		if tick() - lastFire < fireCooldown then return end
		lastFire = tick()

		local targets = getNPCsInRange()
		if #targets > 0 then
			fireAtTargets(targets)
		end
	end)
end

local function stopKillAura()
	if killAuraConnection then
		killAuraConnection:Disconnect()
		killAuraConnection = nil
	end
end

local function getSafeUpgradeKey()
	local upgrades = player.PlayerGui:FindFirstChild("Hud")
		and player.PlayerGui.Hud:FindFirstChild("Upgrades")
	if not upgrades or not upgrades.Visible then return nil end

	for index, key in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C }) do
		local card = upgrades:FindFirstChild("UpgradeCard_" .. index)
		local price = card and card:FindFirstChild("Price", true)
		if card and card.Visible and price and price:IsA("TextLabel") and price.Text:sub(1, 1) == "$" then
			return key
		end
	end
end

local function setAutoUpgrade(enabled)
	autoUpgradeEnabled = enabled
	autoUpgradeToken = autoUpgradeToken + 1
	if not enabled then return end

	local token = autoUpgradeToken
	task.spawn(function()
		while autoUpgradeEnabled and token == autoUpgradeToken do
			local key = getSafeUpgradeKey()
			if key then
				VirtualInputManager:SendKeyEvent(true, key, false, game)
				VirtualInputManager:SendKeyEvent(false, key, false, game)
			end
			task.wait(autoUpgradeDelay)
		end
	end)
end

local function resetAll()
	killAuraEnabled = false
	stopKillAura()
	stopFly()
	speedEnabled = false
	humanoid.WalkSpeed = normalSpeed
	lastFire = 0
	antiAfkEnabled = false
	setAutoUpgrade(false)

	for key in pairs(keys) do
		keys[key] = false
	end
end

-- ======================
-- UI (WindUI)
-- ======================
local Window = WindUI:CreateWindow({
	Title = "DEK DEV HUB",
	Folder = "Dek_Dev_Hub_v1",
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
	Topbar = {
		Height = 44,
		ButtonsType = "Mac",
	},
	User = {
		Enabled = true,
		Anonymous = false,
	},
})

Window:SetToggleKey(Enum.KeyCode.RightControl)

local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

MainTab:Toggle({
	Title = "เปิดลอย (ลอยค้างอัตโนมัติ)",
	Default = false,
	Callback = function(value)
		if value then
			startFly()
			WindUI:Notify({ Title = "Fly", Content = "เปิดลอยแล้ว", Duration = 3 })
		else
			stopFly()
			WindUI:Notify({ Title = "Fly", Content = "ปิดลอยแล้ว", Duration = 3 })
		end
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
		if flying and hoverY then
			hoverY = hoverY + (value - flyHeight)
		end
		flyHeight = value
	end,
})

MainTab:Divider()

MainTab:Toggle({
	Title = "เปิดวิ่งไว (Speed)",
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
		if value then
			startKillAura()
			WindUI:Notify({ Title = "KillAura", Content = "เปิดแล้ว", Duration = 3 })
		else
			stopKillAura()
			WindUI:Notify({ Title = "KillAura", Content = "ปิดแล้ว", Duration = 3 })
		end
	end,
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
	Title = "Auto Upgrade (เลี่ยง Robux)",
	Default = false,
	Callback = setAutoUpgrade,
})

CombatTab:Slider({
	Title = "ความเร็ว Auto Upgrade (วินาที/รอบ)",
	Step = 0.1,
	Value = { Min = 0.1, Max = 5, Default = 1 },
	Callback = function(value) autoUpgradeDelay = value end,
})

CombatTab:Divider()
weaponLabel = CombatTab:Paragraph({ Title = "อาวุธที่ใช้", Desc = "ไม่พบอาวุธ" })
updateWeaponLabel()

SettingsTab:Toggle({
	Title = "Anti AFK",
	Desc = "ป้องกันการถูกเตะเมื่อไม่ได้ขยับ",
	Default = false,
	Callback = function(value)
		antiAfkEnabled = value
	end,
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
			Other = {
				["FPS Cap"] = 360,
				["No Camera Effects"] = true,
				["No Clothes"] = true,
				["Low Water Graphics"] = true,
				["No Shadows"] = true,
				["Low Rendering"] = true,
				["Low Quality Parts"] = true,
				["Low Quality Models"] = true,
				["Reset Materials"] = true,
			},
		}
		loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
	end,
})

-- ======================
-- รีเซ็ต
-- ======================
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	resetAll()
end)
