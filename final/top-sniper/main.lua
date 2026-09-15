local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

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
	local selectedPart = aimPartName
	if selectedPart == "Random" then
		selectedPart = math.random(1, 2) == 1 and "Head" or "Body"
	end
	if selectedPart == "Body" then
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
			highlight.FillColor = target.isBot and Color3.fromRGB(210, 105, 0) or Color3.fromRGB(190, 25, 25)
			highlight.FillTransparency, highlight.OutlineColor, highlight.OutlineTransparency = 0.25, Color3.new(1, 1, 1), 0.35
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

local Window = Rayfield:CreateWindow({
	name = "DEK DEV HUB", subtitle = "Top Sniper", sidebarLayout = true, theme = "default",
	icon = "rbxassetid://134664151762829", showName = "DEK", showIcon = "rbxassetid://134664151762829", showIconOnly = true,
})
local Tabs = {
	Combat = Window:CreateTab({ name = "Combat" }),
	Visuals = Window:CreateTab({ name = "Visuals" }),
	Settings = Window:CreateTab({ name = "Settings" }),
}

Tabs.Combat:CreateSection({ name = "Remote Tools" })
Tabs.Combat:CreateButton({ name = "Capture Shoot Remote (10 seconds)", callback = function()
	captureCount, captureUntil = 0, os.clock() + 10
	Rayfield:Notify({ Title = "Remote Capture", Content = "Fire one normal shot within 10 seconds, then check the console.", Duration = 5 })
end })
Tabs.Combat:CreateSection({ name = "Aim Assistance" })
Tabs.Combat:CreateToggle({ name = "Aim Target", flag = "AimTarget", value = false, description = "Selects the closest target inside the FOV.", callback = function(value) aimEnabled = value end })
Tabs.Combat:CreateToggle({ name = "Silent Aim", flag = "SilentAim", value = false, description = "Redirects Remote 1017 hits to the selected aim part.", callback = function(value) silentAimEnabled = value end })
Tabs.Combat:CreateDropdown({ name = "Aim Part", flag = "AimPart", options = { "Head", "Body", "Random" }, default = "Head", callback = function(value) aimPartName = value end })
Tabs.Combat:CreateSlider({ name = "Aim FOV (pixels)", flag = "AimFov", value = 250, range = { 50, 600 }, increment = 10, callback = function(value) aimFov = value end })
Tabs.Combat:CreateToggle({ name = "Show Aim FOV Circle", flag = "AimFovCircle", value = false, callback = function(value) fovCircleEnabled = value end })

Tabs.Visuals:CreateSection({ name = "Target Types" })
Tabs.Visuals:CreateToggle({ name = "Bot ESP", flag = "BotEsp", value = false, description = "Orange: BotFolder", callback = function(value) botEspEnabled = value; updateESP() end })
Tabs.Visuals:CreateToggle({ name = "Player ESP", flag = "PlayerEsp", value = false, description = "Red: players in Workspace", callback = function(value) playerEspEnabled = value; updateESP() end })
Tabs.Visuals:CreateSection({ name = "Labels" })
Tabs.Visuals:CreateToggle({ name = "Show Name", flag = "ShowName", value = false, callback = function(value) showNames = value; updateLabels() end })
Tabs.Visuals:CreateToggle({ name = "Show Distance", flag = "ShowDistance", value = false, callback = function(value) showDistances = value; updateLabels() end })
Tabs.Visuals:CreateSection({ name = "Screen Indicators" })
Tabs.Visuals:CreateToggle({ name = "Tracers", flag = "Tracers", value = false, description = "Lines from the bottom of the screen to each target.", callback = function(value) tracersEnabled = value end })

Tabs.Settings:CreateButton({ name = "Stop All & Close UI", callback = function() resetAll(); Window:Unload() end })
Tabs.Combat:Select()

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
end)
