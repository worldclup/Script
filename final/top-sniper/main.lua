-- 1. Loading Screen
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local botEspEnabled, playerEspEnabled, aimEnabled, silentAimEnabled = false, false, false, false
local aimFov, fovCircleEnabled = 250, false
local aimPartName = "Head"
local captureUntil, captureCount = 0, 0
local highlights, aimTarget = {}, nil
local espLabels, tracers = {}, {}
local showNames, showDistances, tracersEnabled = false, false, false
local fovCircle = Drawing and Drawing.new("Circle")

if fovCircle then
	fovCircle.Color = Color3.fromRGB(48, 255, 106)
	fovCircle.Thickness, fovCircle.Filled, fovCircle.Transparency, fovCircle.Visible = 2, false, 0.8, false
end

local function getBotFolder()
	local battleArea = workspace:FindFirstChild("BattleArea")
	local mapRoot = battleArea and battleArea:FindFirstChild("MapRootModel")
	return mapRoot and mapRoot:FindFirstChild("BotFolder")
end

local function isValidTarget(model)
	if not model:IsA("Model") or model == character then return false end
	local humanoid, head = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("Head")
	return humanoid and humanoid.Health > 0 and head and head:IsA("BasePart")
end

local function getTargets()
	local targets, botFolder = {}, getBotFolder()
	if botFolder then
		for _, model in ipairs(botFolder:GetChildren()) do
			if isValidTarget(model) then table.insert(targets, { model = model, isBot = true }) end
		end
	end
	for _, model in ipairs(workspace:GetChildren()) do
		if Players:GetPlayerFromCharacter(model) and isValidTarget(model) then
			table.insert(targets, { model = model, isBot = false })
		end
	end
	return targets
end

local function getClosestTarget()
	local camera, center = workspace.CurrentCamera, workspace.CurrentCamera.ViewportSize / 2
	local closest, closestDistance
	for _, target in ipairs(getTargets()) do
		local position, visible = camera:WorldToViewportPoint(target.model.Head.Position)
		if visible then
			local distance = (Vector2.new(position.X, position.Y) - center).Magnitude
			if distance <= aimFov and (not closestDistance or distance < closestDistance) then
				closest, closestDistance = target, distance
			end
		end
	end
	return closest
end

local function getAimPart(model)
	if aimPartName == "Body" then
		return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart") or model.Head
	end
	return model.Head
end

local function updateESP()
	for model, highlight in pairs(highlights) do
		if not model.Parent or not isValidTarget(model) then
			highlight:Destroy()
			highlights[model] = nil
		end
	end
	for _, target in ipairs(getTargets()) do
		local enabled = target.isBot and botEspEnabled or playerEspEnabled
		if enabled and not highlights[target.model] then
			local highlight = Instance.new("Highlight")
			highlight.Name, highlight.Adornee = "DEK_ESP", target.model
			highlight.FillColor = target.isBot and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(255, 70, 70)
			highlight.FillTransparency, highlight.OutlineColor = 0.55, Color3.new(1, 1, 1)
			highlight.DepthMode, highlight.Parent = Enum.HighlightDepthMode.AlwaysOnTop, workspace
			highlights[target.model] = highlight
		elseif not enabled and highlights[target.model] then
			highlights[target.model]:Destroy()
			highlights[target.model] = nil
		end
	end
end

local function getTargetName(target)
	local targetPlayer = Players:GetPlayerFromCharacter(target.model)
	return targetPlayer and targetPlayer.Name or target.model.Name
end

local function updateLabels()
	local active = {}
	for _, target in ipairs(getTargets()) do
		local enabled = target.isBot and botEspEnabled or playerEspEnabled
		if enabled and (showNames or showDistances) then
			active[target.model] = true
			local label = espLabels[target.model]
			if not label then
				label = Instance.new("BillboardGui")
				label.Name = "DEK_ESP_Label"
				label.Size = UDim2.fromOffset(180, 42)
				label.StudsOffset = Vector3.new(0, 3, 0)
				label.AlwaysOnTop = true
				local text = Instance.new("TextLabel")
				text.Name = "Text"
				text.Size = UDim2.fromScale(1, 1)
				text.BackgroundTransparency = 1
				text.TextColor3, text.TextStrokeTransparency = Color3.new(1, 1, 1), 0
				text.TextSize, text.Font = 14, Enum.Font.GothamBold
				text.Parent = label
				label.Parent = workspace
				espLabels[target.model] = label
			end
			label.Adornee = target.model.Head
			local lines = {}
			if showNames then table.insert(lines, getTargetName(target)) end
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if showDistances and rootPart then table.insert(lines, ("%dm"):format((rootPart.Position - target.model.Head.Position).Magnitude)) end
			label.Text.Text = table.concat(lines, "\n")
		end
	end
	for model, label in pairs(espLabels) do
		if not active[model] then
			label:Destroy()
			espLabels[model] = nil
		end
	end
end

local function updateTracers(camera)
	local active = {}
	if tracersEnabled and Drawing then
		for _, target in ipairs(getTargets()) do
			local enabled = target.isBot and botEspEnabled or playerEspEnabled
			local position, visible = camera:WorldToViewportPoint(target.model.Head.Position)
			if enabled and visible then
				active[target.model] = true
				local line = tracers[target.model]
				if not line then
					line = Drawing.new("Line")
					line.Thickness, line.Transparency = 1.5, 0.8
					line.Color = target.isBot and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(255, 70, 70)
					tracers[target.model] = line
				end
				line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				line.To, line.Visible = Vector2.new(position.X, position.Y), true
			end
		end
	end
	for model, line in pairs(tracers) do
		if not active[model] then
			line:Remove()
			tracers[model] = nil
		end
	end
end

local function formatArg(value, depth)
	depth = depth or 0
	if typeof(value) == "Instance" then return value:GetFullName() end
	if typeof(value) == "table" then
		if depth >= 2 then return "{...}" end
		local items = {}
		for key, item in pairs(value) do
			table.insert(items, ("[%s] = %s"):format(formatArg(key, depth + 1), formatArg(item, depth + 1)))
			if #items == 12 then break end
		end
		return "{ " .. table.concat(items, ", ") .. " }"
	end
	return tostring(value)
end

local RemoteManager = require(ReplicatedStorage.GameManager.RemoteManager)

if type(hookfunction) == "function" and type(newcclosure) == "function" then
	local oldDispatchEvent
	oldDispatchEvent = hookfunction(RemoteManager.DispatchEvent, newcclosure(function(self, eventId, recipient, ...)
		local args = table.pack(...)
		if os.clock() < captureUntil and captureCount < 30 then
			captureCount = captureCount + 1
			print("[Top Sniper Capture]", captureCount, "DispatchEvent", eventId)
			for index = 1, args.n do print(("  [%d] = %s"):format(index, formatArg(args[index]))) end
		end
		if silentAimEnabled and eventId == 1017 and recipient == nil and type(args[1]) == "table" then
			local target = aimTarget
			local hit = target and args[1][1]
			if hit and isValidTarget(target.model) then
				local hitPart = getAimPart(target.model)
				hit.instance = hitPart
				hit.taggedHumanoid = target.model:FindFirstChildOfClass("Humanoid")
				hit.position = hitPart.Position
			end
		end
		return oldDispatchEvent(self, eventId, recipient, table.unpack(args, 1, args.n))
	end))
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if fovCircle then
		fovCircle.Position, fovCircle.Radius, fovCircle.Visible = camera.ViewportSize / 2, aimFov, fovCircleEnabled
	end
	aimTarget = (aimEnabled or silentAimEnabled) and getClosestTarget() or nil
	updateTracers(camera)
end)

task.spawn(function()
	while true do
		updateESP()
		updateLabels()
		task.wait(1)
	end
end)

local function resetAll()
	botEspEnabled, playerEspEnabled, aimEnabled, silentAimEnabled, aimTarget, fovCircleEnabled = false, false, false, false, nil, false
	showNames, showDistances, tracersEnabled = false, false, false
	updateESP()
	updateLabels()
end

local Window = WindUI:CreateWindow({
	Title = "DEK DEV HUB", Author = "Top Sniper", Folder = "Dek_Dev_Hub_Top_Sniper", Icon = "crosshair", Theme = "Dark",
	OpenButton = { Title = "DEK", CornerRadius = UDim.new(0, 16), StrokeThickness = 2, Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#2f9fff")), Enabled = true, Draggable = true, OnlyMobile = false, Position = UDim2.new(0, 10, 0, 150) },
	Topbar = { Height = 44, ButtonsType = "Mac" },
})
Window:SetToggleKey(Enum.KeyCode.RightControl)

local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

CombatTab:Button({
	Title = "Capture Shoot Remote (10 seconds)", Icon = "radio",
	Callback = function()
		captureCount, captureUntil = 0, os.clock() + 10
		WindUI:Notify({ Title = "Remote Capture", Content = "ยิงปกติ 1 นัดภายใน 10 วินาที แล้วดู Console", Duration = 5 })
	end,
})
CombatTab:Toggle({ Title = "Aim Target", Desc = "เลือกเป้าในวง FOV สำหรับตรวจ protocol ยิง", Default = false, Callback = function(value) aimEnabled = value end })
CombatTab:Toggle({ Title = "Silent Aim", Desc = "แก้ hit ของ Remote 1017 ไปที่ Head ในวง FOV", Default = false, Callback = function(value) silentAimEnabled = value end })
CombatTab:Dropdown({
	Title = "Aim Part", Values = { "Head", "Body" }, Multi = false, Default = "Head",
	Callback = function(value) aimPartName = value end,
})
CombatTab:Slider({ Title = "Aim FOV (pixels)", Step = 10, Value = { Min = 50, Max = 600, Default = 250 }, Callback = function(value) aimFov = value end })
CombatTab:Toggle({ Title = "Show Aim FOV Circle", Default = false, Callback = function(value) fovCircleEnabled = value end })

VisualsTab:Toggle({
	Title = "Bot ESP", Desc = "สีส้ม: BotFolder", Default = false,
	Callback = function(value)
		botEspEnabled = value
		updateESP()
	end,
})
VisualsTab:Toggle({
	Title = "Show Name", Default = false,
	Callback = function(value)
		showNames = value
		updateLabels()
	end,
})
VisualsTab:Toggle({
	Title = "Show Distance", Default = false,
	Callback = function(value)
		showDistances = value
		updateLabels()
	end,
})
VisualsTab:Toggle({
	Title = "Tracers", Desc = "เส้นจากล่างจอไปยังหัวเป้า", Default = false,
	Callback = function(value) tracersEnabled = value end,
})
VisualsTab:Toggle({
	Title = "Player ESP", Desc = "สีแดง: ผู้เล่นใน Workspace", Default = false,
	Callback = function(value)
		playerEspEnabled = value
		updateESP()
	end,
})

SettingsTab:Button({
	Title = "Stop All & Close UI", Icon = "circle-x", Color = Color3.fromHex("#ff4830"),
	Callback = function()
		resetAll()
		Window:Destroy()
	end,
})

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
end)
