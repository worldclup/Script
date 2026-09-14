local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local zombieField = workspace:WaitForChild("ZombieField")
local remotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local buyUpgrade = remotes:WaitForChild("BuyUpgrade")
local eggTake = remotes:WaitForChild("EggTake")
local abilityCast = remotes:WaitForChild("AbilityCast")

local autoClickEnabled, autoEggEnabled, useEggRemote = false, false, false
local clickRange, clickDelay, lastClick = 100, 0.15, 0
local eggDelay, lastEgg, eggIds, eggScanRunning = 0.75, 0, {}, false
local autoSkills, createdSkillToggles, skillDelay, lastSkill = {}, {}, 1, 0
local autoUpgradeDamage, autoUpgradeHp, upgradeDelay = false, false, 1
local autoUpgradeWeapon = false
local autoCollectDrops = false
local collectingPickup = false
local upgradeTokens = { damage = 0, maxHp = 0 }
local speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled = false, false, false, false
local walkSpeed, jumpPower, flySpeed, flyHeight = 50, 100, 50, 15
local normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
local flyVelocity, flyGyro, flyPosition, flyConnection, hoverY

local function getTargetPart(model)
	return model:FindFirstChild("Head", true) or model:FindFirstChild("HumanoidRootPart", true) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
end

local function clickZombie(part)
	local point, visible = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
	if not visible then return false end
	VirtualInputManager:SendMouseMoveEvent(point.X, point.Y, game)
	VirtualInputManager:SendMouseButtonEvent(point.X, point.Y, 0, true, game, 0)
	task.wait(0.03)
	VirtualInputManager:SendMouseButtonEvent(point.X, point.Y, 0, false, game, 0)
	return true
end

local function getEggPart(item)
	if item:IsA("BasePart") then return item end
	if item:IsA("Model") then return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true) end
end

local function collectEgg(part)
	rootPart.CFrame = part.CFrame * CFrame.new(0, 3, 0)
	task.wait(0.15)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
end

local function getAbilityNames()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local hud = gui and gui:FindFirstChild("ZAArenaHud")
	local leftRoot = hud and hud:FindFirstChild("Root") and hud.Root:FindFirstChild("LeftRoot")
	local abilities = leftRoot and leftRoot:FindFirstChild("RightGroup") and leftRoot.RightGroup:FindFirstChild("Abilities")
	local names = {}
	for _, item in ipairs(abilities and abilities:GetChildren() or {}) do
		if not item.Name:match("^UI") then table.insert(names, item.Name) end
	end
	return names
end

local function scanEggIds()
	if eggScanRunning or type(getgc) ~= "function" then return end
	eggScanRunning = true
	task.spawn(function()
		local eggFolder = workspace:FindFirstChild("ZABrainrotEggs")
		local eggs = {}
		for _, egg in ipairs(eggFolder and eggFolder:GetChildren() or {}) do eggs[egg] = true end
		for index, data in ipairs(getgc(true)) do
			if type(data) == "table" then
				for key, value in pairs(data) do
					if type(key) == "number" and eggs[value] and not eggIds[value] then eggIds[value] = key; print("[Egg ID]", key, value.Name) end
					if eggs[key] and type(value) == "number" and not eggIds[key] then eggIds[key] = value; print("[Egg ID]", value, key.Name) end
				end
			end
			if index % 50 == 0 then task.wait() end
		end
		eggScanRunning = false
	end)
end

local function setAutoUpgrade(kind, enabled)
	if kind == "damage" then autoUpgradeDamage = enabled else autoUpgradeHp = enabled end
	upgradeTokens[kind] = upgradeTokens[kind] + 1
	if not enabled then return end
	local token = upgradeTokens[kind]
	task.spawn(function()
		while token == upgradeTokens[kind] and (kind == "damage" and autoUpgradeDamage or autoUpgradeHp) do
			pcall(function() buyUpgrade:FireServer(kind) end)
			task.wait(upgradeDelay)
		end
	end)
end

local function setFly(enabled)
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end
	if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
	if flyGyro then flyGyro:Destroy() flyGyro = nil end
	if flyPosition then flyPosition:Destroy() flyPosition = nil end
	if not enabled then return end
	hoverY = rootPart.Position.Y + flyHeight
	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce, flyVelocity.Parent = Vector3.new(1e5, 1e5, 1e5), rootPart
	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque, flyGyro.P, flyGyro.Parent = Vector3.new(1e5, 1e5, 1e5), 1e4, rootPart
	flyPosition = Instance.new("BodyPosition")
	flyPosition.MaxForce, flyPosition.P, flyPosition.Parent = Vector3.new(0, 1e5, 0), 1e4, rootPart
	flyConnection = RunService.RenderStepped:Connect(function()
		if not rootPart.Parent then return end
		local move = humanoid.MoveDirection
		flyVelocity.Velocity = Vector3.new(move.X, 0, move.Z) * flySpeed
		flyPosition.Position = Vector3.new(0, hoverY, 0)
		flyGyro.CFrame = workspace.CurrentCamera.CFrame
	end)
end

RunService.Heartbeat:Connect(function()
	if speedEnabled then humanoid.WalkSpeed = walkSpeed end
	if jumpEnabled then humanoid.UseJumpPower = true; humanoid.JumpPower = jumpPower end
end)

player.Idled:Connect(function()
	if antiAfkEnabled then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

task.spawn(function()
	while true do
		if autoClickEnabled and os.clock() - lastClick >= clickDelay then
			for _, model in ipairs(zombieField:GetChildren()) do
				local part = model:IsA("Model") and getTargetPart(model)
				if part and (part.Position - rootPart.Position).Magnitude <= clickRange and clickZombie(part) then lastClick = os.clock(); break end
			end
		end
		task.wait(0.03)
	end
end)

task.spawn(function()
	while true do
		if os.clock() - lastSkill >= skillDelay then
			for _, abilityName in ipairs(getAbilityNames()) do if autoSkills[abilityName] then abilityCast:FireServer(abilityName) end end
			lastSkill = os.clock()
		end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while true do
		if autoEggEnabled and not collectingPickup and os.clock() - lastEgg >= eggDelay then
			local eggs = workspace:FindFirstChild("ZABrainrotEggs")
			local egg = eggs and eggs:GetChildren()[1]
			local part = egg and getEggPart(egg)
			if part then
				collectingPickup = true
				local ok, err = pcall(function()
					if useEggRemote and eggIds[egg] then eggTake:FireServer(eggIds[egg]) else collectEgg(part) end
				end)
				collectingPickup = false
				if not ok then warn("[Auto Collect Eggs]", err) end
				lastEgg = os.clock()
			end
		end
		task.wait(0.1)
	end
end)

local function resetAll()
	autoCollectDrops = false
	autoUpgradeWeapon = false
	autoClickEnabled, autoEggEnabled, useEggRemote, speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled = false, false, false, false, false, false, false
	for abilityName in pairs(autoSkills) do autoSkills[abilityName] = false end
	setAutoUpgrade("damage", false)
	setAutoUpgrade("maxHp", false)
	humanoid.WalkSpeed = normalSpeed
	humanoid.UseJumpPower, humanoid.JumpPower = normalUseJumpPower, normalJumpPower
	setFly(false)
end

local Window = Rayfield:CreateWindow({
	name = "DEK DEV HUB", subtitle = "Endless Zombie",
	sidebarLayout = true, theme = "default", showName = "DEK", showIconOnly = true,
})
local Tabs = {
	Main = Window:CreateTab({ name = "Main" }),
	Combat = Window:CreateTab({ name = "Combat" }),
	Farm = Window:CreateTab({ name = "Farm" }),
	Settings = Window:CreateTab({ name = "Settings" }),
}

Tabs.Combat:CreateToggle({ name = "Auto Click Zombie", flag = "AutoClickZombie", value = false, description = "คลิก Zombie บนจอผ่าน input ปกติของเกม", callback = function(value) autoClickEnabled = value end })
Tabs.Combat:CreateSlider({ name = "Click Range", flag = "ClickRange", value = 100, range = { 20, 300 }, increment = 1, callback = function(value) clickRange = value end })
Tabs.Combat:CreateSlider({ name = "Click Delay (seconds)", flag = "ClickDelay", value = 0.15, range = { 0.05, 2 }, increment = 0.01, callback = function(value) clickDelay = value end })
Tabs.Combat:CreateSection({ name = "Skills" })
local abilityLabel = Tabs.Combat:CreateText({ name = "Detected Skills", text = "Scanning..." })
local skillGroup = Tabs.Combat:CreateGroup({ direction = "column" })
local function addSkillToggles()
	for _, abilityName in ipairs(getAbilityNames()) do
		if not createdSkillToggles[abilityName] then
			createdSkillToggles[abilityName], autoSkills[abilityName] = true, false
			skillGroup:CreateToggle({ name = "Auto Skill: " .. abilityName, flag = "AutoSkill_" .. abilityName, value = false, callback = function(value) autoSkills[abilityName] = value end })
		end
	end
end
addSkillToggles()
Tabs.Combat:CreateButton({ name = "Refresh Skill List", callback = addSkillToggles })
Tabs.Combat:CreateSlider({ name = "Skill Delay (seconds)", flag = "SkillDelay", value = 1, range = { 0.1, 10 }, increment = 0.1, callback = function(value) skillDelay = value end })
Tabs.Combat:CreateSection({ name = "Upgrades" })
Tabs.Combat:CreateToggle({ name = "Auto Upgrade Weapon", flag = "AutoUpgradeWeapon", value = false, description = "อ่านอาวุธถัดไปจาก HUD และปลดล็อกทุก 1 วินาที", callback = function(value) autoUpgradeWeapon = value end })
Tabs.Combat:CreateToggle({ name = "Auto Upgrade Damage", flag = "AutoUpgradeDamage", value = false, callback = function(value) setAutoUpgrade("damage", value) end })
Tabs.Combat:CreateToggle({ name = "Auto Upgrade Max HP", flag = "AutoUpgradeHp", value = false, callback = function(value) setAutoUpgrade("maxHp", value) end })
Tabs.Combat:CreateSlider({ name = "Upgrade Delay (seconds)", flag = "UpgradeDelay", value = 1, range = { 0.1, 5 }, increment = 0.1, callback = function(value) upgradeDelay = value end })

Tabs.Main:CreateSection({ name = "Speed" })
Tabs.Main:CreateToggle({ name = "Speed", flag = "Speed", value = false, callback = function(value) speedEnabled = value; humanoid.WalkSpeed = value and walkSpeed or normalSpeed end })
Tabs.Main:CreateSlider({ name = "Walk Speed", flag = "WalkSpeed", value = 50, range = { 16, 200 }, increment = 1, callback = function(value) walkSpeed = value end })
Tabs.Main:CreateSection({ name = "Jump" })
Tabs.Main:CreateToggle({ name = "High Jump", flag = "HighJump", value = false, callback = function(value) jumpEnabled = value; humanoid.UseJumpPower = value and true or normalUseJumpPower; humanoid.JumpPower = value and jumpPower or normalJumpPower end })
Tabs.Main:CreateSlider({ name = "Jump Power", flag = "JumpPower", value = 100, range = { 50, 300 }, increment = 1, callback = function(value) jumpPower = value end })
Tabs.Main:CreateSection({ name = "Fly" })
Tabs.Main:CreateToggle({ name = "Fly", flag = "Fly", value = false, callback = function(value) flyEnabled = value; setFly(value) end })
Tabs.Main:CreateSlider({ name = "Fly Speed", flag = "FlySpeed", value = 50, range = { 10, 200 }, increment = 1, callback = function(value) flySpeed = value end })
Tabs.Main:CreateSlider({ name = "Fly Height", flag = "FlyHeight", value = 15, range = { 5, 200 }, increment = 1, callback = function(value) if flyEnabled and hoverY then hoverY = hoverY + value - flyHeight end; flyHeight = value end })

Tabs.Farm:CreateSection({ name = "Drops" })
Tabs.Farm:CreateToggle({ name = "Auto Collect Drops", flag = "AutoCollectDrops", value = false, description = "วาร์ปเก็บของใน ZARunDrops สลับกับการเก็บไข่ได้", callback = function(value) autoCollectDrops = value end })
Tabs.Farm:CreateSection({ name = "Eggs" })
Tabs.Farm:CreateToggle({ name = "Auto Collect Eggs", flag = "AutoCollectEggs", value = false, callback = function(value) autoEggEnabled = value end })
Tabs.Farm:CreateButton({ name = "Scan Egg IDs", callback = scanEggIds })
Tabs.Farm:CreateToggle({ name = "Use EggTake ID", flag = "UseEggTakeId", value = false, callback = function(value) useEggRemote = value end })
Tabs.Farm:CreateSlider({ name = "Egg Collect Delay (seconds)", flag = "EggDelay", value = 0.75, range = { 0.2, 5 }, increment = 0.01, callback = function(value) eggDelay = value end })

Tabs.Settings:CreateToggle({ name = "Anti AFK", flag = "AntiAfk", value = false, callback = function(value) antiAfkEnabled = value end })
Tabs.Settings:CreateButton({ name = "Boost FPS",
	callback = function()
		_G.Settings = { Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true }, Meshes = { NoMesh = false, NoTexture = false, Destroy = false }, Images = { Invisible = true, Destroy = false }, Explosions = { Smaller = true, Invisible = false, Destroy = false }, Particles = { Invisible = true, Destroy = false }, TextLabels = { LowerQuality = true, Invisible = false, Destroy = false }, MeshParts = { LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false }, Other = { ["FPS Cap"] = 360, ["No Camera Effects"] = true, ["No Clothes"] = true, ["Low Water Graphics"] = true, ["No Shadows"] = true, ["Low Rendering"] = true, ["Low Quality Parts"] = true, ["Low Quality Models"] = true, ["Reset Materials"] = true } }
		loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
	end,
})
Tabs.Settings:CreateButton({ name = "Stop All & Close UI", callback = function() resetAll(); Window:Unload() end })

task.spawn(function()
	while not Window.unloaded do
		local names = getAbilityNames()
		abilityLabel:Set(#names > 0 and table.concat(names, ", ") or "No skills detected")
		addSkillToggles()
		task.wait(1)
	end
end)

Tabs.Main:Select()

task.spawn(function()
	while not Window.unloaded do
		local drops = workspace:FindFirstChild("ZARunDrops")
		if autoCollectDrops and not collectingPickup and drops then
			for _, drop in ipairs(drops:GetChildren()) do
				if Window.unloaded or not autoCollectDrops or collectingPickup then break end
				local part = getEggPart(drop)
				if part and part:IsDescendantOf(drops) and rootPart.Parent and humanoid.Health > 0 then
					collectingPickup = true
					local ok, err = pcall(function()
						local position = part.Position + Vector3.new(0, 1, 0)
						if flyEnabled then hoverY = position.Y end
						rootPart.CFrame = CFrame.new(position) * rootPart.CFrame.Rotation
						task.wait(0.5)
					end)
					collectingPickup = false
					if not ok then warn("[Auto Collect Drops]", err) end
					break
				end
			end
		end
		task.wait(0.5)
	end
end)

task.spawn(function()
	while not Window.unloaded do
		if autoUpgradeWeapon then
			local slot = player:FindFirstChildOfClass("PlayerGui")
			for _, name in ipairs({ "ZAArenaHud", "Root", "LeftRoot", "TopGroup", "Upgrades", "Stack", "NextSlot" }) do
				slot = slot and slot:FindFirstChild(name)
			end
			local foot = slot and slot:FindFirstChild("Foot")
			local price = slot and slot:FindFirstChild("Price")
			local function isText(item)
				return item and (item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox"))
			end
			if isText(foot) and isText(price) and price.Text:match("%S") then
				local weapon = foot.Text:match("^%s*(.-)%s*$"):lower()
				local unlockSlot = remotes:FindFirstChild("UnlockSlot")
				if weapon ~= "" and unlockSlot and unlockSlot:IsA("RemoteEvent") then
					unlockSlot:FireServer(weapon)
				end
			end
		end
		task.wait(1)
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	resetAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
end)
