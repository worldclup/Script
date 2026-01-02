local queue_on_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)

if queue_on_teleport then
    -- ใส่ Link สคริปต์ของคุณที่นี่ (ถ้าใช้ GitHub/Pastebin) 
    -- หรือถ้าเป็นโค้ดสด ให้ใช้การเก็บโค้ดลงไฟล์แล้วรันใหม่
    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/dungeon-hunter/main.lua", true))()]])
end

-- 2. รอจนกว่าเกมจะโหลดเสร็จสมบูรณ์
if not game:IsLoaded() then
    game.Loaded:Wait()
end
------------------------------------------------------------------------------------
--- Color
------------------------------------------------------------------------------------
local Mythic    = Color3.fromHex("#FF3B3B") -- แดงเพลิง (มายา)
------------------------------------------------------------------------------------
--- Game
------------------------------------------------------------------------------------
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Workspace = game:GetService("Workspace");
------------------------------------------------------------------------------------
--- Module
------------------------------------------------------------------------------------
-- local ConfigsPath = ReplicatedStorage.Scripts.Configs;

------------------------------------------------------------------------------------
--- Game Script
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--- Window UI
------------------------------------------------------------------------------------
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
local UI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = UI:CreateWindow({
    -- Title = "🅳🅴🅺 🅳🅴🆅 🅷🆄🅱",
    Title = "DEK DEV HUB", -- "🅳🅴🅺 🅳🅴🆅 🅷🆄🅱",
	-- Icon = "keyboard",
	SideBarWidth = 150,
	Theme = "Dark", -- Dark, Darker, Light, Aqua, Amethyst, Rose
	Size = UDim2.fromOffset(400, 300),
	MinSize = Vector2.new(400, 300),
    MaxSize = Vector2.new(400, 300),
    -- Theme = "Light",
    NewElements = true,
	-- Topbar = {
	-- 	Height = 44,
	-- 	ButtonsType = "Mac", -- Default or Mac
	-- },
	OpenButton = {
		Title = "DEK",
		CornerRadius = UDim.new(0, 16),
		StrokeThickness = 2,
		Color = ColorSequence.new(Color3.fromHex("#FFFFFF"), Color3.fromHex("#FFFFFF")),
		OnlyMobile = false,
		Enabled = true,
		Draggable = true,
        Position = UDim2.new(0, 8, 0, 80),
	},
})
------------------------------------------------------------------------------------
--- Variables & Settings
------------------------------------------------------------------------------------
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local degree = 0
local orbitDistance = 7 -- ระยะห่างจากมอนสเตอร์
local orbitSpeed = 2    -- ความเร็วในการหมุน

local State = {
    AutoFarm = false,
};

Window:OnDestroy(function()
	State.AutoFarm = false;
end);

------------------------------------------------------------------------------------
--- Helper Functions
------------------------------------------------------------------------------------

-- ฟังก์ชันหาห้องที่ใกล้ที่สุด
local function GetCurrentRoom(myHrp)
    local sandbox = workspace:FindFirstChild("SandboxPlayFolder")
    if not sandbox or not myHrp then return nil end

    local closestRoom = nil
    local shortestDistance = math.huge

    for _, room in pairs(sandbox:GetChildren()) do
        local success, roomPos = pcall(function() return room:GetModelCFrame().Position end)
        if success then
            local distance = (myHrp.Position - roomPos).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestRoom = room
            end
        end
    end
    return closestRoom
end
------------------------------------------------------------------------------------
--- Helper Functions (Updated)
------------------------------------------------------------------------------------

-- ฟังก์ชันโจมตีแบบกดค้าง
local function AutoAttack(targetMonster)
    -- ส่งเฉพาะเหตุการณ์กดปุ่มค้างไว้ (true)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)

    -- กดสกิล Q, E, R แบบรวดเร็ว
    local keys = {Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R}
    for _, key in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

local function HandleNextStage(currentRoom, myHrp)
    local voteDoorFolder = currentRoom:FindFirstChild("VoteDoor")
    if not voteDoorFolder then return end

    for _, door in pairs(voteDoorFolder:GetChildren()) do
        if not door:FindFirstChild("UnlockDoor") then
            local targetVfx = door:FindFirstChild("UnlockVfx")
            if targetVfx then
                -- 1. หยุดตัวละครและล็อคไว้ชั่วคราวกันตกแมพ
                myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                myHrp.Anchored = true 

                local doorCFrame = targetVfx:IsA("BasePart") and targetVfx.CFrame or targetVfx:GetModelCFrame()
                local backDist = 6 -- เพิ่มระยะถอยอีกนิด
                local heightOffset = 2 
                
                local targetPosition = doorCFrame.Position - (doorCFrame.LookVector * backDist) + Vector3.new(0, heightOffset, 0)
                myHrp.CFrame = CFrame.lookAt(targetPosition, doorCFrame.Position)
                
                task.wait(0.5) -- รอให้ตำแหน่งนิ่ง
                
                -- 2. กด F เพื่อเข้าประตู
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                
                task.wait(1)
                myHrp.Anchored = false -- ปลดล็อคตัวละคร
                break
            end
        end
    end
end

------------------------------------------------------------------------------------
--- Main Logic (Updated)
------------------------------------------------------------------------------------
local function LogicAuto()
    while State.AutoFarm do
        if not State.AutoFarm then break end
        
        pcall(function()
            local activationFolder = Workspace:FindFirstChild("Creature") and Workspace.Creature:FindFirstChild("Activation")
            if not activationFolder then return end

            local myHrp, myHum
            for _, folderID in pairs(activationFolder:GetChildren()) do
                local playerModel = folderID:FindFirstChild(LocalPlayer.Name)
                if playerModel then
                    myHrp = playerModel:FindFirstChild("HumanoidRootPart")
                    myHum = playerModel:FindFirstChild("Humanoid")
                    break
                end
            end

            if not myHrp or (myHum and myHum.Health <= 0) then return end

            -- 2. ค้นหามอนสเตอร์และ Chest
            local targetMonster = nil
            local monstersLeft = 0
            
            for _, folderID in pairs(activationFolder:GetChildren()) do
                for _, child in pairs(folderID:GetChildren()) do
                    local name = child.Name:lower()
                    -- เช็คทั้ง Monster, Boss และ Chest
                    if name:find("monster") or name:find("boss") or name:find("chest") then 
                        local hum = child:FindFirstChild("Humanoid")
                        local mHrp = child:FindFirstChild("HumanoidRootPart")
                        
                        -- ถ้าเป็น Chest อาจไม่มี Humanoid ให้เช็คแค่ mHrp
                        if mHrp and (not hum or hum.Health > 0) then
                            targetMonster = child
                            monstersLeft = monstersLeft + 1
                        end
                    end
                end
            end

            -- 3. ระบบตัดสินใจ
            if targetMonster then
                local mHrp = targetMonster:FindFirstChild("HumanoidRootPart")
                if mHrp then
                    local enemyPos = mHrp.Position
                    local heightAbove = 15
                    local targetPosition = enemyPos + Vector3.new(0, heightAbove, 0)

                    myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    myHrp.CFrame = CFrame.lookAt(targetPosition, enemyPos)
                    
                    -- เรียกฟังก์ชันตี (ซึ่งตอนนี้กดค้างไว้)
                    AutoAttack(targetMonster)
                end
            elseif monstersLeft == 0 then
                -- ปล่อยปุ่มเมาส์เมื่อไม่มีมอนสเตอร์
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                
                myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                local currentRoom = GetCurrentRoom(myHrp)
                if currentRoom then
                    HandleNextStage(currentRoom, myHrp)
                end
                task.wait(1) 
            end
        end)
        
        RunService.Heartbeat:Wait()
    end
    -- ปล่อยปุ่มเมาส์หากปิดสคริปต์
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local AutoTab = Window:Tab({
	Title = "Auto Kill",
	Icon = "swords",
    IconColor = Mythic,
	IconShape = "Square",
});

AutoTab:Toggle({
	Title = "Auto Kill",
    -- Desc = "Automatically kill all monster",
	Callback = function(val)
		State.AutoFarm = val;
		if val then
			task.spawn(LogicAuto);
		end;
	end
});
----------------------------------------------------------------
-- FPS BOOST
----------------------------------------------------------------
local function BoostFps()

	_G.Ignore = {}
	_G.Settings = {
		Players = {
			["Ignore Me"] = true,
			["Ignore Others"] = true,
			["Ignore Tools"] = true
		},
		Meshes = {
			NoMesh = false,
			NoTexture = false,
			Destroy = false
		},
		Images = {
			Invisible = true,
			Destroy = false
		},
		Explosions = {
			Smaller = true,
			Invisible = false, -- Not for PVP games
			Destroy = false -- Not for PVP games
		},
		Particles = {
			Invisible = true,
			Destroy = false
		},
		TextLabels = {
			LowerQuality = true,
			Invisible = false,
			Destroy = false
		},
		MeshParts = {
			LowerQuality = true,
			Invisible = false,
			NoTexture = false,
			NoMesh = false,
			Destroy = false
		},
		Other = {
			["FPS Cap"] = 360, -- true to uncap
			["No Camera Effects"] = true,
			["No Clothes"] = true,
			["Low Water Graphics"] = true,
			["No Shadows"] = true,
			["Low Rendering"] = true,
			["Low Quality Parts"] = true,
			["Low Quality Models"] = true,
			["Reset Materials"] = true,
		}
	}
	loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
end
----------------------------------------------------------------
-- Button Boost FPS
----------------------------------------------------------------
AutoTab:Button({
	Title = "Boost FPS (Low Graphics)",
	Icon = "rocket",
	Callback = function()
		BoostFps()
	end
})

Window:SelectTab(1);