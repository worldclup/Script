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
local ReplicatedStorage = game:GetService("ReplicatedStorage");
-- local ReplicatedFirst = game:GetService("ReplicatedFirst");
-- local RunService = game:GetService("RunService");
-- local Reliable = (ReplicatedStorage:WaitForChild("Reply")):WaitForChild("Reliable");
-- local Unreliable = (ReplicatedStorage:WaitForChild("Reply")):WaitForChild("Unreliable");
------------------------------------------------------------------------------------
--- Module
------------------------------------------------------------------------------------
local ModulesPath = ReplicatedStorage.Modules;
local RankModule = require(ModulesPath.Ranks);
------------------------------------------------------------------------------------
--- All Key
------------------------------------------------------------------------------------
local LastZone = nil;
local CurrentZoneName = "";
local CurrentZoneEnemiesCache = {};
local GlobalEnemyMap = {};
local EnemyDropdown
local hrp
local State = {
    AutoFarm = false,
    AutoRankUp = false,
};
------------------------------------------------------------------------------------
--- Window UI
------------------------------------------------------------------------------------
local UI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()

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
    --  Height = 44,
    --  ButtonsType = "Mac", -- Default or Mac
    -- },
    OpenButton = {
        Title = "DEK",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("#FFFFFF"), Color3.fromHex("#FFFFFF")),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true,
    },
})

Window:OnDestroy(function()
    State.AutoFarm = false;
    State.AutoRankUp = false;
end);
------------------------------------------------------------------------------------
--- Refresh Enemy Data
------------------------------------------------------------------------------------
local function RefreshEnemyData()
    local uiList = {}
    local seenForUI = {} 
    GlobalEnemyMap = {} 

    local ClientFolder = Workspace:FindFirstChild("Client")
    local EnemiesFolder = ClientFolder and ClientFolder:FindFirstChild("Enemies")
    
    if not EnemiesFolder then return uiList end

    for _, enemyObj in pairs(EnemiesFolder:GetChildren()) do
        -- เข้าถึงตำแหน่งชื่อและเลือดตามโครงสร้างใหม่
        local head = enemyObj:FindFirstChild("Head")
        local hud = head and head:FindFirstChild("HUD")
        local container = hud and hud:FindFirstChild("Container")
        
        local titleLabel = hud and hud:FindFirstChild("Title") -- สมมติว่า Title อยู่ใน HUD
        local healthLabel = container and container:FindFirstChild("HealthText")

        if titleLabel and healthLabel and (titleLabel:IsA("TextLabel") or titleLabel:IsA("TextBox")) then
            local enemyName = titleLabel.Text
            local healthValue = healthLabel.Text
            
            -- เก็บ Object ลง Map
            if not GlobalEnemyMap[enemyName] then
                GlobalEnemyMap[enemyName] = {}
            end
            table.insert(GlobalEnemyMap[enemyName], enemyObj)

            -- ป้องกันชื่อซ้ำใน Dropdown แต่แสดงเลือดของตัวแรกที่เจอเป็นตัวอย่าง
            if not seenForUI[enemyName] then
                seenForUI[enemyName] = true
                table.insert(uiList, {
                    Title = enemyName,
                    Value = enemyName,
                    Desc = "HP: " .. healthValue -- แสดงเลือดในคำอธิบาย
                })
            end
        end
    end

    -- เรียงตามชื่อมอนสเตอร์
    table.sort(uiList, function(a, b) return a.Title < b.Title end)
    return uiList
end
------------------------------------------------------------------------------------
--- MainSection
------------------------------------------------------------------------------------
local function LogicAutoFarm()
    local currentTargetObj = nil
    
    -- ฟังก์ชันช่วยเช็คว่าศัตรูตายหรือยังจาก Text (0/900K)
    local function IsAlive(enemy)
        if not enemy or not enemy.Parent then return false end
        local head = enemy:FindFirstChild("Head")
        local hud = head and head:FindFirstChild("HUD")
        local container = hud and hud:FindFirstChild("Container")
        local healthText = container and container:FindFirstChild("HealthText")
        
        if healthText then
            -- ดึงเลขตัวหน้าสุดออกมา (ก่อนเครื่องหมาย /)
            local currentHpStr = string.split(healthText.Text, "/")[1]
            if currentHpStr then
                -- ถ้าเลือดตัวหน้าเป็น "0" แปลว่าตายแล้ว
                if currentHpStr == "0" then return false end
                return true
            end
        end
        return false
    end

    while State.AutoFarm do
        if Window.Destroyed then break end

        local myChar = Workspace:FindFirstChild(LocalPlayer.Name)
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        if not myHrp then 
            task.wait(1)
        end

        -- 1. ตรวจสอบเป้าหมายปัจจุบันว่าตายหรือยัง
        if currentTargetObj then
            if not IsAlive(currentTargetObj) then
                currentTargetObj = nil
            end
        end

        -- 2. ค้นหาเป้าหมายใหม่ (กรองเฉพาะตัวที่เลือดยังไม่เป็น 0)
        if not currentTargetObj and State.SelectedEnemy then
            -- ตรวจสอบว่าเป็น Table หรือ String (ขึ้นอยู่กับ Dropdown ของคุณ)
            local targetName = type(State.SelectedEnemy) == "table" and State.SelectedEnemy.Value or State.SelectedEnemy
            local enemyList = GlobalEnemyMap[targetName]
            
            if enemyList then
                local closest, minDst = nil, math.huge
                for _, enemyObj in ipairs(enemyList) do
                    -- เช็คระยะทาง + เช็คว่าต้องยังไม่ตาย (IsAlive)
                    if enemyObj.Parent and enemyObj:FindFirstChild("Head") and IsAlive(enemyObj) then
                        local dst = (myHrp.Position - enemyObj.Head.Position).Magnitude
                        if dst < minDst then
                            minDst = dst
                            closest = enemyObj
                        end
                    end
                end
                currentTargetObj = closest
            end
        end

        -- 3. วาร์ปและโจมตี
        -- 4. วาร์ปและโจมตี (เวอร์ชันติดพื้น)
        if currentTargetObj and myHrp then
            local targetHead = currentTargetObj:FindFirstChild("Head")
            if targetHead then
                -- 1. หาตำแหน่งของศัตรู (X, Z)
                local enemyPos = targetHead.Position
                
                -- 2. หาตำแหน่งพื้นของคุณ (Y) 
                -- ใช้ตำแหน่งปัจจุบันของตัวละครคุณเอง หรือถ้าอยากให้ชัวร์ว่าติดพื้นตลอด 
                -- สามารถใช้ตำแหน่งของขา หรือค่าคงที่ของพื้นแมพได้
                local myGroundY = myHrp.Position.Y 
            
                -- 3. คำนวณจุดที่จะไปยืน (ห่างจากศัตรูออกมา -5 หน่วยในแนวราบ)
                -- เราจะสร้าง Vector ใหม่ที่เอาแค่ X, Z ของศัตรูมา แต่ Y เป็นของเรา
                local targetFlatPos = Vector3.new(enemyPos.X, myGroundY, enemyPos.Z)
                
                -- 4. สร้างตำแหน่งที่ยืน โดยถอยออกมานิดหน่อย (-5 คือระยะห่าง ปรับได้ตามระยะอาวุธ)
                -- ใช้ CFrame.lookAt เพื่อให้ตัวละคร "หันหน้า" ไปหาศัตรูเสมอแม้จะยืนอยู่ที่พื้น
                local standPos = targetFlatPos + (myHrp.CFrame.LookVector * -1) -- หรือระบุตำแหน่งแน่นอน
                
                -- แบบง่ายที่สุด: วาร์ปไปที่ศัตรูในระดับพื้นดิน
                -- CFrame.new(enemyPos.X, myGroundY, enemyPos.Z) * CFrame.new(0, 0, 5) 
                -- 5 คือระยะห่างจากตัวมอนสเตอร์
                myHrp.CFrame = CFrame.lookAt(
                    Vector3.new(enemyPos.X, myGroundY, enemyPos.Z) + Vector3.new(0, 0, 5), 
                    Vector3.new(enemyPos.X, myGroundY, enemyPos.Z)
                )
                
                -- สั่งโจมตี...
            end
        end

        task.wait(0.1)
    end
end
------------------------------------------------------------------------------------
--- MainSection
------------------------------------------------------------------------------------
local MainSection = Window:Section({
    Title = "Main Features",
    -- Icon = "folder",
    Opened = true,
});
------------------------------------------------------------------------------------
--- MainSection Tab 1
------------------------------------------------------------------------------------
local FarmTab = MainSection:Tab({
    Title = "Farming",
    Icon = "swords",
    IconColor = Mythic,
    IconShape = "Square",
});

EnemyDropdown = FarmTab:Dropdown({
    Title = "Select Enemy",
    Desc = "Select the enemy you want to attack",
    Values = RefreshEnemyData(),
    Multi = false,
    AllowNone = true,
    Callback = function(v)
        State.SelectedEnemy = v
    end
})

FarmTab:Button({
    Title = "Refresh List",
    Desc = "Refresh the list of available targets",
    Icon = "refresh-cw",
    Callback = function()
        EnemyDropdown:Refresh(RefreshEnemyData());
    end
});

FarmTab:Toggle({
    Title = "Auto Farm",
    Desc = "Enable auto combat and monster farming",
    Callback = function(val)
        State.AutoFarm = val;
        if val then
            task.spawn(LogicAutoFarm);
        end;
    end
});
------------------------------------------------------------------------------------
--- CharacterSection
------------------------------------------------------------------------------------
local CharacterSection = Window:Section({
	Title = "Character",
	-- Icon = "user",
	Opened = true,
});
------------------------------------------------------------------------------------
--- CharacterSection Tab 1
------------------------------------------------------------------------------------
local RankUpTab = CharacterSection:Tab({
	Title = "Rank Up",
	Icon = "arrow-up-1-0",
    IconColor = Divine,
	IconShape = "Square",
});
local RankProgressUI = RankUpTab:Paragraph({
	Title = "Rank Progress",
	Desc = "Loading data...",
	Image = "arrow-up-1-0",
	ImageSize = 32
})
RankUpTab:Toggle({
	Title = "Auto Rank Up",
	Value = false,
	Callback = function(v)
		State.AutoRankUp = v
	end
})
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local AllRanks = RankModule:GetRanks()
local MaxRankCap = #AllRanks
local function FindMyRankIndex()
    for i, rankName in ipairs(AllRanks) do
        for attrName, attrValue in pairs(LocalPlayer:GetAttributes()) do
            if tostring(attrValue) == rankName then return i end
        end
        for _, obj in pairs(LocalPlayer:GetDescendants()) do
            if (obj:IsA("StringValue") and obj.Value == rankName) or (obj.Name == "Rank" and obj.Value == i) then
                return i
            end
        end
    end
    return nil
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
task.spawn(function()
    while true do
        if Window.Destroyed then
            break
        end
        if not Window.Closed then
            local myRankIndex = FindMyRankIndex()
            local currentYen = LocalPlayer.leaderstats.Yens.Value
            
            if myRankIndex then
                local currentRankName = RankModule["GetRankName"](myRankIndex) or "Unknown"
                local nextRankPrice = RankModule["GetNextRankPrice"](myRankIndex) -- ดึงราคาจาก Module
                
                -- ตั้งค่า Title แสดงลำดับ Rank
                RankProgressUI:SetTitle(string.format("Rank [%d/%d] : %s", myRankIndex, MaxRankCap, currentRankName))
                
                -- ตั้งค่า Desc แสดงราคาที่ต้องใช้
                if nextRankPrice then
                    -- ใช้ฟังก์ชันช่วยจัดการตัวเลขให้ดูง่าย (เช่น 1,000,000) ถ้ามี
                    RankProgressUI:SetDesc(string.format("Cost: %s Yen", tostring(nextRankPrice)))
                else
                    RankProgressUI:SetDesc("You have reached the Maximum Rank!")
                    RankProgressUI:Lock()
                end

                if State.AutoRankUp and nextRankPrice <= currentYen then
                    local args = {
                    	"RankUp",
                    	"RankUp"
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Bridge"):FireServer(unpack(args))
                end
            end
        end
        task.wait(2)
    end
end)