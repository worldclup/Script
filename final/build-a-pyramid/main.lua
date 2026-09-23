local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled = false, false, false, false
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
	speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled = false, false, false, false
	humanoid.WalkSpeed = normalSpeed
	humanoid.UseJumpPower = normalUseJumpPower
	humanoid.JumpPower = normalJumpPower
	setFly(false)
end

local Window = Rayfield:CreateWindow({
	name = "DEK DEV HUB", subtitle = "Build a Pyramid!",
	sidebarLayout = true, theme = "default", icon = "rbxassetid://134664151762829", showName = "DEK", showIcon = "rbxassetid://134664151762829", showIconOnly = true,
})
local Tabs = {
	Main = Window:CreateTab({ name = "Main" }),
	Pyramid = Window:CreateTab({ name = "Pyramid" }),
	Upgrade = Window:CreateTab({ name = "Upgrade" }),
	Train = Window:CreateTab({ name = "Train" }),
	Inspect = Window:CreateTab({ name = "Inspect / Export" }),
	Settings = Window:CreateTab({ name = "Settings" }),
}
local MainTab, InspectTab, SettingsTab = Tabs.Main, Tabs.Inspect, Tabs.Settings
local PyramidTab, UpgradeTab, TrainTab = Tabs.Pyramid, Tabs.Upgrade, Tabs.Train

local inspectRoot, inspectDepth, inspectLimit = "Workspace", 5, 3000
local inspectBusy, inspectCancel, inspectClosed = false, false, false
local inspectOutput
local remoteCaptureEnabled, captureBindables = false, false
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
local function captureValue(value, depth)
	depth = depth or 0
	local kind = typeof(value)
	if kind == "nil" then return "[nil]" end
	if kind == "boolean" or kind == "string" then return value end
	if kind == "number" and value == value and math.abs(value) < math.huge then return value end
	-- กาง table ออกมาด้วย จะได้เห็นว่าเกมส่งฟิลด์อะไรบ้าง (เช่น { Attacker = ..., Damage = ... })
	if kind == "table" and depth < 3 then
		local copy = {}
		for key, item in pairs(value) do
			copy[tostring(key)] = captureValue(item, depth + 1)
		end
		return copy
	end
	return ("[%s] %s"):format(kind, tostring(value))
end
InspectTab:CreateToggle({ name = "Capture Remote Calls", flag = "CaptureRemoteCalls", value = false, callback = function(value)
	remoteCaptureEnabled = value
	remoteStatus:Set(value and "กำลังดัก FireServer / InvokeServer สูงสุด 25 รายการ" or "หยุดดัก Remote")
end })
InspectTab:CreateToggle({ name = "Capture Bindable (Fire/Invoke)", flag = "CaptureBindables", value = false, callback = function(value)
	captureBindables = value
	remoteStatus:Set(value and "ดัก Bindable ด้วย (ช่วยหา args ที่เกมใช้จริงฝั่ง client)" or "ดักเฉพาะ remote ไปเซิร์ฟเวอร์")
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
		local method = remoteCaptureEnabled and getnamecallmethod() or nil
		-- Bindable Fire/Invoke ก็ดักด้วย เพราะบางเกมตัดสินผลฝั่ง client ผ่าน bindable ก่อนค่อยส่ง remote
		local wanted = method == "FireServer" or method == "InvokeServer"
			or (captureBindables and (method == "Fire" or method == "Invoke"))
		if wanted and #remoteCaptures + #remoteQueue < 25 and (type(checkcaller) ~= "function" or not checkcaller()) then
			table.insert(remoteQueue, { remote = self, method = method, args = table.pack(...), capturedAt = os.date("!%Y-%m-%dT%H:%M:%SZ") })
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
				table.insert(remoteCaptures, { remote = ok and path or tostring(event.remote), method = event.method or "FireServer", direction = event.direction or "client→server", args = args, capturedAt = event.capturedAt })
				if #remoteCaptures > 25 then table.remove(remoteCaptures, 1) end
				remoteStatus:Set(("Captured: %s (%s)\nTotal: %d"):format(ok and path or tostring(event.remote), event.method or "FireServer", #remoteCaptures))
				print("[Remote Capture]", event.method or "FireServer", ok and path or event.remote, unpack(args))
			else task.wait(0.1) end
		end
	end)
else
	remoteStatus:Set("Capture unavailable: executor ไม่รองรับ hookmetamethod")
end
InspectTab:CreateSection({ name = "API / Remote Explorer" })
local apiStatus = InspectTab:CreateText({ name = "Remotes", text = "กด List Remotes เพื่อดูว่าเกมมี remote อะไรบ้าง" })
local listenConnections = {}

-- ที่ที่เกมมักเก็บ remote ไว้ (ไม่ไล่ทั้ง game เพราะช้าและเจอขยะเยอะ)
local function remoteRoots()
	return {
		ReplicatedStorage,
		game:GetService("ReplicatedFirst"),
		workspace,
		player,
		player:FindFirstChildOfClass("PlayerGui"),
		player:FindFirstChildOfClass("PlayerScripts"),
	}
end

local function isRemote(item)
	return item:IsA("RemoteEvent") or item:IsA("RemoteFunction") or item:IsA("UnreliableRemoteEvent")
		or item:IsA("BindableEvent") or item:IsA("BindableFunction")
end

local function collectRemotes()
	local found, seen = {}, {}
	for _, root in ipairs(remoteRoots()) do
		for index, item in ipairs(root and root:GetDescendants() or {}) do
			if not seen[item] and isRemote(item) then
				seen[item] = true
				table.insert(found, item)
			end
			if index % 500 == 0 then task.wait() end
		end
	end
	table.sort(found, function(a, b) return a:GetFullName() < b:GetFullName() end)
	return found
end

InspectTab:CreateButton({ name = "List Remotes", callback = function()
	task.spawn(function()
		apiStatus:Set("กำลังไล่หา remote...")
		local ok, json, total, summary = pcall(function()
			local rows, counts = {}, {}
			for _, remote in ipairs(collectRemotes()) do
				counts[remote.ClassName] = (counts[remote.ClassName] or 0) + 1
				table.insert(rows, { path = remote:GetFullName(), name = remote.Name, class = remote.ClassName })
			end
			local lines = {}
			for class, count in pairs(counts) do table.insert(lines, ("%s x%d"):format(class, count)) end
			table.sort(lines)
			local encoded = game:GetService("HttpService"):JSONEncode({
				placeId = game.PlaceId,
				scannedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
				source = "remote explorer",
				total = #rows,
				remotes = rows,
			})
			return encoded, #rows, table.concat(lines, ", ")
		end)
		if not ok then apiStatus:Set("List failed: " .. tostring(json)); return end
		inspectOutput = json
		apiStatus:Set(("พบ %d ตัว — %s\nใช้ Copy JSON / Export JSON File เพื่อดูรายการเต็ม"):format(total, summary))
	end)
end })

-- ดักขาเข้า (server → client) ด้วย OnClientEvent เพื่อดูว่าเกมส่งอะไรกลับมาบ้าง
InspectTab:CreateToggle({ name = "Listen Server → Client", flag = "ListenServerEvents", value = false, callback = function(value)
	for _, connection in ipairs(listenConnections) do connection:Disconnect() end
	table.clear(listenConnections)
	if not value then apiStatus:Set("หยุดฟังฝั่ง server แล้ว"); return end
	task.spawn(function()
		local count = 0
		for _, remote in ipairs(collectRemotes()) do
			if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
				count = count + 1
				if count > 150 then break end
				local path = remote:GetFullName()
				table.insert(listenConnections, remote.OnClientEvent:Connect(function(...)
					if #remoteCaptures + #remoteQueue >= 25 then return end
					table.insert(remoteQueue, { remote = remote, method = "OnClientEvent", direction = "server→client", args = table.pack(...), capturedAt = os.date("!%Y-%m-%dT%H:%M:%SZ") })
					print("[Server→Client]", path, ...)
				end))
			end
		end
		apiStatus:Set(("กำลังฟัง %d RemoteEvent (ดูผลในกล่อง Remote Calls)"):format(#listenConnections))
	end)
end })

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

-- ===== Pyramid: เก็บหิน -> วางหิน =====
local VirtualInputManager = game:GetService("VirtualInputManager")

local autoRun, useTeleport = false, false
local moveSpeed, arriveRadius = 60, 6
local holdTime, clickPrompt, holdContinuous = 0.35, false, true
local anyPrompt = true
local blindPlace, placeTimeout, collectTimeout = true, 15, 8
local lastCarried, carriedChanged = nil, 0
local mode, stuckSince = "collect", nil
local roamEnabled, roamInterval, roamMargin = true, 3, 0.85
local roamTarget, roamSince, roamMisses = nil, 0, 0
local gapAim, gapCache, gapCacheAt = true, nil, 0
local gapStep, gapFolder, gapLayer = 0, nil, 1
local failedSpots, failCooldown = {}, 45
local floatEnabled, floatHeight, floatSpeed = true, 1, 80
local autoJump = true
local walkLastPos, walkStuckSince, walkJumpAt = nil, nil, 0
local floatMover, floatAnchorY
local noclipStates, noclipConnection = {}, nil
local trainingActive = false
local pyramidStatus = PyramidTab:CreateText({ name = "Pyramid", text = "กด Auto เพื่อวนเก็บหิน/วางหิน" })

local function region(name)
	local regions = workspace:FindFirstChild("Regions")
	return regions and regions:FindFirstChild("Region:" .. name)
end

local function regionPosition(name)
	local model = region(name)
	if not model then return nil end
	if model:IsA("BasePart") then return model.Position end
	if model:IsA("Model") then return model:GetPivot().Position end
	local part = model:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position
end

-- กรอบของพีระมิดที่กำลังสร้าง: workspace.PyramidBuild
local function buildModel()
	local model = workspace:FindFirstChild("PyramidBuild")
	return model and model:IsA("Model") and model or nil
end

-- สุ่มจุดในกรอบ (หดขอบเข้ามานิดหน่อยกันหลุดออกนอกโซน)
-- ใช้ Y ของตัวเองเป็นหลัก ระยะทางจะได้วัดแนวราบล้วน ๆ ไม่เพี้ยนตามความสูงพีระมิด
local function randomBuildPoint()
	local model = buildModel()
	if not model then return nil end
	local ok, cf, size = pcall(model.GetBoundingBox, model)
	if not ok or not cf then return nil end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local point = cf.Position + Vector3.new(
		(math.random() * 2 - 1) * size.X / 2 * roamMargin,
		0,
		(math.random() * 2 - 1) * size.Z / 2 * roamMargin
	)
	return Vector3.new(point.X, root and root.Position.Y or point.Y, point.Z)
end

-- ชั้นที่กำลังสร้าง: อ่านจาก attribute CurrentLayer ของ PyramidBuild ก่อน ถ้าไม่มีก็ดูจากโฟลเดอร์ Layer ที่สูงสุด
local function currentLayerNumber()
	local model = buildModel()
	if not model then return 1 end
	local attribute = model:GetAttribute("CurrentLayer")
	if type(attribute) == "number" and attribute > 0 then return math.floor(attribute) end
	local highest = 1
	for _, child in ipairs(model:GetChildren()) do
		local number = tonumber(tostring(child.Name):match("^Layer(%d+)$"))
		if number and number > highest then highest = number end
	end
	return highest
end

-- workspace.PyramidSlabs.LayerSlab{N} = แผ่นโปร่งใสที่บอกพื้นที่ของชั้นนั้น (ขอบเขตจริง ไม่ต้องเดา)
local function layerSlab(number)
	local slabs = workspace:FindFirstChild("PyramidSlabs")
	local slab = slabs and slabs:FindFirstChild("LayerSlab" .. number)
	return slab and slab:IsA("BasePart") and slab or nil
end

local function layerFolder(number)
	local model = buildModel()
	return model and model:FindFirstChild("Layer" .. number) or nil
end

-- ปูตารางทับพื้นที่ของ LayerSlab แล้วดูว่าช่องไหนยังไม่มีก้อนใน Layer เดียวกัน
local function findGaps()
	local layer = currentLayerNumber()
	local slab = layerSlab(layer)
	local folder = layerFolder(layer)
	gapLayer, gapFolder = layer, folder
	if not slab then return {} end

	local parts = {}
	if folder then
		for _, item in ipairs(folder:GetDescendants()) do
			if item:IsA("BasePart") then parts[#parts + 1] = item end
		end
	end

	-- ระยะกริด = ขนาดก้อนที่พบบ่อยที่สุดในชั้นนี้ (ชั้นเพิ่งเปิดใหม่ยังไม่มีก้อน ใช้ 10 ไปก่อน)
	local sizes, step, best = {}, 10, 0
	for _, part in ipairs(parts) do
		local key = math.floor(part.Size.X * 10 + 0.5) / 10
		sizes[key] = (sizes[key] or 0) + 1
	end
	for size, count in pairs(sizes) do
		if count > best and size > 0 then step, best = size, count end
	end
	gapStep = step

	local halfX, halfZ = slab.Size.X / 2, slab.Size.Z / 2
	local countX = math.max(1, math.floor(slab.Size.X / step + 0.5))
	local countZ = math.max(1, math.floor(slab.Size.Z / step + 0.5))

	-- แปลงตำแหน่งก้อนเข้าสู่พิกัดของแผ่น (แผ่นหมุนอยู่ จึงต้องใช้ object space)
	local occupied = {}
	for _, part in ipairs(parts) do
		local point = slab.CFrame:PointToObjectSpace(part.Position)
		local gx = math.floor((point.X + halfX) / step)
		local gz = math.floor((point.Z + halfZ) / step)
		occupied[gx .. "," .. gz] = true
	end

	local gaps = {}
	for gx = 0, countX - 1 do
		for gz = 0, countZ - 1 do
			if not occupied[gx .. "," .. gz] then
				local offset = Vector3.new(-halfX + (gx + 0.5) * step, 0, -halfZ + (gz + 0.5) * step)
				gaps[#gaps + 1] = (slab.CFrame * CFrame.new(offset)).Position
			end
		end
	end
	return gaps
end

-- เช็คซ้ำด้วยการตรวจชน เฉพาะก้อนในชั้นเดียวกัน (ชั้นล่างอยู่ใต้ตำแหน่งเดียวกันเสมอ จึงต้องกันไม่ให้นับ)
local function cellFree(point)
	if not gapFolder then return true end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { gapFolder }
	params.MaxParts = 1
	local step = gapStep > 0 and gapStep or 10
	local hits = workspace:GetPartBoundsInBox(
		CFrame.new(point),
		Vector3.new(step * 0.7, 40, step * 0.7),
		params
	)
	return #hits == 0
end

-- ช่องที่ไปยืนแล้ววางไม่ลง ให้พักไว้ก่อน จะได้ไม่วนกลับไปช่องเดิม
local function spotKey(point)
	return ("%d,%d"):format(math.floor(point.X + 0.5), math.floor(point.Z + 0.5))
end

local function markFailed(point)
	if point then failedSpots[spotKey(point)] = os.clock() + failCooldown end
end

local function isFailed(point)
	local until_ = failedSpots[spotKey(point)]
	if not until_ then return false end
	if os.clock() > until_ then failedSpots[spotKey(point)] = nil; return false end
	return true
end

-- ช่องว่างที่ใกล้ตัวที่สุดที่ยังไม่โดนพักและว่างจริง
local function nextGapPoint()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	if not gapCache or os.clock() - gapCacheAt > 2 then
		gapCache, gapCacheAt = findGaps(), os.clock()
	end
	if #gapCache == 0 then return nil end
	local function flatDistance(point)
		return (Vector2.new(point.X, point.Z) - Vector2.new(root.Position.X, root.Position.Z)).Magnitude
	end
	table.sort(gapCache, function(a, b) return flatDistance(a) < flatDistance(b) end)

	local free = {}
	for _, point in ipairs(gapCache) do
		if not isFailed(point) and cellFree(point) then
			free[#free + 1] = point
			if #free >= 5 then break end
		end
	end
	if #free == 0 then return nil end
	local pick = free[math.random(1, #free)]
	return Vector3.new(pick.X, root.Position.Y, pick.Z)
end

-- ผิวบนของแผ่นชั้นปัจจุบัน = ความสูงที่ควรไปยืน (วาร์ป/ลอย จะได้ไม่ไปโผล่ใต้ชั้นแล้วตกแมพ)
local function layerSurfaceY()
	local slab = layerSlab(currentLayerNumber())
	if not slab then return nil end
	return slab.Position.Y + slab.Size.Y / 2
end

-- อยู่ในพื้นที่ของแผ่นชั้นนี้หรือยัง (ใช้ตัดสินว่าจะเริ่มกด E วางได้แล้ว)
local function insideBuild()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local slab = layerSlab(currentLayerNumber())
	if not slab then
		local model = buildModel()
		if not model then return false end
		local ok, cf, size = pcall(model.GetBoundingBox, model)
		if not ok or not cf then return false end
		local point = cf:PointToObjectSpace(root.Position)
		return math.abs(point.X) <= size.X / 2 and math.abs(point.Z) <= size.Z / 2
	end
	local point = slab.CFrame:PointToObjectSpace(root.Position)
	return math.abs(point.X) <= slab.Size.X / 2 and math.abs(point.Z) <= slab.Size.Z / 2
end

-- ตัวนับด้านซ้ายบอกว่าแบกมาแล้วเท่าไร / แบกได้สูงสุดเท่าไร เช่น 7/31
local function capacity()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local screen = gui and gui:FindFirstChild("ScreenGui")
	local label = screen
		and screen:FindFirstChild("CenterLeft")
		and screen.CenterLeft:FindFirstChild("LeftSideBar")
		and screen.CenterLeft.LeftSideBar:FindFirstChild("StrengthCounter")
		and screen.CenterLeft.LeftSideBar.StrengthCounter:FindFirstChild("Readout")
		and screen.CenterLeft.LeftSideBar.StrengthCounter.Readout:FindFirstChild("Detail")
		and screen.CenterLeft.LeftSideBar.StrengthCounter.Readout.Detail:FindFirstChild("TextLabel")
	if not label then return nil, nil end
	local carried, maximum = tostring(label.Text):match("(%d+)%s*/%s*(%d+)")
	return tonumber(carried), tonumber(maximum)
end

-- ปุ่มโต้ตอบของเกม: โผล่เฉพาะตอนที่กดได้จริง (ActionText = Pick Up / Place)
local function promptButton()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local screen = gui and gui:FindFirstChild("RegionPromptGui")
	local container = screen and screen:FindFirstChild("RegionPromptContainer")
	local button = container and container:FindFirstChild("Button")
	if not container or not button or not container.Visible then return nil end
	local action = button:FindFirstChild("ActionText")
	local object = button:FindFirstChild("ObjectText")
	return button, action and action.Text or "", object and object.Text or ""
end

-- เกมอาจเขียนว่า "Place Stone" / "Pick Up Stone" ไม่ตรงตัวเป๊ะ จึงจับแบบหลวม
local function actionMatches(action, wanted)
	if anyPrompt then return true end
	local text = tostring(action):lower()
	if wanted == "Pick Up" then
		return text:find("pick") ~= nil or text:find("collect") ~= nil or text:find("grab") ~= nil
	end
	return text:find("place") ~= nil or text:find("drop") ~= nil or text:find("build") ~= nil or text:find("deposit") ~= nil
end

-- ปุ่มเป็นแบบกดค้าง (มี HoldWrap ใน UI) กดติ๊ดเดียวจึงไม่ติด
-- จึงแยกเป็น "กดลง" กับ "ปล่อย" แล้วค้างไว้ข้ามรอบ จนกว่าจะวาง/เก็บหมด
local holdActive, holdPoint, holdStart = false, nil, 0

local function setHold(down)
	if holdActive == down then return end
	holdActive, holdStart = down, os.clock()
	if holdPoint then
		if type(firesignal) == "function" and typeof(holdPoint) == "Instance" then
			pcall(firesignal, down and holdPoint.MouseButton1Down or holdPoint.MouseButton1Up)
			if not down then pcall(firesignal, holdPoint.MouseButton1Click) end
		elseif typeof(holdPoint) == "Vector2" then
			VirtualInputManager:SendMouseButtonEvent(holdPoint.X, holdPoint.Y, 0, down, game, 1)
		end
		if not down then holdPoint = nil end
		return
	end
	VirtualInputManager:SendKeyEvent(down, Enum.KeyCode.E, false, game)
end

-- บางเกม/บางตัวรันปล่อยสถานะคีย์ทิ้งไประหว่างเฟรม จึงย้ำ "กดลง" ซ้ำทุกรอบ
local function repeatHold()
	if holdActive and not holdPoint then
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	end
end

-- เริ่มกดค้าง: เลือกว่าจะค้างคีย์ E หรือค้างเมาส์บนปุ่มในจอ
local function beginHold(button)
	if holdActive then return end
	if clickPrompt and button then
		holdPoint = type(firesignal) == "function" and button
			or (button.AbsolutePosition + button.AbsoluteSize / 2 + game:GetService("GuiService"):GetGuiInset())
	else
		holdPoint = nil
	end
	setHold(true)
end

-- ตอนวางไม่มีปุ่มขึ้น จึงกด E เป็นจังหวะ (ลง holdTime แล้วปล่อยหนึ่งรอบ) วางทีละก้อนไปเรื่อย ๆ
local function pulseHold()
	if not holdActive then
		beginHold(nil)
	elseif os.clock() - holdStart >= holdTime then
		setHold(false)
	else
		repeatHold()
	end
end

-- WalkSpeed วิ่งไวไม่ได้ (เกมล็อก) จึงขยับด้วย BodyVelocity แล้วลอยเหนือพื้นนิดหน่อย
local function setFloat(enabled)
	if floatMover then floatMover:Destroy(); floatMover = nil end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not enabled or not root then floatAnchorY = nil; return end
	-- แมพนี้พื้นไม่นิ่ง (กองหิน/พีระมิดโตขึ้นเรื่อย ๆ) จึงล็อกความสูงจากตัวเอง ไม่ยิงเรย์หาพื้น
	floatAnchorY = root.Position.Y + floatHeight
	floatMover = Instance.new("BodyVelocity")
	floatMover.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	floatMover.Velocity = Vector3.zero
	floatMover.Parent = root
end

-- กด CanCollide ลงทุกเฟรม พาร์ทที่เกมเพิ่มทีหลังก็ยังทะลุ
local function setNoclip(enabled)
	if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
	if enabled then
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
		for part, state in pairs(noclipStates) do
			if part.Parent then pcall(function() part.CanCollide = state end) end
			noclipStates[part] = nil
		end
	end
end

-- ความสูงของพื้น/ก้อนหินจริงที่จุดหนึ่ง (ไม่ใช่ผิวของ LayerSlab ซึ่งอยู่แค่ระดับฐาน)
local function groundYAt(point)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(point.X, point.Y + 300, point.Z), Vector3.new(0, -600, 0), params)
	return result and result.Position.Y or nil
end

-- มีอะไรขวางข้างหน้าในระยะ studs ที่กำหนดไหม (ยิงทั้งระดับเอวและระดับเท้า)
local function blockedAhead(root, direction, reach)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = true
	for _, offsetY in ipairs({ 0, -1.5 }) do
		local from = root.Position + Vector3.new(0, offsetY, 0)
		if workspace:Raycast(from, direction * reach, params) then return true end
	end
	return false
end

-- เกมบางเกมปิดสถานะกระโดดหรือกด JumpPower เหลือ 0 จึงปลดล็อกแล้วสั่งหลายทางพร้อมกัน
local function forceJump(currentHumanoid)
	pcall(function() currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
	pcall(function() currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true) end)
	if currentHumanoid.UseJumpPower then
		if currentHumanoid.JumpPower < 50 then currentHumanoid.JumpPower = 50 end
	elseif currentHumanoid.JumpHeight < 7 then
		currentHumanoid.JumpHeight = 7
	end
	currentHumanoid.Jump = true
	pcall(function() currentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

-- ไปหาจุดหมาย: ลอย / เดิน / วาร์ป แล้วบอกว่าถึงหรือยัง
-- surfaceY = ความสูงผิวที่ต้องไปยืน (ใส่มาเฉพาะตอนวางบนชั้นพีระมิด)
local function goTo(position, surfaceY)
	local currentCharacter = player.Character
	local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
	local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
	if not currentHumanoid or not root or not position then return false, 0 end

	-- วัดแนวราบล้วน ๆ ความสูงต่างกันไม่ควรทำให้ "ยังไม่ถึง"
	local flat = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z)
	local distance = flat.Magnitude
	local arrived = distance <= arriveRadius

	if useTeleport then
		if floatMover then setFloat(false) end
		-- ยกขึ้นเหนือผิวชั้นเสมอ ไม่งั้นวาร์ปไปโผล่ใต้ Layer แล้วร่วง
		local landingY = (surfaceY or position.Y) + 5
		if not arrived then root.CFrame = CFrame.new(position.X, landingY, position.Z) end
		return arrived, distance
	end

	if not floatEnabled then
		if floatMover then setFloat(false) end
		currentHumanoid.WalkSpeed = moveSpeed

		-- ปีนเฉพาะตอนไปวางบนชั้น (surfaceY มีค่า) และต้องใกล้พอแล้วเท่านั้น
		-- ที่ Quarry ยอดกองหินสูงมาก ถ้าไม่กันไว้จะเข้าใจผิดว่าต้องปีนตลอดแล้วกระโดดรัวไม่หยุด
		local needClimb = false
		if autoJump and surfaceY and distance < 15 then
			local feetY = root.Position.Y - (currentHumanoid.HipHeight + root.Size.Y / 2)
			local targetGround = groundYAt(position)
			local rise = targetGround and targetGround - feetY or 0
			needClimb = rise > 1.5 and rise < 15
		end

		if arrived and not needClimb then
			currentHumanoid:Move(Vector3.zero, false)
			walkLastPos, walkStuckSince = nil, nil
			return arrived, distance
		end

		local now = os.clock()
		if autoJump then
			-- ขยับได้น้อยกว่า 0.5 studs ระหว่างรอบ = ติดขอบชั้น/ก้อนหินอยู่
			if walkLastPos and (root.Position - walkLastPos).Magnitude < 0.5 then
				walkStuckSince = walkStuckSince or now
			else
				walkStuckSince = nil
			end
			walkLastPos = root.Position
			local stuck = walkStuckSince and now - walkStuckSince or 0

			-- กระโดดเมื่อ "ขยับไม่ไปจริง ๆ" หรือกำลังจะปีนขึ้นชั้นเท่านั้น
			-- (ไม่ใช้ blockedAhead เป็นตัวจุดเอง เพราะยืนข้างกองหินก็โดนตลอด)
			local forward = distance > 0.1 and flat.Unit or root.CFrame.LookVector
			local jamming = stuck > 0.2 and blockedAhead(root, forward, 4)
			if (jamming or needClimb) and now - walkJumpAt > 0.25 then
				forceJump(currentHumanoid)
				walkJumpAt = now
			end
		end
		-- ต้องปีนขึ้นก็เดินชนขอบไว้ ไม่งั้นกระโดดแล้วไม่มีแรงไปข้างหน้า
		currentHumanoid:MoveTo(needClimb and (root.Position + (distance > 0.1 and flat.Unit or root.CFrame.LookVector) * 6) or position)
		return arrived and not needClimb, distance
	end

	if not floatMover or floatMover.Parent ~= root then setFloat(true) end
	if floatMover then
		local horizontal = (arrived or flat.Magnitude < 1) and Vector3.zero
			or flat.Unit * math.min(floatSpeed, flat.Magnitude * 4)
		-- ชั้นสูงขึ้นก็ยกตัวตามผิวชั้น ไม่ค้างอยู่ระดับเดิมจนมุดเข้าไปในก้อน
		if surfaceY then floatAnchorY = surfaceY + floatHeight + 3 end
		if not floatAnchorY then floatAnchorY = root.Position.Y + floatHeight end
		local verticalY = (floatAnchorY - root.Position.Y) * 6
		floatMover.Velocity = Vector3.new(horizontal.X, math.clamp(verticalY, -40, 40), horizontal.Z)
	end
	return arrived, distance
end

local function currentPosition()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

PyramidTab:CreateToggle({ name = "Auto เก็บหิน / วางหิน", flag = "AutoPyramid", value = false, callback = function(value)
	autoRun = value
	mode, stuckSince, roamTarget, roamMisses = "collect", nil, nil, 0
	lastCarried, carriedChanged = nil, os.clock()
	table.clear(failedSpots)
	pyramidStatus:Set("Auto: " .. (value and "ON" or "OFF"))
	local currentHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not value then
		setHold(false)
		setFloat(false)
		if currentHumanoid then currentHumanoid.WalkSpeed = speedEnabled and walkSpeed or normalSpeed end
	end
end })

-- ===== 1. การเคลื่อนที่: ลอย / วาร์ป / เดิน อยู่ด้วยกัน =====
PyramidTab:CreateSection({ name = "การเคลื่อนที่" })
PyramidTab:CreateToggle({ name = "ลอยแทนการวิ่ง", flag = "FloatMove", value = true, description = "WalkSpeed ถูกเกมล็อก จึงขยับด้วย BodyVelocity แทน", callback = function(value)
	floatEnabled = value
	if not value then setFloat(false) end
end })
PyramidTab:CreateSlider({ name = "ความไวลอย", flag = "FloatSpeed", range = { 16, 2000 }, increment = 10, value = 80, callback = function(value) floatSpeed = value end })
PyramidTab:CreateSlider({ name = "ความสูงที่ลอย (studs)", flag = "FloatHeight", range = { 0, 40 }, increment = 0.5, value = 1, description = "วัดจากตัวเอง ไม่ใช่จากพื้น", callback = function(value)
	if floatAnchorY then floatAnchorY = floatAnchorY + value - floatHeight end
	floatHeight = value
end })
PyramidTab:CreateButton({ name = "ตั้งความสูงลอย = ตรงนี้", callback = function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then floatAnchorY = root.Position.Y; pyramidStatus:Set(("ล็อกความสูงที่ Y = %.1f"):format(floatAnchorY)) end
end })
PyramidTab:CreateToggle({ name = "วาร์ปแทนการเดิน", flag = "PyramidTeleport", value = false, description = "เร็วกว่าแต่เสี่ยงโดนตรวจมากกว่า (ปิดการลอยชั่วคราว)", callback = function(value) useTeleport = value end })
PyramidTab:CreateToggle({ name = "Noclip (ทะลุทุกอย่าง)", flag = "Noclip", value = false, callback = setNoclip })
PyramidTab:CreateSlider({ name = "ความไวเดิน (ใช้เมื่อปิดลอย)", flag = "PyramidSpeed", range = { 16, 300 }, increment = 2, value = 60, callback = function(value) moveSpeed = value end })
PyramidTab:CreateToggle({ name = "เดินติดแล้วกระโดด", flag = "AutoJump", value = true, description = "ใช้ตอนปิดลอย: กระโดดขึ้นชั้นที่สูงกว่า และกระโดดข้ามสิ่งที่ขวาง", callback = function(value)
	autoJump = value
	walkStuckSince = nil
end })
PyramidTab:CreateSlider({ name = "ระยะที่ถือว่าถึงแล้ว (studs)", flag = "ArriveRadius", range = { 2, 30 }, increment = 1, value = 6, callback = function(value) arriveRadius = value end })
PyramidTab:CreateButton({ name = "ไป Quarry", callback = function() goTo(regionPosition("Quarry")) end })
PyramidTab:CreateButton({ name = "ไป Pyramid", callback = function() goTo(regionPosition("Pyramid"), layerSurfaceY()) end })

-- ===== 2. การกดปุ่ม: ทุกอย่างที่เกี่ยวกับ E อยู่ด้วยกัน =====
PyramidTab:CreateSection({ name = "การกดปุ่ม E" })
PyramidTab:CreateToggle({ name = "กด E ค้างยาวจนหมด", flag = "HoldContinuous", value = true, description = "ปิดถ้าเกมนับเป็นครั้ง ๆ แล้วจะกดเป็นจังหวะแทน", callback = function(value)
	holdContinuous = value
	setHold(false)
end })
PyramidTab:CreateSlider({ name = "กดค้างครั้งละ (วินาที)", flag = "HoldTime", range = { 0.05, 3 }, increment = 0.05, value = 0.35, description = "ใช้เมื่อปิด 'ค้างยาว' และตอนวางแบบไม่มีปุ่ม", callback = function(value) holdTime = value end })
PyramidTab:CreateToggle({ name = "กดทุกปุ่มที่ขึ้น (ไม่สนข้อความ)", flag = "AnyPrompt", value = true, description = "ปิดถ้าอยากให้กดเฉพาะปุ่มที่ข้อความตรงกับงาน", callback = function(value) anyPrompt = value end })
PyramidTab:CreateToggle({ name = "กดปุ่มบนจอแทนคีย์ E", flag = "ClickPrompt", value = false, description = "ใช้เมื่อกด E แล้วไม่ติด", callback = function(value) clickPrompt = value end })
PyramidTab:CreateButton({ name = "ทดสอบ: กด E ค้าง 1 วิ", callback = function()
	task.spawn(function()
		local button, action, object = promptButton()
		beginHold(button)
		for _ = 1, 10 do repeatHold(); task.wait(0.1) end
		setHold(false)
		pyramidStatus:Set(("ทดสอบกดแล้ว | ปุ่มที่เจอ: %s"):format(button and ("%s / %s"):format(action, object) or "ไม่มีปุ่มบนจอ"))
	end)
end })

-- ===== 3. การวางหิน: เลือกช่อง + จังหวะย้ายจุด =====
PyramidTab:CreateSection({ name = "การวางหิน" })
PyramidTab:CreateToggle({ name = "ตอนวางกด E เอง (เกมไม่มีปุ่มขึ้น)", flag = "BlindPlace", value = true, description = "กด E รัว ๆ ระหว่างอยู่ในกรอบของชั้นที่สร้าง", callback = function(value)
	blindPlace = value
	setHold(false)
end })
PyramidTab:CreateToggle({ name = "เล็งช่องว่างที่ยังไม่ได้วาง", flag = "GapAim", value = true, description = "คำนวณจาก LayerSlab + ก้อนที่วางแล้ว แล้วไปยืนตรงช่องที่ยังว่าง", callback = function(value)
	gapAim, gapCache, roamTarget = value, nil, nil
end })
PyramidTab:CreateToggle({ name = "สุ่มในกรอบ (ใช้เมื่อหาช่องว่างไม่เจอ)", flag = "RoamBuild", value = true, callback = function(value)
	roamEnabled, roamTarget = value, nil
end })
PyramidTab:CreateSlider({ name = "หินไม่ลดกี่วิถึงย้ายจุด", flag = "RoamInterval", range = { 0.5, 15 }, increment = 0.5, value = 3, description = "วางได้อยู่ก็ยืนที่เดิมต่อ ย้ายเมื่อตัวนับหินนิ่งเท่านั้น", callback = function(value) roamInterval = value end })
PyramidTab:CreateSlider({ name = "ความกว้างที่สุ่ม (% ของกรอบ)", flag = "RoamMargin", range = { 20, 100 }, increment = 5, value = 85, callback = function(value) roamMargin = value / 100 end })
PyramidTab:CreateButton({ name = "นับช่องว่างตอนนี้", callback = function()
	local gaps = findGaps()
	local free = 0
	for _, point in ipairs(gaps) do if cellFree(point) then free = free + 1 end end
	pyramidStatus:Set(("Layer %d | ช่องว่างจากตาราง %d | ตรวจชนแล้วว่างจริง %d | กริด %.1f studs%s"):format(gapLayer, #gaps, free, gapStep, gapFolder and "" or " (ไม่พบโฟลเดอร์ Layer)"))
end })
PyramidTab:CreateButton({ name = "ล้างช่องที่พักไว้", callback = function()
	table.clear(failedSpots)
	gapCache, roamTarget = nil, nil
	pyramidStatus:Set("ล้างรายการช่องที่วางไม่ลงแล้ว")
end })

-- ===== 4. จังหวะสลับงาน: ตัวกันค้างทั้งสองฝั่ง =====
PyramidTab:CreateSection({ name = "จังหวะสลับงาน" })
PyramidTab:CreateSlider({ name = "เก็บไม่คืบหน้ากี่วิถึงไปวาง", flag = "CollectTimeout", range = { 3, 60 }, increment = 1, value = 8, description = "ตัวนับหยุดขยับ = เต็มมือแล้ว", callback = function(value) collectTimeout = value end })
PyramidTab:CreateSlider({ name = "วางไม่คืบหน้ากี่วิถึงกลับไปเก็บ", flag = "PlaceTimeout", range = { 5, 60 }, increment = 1, value = 15, callback = function(value) placeTimeout = value end })

task.spawn(function()
	while true do
		if not autoRun or trainingActive then
			setHold(false)
		else
			local carried, maximum = capacity()
			if carried ~= lastCarried then lastCarried, carriedChanged, gapCache = carried, os.clock(), nil end
			-- สลับโหมดเฉพาะตอน "เต็มมือ" กับ "มือว่าง" เท่านั้น
			-- ระหว่างนั้นค้างโหมดเดิมไว้ จะได้ไม่วิ่งไปเก็บหินทั้งที่ยังวางไม่หมด
			if carried then
				if mode == "collect" and maximum and carried >= maximum then mode, stuckSince, carriedChanged = "place", nil, os.clock() end
				if mode == "place" and carried == 0 then mode, stuckSince, carriedChanged = "collect", nil, os.clock() end
			end
			-- ตัวนับหยุดขยับตอนเก็บ = เต็มมือแล้ว (หรืออ่านตัวนับไม่ได้) ก็ไปวางเลย ไม่ต้องรอเลข
			if mode == "collect" and os.clock() - carriedChanged > collectTimeout then
				mode, stuckSince, carriedChanged = "place", nil, os.clock()
				setHold(false)
			end

			local name = mode == "collect" and "Quarry" or "Pyramid"
			local wantedAction = mode == "collect" and "Pick Up" or "Place"
			local roaming = mode == "place" and roamEnabled and buildModel() ~= nil
			if roaming then
				-- อยู่จุดเดิมได้เรื่อย ๆ ตราบใดที่หินยังลด (วางลงจริง) ย้ายเมื่อหินนิ่งเกิน roamInterval เท่านั้น
				if not roamTarget or os.clock() - carriedChanged > roamInterval then
					roamTarget = (gapAim and nextGapPoint()) or randomBuildPoint() or roamTarget
					roamSince = os.clock()
				end
			elseif mode == "collect" then
				roamTarget = nil
			end
			local position = (roaming and roamTarget) or regionPosition(name)
			local counter = ("%s/%s"):format(carried or "?", maximum or "?")

			if not position then
				setHold(false)
				pyramidStatus:Set("ไม่พบเป้าหมาย (" .. name .. ")")
			else
				local button, action, object = promptButton()
				local matched = button ~= nil and actionMatches(action, wantedAction)
				-- ปุ่มขึ้นแล้วให้ยืนนิ่ง ๆ กดค้างให้จบก่อน ค่อยขยับต่อ
				-- ตอนวางให้ใช้ความสูงของแผ่นชั้นนั้น จะได้ไม่วาร์ปลงไปใต้ชั้น
				local surfaceY = mode == "place" and layerSurfaceY() or nil
				local arrived, distance = goTo(matched and (currentPosition() or position) or position, surfaceY)

				if matched then
					stuckSince = nil
					-- ค้างปุ่มไว้ข้ามรอบจนกว่าจะเต็ม/หมด (ปิด "ค้างยาว" ถ้าเกมนับเป็นครั้ง ๆ)
					if holdActive and not holdContinuous and os.clock() - holdStart >= holdTime then
						setHold(false)
						task.wait(0.08)
					end
					beginHold(button)
					repeatHold()
					roamSince, roamMisses = os.clock(), 0
					pyramidStatus:Set(("ค้าง %s %s | %s"):format(action, object ~= "" and object or name, counter))
				elseif mode == "place" and blindPlace then
					-- เกมไม่ขึ้นปุ่มตอนวาง: เดินวนในกรอบแล้วกด E รัว ๆ เอง
					local inside = buildModel() == nil or distance <= arriveRadius or insideBuild()
					if inside then pulseHold() else setHold(false) end
					-- ยืนถึงช่องแล้วหินไม่ลดตามเวลาที่ตั้ง = ช่องนี้วางไม่ลง พักช่องนี้แล้วหาช่องใหม่
					if gapAim and distance <= arriveRadius and os.clock() - carriedChanged > roamInterval then
						markFailed(roamTarget)
						roamTarget, roamSince, gapCache = nil, 0, nil
					end
					if os.clock() - carriedChanged > placeTimeout then
						-- ตัวนับไม่ขยับเลย แปลว่าวางไม่ลงแล้ว กลับไปเก็บหินต่อ
						mode, stuckSince, roamTarget = "collect", nil, nil
						carriedChanged = os.clock()
						setHold(false)
					end
					pyramidStatus:Set(("%s | %s | หินนิ่ง %.1fs"):format(
						inside and "กด E วาง" or ("เข้ากรอบ (%.0f studs)"):format(distance), counter, os.clock() - carriedChanged))
				else
					setHold(false)
					if button then
						stuckSince = nil
						pyramidStatus:Set(("รอ %s (เจอ %s) | %s"):format(wantedAction, action ~= "" and action or "ปุ่มอื่น", counter))
					elseif arrived then
						-- ถึงจุดแล้วแต่ UI ไม่ขึ้น (หา RegionPromptGui ไม่เจอ ฯลฯ) ก็ลองกด E เผื่อไว้
						if anyPrompt then beginHold(nil); repeatHold() end
						stuckSince = stuckSince or os.clock()
						local waited = os.clock() - stuckSince
						if roaming and waited > 1.5 then
							-- จุดนี้วางไม่ลง ก็สุ่มจุดใหม่ในกรอบ; สุ่มพลาดรัว ๆ แปลว่าวางไม่ได้แล้ว ไปเก็บหินต่อ
							roamTarget, roamSince, stuckSince = randomBuildPoint(), os.clock(), nil
							roamMisses = roamMisses + 1
							if roamMisses > 12 then
								mode, roamTarget, roamMisses = "collect", nil, 0
							end
						elseif waited > 4 then
							if carried and mode == "collect" and carried > 0 then
								mode, stuckSince = "place", nil
							elseif carried and mode == "place" and carried == 0 then
								mode, stuckSince = "collect", nil
							elseif waited > 10 then
								-- อ่านตัวนับไม่ได้/วางไม่ลงจริง ๆ ก็สลับงานไปเลย ดีกว่ายืนแช่
								mode, stuckSince = mode == "place" and "collect" or "place", nil
							end
						end
						pyramidStatus:Set(("ถึง %s%s แล้วแต่ยังไม่ขึ้นปุ่ม (%.1fs) | %s"):format(name, roaming and " (ช่องว่าง)" or "", waited, counter))
					else
						stuckSince = nil
						pyramidStatus:Set(("ไป %s%s (%.0f studs) | %s"):format(name, roaming and " (ช่องว่าง)" or "", distance, counter))
					end
				end
			end
		end
		task.wait(autoRun and 0.1 or 0.5)
	end
end)


-- ===== Upgrade: ซื้ออัปเกรดอัตโนมัติ =====
-- ราคา/เลเวลไม่ได้อยู่ใน instance แต่อยู่ใน ModuleScript จึง require เอาตอนรัน
local UPGRADE_IDS = { "bulkPickup", "bulkPlace", "placementRange" }
local autoUpgrade, upgradeInterval = {}, 3
local upgradeLevels, upgradeCatalog, upgradeLastBuy = {}, nil, {}
local upgradeStatus = UpgradeTab:CreateText({ name = "Upgrade", text = "เปิดโทเกิลเพื่อซื้ออัปเกรดอัตโนมัติเมื่อเงินพอ" })

-- เงินอยู่ที่ ScreenGui.CenterLeft.LeftSideBar.CoinsCounter...Amount.TextLabel
local function coins()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local screen = gui and gui:FindFirstChild("ScreenGui")
	local label = screen
		and screen:FindFirstChild("CenterLeft")
		and screen.CenterLeft:FindFirstChild("LeftSideBar")
		and screen.CenterLeft.LeftSideBar:FindFirstChild("CoinsCounter")
		and screen.CenterLeft.LeftSideBar.CoinsCounter:FindFirstChild("BumpScale")
		and screen.CenterLeft.LeftSideBar.CoinsCounter.BumpScale:FindFirstChild("Readout")
		and screen.CenterLeft.LeftSideBar.CoinsCounter.BumpScale.Readout:FindFirstChild("Amount")
		and screen.CenterLeft.LeftSideBar.CoinsCounter.BumpScale.Readout.Amount:FindFirstChild("TextLabel")
	if not label then return nil end
	-- ข้อความอาจมีคอมมาหรือหน่วย K/M ต่อท้าย
	local text = tostring(label.Text):gsub(",", "")
	local amount, suffix = text:match("([%d%.]+)%s*([KkMmBb]?)")
	if not amount then return nil end
	local value = tonumber(amount)
	if not value then return nil end
	local scale = { k = 1e3, m = 1e6, b = 1e9 }
	return value * (scale[suffix:lower()] or 1)
end

local function knitService(name)
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local index = packages and packages:FindFirstChild("_Index")
	if not index then return nil end
	for _, child in ipairs(index:GetChildren()) do
		if child.Name:match("^sleitnick_knit") then
			local knit = child:FindFirstChild("knit")
			local services = knit and knit:FindFirstChild("Services")
			local service = services and services:FindFirstChild(name)
			return service
		end
	end
	return nil
end

local function dataRemote(name)
	local service = knitService("DataService")
	local folder = service and service:FindFirstChild("RF")
	return folder and folder:FindFirstChild(name) or nil
end

local function loadCatalog()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local config = shared and shared:FindFirstChild("Config")
	for _, name in ipairs({ "UpgradeCatalog", "UpgradeConfig" }) do
		local module = config and config:FindFirstChild(name)
		if module then
			local ok, data = pcall(require, module)
			if ok and type(data) == "table" then return data end
		end
	end
	local upgrades = shared and shared:FindFirstChild("Upgrades")
	local levels = upgrades and upgrades:FindFirstChild("UpgradeLevels")
	if levels then
		local ok, data = pcall(require, levels)
		if ok and type(data) == "table" then return data end
	end
	return nil
end

-- UpgradeCatalog คืน { ById = { [id] = entry }, AttributePrefix = "UpgradeLevel_", ... }
local function catalogEntry(id)
	local byId = upgradeCatalog and upgradeCatalog.ById
	return type(byId) == "table" and byId[id] or nil
end

-- Costs เป็น array ของราคาแต่ละเลเวล: เลเวล 0 -> Costs[1], เลเวล 8 -> Costs[9]
local function upgradeCost(id, level)
	local entry = catalogEntry(id)
	if not entry or type(entry.Costs) ~= "table" then return nil end
	if entry.MaxLevel and level >= entry.MaxLevel then return nil end
	return tonumber(entry.Costs[level + 1])
end

local function upgradeMaxLevel(id)
	local entry = catalogEntry(id)
	return entry and tonumber(entry.MaxLevel) or 9
end

local function upgradeName(id)
	local entry = catalogEntry(id)
	return entry and tostring(entry.DisplayName) or id
end

local function refreshLevels()
	local remote = dataRemote("GetUpgradeLevels")
	if not remote then return false, "ไม่พบ GetUpgradeLevels" end
	local ok, result = pcall(function() return remote:InvokeServer() end)
	if not ok then return false, tostring(result) end
	if type(result) == "table" then upgradeLevels = result end
	return true
end

-- เลเวลเก็บเป็น attribute ของ player (UpgradeLevel_BulkPickup ฯลฯ) อ่านตรงนี้ได้เลยไม่ต้องยิง remote
local function upgradeLevel(id)
	local entry = catalogEntry(id)
	if entry and entry.Attribute then
		local prefix = (upgradeCatalog and upgradeCatalog.AttributePrefix) or "UpgradeLevel_"
		for _, holder in ipairs({ player, player.Character }) do
			local value = holder and holder:GetAttribute(prefix .. entry.Attribute)
			if tonumber(value) then return tonumber(value) end
		end
	end
	local value = upgradeLevels and (upgradeLevels[id] or upgradeLevels[entry and entry.Attribute or id])
	if type(value) == "table" then value = value.level or value.Level end
	return tonumber(value) or 0
end

local function buyUpgrade(id)
	local remote = dataRemote("PurchaseUpgrade")
	if not remote then return false, "ไม่พบ PurchaseUpgrade" end
	local ok, result = pcall(function() return remote:InvokeServer(id) end)
	if not ok then return false, tostring(result) end
	refreshLevels()
	return true, result
end

local function upgradeSummary()
	local money = coins()
	local lines = { ("เงิน: %s"):format(money and string.format("%.0f", money) or "อ่านไม่ได้") }
	for _, id in ipairs(UPGRADE_IDS) do
		local level, maxLevel = upgradeLevel(id), upgradeMaxLevel(id)
		local cost = upgradeCost(id, level)
		lines[#lines + 1] = ("%s — Lv.%d/%d | %s%s"):format(
			upgradeName(id), level, maxLevel,
			level >= maxLevel and "MAX แล้ว" or ("ราคา " .. (cost and string.format("%.0f", cost) or "?")),
			autoUpgrade[id] and " | AUTO" or ""
		)
	end
	return table.concat(lines, "\n")
end

UpgradeTab:CreateButton({ name = "รีเฟรชเลเวล / ราคา", callback = function()
	upgradeCatalog = loadCatalog()
	local ok, err = refreshLevels()
	upgradeStatus:Set((ok and "" or ("อ่านเลเวลไม่ได้: " .. tostring(err) .. "\n")) .. upgradeSummary()
		.. (upgradeCatalog and "" or "\n(อ่าน catalog ไม่ได้ — ราคาจะขึ้นเป็น ? แต่ยังซื้อได้)"))
end })
upgradeCatalog = loadCatalog()
for _, id in ipairs(UPGRADE_IDS) do
	UpgradeTab:CreateToggle({ name = "Auto: " .. upgradeName(id), flag = "Auto_" .. id, value = false, callback = function(value)
		autoUpgrade[id] = value
		upgradeStatus:Set(upgradeSummary())
	end })
	UpgradeTab:CreateButton({ name = "ซื้อ " .. upgradeName(id) .. " 1 ครั้ง", callback = function()
		local ok, result = buyUpgrade(id)
		upgradeStatus:Set(("ซื้อ %s: %s\n%s"):format(id, ok and tostring(result) or ("ล้มเหลว " .. tostring(result)), upgradeSummary()))
	end })
end
UpgradeTab:CreateSlider({ name = "เว้นระยะการซื้อ (วินาที)", flag = "UpgradeInterval", range = { 1, 30 }, increment = 1, value = 3, callback = function(value) upgradeInterval = value end })
UpgradeTab:CreateButton({ name = "คัดลอกข้อมูล Upgrade (JSON)", callback = function()
	upgradeCatalog = upgradeCatalog or loadCatalog()
	refreshLevels()
	local function plain(value, depth)
		depth = depth or 0
		if type(value) ~= "table" or depth > 4 then
			local kind = typeof(value)
			if kind == "number" or kind == "boolean" or kind == "string" then return value end
			return tostring(value)
		end
		local copy = {}
		for key, item in pairs(value) do copy[tostring(key)] = plain(item, depth + 1) end
		return copy
	end
	inspectOutput = game:GetService("HttpService"):JSONEncode({
		coins = coins(), levels = plain(upgradeLevels), catalog = plain(upgradeCatalog),
	})
	if type(setclipboard) == "function" then pcall(setclipboard, inspectOutput) end
	upgradeStatus:Set("เตรียม JSON แล้ว (คัดลอกให้ถ้าตัวรันรองรับ) — หรือใช้ปุ่ม Export ในแท็บ Inspect")
end })

task.spawn(function()
	while true do
		local wanted = false
		for _, id in ipairs(UPGRADE_IDS) do wanted = wanted or autoUpgrade[id] end
		if wanted and not trainingActive then
			upgradeCatalog = upgradeCatalog or loadCatalog()
			local money = coins()
			for _, id in ipairs(UPGRADE_IDS) do
				if autoUpgrade[id] then
					local level = upgradeLevel(id)
					local cost = upgradeCost(id, level)
					if level >= upgradeMaxLevel(id) then
						-- MAX แล้วก็ปิดตัวเองซะ ไม่ต้องยิง remote ทิ้ง
						autoUpgrade[id] = false
						upgradeStatus:Set(("%s ถึง MAX แล้ว — ปิด auto ให้\n%s"):format(upgradeName(id), upgradeSummary()))
					elseif money and cost and money >= cost then
						upgradeLastBuy[id] = os.clock()
						local ok, result = buyUpgrade(id)
						upgradeStatus:Set(("ซื้อ %s (Lv.%d -> %d): %s\n%s"):format(
							upgradeName(id), level, upgradeLevel(id), ok and tostring(result) or "ล้มเหลว", upgradeSummary()))
						money = coins()
					elseif not cost and os.clock() - (upgradeLastBuy[id] or 0) > 10 then
						-- อ่านราคาไม่ได้ก็ลองซื้อห่าง ๆ
						upgradeLastBuy[id] = os.clock()
						buyUpgrade(id)
					end
				end
			end
			upgradeStatus:Set(upgradeSummary())
		end
		task.wait(wanted and upgradeInterval or 1)
	end
end)


-- ===== Train: พีระมิดที่สร้างเสร็จโผล่มาเมื่อไร ไปแช่น้ำอย่างเดียว =====
-- ตัวอย่าง: workspace.CompletedBasicPyramid.Decor.Pool.Water
local trainPool, trainStatus = false, nil
trainStatus = TrainTab:CreateText({ name = "Train", text = "เปิด Train Pool เพื่อรอพีระมิดที่สร้างเสร็จ แล้ววาร์ปไปแช่น้ำ" })

local function completedPyramid()
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("Model") and child.Name:match("^Completed.*Pyramid$") then return child end
	end
	return nil
end

-- Water เป็นได้ทั้ง Part และ Model จึงต้องหาตำแหน่งให้ครอบทั้งสองแบบ
local function waterPosition(item)
	if item:IsA("BasePart") then return item.Position end
	if item:IsA("Model") then
		local ok, cf = pcall(item.GetPivot, item)
		if ok and cf then return cf.Position end
		local part = item:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position
	end
	return nil
end

-- อยู่ในบ่อแล้วหรือยัง จะได้ไม่วาร์ปซ้ำทุกรอบจนตัวกระตุก
local function insideWater(item)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local cf, size
	if item:IsA("BasePart") then
		cf, size = item.CFrame, item.Size
	elseif item:IsA("Model") then
		local ok, modelCF, modelSize = pcall(item.GetBoundingBox, item)
		if not ok or not modelCF then return false end
		cf, size = modelCF, modelSize
	end
	if not cf then return false end
	local point = cf:PointToObjectSpace(root.Position)
	return math.abs(point.X) <= size.X / 2
		and math.abs(point.Y) <= size.Y / 2 + 3
		and math.abs(point.Z) <= size.Z / 2
end

-- ในพีระมิดมีบ่อน้ำได้หลายจุด (Decor.Pool / Structure.Interior.PoolRoom) เลือกอันที่ใกล้ตัวที่สุด
local function poolWater(model)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local best, bestPosition, bestDistance
	for _, item in ipairs(model:GetDescendants()) do
		if item.Name == "Water" then
			local position = waterPosition(item)
			if position then
				local distance = root and (position - root.Position).Magnitude or 0
				if not best or distance < bestDistance then
					best, bestPosition, bestDistance = item, position, distance
				end
			end
		end
	end
	return best, bestPosition
end

TrainTab:CreateToggle({ name = "Train Pool", flag = "TrainPool", value = false, description = "เจอ Completed*Pyramid เมื่อไร หยุดงานอื่นแล้ววาร์ปไปแช่น้ำจนกว่ามันจะหาย", callback = function(value)
	trainPool = value
	if not value then
		trainingActive = false
		trainStatus:Set("ปิด Train Pool")
	end
end })
TrainTab:CreateButton({ name = "เช็คตอนนี้ว่ามีพีระมิดที่เสร็จไหม", callback = function()
	local model = completedPyramid()
	local water, position = model and poolWater(model)
	trainStatus:Set(model
		and ("เจอ %s | น้ำ: %s"):format(model.Name, water
			and ("%s [%s] ที่ %.0f, %.0f, %.0f"):format(water:GetFullName(), water.ClassName, position.X, position.Y, position.Z)
			or "ไม่พบ Water")
		or "ยังไม่มีพีระมิดที่สร้างเสร็จใน workspace")
end })

task.spawn(function()
	while true do
		if trainPool then
			local model = completedPyramid()
			if not model then
				if trainingActive then
					trainingActive = false
					trainStatus:Set("พีระมิดหายไปแล้ว — กลับไปทำงานอื่นต่อ")
				end
			else
				local water, position = poolWater(model)
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if water and position and root then
					if not trainingActive then
						-- เพิ่งเริ่ม: ตัดตัวช่วยของโหมดพีระมิดออกก่อน ไม่งั้นมันดึงกันเอง
						trainingActive = true
						setHold(false)
						setFloat(false)
					end
					-- วาร์ปเฉพาะตอนยังไม่ถึง อยู่ในบ่อแล้วปล่อยให้ยืนเฉย ๆ ไม่งั้นตัวกระตุกตลอด
					local inWater = insideWater(water)
					if not inWater then root.CFrame = CFrame.new(position) end
					trainStatus:Set(("%s %s\n%s"):format(inWater and "กำลัง train ใน" or "กำลังไปที่บ่อของ", model.Name, water:GetFullName()))
				else
					trainStatus:Set(("เจอ %s แต่หา Water ไม่เจอ"):format(model.Name))
				end
			end
		elseif trainingActive then
			trainingActive = false
		end
		task.wait(trainingActive and 0.2 or 1)
	end
end)

SettingsTab:CreateToggle({ name = "Anti AFK", flag = "AntiAfk", value = false, callback = function(value) antiAfkEnabled = value end })

-- ===== Anti AFK ของเกมนี้: ยิง AFKService.Activity เองแทนการขยับจริง =====
-- AFKController ฝั่ง client ยิง signal นี้เมื่อมี input จริง ส่วน AFKPolicy ฝั่ง server
-- เอาเวลาที่ไม่มี activity ไปตัดสิน isAFK / shouldRejoin
local gameAntiAfk, afkStatus = false, nil
afkStatus = SettingsTab:CreateText({ name = "Anti AFK ของเกม", text = "ยิง AFKService.Activity ตามจังหวะที่ AFKConfig กำหนด" })

local function afkConfig()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local config = shared and shared:FindFirstChild("Config")
	local module = config and config:FindFirstChild("AFKConfig")
	if not module then return nil end
	local ok, data = pcall(require, module)
	return ok and type(data) == "table" and data or nil
end

local function afkService()
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local knitModule = packages and packages:FindFirstChild("Knit")
	if not knitModule then return nil end
	local ok, knit = pcall(require, knitModule)
	if not ok or type(knit) ~= "table" then return nil end
	local gotService, service = pcall(function() return knit.GetService("AFKService") end)
	return gotService and service or nil
end

local function fireActivity()
	local service = afkService()
	if not service or not service.Activity then return false, "ไม่พบ AFKService.Activity" end
	local ok, err = pcall(function() service.Activity:Fire() end)
	return ok, err
end

SettingsTab:CreateToggle({ name = "Anti AFK (ยิง Activity ให้เกม)", flag = "GameAntiAfk", value = false, description = "ใช้ระบบของเกมเอง ไม่ต้องขยับตัวจริง", callback = function(value)
	gameAntiAfk = value
	afkStatus:Set(value and "เปิดแล้ว — กำลังยิง Activity ให้เอง" or "ปิด Anti AFK ของเกม")
end })
SettingsTab:CreateButton({ name = "เช็คสถานะ AFK ตอนนี้", callback = function()
	local config = afkConfig()
	local attribute = config and config.AttributeName
	local flagged = attribute and player:GetAttribute(attribute)
	local ok, err = fireActivity()
	afkStatus:Set(("AFKService: %s\nattribute %s = %s\nรายงานทุก %s วิ | ติด AFK ที่ %s วิ | รีจอยน์ที่ %s วิ"):format(
		ok and "ยิง Activity สำเร็จ" or ("ยิงไม่ได้ — " .. tostring(err)),
		tostring(attribute or "?"), tostring(flagged),
		tostring(config and config.ActivityReportSeconds or "?"),
		tostring(config and config.TitleAfterSeconds or "?"),
		tostring(config and config.RejoinAfterSeconds or "?")))
end })

task.spawn(function()
	while true do
		local config = afkConfig()
		-- ยิงถี่กว่าที่เกมกำหนดนิดหน่อย จะได้ไม่มีช่วงที่เซิร์ฟเวอร์นับว่าเงียบ
		local interval = math.max(5, (tonumber(config and config.ActivityReportSeconds) or 30) * 0.5)
		if gameAntiAfk then
			local ok, err = fireActivity()
			local attribute = config and config.AttributeName
			afkStatus:Set(("%s | AFK flag: %s"):format(
				ok and "ยิง Activity แล้ว" or ("ยิงไม่ได้ — " .. tostring(err)),
				tostring(attribute and player:GetAttribute(attribute))))
		end
		task.wait(gameAntiAfk and interval or 5)
	end
end)

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
		autoRun = false
		table.clear(autoUpgrade)
		trainPool, trainingActive, gameAntiAfk = false, false, false
		setHold(false)
		setFloat(false)
		setNoclip(false)
		for _, connection in ipairs(listenConnections) do connection:Disconnect() end
		table.clear(listenConnections)
		inspectClosed, inspectCancel = true, true
		Window:Unload()
	end,
})

Tabs.Main:Select()

player.CharacterAdded:Connect(function(newCharacter)
	resetAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
end)
