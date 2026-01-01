------------------------------------------------------------------------------------
--- Color
------------------------------------------------------------------------------------
local Purple    = Color3.fromHex("#7775F2")
local Yellow    = Color3.fromHex("#ECA201")
local Green     = Color3.fromHex("#10C550")
local Grey      = Color3.fromHex("#83889E")
local Blue      = Color3.fromHex("#257AF7")
local Red       = Color3.fromHex("#EF4F1D")

local Common    = Color3.fromHex("#BCC1C5") -- เทาอ่อน (ทั่วไป)
local Rare      = Color3.fromHex("#3692FF") -- ฟ้าสดใส (หายาก)
local Epic      = Color3.fromHex("#9D5CFF") -- ม่วงเข้ม (เอปิก)
local Legendary = Color3.fromHex("#FFAC38") -- ส้มทอง (ตำนาน)
local Mythic    = Color3.fromHex("#FF3B3B") -- แดงเพลิง (มายา)
local Divine    = Color3.fromHex("#FFD700") -- ทองสว่าง (เทพเจ้า)
local Special   = Color3.fromHex("#00FFC3") -- เขียวมิ้นท์สว่าง (พิเศษ)

local Success = Color3.fromHex("#27E181") -- เขียวสว่าง (สำเร็จ)
local Warning = Color3.fromHex("#F7D547") -- เหลืองอำพัน (เตือน)
local Error   = Color3.fromHex("#FF4D4D") -- แดงสว่าง (ผิดพลาด)
local Info    = Color3.fromHex("#00D1FF") -- ฟ้าอ่อน (ข้อมูล)
local Neutral = Color3.fromHex("#E0E0E0") -- ขาวนวล (ปกติ)

local NeonPink   = Color3.fromHex("#FF00D4")
local NeonBlue   = Color3.fromHex("#00F0FF")
local NeonGreen  = Color3.fromHex("#ADFF2F")
local SoftPurple = Color3.fromHex("#C3B1E1")
local DeepSea    = Color3.fromHex("#124076")
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
--- All Key
------------------------------------------------------------------------------------
local hrp
local State = {
	AutoFarm = false,
};

------------------------------------------------------------------------------------
--- Window UI
------------------------------------------------------------------------------------
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()
local UI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = UI:CreateWindow({
    -- Title = "🅳🅴🅺 🅳🅴🆅 🅷🆄🅱",
    Title = "DEK DEV HUB", -- "🅳🅴🅺 🅳🅴🆅 🅷🆄🅱",
	-- Icon = "keyboard",
	SideBarWidth = 200,
	Theme = "Dark", -- Dark, Darker, Light, Aqua, Amethyst, Rose
	Size = UDim2.fromOffset(800, 400),
	MinSize = Vector2.new(800, 400),
    MaxSize = Vector2.new(800, 400),
    -- NewElements = true,
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

-- ฟังก์ชันโจมตีและกดสกิล (แยก Thread เพื่อไม่ให้กระตุก)
local function AutoAttack(targetMonster)
    -- คลิกเมาส์ซ้าย (Button1)
    -- พิกัด 0, 0 คือคลิกที่ตำแหน่งปัจจุบันของเมาส์
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait() -- รอช่วงจิ๋วเดียวให้เกมรับรู้ว่ากดลงไปแล้ว
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)

    -- กดสกิล Q, E, R
    local keys = {Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R}
    for _, key in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- ฟังก์ชันเลือกประตูที่เข้าได้ (ไม่มี UnlockDoor) และวาร์ปไป UnlockVfx
local function HandleNextStage(currentRoom, myHrp)
    local voteDoorFolder = currentRoom:FindFirstChild("VoteDoor")
    if not voteDoorFolder then return end

    for _, door in pairs(voteDoorFolder:GetChildren()) do
        -- เงื่อนไข: ประตูที่เข้าได้ต้องไม่มีโมเดล UnlockDoor อยู่ภายใน
        if not door:FindFirstChild("UnlockDoor") then
            local targetVfx = door:FindFirstChild("UnlockVfx")
            if targetVfx then
                -- วาร์ปไปที่จุด UnlockVfx
                myHrp.CFrame = targetVfx:IsA("BasePart") and targetVfx.CFrame or targetVfx:GetModelCFrame()
                
                -- จำลองการกด F เพื่อเข้าประตู
                task.wait(0.2)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                break
            end
        end
    end
end

------------------------------------------------------------------------------------
--- Main Logic
------------------------------------------------------------------------------------
local function LogicAuto()
    while State.AutoFarm do
        if Window.Destroyed then break end
        
        pcall(function()
            local activationFolder = Workspace:FindFirstChild("Creature") and Workspace.Creature:FindFirstChild("Activation")
            if not activationFolder then return end

            -- 1. ค้นหาตำแหน่งเราใน Activation
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

            -- 2. ค้นหามอนสเตอร์
            local targetMonster = nil
            local monstersLeft = 0
            
            for _, folderID in pairs(activationFolder:GetChildren()) do
                for _, child in pairs(folderID:GetChildren()) do
                    if child.Name:match("Monster%d+") or child.Name:match("EliteMonster%d+") or child.Name:match("Boss%d+") then 
                        local hum = child:FindFirstChild("Humanoid")
                        local mHrp = child:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 and mHrp then
                            targetMonster = child
                            monstersLeft = monstersLeft + 1
                        end
                    end
                end
            end

            -- 3. ระบบตัดสินใจ
            if targetMonster then
                -- -- มีมอนสเตอร์: หมุนรอบตัว (Orbit)
                -- local mHrp = targetMonster.HumanoidRootPart
                -- degree = (degree + orbitSpeed) % 360
                -- local rad = math.rad(degree)

                -- local targetPos = Vector3.new(
                --     mHrp.Position.X + math.cos(rad) * orbitDistance,
                --     myHrp.Position.Y,
                --     mHrp.Position.Z + math.sin(rad) * orbitDistance
                -- )

                -- myHrp.CFrame = CFrame.lookAt(targetPos, mHrp.Position)
                
                -- -- สั่งโจมตี (ใช้ task.spawn เพื่อไม่ให้ขัดจังหวะการหมุน)
                -- task.spawn(AutoAttack, targetMonster, mHrp.Position)
                -- มีมอนสเตอร์: วาร์ปไปยืนด้านหน้า (ไม่ต้องหมุน)
                local mHrp = targetMonster.HumanoidRootPart
                local enemyPos = mHrp.Position
                local myGroundY = myHrp.Position.Y 

                -- คำนวณจุดที่จะไปยืน (ห่างจากศัตรูออกมา 5 หน่วยในแนวราบ)
                -- ใช้ CFrame.lookAt เพื่อให้ตัวละครหันหน้าไปหาศัตรูเสมอ
                local targetPosition = Vector3.new(enemyPos.X, myGroundY, enemyPos.Z) + (mHrp.CFrame.LookVector * 5)
                
                myHrp.CFrame = CFrame.lookAt(targetPosition, Vector3.new(enemyPos.X, myGroundY, enemyPos.Z))
                
                -- สั่งโจมตี
                task.spawn(AutoAttack, targetMonster, enemyPos)
            elseif monstersLeft == 0 then
                -- มอนสเตอร์หมด: เข้าประตูไปห้องถัดไป
                local currentRoom = GetCurrentRoom(myHrp)
                if currentRoom then
                    HandleNextStage(currentRoom, myHrp)
                end
                task.wait(0.5)
            end
        end)
        
        RunService.Heartbeat:Wait() -- ใช้ความเร็วตาม Frame rate เพื่อความลื่นไหล
    end
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
    Desc = "Automatically kill all monster",
	Callback = function(val)
		State.AutoFarm = val;
		if val then
			task.spawn(LogicAuto);
		end;
	end
});