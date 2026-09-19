local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled, autoUpgrade, autoCollect = false, false, false, false, false, false
local walkSpeed, jumpPower, flySpeed, flyHeight = 50, 100, 50, 15
local normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
local flyVelocity, flyGyro, flyPosition, flyConnection, hoverY

local function setFly(enabled)
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end
	if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
	if flyGyro then flyGyro:Destroy() flyGyro = nil end
	if flyPosition then flyPosition:Destroy() flyPosition = nil end
	if not enabled then return end

	hoverY = rootPart.Position.Y + flyHeight
	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyVelocity.Parent = rootPart
	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque, flyGyro.P = Vector3.new(1e5, 1e5, 1e5), 1e4
	flyGyro.Parent = rootPart
	flyPosition = Instance.new("BodyPosition")
	flyPosition.MaxForce, flyPosition.P = Vector3.new(0, 1e5, 0), 1e4
	flyPosition.Parent = rootPart
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
	if jumpEnabled then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = jumpPower
	end
end)

player.Idled:Connect(function()
	if antiAfkEnabled then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

local function resetAll()
	speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled, autoUpgrade, autoCollect = false, false, false, false, false, false
	humanoid.WalkSpeed = normalSpeed
	humanoid.UseJumpPower = normalUseJumpPower
	humanoid.JumpPower = normalJumpPower
	setFly(false)
end

local Window = Rayfield:CreateWindow({
	name = "DEK DEV HUB", subtitle = "Ride A Pet",
	sidebarLayout = true, theme = "default", icon = "rbxassetid://134664151762829", showName = "DEK", showIcon = "rbxassetid://134664151762829", showIconOnly = true,
})
local Tabs = {
	Main = Window:CreateTab({ name = "Main" }),
	Pet = Window:CreateTab({ name = "Pet" }),
	Upgrade = Window:CreateTab({ name = "Upgrade" }),
	BuySell = Window:CreateTab({ name = "Buy & Sell" }),
	Inspect = Window:CreateTab({ name = "Inspect / Export" }),
	Settings = Window:CreateTab({ name = "Settings" }),
}
local MainTab, InspectTab, SettingsTab = Tabs.Main, Tabs.Inspect, Tabs.Settings
local UpgradeTab, PetTab, BuyTab = Tabs.Upgrade, Tabs.Pet, Tabs.BuySell

local inspectRoot, inspectDepth, inspectLimit = "Workspace", 5, 3000
local inspectBusy, inspectCancel, inspectClosed = false, false, false
local inspectOutput
local remoteCaptureEnabled = false
local remoteCaptures, remoteQueue = {}, {}
local inspectStatus = InspectTab:CreateText({ name = "Inspector", text = "อ่านข้อมูลฝั่ง client เท่านั้น ไม่เรียก remote หรือดึง Source\nเลือกจุดเริ่มต้นแล้วกด Scan; ตรวจข้อมูลก่อนแชร์ เพราะอาจมีข้อความส่วนตัว" })
local function inspectMessage(message)
	if not inspectClosed then inspectStatus:Set(message) end
end
for _, rootName in ipairs({ "Workspace", "ReplicatedStorage", "PlayerGui", "LocalPlayer" }) do
	InspectTab:CreateButton({ name = "Select: " .. rootName, callback = function()
		inspectRoot = rootName
		inspectMessage("Selected: " .. rootName)
	end })
end
InspectTab:CreateSlider({ name = "Scan Depth", flag = "InspectDepth", range = { 1, 15 }, increment = 1, value = 5, callback = function(value) inspectDepth = value end })
InspectTab:CreateSlider({ name = "Max Items / GC Tables", flag = "InspectLimit", range = { 100, 10000 }, increment = 100, value = 3000, callback = function(value) inspectLimit = value end })
InspectTab:CreateButton({ name = "Scan", callback = function()
	if inspectBusy then return end
	local root = inspectRoot == "LocalPlayer" and player or (inspectRoot == "PlayerGui" and player:FindFirstChildOfClass("PlayerGui") or game:GetService(inspectRoot))
	if not root then inspectMessage("ไม่พบจุดเริ่มต้น"); return end
	inspectBusy, inspectCancel, inspectOutput = true, false, nil
	local depthLimit, itemLimit = inspectDepth, inspectLimit
	task.spawn(function()
		local ok, result = pcall(function()
			local report = { placeId = game.PlaceId, scannedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"), root = root:GetFullName(), maxDepth = depthLimit, maxItems = itemLimit, items = {}, truncated = false, errors = 0 }
			local queue, cursor = { { root, 0, 0 } }, 1
			local function safeString(value)
				local text = tostring(value)
				if utf8.len(text) then return text:sub(1, 1000) end
				return (text:gsub("[\128-\255]", function(byte)
					return ("\\u%04X"):format(string.byte(byte))
				end)):sub(1, 1000)
			end
			local function encodeValue(value)
				local kind = typeof(value)
				if kind == "boolean" then return value end
				if kind == "string" then return safeString(value) end
				if kind == "number" and value == value and math.abs(value) < math.huge then return value end
				return ("[%s] %s"):format(kind, safeString(value))
			end
			while cursor <= #queue and not inspectCancel do
				local entry = queue[cursor]
				local item, depth = entry[1], entry[2]
				local readOk = pcall(function()
					local row = { index = cursor, parentIndex = entry[3], name = safeString(item.Name), class = safeString(item.ClassName), path = safeString(item:GetFullName()), depth = depth, attributes = {} }
					for key, value in pairs(item:GetAttributes()) do row.attributes[safeString(key)] = encodeValue(value) end
					if item:IsA("ValueBase") then row.value = encodeValue(item.Value) end
					if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then row.text = safeString(item.Text) end
					if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") or item:IsA("UnreliableRemoteEvent") then row.remote = true end
					table.insert(report.items, row)
					local children = item:GetChildren()
					if depth < depthLimit then
						for _, child in ipairs(children) do
							if #queue >= itemLimit then report.truncated = true; break end
							table.insert(queue, { child, depth + 1, cursor })
						end
					elseif #children > 0 then report.truncated = true end
				end)
				if not readOk then report.errors = report.errors + 1 end
				cursor = cursor + 1
				if cursor % 25 == 0 then task.wait() end
			end
			report.cancelled = inspectCancel
			return game:GetService("HttpService"):JSONEncode(report)
		end)
		inspectBusy = false
		if ok then
			inspectOutput = result
			inspectMessage("Scan เสร็จ (" .. #result .. " bytes) — พร้อม Export / Copy\n" .. result:sub(1, 700))
		else inspectMessage("Scan failed: " .. tostring(result)) end
	end)
end })
InspectTab:CreateButton({ name = "Scan GC Tables", callback = function()
	if inspectBusy then return end
	if type(getgc) ~= "function" then inspectMessage("ตัวรันนี้ไม่รองรับ getgc"); return end
	inspectBusy, inspectCancel, inspectOutput = true, false, nil
	local tableLimit = inspectLimit
	task.spawn(function()
		local ok, result = pcall(function()
			local report = { placeId = game.PlaceId, scannedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"), source = "getgc(true)", maxTables = tableLimit, tables = {}, truncated = false, errors = 0 }
			local function text(value)
				local result = tostring(value)
				if utf8.len(result) then return result:sub(1, 500) end
				return ("[%s bytes]"):format(#result)
			end
			local function value(key, item)
				local keyText = text(key):lower()
				if keyText:find("token", 1, true) or keyText:find("secret", 1, true) or keyText:find("password", 1, true) or keyText:find("cookie", 1, true) then return "[redacted]" end
				local kind = typeof(item)
				if kind == "boolean" then return item end
				if kind == "number" and item == item and math.abs(item) < math.huge then return item end
				return ("[%s] %s"):format(kind, text(item))
			end
			for gcIndex, object in ipairs(getgc(true)) do
				if inspectCancel then break end
				if type(object) == "table" then
					local fields, count = {}, 0
					local readOk = pcall(function()
						for key, item in pairs(object) do
							count = count + 1
							if #fields < 25 then table.insert(fields, { key = value("", key), value = value(key, item) }) end
							if count % 100 == 0 then task.wait() end
						end
					end)
					if readOk and count > 0 then
						table.insert(report.tables, { gcIndex = gcIndex, size = count, sample = fields })
						if #report.tables >= tableLimit then report.truncated = true; break end
					elseif not readOk then report.errors = report.errors + 1 end
				end
				if gcIndex % 50 == 0 then task.wait() end
			end
			report.cancelled = inspectCancel
			return game:GetService("HttpService"):JSONEncode(report)
		end)
		inspectBusy = false
		if ok then
			inspectOutput = result
			inspectMessage("GC scan เสร็จ (" .. #result .. " bytes) — พร้อม Export / Copy\n" .. result:sub(1, 700))
		else inspectMessage("GC scan failed: " .. tostring(result)) end
	end)
end })
InspectTab:CreateSection({ name = "Remote Capture" })
local remoteStatus = InspectTab:CreateText({ name = "Remote Calls", text = "เปิด Capture แล้วกด action ในเกมด้วยตัวเอง" })
local function captureValue(value)
	local kind = typeof(value)
	if kind == "nil" then return "[nil]" end
	if kind == "boolean" or kind == "string" then return value end
	if kind == "number" and value == value and math.abs(value) < math.huge then return value end
	return ("[%s] %s"):format(kind, tostring(value))
end
InspectTab:CreateToggle({ name = "Capture Remote Calls", flag = "CaptureRemoteCalls", value = false, callback = function(value)
	remoteCaptureEnabled = value
	remoteStatus:Set(value and "กำลังดัก FireServer สูงสุด 25 รายการ" or "หยุดดัก Remote")
end })
InspectTab:CreateButton({ name = "Prepare Remote JSON", callback = function()
	if #remoteCaptures == 0 then inspectMessage("ยังไม่มี Remote ที่ดักได้"); return end
	inspectOutput = game:GetService("HttpService"):JSONEncode({ placeId = game.PlaceId, source = "RemoteEvent FireServer capture", events = remoteCaptures })
	inspectMessage("เตรียม Remote JSON แล้ว — ใช้ Copy JSON หรือ Export JSON File")
end })
InspectTab:CreateButton({ name = "Clear Remote Captures", callback = function()
	table.clear(remoteCaptures)
	table.clear(remoteQueue)
	remoteStatus:Set("ล้างรายการแล้ว")
end })
if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function" then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if remoteCaptureEnabled and #remoteCaptures + #remoteQueue < 25 and getnamecallmethod() == "FireServer" and (type(checkcaller) ~= "function" or not checkcaller()) then
			table.insert(remoteQueue, { remote = self, args = table.pack(...), capturedAt = os.date("!%Y-%m-%dT%H:%M:%SZ") })
		end
		return oldNamecall(self, ...)
	end))
	task.spawn(function()
		while not inspectClosed do
			local event = table.remove(remoteQueue, 1)
			if event then
				local args = {}
				for index = 1, event.args.n do args[index] = captureValue(event.args[index]) end
				local ok, path = pcall(function() return event.remote:GetFullName() end)
				table.insert(remoteCaptures, { remote = ok and path or tostring(event.remote), args = args, capturedAt = event.capturedAt })
				if #remoteCaptures > 25 then table.remove(remoteCaptures, 1) end
				remoteStatus:Set(("Captured: %s\nTotal: %d"):format(ok and path or tostring(event.remote), #remoteCaptures))
				print("[Remote Capture]", ok and path or event.remote, unpack(args))
			else task.wait(0.1) end
		end
	end)
else
	remoteStatus:Set("Capture unavailable: executor ไม่รองรับ hookmetamethod")
end
InspectTab:CreateButton({ name = "Cancel Scan", callback = function() inspectCancel = true end })
InspectTab:CreateButton({ name = "Copy JSON", callback = function()
	if not inspectOutput then inspectMessage("กด Scan ก่อน"); return end
	if type(setclipboard) ~= "function" then inspectMessage("ไม่รองรับ clipboard — ใช้ Export หรือ Print JSON"); return end
	local ok, err = pcall(setclipboard, inspectOutput)
	inspectMessage(ok and "คัดลอก JSON แล้ว ตรวจข้อความก่อนแชร์" or tostring(err))
end })
InspectTab:CreateButton({ name = "Print JSON (Console)", callback = function()
	if not inspectOutput then inspectMessage("กด Scan ก่อน"); return end
	-- Print only on request; chunk and yield to avoid flooding in one frame.
	local output = inspectOutput
	task.spawn(function()
		for offset = 1, #output, 2000 do
			if inspectClosed then break end
			print(output:sub(offset, offset + 1999))
			task.wait()
		end
	end)
end })
InspectTab:CreateButton({ name = "Export JSON File", callback = function()
	if not inspectOutput then inspectMessage("กด Scan ก่อน"); return end
	if type(writefile) ~= "function" or type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		inspectMessage("ไม่รองรับเขียนไฟล์ — ใช้ Copy JSON หรือ Print JSON"); return
	end
	local folder = "GameExports/" .. tostring(game.PlaceId)
	local path = folder .. "/snapshot-" .. os.date("!%Y%m%d-%H%M%S") .. "-" .. game:GetService("HttpService"):GenerateGUID(false) .. ".json"
	local ok, err = pcall(function()
		if not isfolder("GameExports") then makefolder("GameExports") end
		if not isfolder(folder) then makefolder(folder) end
		writefile(path, inspectOutput)
	end)
	inspectMessage(ok and ("Saved: " .. path .. "\nอยู่ใน workspace ของตัวรัน ไม่ใช่โฟลเดอร์ VS Code") or ("Export failed: " .. tostring(err)))
end })

MainTab:CreateSection({ name = "Speed" })
MainTab:CreateToggle({
	name = "Speed", flag = "Speed", value = false,
	callback = function(value)
		speedEnabled = value
		humanoid.WalkSpeed = value and walkSpeed or normalSpeed
	end,
})
MainTab:CreateSlider({ name = "Walk Speed", flag = "WalkSpeed", range = { 16, 1000 }, increment = 1, value = 50, callback = function(value) walkSpeed = value end })
MainTab:CreateSection({ name = "Jump" })
MainTab:CreateToggle({
	name = "High Jump", flag = "HighJump", value = false,
	callback = function(value)
		jumpEnabled = value
		humanoid.UseJumpPower = value and true or normalUseJumpPower
		humanoid.JumpPower = value and jumpPower or normalJumpPower
	end,
})
MainTab:CreateSlider({ name = "Jump Power", flag = "JumpPower", range = { 50, 300 }, increment = 5, value = 100, callback = function(value) jumpPower = value end })
MainTab:CreateSection({ name = "Fly" })
MainTab:CreateToggle({ name = "Fly", flag = "Fly", value = false, callback = function(value) flyEnabled = value; setFly(value) end })
MainTab:CreateSlider({ name = "Fly Speed", flag = "FlySpeed", range = { 10, 200 }, increment = 5, value = 50, callback = function(value) flySpeed = value end })
MainTab:CreateSlider({
	name = "Fly Height", flag = "FlyHeight", range = { 5, 200 }, increment = 1, value = 15,
	callback = function(value)
		if flyEnabled and hoverY then hoverY = hoverY + value - flyHeight end
		flyHeight = value
	end,
})

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
		resetAll()
		remoteCaptureEnabled = false
		autoUpgrade = false
		inspectClosed, inspectCancel = true, true
		Window:Unload()
	end,
})


local upgradeDelay = 1
local upgradeStatus = UpgradeTab:CreateText({ name = "Upgrade Status", text = "Auto Up: OFF" })

local function upgradeMax()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game"):WaitForChild("Plot"):WaitForChild("Upgrades")
	remote:FireServer("Max")
end

UpgradeTab:CreateToggle({
	name = "Auto Up (Max)", flag = "AutoUpgrade", value = false,
	callback = function(value)
		autoUpgrade = value
		upgradeStatus:Set("Auto Up: " .. (value and "ON" or "OFF"))
	end,
})
UpgradeTab:CreateSlider({ name = "Upgrade Delay (วินาที)", flag = "UpgradeDelay", range = { 0.1, 10 }, increment = 0.1, value = 1, callback = function(value) upgradeDelay = value end })
UpgradeTab:CreateButton({ name = "Upgrade Max Once", callback = function()
	local ok, err = pcall(upgradeMax)
	upgradeStatus:Set(ok and "Upgrade Max sent" or "Upgrade failed: " .. tostring(err))
end })

task.spawn(function()
	while true do
		if autoUpgrade then
			local ok, err = pcall(upgradeMax)
			if not ok then upgradeStatus:Set("Upgrade failed: " .. tostring(err)) end
		end
		task.wait(upgradeDelay)
	end
end)

-- อ่านตารางจากเกมโดยตรง ถ้า require ไม่ได้ค่อยใช้ค่าที่ฝังไว้
local function gameData(name)
	local folder = ReplicatedStorage:FindFirstChild("GameData")
	local module = folder and folder:FindFirstChild(name)
	local ok, data = pcall(require, module)
	return ok and type(data) == "table" and data or nil
end

local eggData = gameData("Eggs") or {}
local rarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal" }
local rarityEmoji = { Common = "⚪", Rare = "🔵", Epic = "🟣", Legendary = "🟡", Mythic = "🔴", Divine = "🌟", Ethereal = "💠" }
local selectedRarities = {}

-- ชื่อใน RenderedEggs อาจมีส่วนต่อท้าย จึงเทียบตรงก่อน แล้วค่อยเทียบแบบมีชื่ออยู่ในนั้น
local function eggRarity(eggName)
	local info = eggData[eggName]
	if info then return info.Rarity end
	for name, data in pairs(eggData) do
		if eggName:find(name, 1, true) then return data.Rarity end
	end
end

local function rarityAllowed(eggName)
	if not next(selectedRarities) then return true end
	local rarity = eggRarity(eggName)
	return rarity ~= nil and selectedRarities[rarity] == true
end

local foodData = gameData("Foods") or {
	Grass = { Cost = 10 }, Bone = { Cost = 1500 }, Meat = { Cost = 30000 },
	["Magic Apple"] = { Cost = 700000 }, Dragonfruit = { Cost = 30000000 },
}

local buyStatus = BuyTab:CreateText({ name = "Auto Buy", text = "เปิดชนิดที่อยากให้ซื้ออัตโนมัติ" })

local function setAutobuy(kind, name, enabled)
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game"):WaitForChild("Autobuy"):FireServer(kind, name, enabled)
end

local foodNames = {}
for name in pairs(foodData) do table.insert(foodNames, name) end
table.sort(foodNames, function(a, b) return (foodData[a].Cost or 0) < (foodData[b].Cost or 0) end)

BuyTab:CreateSection({ name = "Food" })
for _, name in ipairs(foodNames) do
	local info = foodData[name]
	BuyTab:CreateToggle({
		name = ("%s (%s)"):format(name, info.Rarity or "?"), flag = "AutoBuyFood_" .. name, value = false,
		callback = function(value)
			local ok, err = pcall(setAutobuy, "Food", name, value)
			buyStatus:Set(ok and ("Autobuy %s: %s"):format(name, value and "ON" or "OFF") or ("ส่งไม่สำเร็จ: " .. tostring(err)))
		end,
	})
end

-- ===== Auto Feed (แท็บ Upgrade) =====
local autoFeed, feedDelay = false, 0.5
local selectedPets, petLabelToKey, petDropdown = {}, {}, nil

-- หา plot ของเราจาก Data.Owner (เป็นชื่อผู้เล่นหรือ ObjectValue ก็ได้)
local function myPlot()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return end
	for _, plot in ipairs(plots:GetChildren()) do
		local data = plot:FindFirstChild("Data")
		local owner = data and data:FindFirstChild("Owner")
		if owner and (owner.Value == player or owner.Value == player.Name or owner.Value == player.UserId) then return plot end
	end
end

local function myPets()
	local plot = myPlot()
	local folder = plot and plot:FindFirstChild("Pets")
	return folder and folder:GetChildren() or {}
end

local function petOptions()
	local options = {}
	table.clear(petLabelToKey)
	for _, pet in ipairs(myPets()) do
		local key = pet:GetAttribute("PetKey")
		if key then
			local label = ("%s - %s"):format(pet:GetAttribute("PetName") or pet.Name, tostring(pet:GetAttribute("Age") or "?"))
			petLabelToKey[label] = key
			table.insert(options, label)
		end
	end
	return options
end

-- ใช้อาหารที่ XP สูงสุดเท่าที่มีในกระเป๋า
local function bestFood()
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end
	local best, bestXP
	for _, item in ipairs(backpack:GetChildren()) do
		local info = foodData[item.Name]
		local data = item:FindFirstChild("Data")
		local amount = data and data:FindFirstChild("Amount")
		if info and amount and (tonumber(amount.Value) or 0) > 0 and (not bestXP or (info.XP or 0) > bestXP) then
			best, bestXP = item.Name, info.XP or 0
		end
	end
	return best
end

UpgradeTab:CreateSection({ name = "Auto Feed" })
local feedStatus = UpgradeTab:CreateText({ name = "Auto Feed", text = "Auto Feed: OFF" })
petDropdown = UpgradeTab:CreateDropdown({ name = "Pets (ไม่เลือก = ทุกตัว)", flag = "FeedPets", options = petOptions(), multiSelect = true, value = {}, callback = function(value)
	table.clear(selectedPets)
	local list = type(value) == "table" and value or { value }
	for _, label in ipairs(list) do
		local key = petLabelToKey[label]
		if key then selectedPets[key] = true end
	end
	feedStatus:Set(#list > 0 and ("เลือก %d ตัว"):format(#list) or "เลือกทุกตัว")
end })
-- อัปเดตรายการ (Age เปลี่ยนตลอด) แล้วเลือกกลับตาม PetKey ที่เคยเลือกไว้
local lastPetSignature = ""
local function refreshPetDropdown(force)
	local options = petOptions()
	local signature = table.concat(options, "|")
	if not force and signature == lastPetSignature then return options end
	lastPetSignature = signature
	pcall(function() petDropdown:Refresh(options) end)
	local chosen = {}
	for label, key in pairs(petLabelToKey) do
		if selectedPets[key] then table.insert(chosen, label) end
	end
	pcall(function() petDropdown:Set(chosen) end)
	return options
end

UpgradeTab:CreateButton({ name = "Refresh Pet List", callback = function()
	feedStatus:Set(("พบ %d ตัวใน plot ของเรา"):format(#refreshPetDropdown(true)))
end })
UpgradeTab:CreateToggle({ name = "Auto Feed", flag = "AutoFeed", value = false, callback = function(value)
	autoFeed = value
	feedStatus:Set("Auto Feed: " .. (value and "ON" or "OFF"))
end })
UpgradeTab:CreateSlider({ name = "Feed Delay (วินาที)", flag = "FeedDelay", range = { 0.1, 10 }, increment = 0.1, value = 0.5, callback = function(value) feedDelay = value end })

task.spawn(function()
	while true do
		pcall(refreshPetDropdown)
		task.wait(3)
	end
end)

-- ป้อนทีละตัวตามลำดับ ตัวไหน Age ถึง 100 ก็ข้ามไปตัวถัดไป
task.spawn(function()
	while true do
		if autoFeed then
			local food = bestFood()
			if not food then
				feedStatus:Set("ไม่มีอาหารในกระเป๋า")
			else
				local target
				for _, pet in ipairs(myPets()) do
					local key = pet:GetAttribute("PetKey")
					local age = tonumber(pet:GetAttribute("Age")) or 0
					if key and age < 100 and (not next(selectedPets) or selectedPets[key]) then target = pet; break end
				end
				if target then
					local ok, err = pcall(function()
						ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game"):WaitForChild("FeedPet"):FireServer(target:GetAttribute("PetKey"), food)
					end)
					feedStatus:Set(ok and ("ป้อน %s ให้ %s (Age %s)"):format(food, target:GetAttribute("PetName") or target.Name, tostring(target:GetAttribute("Age")))
						or ("Feed failed: " .. tostring(err)))
				else
					feedStatus:Set("ตัวที่เลือก Age ครบ 100 หมดแล้ว")
				end
			end
		end
		task.wait(feedDelay)
	end
end)

local eggStatus = PetTab:CreateText({ name = "Egg Distance / Luck", text = "กด Refresh เพื่อหา RenderedEggs" })

local function getPosition(instance)
	if instance:IsA("BasePart") then return instance.Position end
	if instance:IsA("Attachment") then return instance.WorldPosition end
	if instance:IsA("Model") then return instance:GetPivot().Position end
	local part = instance:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position
end

local function refreshEggs()
	local currentCharacter = player.Character
	local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("RenderedEggs")
	if not root then eggStatus:Set("ไม่พบ HumanoidRootPart"); return end
	if not folder then eggStatus:Set("ไม่พบ workspace.RenderedEggs"); return end

	-- นับจำนวนต่อชื่อไข่ และเก็บระยะที่ใกล้ที่สุดของชื่อนั้น แยกตาม rarity
	local groups = {}
	for _, egg in ipairs(folder:GetChildren()) do
		local position = getPosition(egg)
		if position then
			local rarity = eggRarity(egg.Name) or "Unknown"
			local group = groups[rarity] or {}
			groups[rarity] = group
			local entry = group[egg.Name] or { count = 0, distance = math.huge }
			group[egg.Name] = entry
			entry.count = entry.count + 1
			entry.distance = math.min(entry.distance, (root.Position - position).Magnitude)
		end
	end

	local lines = {}
	for _, rarity in ipairs(rarityOrder) do
		local group = groups[rarity]
		if group then
			local names = {}
			for name, entry in pairs(group) do
				entry.name = name
				table.insert(names, entry)
			end
			table.sort(names, function(a, b) return a.distance < b.distance end)
			table.insert(lines, ("%s %s"):format(rarityEmoji[rarity] or "•", rarity:upper()))
			for _, entry in ipairs(names) do
				table.insert(lines, ("- %s x%d"):format(entry.name, entry.count))
			end
		end
	end
	if groups.Unknown then
		table.insert(lines, "❓ UNKNOWN")
		for name, entry in pairs(groups.Unknown) do
			table.insert(lines, ("- %s x%d"):format(name, entry.count))
		end
	end
	eggStatus:Set(#lines > 0 and table.concat(lines, "\n") or "ไม่พบ Egg ที่มีตำแหน่ง")
end

-- refresh เองทุก 2 วินาที
task.spawn(function()
	while true do
		pcall(refreshEggs)
		task.wait(2)
	end
end)

local VirtualInputManager = game:GetService("VirtualInputManager")
local homeCFrame, minimumLuck = nil, 0
local travelSpeed = 400
local noclipStates, noclipConnection, noclipAlways = {}, nil, false
local collectStatus = PetTab:CreateText({ name = "Auto Collect", text = "ตั้งจุดบ้านก่อน แล้วเปิด Auto Collect" })

-- รองรับหน่วยยาวถึง Qi; ตัวที่ไม่รู้จักถือว่าไม่มีหน่วย (คูณ 1)
local luckUnits = { K = 1e3, M = 1e6, B = 1e9, T = 1e12, QA = 1e15, Q = 1e15, QD = 1e18, QI = 1e18, SX = 1e21, SP = 1e24 }

local function luckValue(text)
	local clean = tostring(text):gsub(",", ""):upper()
	local number, suffix = clean:match("([%d%.]+)%s*([A-Z]*)")
	return (tonumber(number) or 0) * (luckUnits[suffix] or 1)
end

local function luckText(value)
	for _, unit in ipairs({ { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if value >= unit[1] then return ("%.2f%s"):format(value / unit[1], unit[2]) end
	end
	return ("%d"):format(value)
end

-- กด CanCollide ลงทุกเฟรม ไม่ใช่ครั้งเดียว: พาร์ทที่เกมเพิ่ม/รีเซ็ตทีหลังก็ยังทะลุ
local function setNoclip(enabled)
	if not enabled and noclipAlways then return end
	if enabled then
		if noclipConnection then return end
		noclipConnection = RunService.Stepped:Connect(function()
			local currentCharacter = player.Character
			if not currentCharacter then return end
			for _, part in ipairs(currentCharacter:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					if noclipStates[part] == nil then noclipStates[part] = true end
					part.CanCollide = false
				end
			end
		end)
	else
		if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
		for part, state in pairs(noclipStates) do
			if part.Parent then pcall(function() part.CanCollide = state end) end
			noclipStates[part] = nil
		end
	end
end

-- ลอยไปด้วย BodyVelocity: ความเร็วลดลงตามระยะที่เหลือ จึงไม่เลยจุด
local function flyTo(root, target, stopRadius, timeout, speed)
	local mover = Instance.new("BodyVelocity")
	mover.MaxForce = Vector3.new(1e7, 1e7, 1e7)
	mover.Velocity = Vector3.zero
	mover.Parent = root
	local deadline = os.clock() + (timeout or 20)
	while autoCollect and root.Parent and os.clock() < deadline do
		local offset = target - root.Position
		if offset.Magnitude <= stopRadius then break end
		speed = speed or travelSpeed
		mover.Velocity = offset.Unit * math.clamp(offset.Magnitude * 6, math.min(20, speed), speed)
		task.wait()
	end
	mover:Destroy()
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return (target - root.Position).Magnitude <= stopRadius
end

-- เส้นทางเดียวกันทั้งไปและกลับ: ลอยขึ้น -> ลอยตรงไปเหนือเป้า -> ลอยลง
local function flyRoute(root, target, stopRadius)
	local height = math.max(root.Position.Y, target.Y) + 120
	flyTo(root, Vector3.new(root.Position.X, height, root.Position.Z), 5, 8)
	flyTo(root, Vector3.new(target.X, height, target.Z), 5, 20)
	return flyTo(root, target, stopRadius, 10 + height / 60)
end

local function returnHome()
	local currentCharacter = player.Character
	local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
	local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not homeCFrame or not currentHumanoid or not root then return end

	setNoclip(true)
	local target = homeCFrame.Position
	flyRoute(root, target, 4)

	-- ปรับตำแหน่งให้ตรงจุดบ้าน
	root.CFrame = CFrame.new(target.X, root.Position.Y, target.Z) * (homeCFrame - homeCFrame.Position)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	setNoclip(false)
	currentHumanoid.WalkSpeed = speedEnabled and walkSpeed or normalSpeed

	local landed = (root.Position - target).Magnitude <= 8
	if not landed then
		autoCollect = false
		collectStatus:Set("กลับบ้านไม่สำเร็จ — หยุด Auto Collect")
		return false
	end

	-- ===== รอ 3 วินาทีหลังลงพื้น =====
	collectStatus:Set("ถึงบ้านแล้ว รอ 3 วินาที...")
	task.wait(3)

	return true
end

local function collectEgg(egg)
	local currentCharacter = player.Character
	local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	local position = root and getPosition(egg)
	if not position then return end
	setNoclip(true)
	flyRoute(root, position + Vector3.new(0, 6, 0), 4)
	task.wait(1)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(1.5)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	returnHome()
end

-- วางไว้ตรงนี้เพราะ setNoclip เพิ่งถูกประกาศด้านบน
MainTab:CreateSection({ name = "Noclip" })
MainTab:CreateToggle({ name = "Noclip (ทะลุทุกอย่าง)", flag = "Noclip", value = false, callback = function(value)
	noclipAlways = value
	setNoclip(value)
end })

PetTab:CreateButton({ name = "Set Home Here", callback = function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then collectStatus:Set("ไม่พบ HumanoidRootPart"); return end
	homeCFrame = root.CFrame
	collectStatus:Set("บันทึกจุดบ้านแล้ว")
end })
PetTab:CreateDropdown({ name = "Egg Rarity (ไม่เลือก = ทุกระดับ)", flag = "EggRarity", options = rarityOrder, multiSelect = true, value = {}, callback = function(value)
	table.clear(selectedRarities)
	local list = type(value) == "table" and value or { value }
	for _, rarity in ipairs(list) do selectedRarities[rarity] = true end
	collectStatus:Set(#list > 0 and ("Rarity: " .. table.concat(list, ", ")) or "Rarity: ทุกระดับ")
end })
PetTab:CreateSlider({ name = "Travel Speed", flag = "TravelSpeed", range = { 100, 1000 }, increment = 10, value = 400, callback = function(value) travelSpeed = value end })
PetTab:CreateInput({ name = "Minimum Luck", flag = "MinimumEggLuck", placeholder = "เช่น 1.5T / 250B / 0", callback = function(text)
	minimumLuck = luckValue(text)
	collectStatus:Set("Minimum Luck: " .. luckText(minimumLuck))
end })
PetTab:CreateToggle({ name = "Auto Collect Egg", flag = "AutoCollectEgg", value = false, callback = function(value)
	if value and not homeCFrame then collectStatus:Set("กด Set Home Here ก่อน"); return end
	autoCollect = value
	collectStatus:Set(value and "Auto Collect: ON" or "Auto Collect: OFF")
end })

task.spawn(function()
	while true do
		if autoCollect and homeCFrame then
			local folder = workspace:FindFirstChild("RenderedEggs")
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local target, targetDistance
			if folder and root then
				for _, egg in ipairs(folder:GetChildren()) do
					local luck = egg:FindFirstChild("Handle") and egg.Handle:FindFirstChild("EggLuck") and egg.Handle.EggLuck:FindFirstChild("Luck")
					local position = getPosition(egg)
					local distance = position and (root.Position - position).Magnitude
					if luck and distance and luckValue(luck.Text) >= minimumLuck and rarityAllowed(egg.Name) and (not targetDistance or distance < targetDistance) then target, targetDistance = egg, distance end
				end
			end
			if target then collectStatus:Set("กำลังเก็บ: " .. target.Name); collectEgg(target) else task.wait(0.5) end
		else task.wait(0.5) end
	end
end)

Tabs.Main:Select()

player.CharacterAdded:Connect(function(newCharacter)
	resetAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
end)
