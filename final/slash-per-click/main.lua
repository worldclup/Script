local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local speedEnabled, antiAfkEnabled = false, false
local walkSpeed = 100
local normalSpeed = humanoid.WalkSpeed

RunService.Heartbeat:Connect(function()
	if speedEnabled then humanoid.WalkSpeed = walkSpeed end
end)

player.Idled:Connect(function()
	if antiAfkEnabled then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- ===== Remote ของเกม =====
local function autoWinRemote()
	local folder = ReplicatedStorage:FindFirstChild("PunchEscapeRemotes")
	return folder and folder:FindFirstChild("AutoWinRequest") or nil
end

local autoWin, autoCollect, autoPunch = false, false, false
local punchRate = 20
local collectStatus

-- แยกการ "ยิง remote" ออกจาก "สถานะที่ผู้ใช้ตั้งไว้" เพราะตอนเก็บดาบต้องปิดชั่วคราวแล้วเปิดคืน
local function sendAutoWin(on)
	local remote = autoWinRemote()
	if not remote then return false, "ไม่พบ PunchEscapeRemotes.AutoWinRequest" end
	local ok, err = pcall(function() remote:FireServer(on) end)
	return ok, err
end

-- ===== Auto Click (Punch) =====
-- PunchRequest รับ Vector3 หนึ่งตัว = ตำแหน่งที่ต่อย ส่งตำแหน่งตัวเราไปตรง ๆ
local function punchRemote()
	local folder = ReplicatedStorage:FindFirstChild("PunchEscapeRemotes")
	return folder and folder:FindFirstChild("PunchRequest") or nil
end

local function sendPunch()
	local remote = punchRemote()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not remote then return false, "ไม่พบ PunchEscapeRemotes.PunchRequest" end
	if not root then return false, "ไม่พบ HumanoidRootPart" end
	local ok, err = pcall(function() remote:FireServer(root.Position) end)
	return ok, err
end

task.spawn(function()
	while true do
		if autoPunch then
			sendPunch()
			task.wait(1 / math.max(punchRate, 1))
		else
			task.wait(0.2)
		end
	end
end)

-- ===== Auto Collect Sword Drop =====
local holdTime, collectTimeout, maxRetries = 2, 20, 3
local dropFolderName = "ActiveSwordDrop"
local lastSpotKey, spotFails = nil, 0

local function dropFolder()
	return workspace:FindFirstChild(dropFolderName)
end

local function positionOf(item)
	if not item then return nil end
	if item:IsA("BasePart") then return item.Position end
	if item:IsA("Model") then
		local ok, cf = pcall(item.GetPivot, item)
		if ok and cf then return cf.Position end
		local part = item:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position
	end
	return nil
end

-- ในโฟลเดอร์มีได้ทั้ง FallenSword และ Crater; Crater โผล่ทีหลัง จึงเล็ง Crater ก่อนถ้ามี
local function dropTarget()
	local folder = dropFolder()
	if not folder then return nil end
	local crater = folder:FindFirstChild("Crater")
	if crater then return positionOf(crater), "Crater" end
	for _, item in ipairs(folder:GetChildren()) do
		local position = positionOf(item)
		if position then return position, item.Name end
	end
	return nil
end

local function teleportTo(position)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not position then return false end
	root.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
	return true
end

local function holdE(seconds)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		-- ย้ำคีย์ลงทุกรอบ เผื่อตัวรันปล่อยสถานะคีย์ทิ้งระหว่างเฟรม
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.1)
	end
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function collectDrop()
	local wasAutoWin = autoWin
	-- ปิด auto win ด้วย remote ก่อน ไม่งั้นเกมจะดึงเรากลับระหว่างวาร์ป
	if wasAutoWin then
		sendAutoWin(false)
		task.wait(0.3)
	end

	-- วาร์ปสองรอบ: รอบแรกทำให้เกม stream ของในโฟลเดอร์ (Crater มักโผล่หลังเข้าใกล้)
	for round = 1, 2 do
		local position, name = dropTarget()
		if not position then break end
		teleportTo(position)
		collectStatus:Set(("วาร์ปรอบ %d -> %s"):format(round, name))
		task.wait(0.6)
	end

	if dropFolder() then
		collectStatus:Set("ถึงจุดดาบแล้ว — กด E ค้าง " .. holdTime .. " วิ")
		holdE(holdTime)
	end

	-- รอจนโฟลเดอร์หายไป = เก็บเสร็จแล้ว (มี timeout กันค้าง)
	local deadline = os.clock() + collectTimeout
	while dropFolder() and os.clock() < deadline and autoCollect do
		task.wait(0.3)
	end

	-- ยังไม่หาย = เก็บไม่ได้; ถ้าพลาดที่จุดเดิมครบโควตาก็ลบโฟลเดอร์ทิ้งไปเลย
	local folder = dropFolder()
	if folder then
		local position = positionOf(folder:FindFirstChild("Crater")) or positionOf(folder:GetChildren()[1])
		local key = position and ("%d,%d,%d"):format(position.X, position.Y, position.Z) or "?"
		spotFails = (key == lastSpotKey) and spotFails + 1 or 1
		lastSpotKey = key

		if spotFails >= maxRetries then
			pcall(function() folder:Destroy() end)
			lastSpotKey, spotFails = nil, 0
			collectStatus:Set(("เก็บไม่ได้ %d รอบที่จุดเดิม — ลบ %s ทิ้งแล้ว"):format(maxRetries, dropFolderName))
		else
			collectStatus:Set(("เก็บไม่ได้ (%d/%d) ที่จุดเดิม — ลองใหม่"):format(spotFails, maxRetries))
		end
	else
		lastSpotKey, spotFails = nil, 0
	end

	if wasAutoWin then
		sendAutoWin(true)
		if not folder then collectStatus:Set("เก็บเสร็จ — เปิด Auto Win คืนแล้ว") end
	elseif not folder then
		collectStatus:Set("เก็บเสร็จแล้ว")
	end
end

task.spawn(function()
	while true do
		if autoCollect and dropFolder() then
			local ok, err = pcall(collectDrop)
			if not ok then collectStatus:Set("ผิดพลาด: " .. tostring(err)) end
			task.wait(1)
		else
			task.wait(0.5)
		end
	end
end)

-- ===== UI =====
local Window = Rayfield:CreateWindow({
	name = "DEK DEV HUB", subtitle = "+1 Slash Per Click",
	sidebarLayout = true, theme = "default", icon = "rbxassetid://134664151762829", showName = "DEK", showIcon = "rbxassetid://134664151762829", showIconOnly = true,
})
local Tabs = {
	Combat = Window:CreateTab({ name = "Combat" }),
	Farm = Window:CreateTab({ name = "Farm" }),
	Settings = Window:CreateTab({ name = "Settings" }),
}
local CombatTab, FarmTab, SettingsTab = Tabs.Combat, Tabs.Farm, Tabs.Settings

local combatStatus = CombatTab:CreateText({ name = "Combat", text = "เปิด Auto Win แล้วปรับความเร็วได้เลย" })

CombatTab:CreateSection({ name = "Auto Win" })
CombatTab:CreateToggle({ name = "Auto Win", flag = "AutoWin", value = false, callback = function(value)
	autoWin = value
	local ok, err = sendAutoWin(value)
	combatStatus:Set(ok and ("Auto Win: " .. (value and "ON" or "OFF")) or ("ยิง remote ไม่ได้ — " .. tostring(err)))
end })

CombatTab:CreateSection({ name = "Auto Click" })
CombatTab:CreateToggle({ name = "Auto Click (Punch)", flag = "AutoPunch", value = false, description = "ยิง PunchRequest ด้วยตำแหน่งตัวเราเอง ไม่ต้องคลิกจริง", callback = function(value)
	autoPunch = value
	if value then
		local ok, err = sendPunch()
		combatStatus:Set(ok and ("Auto Click: ON (" .. punchRate .. " ครั้ง/วิ)") or ("ต่อยไม่ได้ — " .. tostring(err)))
	else
		combatStatus:Set("Auto Click: OFF")
	end
end })
CombatTab:CreateSlider({ name = "ความถี่ (ครั้ง/วินาที)", flag = "PunchRate", range = { 1, 60 }, increment = 1, value = 20, callback = function(value)
	punchRate = value
	if autoPunch then combatStatus:Set("Auto Click: " .. value .. " ครั้ง/วิ") end
end })

CombatTab:CreateSection({ name = "Speed Run" })
CombatTab:CreateToggle({ name = "Speed Run", flag = "SpeedRun", value = false, callback = function(value)
	speedEnabled = value
	humanoid.WalkSpeed = value and walkSpeed or normalSpeed
	combatStatus:Set("Speed Run: " .. (value and (walkSpeed .. " studs/s") or "OFF"))
end })
CombatTab:CreateSlider({ name = "Speed", flag = "SpeedRunLength", range = { 1, 2000 }, increment = 1, value = 100, callback = function(value)
	walkSpeed = value
	if speedEnabled then humanoid.WalkSpeed = walkSpeed end
end })

collectStatus = FarmTab:CreateText({ name = "Sword Drop", text = "รอ workspace.ActiveSwordDrop โผล่ขึ้นมา" })

FarmTab:CreateToggle({ name = "Auto Collect Sword Drop", flag = "AutoCollectSword", value = false, description = "ปิด Auto Win ชั่วคราว -> วาร์ป 2 รอบ -> กด E ค้าง -> เปิด Auto Win คืน", callback = function(value)
	autoCollect = value
	collectStatus:Set(value and "Auto Collect: ON — รอดาบตก" or "Auto Collect: OFF")
end })
FarmTab:CreateSlider({ name = "กด E ค้างกี่วินาที", flag = "SwordHoldTime", range = { 0.5, 6 }, increment = 0.5, value = 2, callback = function(value) holdTime = value end })
FarmTab:CreateSlider({ name = "รอเก็บนานสุดกี่วินาที", flag = "SwordTimeout", range = { 5, 60 }, increment = 5, value = 20, description = "กันค้างถ้าโฟลเดอร์ไม่หายสักที", callback = function(value) collectTimeout = value end })
FarmTab:CreateSlider({ name = "พลาดกี่รอบถึงลบโฟลเดอร์ทิ้ง", flag = "SwordMaxRetries", range = { 1, 10 }, increment = 1, value = 3, description = "นับเฉพาะตอนพลาดที่จุดเดิมซ้ำ ๆ", callback = function(value) maxRetries = value end })
FarmTab:CreateButton({ name = "ลบ ActiveSwordDrop ทิ้งเดี๋ยวนี้", callback = function()
	local folder = dropFolder()
	if not folder then collectStatus:Set("ไม่มีโฟลเดอร์ให้ลบ"); return end
	pcall(function() folder:Destroy() end)
	lastSpotKey, spotFails = nil, 0
	collectStatus:Set("ลบ " .. dropFolderName .. " แล้ว")
end })
FarmTab:CreateButton({ name = "เก็บดาบเดี๋ยวนี้ (ทดสอบ)", callback = function()
	if not dropFolder() then collectStatus:Set("ยังไม่มี ActiveSwordDrop ใน workspace"); return end
	task.spawn(function()
		local ok, err = pcall(collectDrop)
		if not ok then collectStatus:Set("ผิดพลาด: " .. tostring(err)) end
	end)
end })
FarmTab:CreateButton({ name = "เช็คว่ามีดาบตกอยู่ไหม", callback = function()
	local folder = dropFolder()
	if not folder then collectStatus:Set("ยังไม่มี ActiveSwordDrop"); return end
	local names = {}
	for _, item in ipairs(folder:GetChildren()) do names[#names + 1] = item.Name end
	local position, target = dropTarget()
	collectStatus:Set(("ในโฟลเดอร์: %s\nเป้าหมาย: %s%s"):format(
		table.concat(names, ", "),
		tostring(target),
		position and (" ที่ %.0f, %.0f, %.0f"):format(position.X, position.Y, position.Z) or ""))
end })

SettingsTab:CreateToggle({ name = "Anti AFK", flag = "AntiAfk", value = false, callback = function(value) antiAfkEnabled = value end })
SettingsTab:CreateButton({
	name = "Boost FPS",
	callback = function()
		_G.Settings = { Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true }, Meshes = { NoMesh = false, NoTexture = false, Destroy = false }, Images = { Invisible = true, Destroy = false }, Explosions = { Smaller = true, Invisible = false, Destroy = false }, Particles = { Invisible = true, Destroy = false }, TextLabels = { LowerQuality = true, Invisible = false, Destroy = false }, MeshParts = { LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false }, Other = { ["FPS Cap"] = 360, ["No Camera Effects"] = true, ["No Clothes"] = true, ["Low Water Graphics"] = true, ["No Shadows"] = true, ["Low Rendering"] = true, ["Low Quality Parts"] = true, ["Low Quality Models"] = true, ["Reset Materials"] = true } }
		loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
	end,
})
SettingsTab:CreateButton({
	name = "Stop All & Close UI",
	callback = function()
		autoCollect, autoPunch, speedEnabled, antiAfkEnabled = false, false, false, false
		if autoWin then sendAutoWin(false) end
		autoWin = false
		humanoid.WalkSpeed = normalSpeed
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		Window:Unload()
	end,
})

Tabs.Combat:Select()

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed = humanoid.WalkSpeed
end)
