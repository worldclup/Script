----------------------------------------------------------------
-- FPS BOOST (LOW GRAPHIC MODE)
----------------------------------------------------------------

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- 🔻 ตั้งค่า Roblox Engine
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- 🔻 Lighting
Lighting.GlobalShadows = false
Lighting.FogEnd = 1e10
Lighting.Brightness = 0
Lighting.ClockTime = 12
Lighting.OutdoorAmbient = Color3.new(1,1,1)
Lighting.Ambient = Color3.new(1,1,1)

-- ลบ Effect ทั้งหมด
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then
        v:Destroy()
    end
end

-- 🔻 ลดทุก Part ใน Map
for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
        v.CastShadow = false

    elseif v:IsA("Decal") or v:IsA("Texture") then
        v:Destroy()

    elseif v:IsA("ParticleEmitter")
        or v:IsA("Trail")
        or v:IsA("Beam")
        or v:IsA("Smoke")
        or v:IsA("Fire") then
        v.Enabled = false

    elseif v:IsA("MeshPart") then
        v.Material = Enum.Material.SmoothPlastic
        v.CastShadow = false
    end
end

-- 🔻 ปิด Effect ของ Character
local function OptimizeCharacter(char)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.CastShadow = false
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
    end
end

for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("MeshPart") then
        v.Transparency = 1
        v.CanCollide = false
    end
end

if player.Character then
    OptimizeCharacter(player.Character)
end
player.CharacterAdded:Connect(OptimizeCharacter)

-- 🔻 ลดงาน Render
RunService:Set3dRenderingEnabled(true)

-- 🔻 ลด Physics ที่ไม่จำเป็น
sethiddenproperty(player, "SimulationRadius", math.huge)
sethiddenproperty(player, "MaxSimulationRadius", math.huge)

print("[FPS BOOST] Low graphic mode enabled")
