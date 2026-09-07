-- 1. Loading Screen
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
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

local speedEnabled = false
local walkSpeed = 50
local normalSpeed = humanoid.WalkSpeed
local antiAfkEnabled = false
local killAuraEnabled = false
local killAuraRange = 80
local fireCooldown = 0.25
local lastFire = 0
local attackId = 0
local weaponId = 300004
local killAuraConnection
local autoPickCardEnabled = false
local lastCardPick = 0
local skillKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three }
local autoSkills = { [Enum.KeyCode.One] = false, [Enum.KeyCode.Two] = false, [Enum.KeyCode.Three] = false }
local autoSkillDelay = 1
local lastSkillUse = {}

local remoteSpyEnabled = false
local remoteSpyCombatOnly = false
local captureUntil = 0
local captureCount = 0

local function isCombatRemote(remote)
	local name = remote.Name:lower()
	for _, keyword in ipairs({ "damage", "hit", "attack", "combat", "weapon", "gun", "zombie", "enemy", "mob" }) do
		if name:find(keyword, 1, true) then return true end
	end
	return false
end

local function formatRemoteArg(value, depth)
	depth = depth or 0
	if typeof(value) == "buffer" then
		local bytes = {}
		for index = 0, math.min(buffer.len(value), 24) - 1 do
			table.insert(bytes, string.format("%02X", buffer.readu8(value, index)))
		end
		return ("buffer (%d bytes): %s"):format(buffer.len(value), table.concat(bytes, " "))
	end
	if typeof(value) == "table" then
		if depth >= 3 then return "{...}" end
		local items = {}
		for key, item in pairs(value) do
			table.insert(items, ("[%s] = %s"):format(formatRemoteArg(key, depth + 1), formatRemoteArg(item, depth + 1)))
			if #items == (depth == 1 and 3 or 20) then break end
		end
		return "{ " .. table.concat(items, ", ") .. " }"
	end
	return tostring(value)
end

if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function" then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local args = { ... }
		if typeof(self) == "Instance" and self.Name == "WeaponInput" and type(args[1]) == "table" then
			weaponId = args[1].weaponId or weaponId
			attackId = math.max(attackId, args[1].clientAttackId or 0)
		end
		local capturing = os.clock() < captureUntil and captureCount < 20
		if (remoteSpyEnabled or capturing)
			and (method == "FireServer" or method == "InvokeServer")
			and typeof(self) == "Instance"
			and (self.ClassName == "RemoteEvent" or self.ClassName == "RemoteFunction")
			and (capturing or not remoteSpyCombatOnly or isCombatRemote(self)) then

			if capturing then
				captureCount = captureCount + 1
				local caller = type(getcallingscript) == "function" and getcallingscript()
				print("[Damage Capture]", captureCount, method, self.Name, "Caller:", caller and caller.Name or "unknown")
			else
				print("[RemoteSpy]", method, self.Name)
			end
			for index, value in ipairs(args) do
				print(("  [%d] = %s"):format(index, formatRemoteArg(value)))
			end
		end
		return oldNamecall(self, ...)
	end))
end

local function getRemote(name)
	return ReplicatedStorage:FindFirstChild(name, true)
end

local function getNearbyEnemies()
	local result = {}
	local enemies = workspace:FindFirstChild("Entities") and workspace.Entities:FindFirstChild("Enemy")
	if not enemies then return result end

	for _, enemy in ipairs(enemies:GetChildren()) do
		if enemy:IsA("Model") then
			local entityId = enemy:GetAttribute("EntityID")
			local targetPart = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if typeof(entityId) == "number" and targetPart then
				local position = targetPart.Position
				local flatPosition = Vector3.new(position.X, 0, position.Z)
				local distance = (rootPart.Position - flatPosition).Magnitude
				if distance <= killAuraRange then
					table.insert(result, {
						enemy = enemy,
						entityId = entityId,
						targetPart = targetPart,
						position = flatPosition,
						distance = distance,
					})
				end
			end
		end
	end
	return result
end

local function startKillAura()
	if killAuraConnection then return end
	killAuraConnection = RunService.Heartbeat:Connect(function()
		if not killAuraEnabled or os.clock() - lastFire < fireCooldown then return end

		local weaponHit = getRemote("WeaponHit")
		local weaponInput = getRemote("WeaponInput")
		local enemies = getNearbyEnemies()
		if not weaponHit or not weaponInput or #enemies == 0 then return end
		lastFire = os.clock()

		table.sort(enemies, function(a, b) return a.distance < b.distance end)

		local nearbyEntities = {}
		for index, enemy in ipairs(enemies) do
			nearbyEntities[index] = {
				entityId = enemy.entityId,
				distance = enemy.distance,
				position = enemy.position,
			}
		end

		for _, target in ipairs(enemies) do
			attackId = attackId + 1
			local aimPosition = target.targetPart.Position
			weaponHit:FireServer({
				hitPosition = aimPosition,
				weaponId = weaponId,
				entityId = target.entityId,
				clientAttackId = attackId,
				nearbyEntities = nearbyEntities,
				hitType = "entity",
			})
			weaponInput:FireServer({
				op = "attack_request",
				weaponId = weaponId,
				clientTime = workspace.DistributedGameTime,
				clientAttackId = attackId,
				aimPosition = aimPosition,
				attackType = "gun_hitscan",
			})
		end
	end)
end

local function stopKillAura()
	if killAuraConnection then killAuraConnection:Disconnect() killAuraConnection = nil end
end

local function pickCard()
	local screenGui = player.PlayerGui:FindFirstChild("ScreenGui")
	local cardList = screenGui and screenGui:FindFirstChild("Main")
		and screenGui.Main:FindFirstChild("CardRoll")
		and screenGui.Main.CardRoll:FindFirstChild("Content")
		and screenGui.Main.CardRoll.Content:FindFirstChild("Card")
	if not cardList or not cardList.Visible then return end

	local card = cardList:FindFirstChild("Card1")
	local button = card and (card:IsA("GuiButton") and card or card:FindFirstChildWhichIsA("GuiButton", true))
	if button and button.Visible and type(firesignal) == "function" then
		firesignal(button.MouseButton1Click)
	end
end

local function startFly()
	if flying then return end
	flying = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	bodyVelocity.Parent = rootPart
	hoverY = rootPart.Position.Y + flyHeight

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
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if bodyPosition then bodyPosition:Destroy() bodyPosition = nil end
	hoverY = nil
end

RunService.Heartbeat:Connect(function()
	if not flying or not bodyVelocity or not bodyGyro or not bodyPosition then return end

	local camera = workspace.CurrentCamera
	local direction = humanoid.MoveDirection
	direction = Vector3.new(direction.X, 0, direction.Z)
	direction = direction.Magnitude > 0 and direction.Unit * flySpeed or Vector3.zero
	bodyVelocity.Velocity = direction
	bodyPosition.Position = Vector3.new(0, hoverY, 0)

	local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if look.Magnitude > 0 then
		bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + look)
	end
end)

RunService.Heartbeat:Connect(function()
	if autoPickCardEnabled and os.clock() - lastCardPick >= 1 then
		lastCardPick = os.clock()
		pickCard()
	end
end)

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for keyCode, enabled in pairs(autoSkills) do
		if enabled and now - (lastSkillUse[keyCode] or 0) >= autoSkillDelay then
			lastSkillUse[keyCode] = now
			VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
			VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
		end
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
	autoPickCardEnabled = false
	for _, keyCode in ipairs(skillKeys) do autoSkills[keyCode] = false end
	stopFly()
	speedEnabled = false
	humanoid.WalkSpeed = normalSpeed
	antiAfkEnabled = false
end

local Window = WindUI:CreateWindow({
	Title = "DEK DEV HUB",
	Author = "Zombie Island",
	Folder = "Dek_Dev_Hub_Zombie_Island",
	Icon = "swords",
	NewElements = true,
	Theme = "Dark",
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

CombatTab:Toggle({
	Title = "Auto Pick Card (Card 1)",
	Default = false,
	Callback = function(value) autoPickCardEnabled = value end,
})

CombatTab:Divider()
for index, keyCode in ipairs(skillKeys) do
	CombatTab:Toggle({
		Title = "Auto Skill " .. index,
		Default = false,
		Callback = function(value) autoSkills[keyCode] = value end,
	})
end

CombatTab:Slider({
	Title = "Auto Skill Rate (seconds)",
	Step = 0.1,
	Value = { Min = 0.1, Max = 10, Default = 1 },
	Callback = function(value) autoSkillDelay = value end,
})

CombatTab:Slider({
	Title = "Fire Rate (seconds)",
	Step = 0.05,
	Value = { Min = 0.1, Max = 2, Default = 0.25 },
	Callback = function(value) fireCooldown = value end,
})

SettingsTab:Toggle({
	Title = "Anti AFK",
	Default = false,
	Callback = function(value) antiAfkEnabled = value end,
})

SettingsTab:Button({
	Title = "Capture Damage Remote (5 seconds)",
	Icon = "radio",
	Callback = function()
		captureCount = 0
		captureUntil = os.clock() + 5
		WindUI:Notify({ Title = "Damage Capture", Content = "ยิงมอนปกติ 1 ครั้งภายใน 5 วินาที แล้วดู Console", Duration = 5 })
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

SettingsTab:Toggle({
	Title = "Remote Spy",
	Desc = "แสดง Remote ที่เกมส่งใน Console",
	Default = false,
	Callback = function(value)
		remoteSpyEnabled = value
		print("[RemoteSpy]", value and "enabled" or "disabled")
	end,
})

SettingsTab:Toggle({
	Title = "เฉพาะ Combat Remote",
	Desc = "กรองชื่อ Damage, Hit, Attack, Weapon และ Zombie",
	Default = false,
	Callback = function(value)
		remoteSpyCombatOnly = value
	end,
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

player.CharacterAdded:Connect(function(newCharacter)
	resetAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed = humanoid.WalkSpeed
end)
