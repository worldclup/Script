-- 1. Loading Screen
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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

local Window = WindUI:CreateWindow({
	Title = "DEK DEV HUB", Author = "Universal", Folder = "Dek_Dev_Hub_Universal", Icon = "zap", Theme = "Dark",
	OpenButton = { Title = "DEK", CornerRadius = UDim.new(0, 16), StrokeThickness = 2, Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#2f9fff")), Enabled = true, Draggable = true, OnlyMobile = false, Position = UDim2.new(0, 10, 0, 150) },
	Topbar = { Height = 44, ButtonsType = "Mac" },
})
Window:SetToggleKey(Enum.KeyCode.RightControl)

local MainTab = Window:Tab({ Title = "Main", Icon = "zap" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

MainTab:Toggle({
	Title = "Speed", Default = false,
	Callback = function(value)
		speedEnabled = value
		humanoid.WalkSpeed = value and walkSpeed or normalSpeed
	end,
})
MainTab:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 200, Default = 50 }, Callback = function(value) walkSpeed = value end })
MainTab:Toggle({
	Title = "High Jump", Default = false,
	Callback = function(value)
		jumpEnabled = value
		humanoid.UseJumpPower = value and true or normalUseJumpPower
		humanoid.JumpPower = value and jumpPower or normalJumpPower
	end,
})
MainTab:Slider({ Title = "Jump Power", Step = 5, Value = { Min = 50, Max = 300, Default = 100 }, Callback = function(value) jumpPower = value end })
MainTab:Toggle({ Title = "Fly", Default = false, Callback = function(value) flyEnabled = value; setFly(value) end })
MainTab:Slider({ Title = "Fly Speed", Step = 5, Value = { Min = 10, Max = 200, Default = 50 }, Callback = function(value) flySpeed = value end })
MainTab:Slider({
	Title = "Fly Height", Step = 1, Value = { Min = 5, Max = 200, Default = 15 },
	Callback = function(value)
		if flyEnabled and hoverY then hoverY = hoverY + value - flyHeight end
		flyHeight = value
	end,
})

SettingsTab:Toggle({ Title = "Anti AFK", Default = false, Callback = function(value) antiAfkEnabled = value end })
SettingsTab:Button({
	Title = "Boost FPS", Icon = "zap", Color = Color3.fromHex("#30FF6A"),
	Callback = function()
		_G.Settings = { Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true }, Meshes = { NoMesh = false, NoTexture = false, Destroy = false }, Images = { Invisible = true, Destroy = false }, Explosions = { Smaller = true, Invisible = false, Destroy = false }, Particles = { Invisible = true, Destroy = false }, TextLabels = { LowerQuality = true, Invisible = false, Destroy = false }, MeshParts = { LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false }, Other = { ["FPS Cap"] = 360, ["No Camera Effects"] = true, ["No Clothes"] = true, ["Low Water Graphics"] = true, ["No Shadows"] = true, ["Low Rendering"] = true, ["Low Quality Parts"] = true, ["Low Quality Models"] = true, ["Reset Materials"] = true } }
		loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
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
	resetAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
end)
