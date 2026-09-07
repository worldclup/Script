-- 1. Loading Screen
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local silentAimEnabled = false
local espEnabled = false
local aimFov = 250
local fovCircleEnabled = false
local fovCircle = Drawing and Drawing.new("Circle")
local espHighlights = {}
local espLabels = {}
local showName = false
local showDistance = false
local shootCaptureUntil = 0
local silentTarget

if fovCircle then
	fovCircle.Color = Color3.fromRGB(48, 255, 106)
	fovCircle.Thickness = 2
	fovCircle.Filled = false
	fovCircle.Transparency = 0.8
	fovCircle.Visible = false
end

local function isTarget(model)
	if not model:IsA("Model") or model == character then return false end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local head = model:FindFirstChild("Head")
	return humanoid and humanoid.Health > 0 and head and head:IsA("BasePart")
end

local function getTargets()
	local targets = {}
	for _, model in ipairs(workspace:GetChildren()) do
		if isTarget(model) then table.insert(targets, model) end
	end
	return targets
end

local function getClosestTarget()
	local camera = workspace.CurrentCamera
	local center = camera.ViewportSize / 2
	local closest, closestDistance
	for _, model in ipairs(getTargets()) do
		local position, visible = camera:WorldToViewportPoint(model.Head.Position)
		if visible then
			local distance = (Vector2.new(position.X, position.Y) - center).Magnitude
			if distance <= aimFov and (not closestDistance or distance < closestDistance) then
				closest, closestDistance = model, distance
			end
		end
	end
	return closest
end

local function formatShootArg(value)
	if typeof(value) == "Instance" then return value:GetFullName() end
	return tostring(value)
end

local networkRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Packages")
	:WaitForChild("Network"):WaitForChild("NetworkRemote")
local Mouse = require(ReplicatedStorage.Modules.Packages.Mouse)

if type(hookfunction) == "function" then
	local oldGetMousePos
	oldGetMousePos = hookfunction(Mouse.GetMousePos, newcclosure(function(...)
		local target = silentTarget
		if silentAimEnabled and target and isTarget(target) then
			local hitPart = target:FindFirstChild("BodyHitbox", true) or target.Head
			return hitPart.Position
		end
		return oldGetMousePos(...)
	end))
end

if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(getnamecallmethod) == "function" then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local args = table.pack(...)
		local method = getnamecallmethod()
		if os.clock() < shootCaptureUntil and self == networkRemote and method == "FireServer" and args[1] == "Shoot" then
			print("[Shoot Capture]", self:GetFullName())
			for index = 1, args.n do print(("  [%d] = %s"):format(index, formatShootArg(args[index]))) end
		end
		return oldNamecall(self, table.unpack(args, 1, args.n))
	end))
end

local function updateESP()
	for model, highlight in pairs(espHighlights) do
		if not espEnabled or not model.Parent or not isTarget(model) then
			highlight:Destroy()
			espHighlights[model] = nil
		end
	end
	for model, label in pairs(espLabels) do
		if not espEnabled or not model.Parent or not isTarget(model) or not (showName or showDistance) then
			label:Destroy()
			espLabels[model] = nil
		end
	end
	if not espEnabled then return end

	for _, model in ipairs(getTargets()) do
		if not espHighlights[model] then
			local highlight = Instance.new("Highlight")
			highlight.Name = "DEK_ESP"
			highlight.Adornee = model
			highlight.FillColor = Color3.fromRGB(255, 70, 70)
			highlight.FillTransparency = 0.55
			highlight.OutlineColor = Color3.new(1, 1, 1)
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = workspace
			espHighlights[model] = highlight
		end
		if showName or showDistance then
			local label = espLabels[model]
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
				text.TextColor3 = Color3.new(1, 1, 1)
				text.TextStrokeTransparency = 0
				text.TextSize = 14
				text.Font = Enum.Font.GothamBold
				text.Parent = label
				label.Parent = workspace
				espLabels[model] = label
			end
			local part = model:FindFirstChild("Head") or model.PrimaryPart
			label.Adornee = part
			local lines = {}
			if showName then table.insert(lines, model.Name) end
			if showDistance and part and character:FindFirstChild("HumanoidRootPart") then
				table.insert(lines, ("%dm"):format((character.HumanoidRootPart.Position - part.Position).Magnitude))
			end
			label.Text.Text = table.concat(lines, "\n")
		end
	end

end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if fovCircle then
		fovCircle.Position = camera.ViewportSize / 2
		fovCircle.Radius = aimFov
		fovCircle.Visible = fovCircleEnabled
	end
	silentTarget = silentAimEnabled and getClosestTarget() or nil
end)

task.spawn(function()
	while true do
		updateESP()
		task.wait(1)
	end
end)

local function resetAll()
	silentAimEnabled = false
	silentTarget = nil
	espEnabled = false
	showName = false
	showDistance = false
	fovCircleEnabled = false
	updateESP()
end

local Window = WindUI:CreateWindow({
	Title = "DEK DEV HUB",
	Author = "Deagle Arena",
	Folder = "Dek_Dev_Hub_Deagle_Arena",
	Icon = "crosshair",
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
})

Window:SetToggleKey(Enum.KeyCode.RightControl)

local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

CombatTab:Button({
	Title = "Capture Shoot Remote (10 seconds)",
	Icon = "radio",
	Callback = function()
		shootCaptureUntil = os.clock() + 10
		WindUI:Notify({ Title = "Shoot Capture", Content = "ยิงโดนผู้เล่นจริง 1 นัดภายใน 10 วินาที แล้วดู Console", Duration = 5 })
	end,
})

CombatTab:Toggle({
	Title = "Silent Aim",
	Desc = "ยิง Head ในวง FOV โดยไม่หมุนกล้อง",
	Default = false,
	Callback = function(value) silentAimEnabled = value end,
})

CombatTab:Slider({
	Title = "Aim FOV (pixels)",
	Step = 10,
	Value = { Min = 50, Max = 600, Default = 250 },
	Callback = function(value) aimFov = value end,
})

CombatTab:Toggle({
	Title = "Show Aim FOV Circle",
	Default = false,
	Callback = function(value) fovCircleEnabled = value end,
})

VisualsTab:Toggle({
	Title = "Player ESP",
	Desc = "แสดงเฉพาะ Model ที่มี Humanoid",
	Default = false,
	Callback = function(value)
		espEnabled = value
		updateESP()
	end,
})

VisualsTab:Toggle({
	Title = "Show Name",
	Default = false,
	Callback = function(value)
		showName = value
		updateESP()
	end,
})

VisualsTab:Toggle({
	Title = "Show Distance",
	Default = false,
	Callback = function(value)
		showDistance = value
		updateESP()
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
	character = newCharacter
end)
