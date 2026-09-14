local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

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
	name = "DEK DEV HUB", subtitle = "Universal",
	sidebarLayout = true, theme = "default", icon = "rbxassetid://134664151762829", showName = "DEK", showIcon = "rbxassetid://134664151762829", showIconOnly = true,
})
local Tabs = {
	Main = Window:CreateTab({ name = "Main" }),
	Inspect = Window:CreateTab({ name = "Inspect / Export" }),
	Settings = Window:CreateTab({ name = "Settings" }),
}
local MainTab, InspectTab, SettingsTab = Tabs.Main, Tabs.Inspect, Tabs.Settings

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
MainTab:CreateSlider({ name = "Walk Speed", flag = "WalkSpeed", range = { 16, 200 }, increment = 1, value = 50, callback = function(value) walkSpeed = value end })
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
