------------------------------------------------------------------------------------
--- Color
------------------------------------------------------------------------------------
local Mythic    = Color3.fromHex("#FF3B3B") -- แดงเพลิง (มายา)
local Green     = Color3.fromHex("#10C550")
local Grey      = Color3.fromHex("#83889E")
------------------------------------------------------------------------------------
--- Game
------------------------------------------------------------------------------------
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Workspace = game:GetService("Workspace");

local RebirthConstants = require(game:GetService("ReplicatedStorage").Modules.Constants.RebirthConstants)
local MapConstants = require(game:GetService("ReplicatedStorage").Modules.Constants.MapConstants)
------------------------------------------------------------------------------------
--- Anti-AFK System
------------------------------------------------------------------------------------
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    warn("Anti-AFK System: Active!") -- แจ้งเตือนใน Console ว่าระบบทำงาน
end)
------------------------------------------------------------------------------------
--- Window UI
------------------------------------------------------------------------------------
_G.Settings = {
	Desc = {
		Game = "OP Blade",
        Color = Color3.fromHex("#FF3B3B")
	},
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/main.lua"))()
local UI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = UI:CreateWindow({
    -- Title = "🅳🅴🅺 🅳🅴🆅 🅷🆄🅱",
    Title = "DEK DEV HUB", -- "🅳🅴🅺 🅳🅴🆅 🅷🆄🅱",
	-- Icon = "keyboard",
	SideBarWidth = 150,
	Theme = "Dark", -- Dark, Darker, Light, Aqua, Amethyst, Rose
	Size = UDim2.fromOffset(700, 300),
	MinSize = Vector2.new(700, 300),
    MaxSize = Vector2.new(700, 300),
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

local State = {
    AutoStart = false,
    AutoFarm = false,
    AutoLeave = false,
    AutoRebirth = false,
    Wave = 5000,
    SelectedMap = "forest",
    SelectedWave = 1,
};

Window:OnDestroy(function()
    State.AutoStart = false;
	State.AutoFarm = false;
    State.AutoLeave = false;
    State.Wave = 5000;
    State.AutoRebirth = false;
    State.SelectedMap = "forest";
    State.SelectedWave = 1;
end);

------------------------------------------------------------------------------------
--- Main Logic (Updated with Auto Loot)
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--- Main Logic (Updated with Set Starting Wave)
------------------------------------------------------------------------------------
-- local function LogicAuto()
--     while State.AutoFarm do
--         if Window.Destroyed then break end
--         task.wait(0.2)
        
--         local myChar = workspace:FindFirstChild(LocalPlayer.Name)
--         local rootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")
--         if not rootPart then  end

--         -- 1. ตรวจสอบ Auto Leave (เช็ค Wave)
--         if State.AutoLeave then
--             -- แก้ไขการดึงค่า Wave จาก UI ให้ถูกต้องตาม Hierarchy
--             local success, currentWaveStr = pcall(function()
--                 return LocalPlayer.PlayerGui.DifficultyDisplayUI.RoactTree.WaveDisplay.Content.Value.ContentText
--             end)
        
--             if success and currentWaveStr then
--                 local currentWave = tonumber(currentWaveStr)
--                 if currentWave and currentWave >= State.Wave then
--                     local leaveRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/Arena_LeaveRequest")
--                     leaveRemote:FireServer()
--                     task.wait(5)
                     
--                 end
--             end
--         end

--         local myGroundY = rootPart.Position.Y
--         ------------------------------------------------------------------------------------
--         -- 2. ระบบ Auto Loot (เก็บของที่ดรอป) [เพิ่มใหม่]
--         ------------------------------------------------------------------------------------
--         local lootAnchor = workspace:FindFirstChild("LootAnchor")
--         local lootTarget = nil
--         local shortestLootDist = math.huge

--         if lootAnchor then
--             for _, loot in pairs(lootAnchor:GetChildren()) do
--                 -- ตรวจสอบตำแหน่งของของที่ดรอป (LootAttachment หรือ BasePart)
--                 local lootPos = (loot:IsA("Attachment") and loot.WorldPosition) or (loot:IsA("BasePart") and loot.Position)
                
--                 if lootPos then
--                     local dist = (rootPart.Position - lootPos).Magnitude
--                     if dist < shortestLootDist then
--                         shortestLootDist = dist
--                         lootTarget = lootPos
--                     end
--                 end
--             end
--         end

--         -- ถ้าเจอของดรอป ให้วาร์ปไปเก็บก่อน
--         if lootTarget then
--             rootPart.CFrame = CFrame.new(lootTarget.X, myGroundY, lootTarget.Z)
--             task.wait(0.05)
--         end

--         -- 2. ค้นหามอนสเตอร์ (อ้างอิงจาก GlobalSpriteAnchor)
--         local enemies = workspace.GlobalSpriteAnchor:GetChildren()
--         local monsterTarget = nil
--         local shortestMonsterDist = math.huge

--         for _, enemy in pairs(enemies) do
--             -- ตรวจสอบทั้ง Attachment และ Billboard
--             if enemy.Name == "EnemyBillboard" or enemy.Name == "EnemyAttachment" or enemy:IsA("Attachment") then
--                 local monsterPos = enemy:IsA("Attachment") and enemy.WorldPosition or (enemy:IsA("BasePart") and enemy.Position)
--                 if monsterPos then
--                     local dist = (rootPart.Position - monsterPos).Magnitude
--                     if dist < shortestMonsterDist then
--                         shortestMonsterDist = dist
--                         monsterTarget = monsterPos
--                     end
--                 end
--             end
--         end

--         if monsterTarget then
--             -- ปรับระยะห่างตรงนี้ (ยิ่งลบเยอะยิ่งยืนห่าง)
--             local offsetDist = 3

--             -- สร้างตำแหน่งเป้าหมายในระดับพื้น (Flat Position)
--             local targetFlatPos = Vector3.new(monsterTarget.X, myGroundY, monsterTarget.Z)

--             -- ใช้ CFrame.lookAt เพื่อยืนห่างออกมาและหันหน้าเข้าหาศัตรู
--             -- สูตร: (ตำแหน่งมอนสเตอร์) + (ถอยหลังออกมาตามทิศทาง LookVector)
--             rootPart.CFrame = CFrame.lookAt(
--                 targetFlatPos + (rootPart.CFrame.LookVector * -offsetDist), 
--                 targetFlatPos
--             )
--         else
--             -- 3. ถ้าไม่เจอมอนสเตอร์ และเปิด Auto Start (Lobby Logic)
--             if State.AutoStart and #enemies == 0 then
--                 task.wait(10)
--                 local args = {
--                 	true
--                 }
--                 game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/Map_ToggleMobSpeedBoost"):FireServer(unpack(args))
--                 task.wait(2)

--                 local netPath = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

--                 -- ขั้นตอนที่ 1: วาร์ปไปแมพที่เลือก
--                 local teleportRemote = netPath:WaitForChild("RE/Arena_TeleportToArena")
--                 teleportRemote:FireServer(State.SelectedMap)

--                 task.wait(1)

--                 -- ขั้นตอนที่ 2: ตั้งค่า Wave ที่เลือกจาก Dropdown
--                 local setWaveRemote = netPath:WaitForChild("RE/Arena_SetStartingWave")
--                 setWaveRemote:FireServer(State.SelectedWave)

--                 task.wait(0.5)

--                 -- ขั้นตอนที่ 3: กดยืนยันเข้าเล่น
--                 local enterRemote = netPath:WaitForChild("RE/Arena_PlayerEnter")
--                 enterRemote:FireServer()

--                 task.wait(5) -- รอโหลดแมพ
--             end
--         end
--     end
-- end
local function LogicAuto()
    local FloatOffset = 10 -- ระยะที่อยากให้ลอยสูงจากพื้น (ปรับได้ตามชอบ)
    local FixedY = nil -- ตัวแปรสำหรับเก็บค่าความสูงที่ล็อคไว้
    
    while State.AutoFarm do
        if Window.Destroyed then break end
        
        local myChar = workspace:FindFirstChild(LocalPlayer.Name)
        local rootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        if rootPart then
            -- 1. กำหนดค่าความสูงคงที่ครั้งแรก (ล็อคค่า Y ไว้ไม่ให้ไหล)
            if not FixedY then
                FixedY = rootPart.Position.Y + FloatOffset
            end

            -- หยุดแรงฟิสิกส์ทิ้งทั้งหมด
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            
            -- [ส่วนเช็ค Auto Leave เหมือนเดิม...]
            if State.AutoLeave then
                local success, currentWaveStr = pcall(function()
                    return LocalPlayer.PlayerGui.DifficultyDisplayUI.RoactTree.WaveDisplay.Content.Value.ContentText
                end)
                if success and currentWaveStr and tonumber(currentWaveStr) >= State.Wave then
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/Arena_LeaveRequest"):FireServer()
                    FixedY = nil -- ล้างค่า Y เมื่อออกจากแมพ
                    task.wait(5)
                end
            end

            ------------------------------------------------------------------------------------
            -- 2. ระบบหาเป้าหมาย (Loot หรือ Monster)
            ------------------------------------------------------------------------------------
            local targetPos = nil
            
            -- เช็คของดรอปก่อน
            local lootAnchor = workspace:FindFirstChild("LootAnchor")
            if lootAnchor and #lootAnchor:GetChildren() > 0 then
                local shortestDist = math.huge
                for _, loot in pairs(lootAnchor:GetChildren()) do
                    local p = (loot:IsA("Attachment") and loot.WorldPosition) or (loot:IsA("BasePart") and loot.Position)
                    if p then
                        local d = (rootPart.Position - p).Magnitude
                        if d < shortestDist then
                            shortestDist = d
                            targetPos = p
                        end
                    end
                end
            end

            -- ถ้าไม่มีของ ให้หามอนสเตอร์
            local enemies = workspace.GlobalSpriteAnchor:GetChildren()
            if not targetPos then
                local shortestDist = math.huge
                for _, enemy in pairs(enemies) do
                    if enemy.Name == "EnemyBillboard" or enemy.Name == "EnemyAttachment" or enemy:IsA("Attachment") then
                        local p = enemy:IsA("Attachment") and enemy.WorldPosition or (enemy:IsA("BasePart") and enemy.Position)
                        if p then
                            local d = (rootPart.Position - p).Magnitude
                            if d < shortestDist then
                                shortestDist = d
                                targetPos = p
                            end
                        end
                    end
                end
            end

            ------------------------------------------------------------------------------------
            -- 3. การวาร์ปแบบ Fixed Y (ล็อคความสูง)
            ------------------------------------------------------------------------------------
            if targetPos then
                -- วาร์ปไปที่ X, Z ของเป้าหมาย แต่ใช้ค่า Y ที่เราล็อคไว้ (FixedY)
                -- และใช้ CFrame.lookAt เพื่อหันหน้าลงไปหาเป้าหมาย
                local flyPos = Vector3.new(targetPos.X, FixedY, targetPos.Z)
                rootPart.CFrame = CFrame.lookAt(flyPos, targetPos)
            else
                    -- 4. ระบบ Auto Start (Lobby Logic)
                if State.AutoStart and #enemies == 0 then
                    task.wait(10)
                    local args = {
                    	true
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/Map_ToggleMobSpeedBoost"):FireServer(unpack(args))
                    task.wait(2)
                
                    local netPath = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
                
                    -- ขั้นตอนที่ 1: วาร์ปไปแมพที่เลือก
                    local teleportRemote = netPath:WaitForChild("RE/Arena_TeleportToArena")
                    teleportRemote:FireServer(State.SelectedMap)
                
                    task.wait(1)
                
                    -- ขั้นตอนที่ 2: ตั้งค่า Wave ที่เลือกจาก Dropdown
                    local setWaveRemote = netPath:WaitForChild("RE/Arena_SetStartingWave")
                    setWaveRemote:FireServer(State.SelectedWave)
                
                    task.wait(0.5)
                
                    -- ขั้นตอนที่ 3: กดยืนยันเข้าเล่น
                    local enterRemote = netPath:WaitForChild("RE/Arena_PlayerEnter")
                    enterRemote:FireServer()
                
                    task.wait(5) -- รอโหลดแมพ
                end
            end
        end
        game:GetService("RunService").Heartbeat:Wait() -- ใช้ Heartbeat เพื่อความนิ่งในการวาร์ป
    end
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function GetMapList()
    local mapList = {}
    local allMaps = MapConstants.getAllMaps()
    
    -- สร้างตารางสำหรับ Dropdown
    for id, data in pairs(allMaps) do
        table.insert(mapList, {
            Title = data.name, -- ชื่อที่แสดงใน UI
            Value = id,        -- ค่า id ที่ส่งเข้า Remote (เช่น "forest", "winter")
            Order = data.order or 0
        })
    end
    
    -- เรียงลำดับแมพตาม Order ในเกม
    table.sort(mapList, function(a, b) return a.Order < b.Order end)
    return mapList
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function GetWaveList(mapId)

    if not mapId then mapId = "forest" end
    local waveList = {}
    -- รายการ Wave ที่เกมอนุญาตให้เลือกได้ (ล็อคตามหน้า UI เกม)
    local standardCheckpoints = {1, 50, 100, 300, 1000, 5000}
    
    local success, unlockedWaves = pcall(function()
        local getWaveRF = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RF/Arena_GetWaveCheckpoints")
        return getWaveRF:InvokeServer(mapId)
    end)

    local maxUnlocked = 1 -- ค่าเริ่มต้นคือ Wave 1
    
    if success and type(unlockedWaves) == "table" then
        -- หาค่า Wave สูงสุดที่ปลดล็อกแล้วจากข้อมูลใน Table
        for _, innerValue in pairs(unlockedWaves) do
            local val = nil
            if type(innerValue) == "number" then
                val = innerValue
            end
            
            if val and val > maxUnlocked then
                maxUnlocked = val
            end
        end
    end

    -- กรองเอาเฉพาะ Checkpoint ที่เราปลดล็อกถึงแล้วเท่านั้น
    for _, cp in ipairs(standardCheckpoints) do
        if maxUnlocked >= cp then
            table.insert(waveList, {
                Title = "Wave " .. tostring(cp),
                Value = cp
            })
        end
    end

    return waveList
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local AutoTab = Window:Tab({
	Title = "Main",
	Icon = "folder",
    IconColor = Mythic,
	IconShape = "Square",
});
local WaveDropdown
-- Dropdown เลือกแมพ
AutoTab:Dropdown({
    Title = "Select Map",
    Desc = "Choose your destination",
    Values = GetMapList(), -- เรียกใช้ฟังก์ชันดึงแมพ
    Value = "Enchanted Forest",
    Callback = function(v)
        State.SelectedMap = v.Value
        -- เมื่อเปลี่ยนแมพ ให้ Refresh รายชื่อเวฟทันที
        WaveDropdown:Refresh(GetWaveList(v.Value), true)

        local args = {
        	v.Value
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/Map_Select"):FireServer(unpack(args))

    end
})

-- Dropdown เลือกเวฟ
WaveDropdown = AutoTab:Dropdown({
    Title = "Select Starting Wave",
    Desc = "Choose which wave to begin",
    Values = GetWaveList(State.SelectedMap), -- ดึงเวฟของแมพปัจจุบัน
    Value = 1,
    Callback = function(v)
        State.SelectedWave = tonumber(v.Value)
    end
})

AutoTab:Toggle({
	Title = "Auto Start",
    -- Desc = "Automatically kill all monster",
	Callback = function(val)
		State.AutoStart = val;
	end
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

local AutoTabGroup = AutoTab:Group({})
AutoTabGroup:Input({
	Title = "Wave",
    -- Desc = "Automatically exit the Defense after reaching this stage",
	Value = State.Wave,
	Type = "Input",
	Callback = function(v)
		local num = tonumber(v)
		if not num then
			warn("Input Number!!!")
			return
		end
		State.Wave = num
	end
})

AutoTabGroup:Toggle({
	Title = "Auto Leave",
	Callback = function(val)
		State.AutoLeave = val;
	end
});
------------------------------------------------------------------------------------
--- Window UI - Upgrade Tab
------------------------------------------------------------------------------------
local UpgradeTab = Window:Tab({
    Title = "Upgrade",
    Icon = "geist:chevron-double-up",
    IconColor = Green,
    IconShape = "Square",
});

local RebirthInfo = UpgradeTab:Paragraph({
    Title = "Rebirth Status",
    Desc = "Current Rank: Loading...\nNext Rebirth: Loading..."
})

UpgradeTab:Toggle({
    Title = "Auto Rebirth",
    Callback = function(val)
        State.AutoRebirth = val;
    end
});

------------------------------------------------------------------------------------
--- Logic สำหรับการคำนวณและ Rebirth
------------------------------------------------------------------------------------
local function UpdateRebirthUI()
    local player = game:GetService("Players").LocalPlayer
    local rebirths = player.leaderstats.Rebirths.Value
    local currentGold = player.leaderstats.Gold.Value
    
    -- 2. เรียกใช้ฟังก์ชัน getRebirthCost ของเกมโดยตรง
    -- p8 คือจำนวน Rebirth ปัจจุบัน, p9 คือส่วนลด (ถ้ามี ให้ใส่ 0)
    local nextCost = RebirthConstants.getRebirthCost(rebirths, 0)
    
    RebirthInfo:SetDesc(string.format(
        "Current Rank: %d\nNext Rebirth Cost: %s Gold\nYour Gold: %s",
        rebirths,
        formatNumber(nextCost), 
        formatNumber(currentGold)
    ))
    
    return nextCost, rebirths, currentGold
end

-- ฟังก์ชันช่วยแสดงตัวเลขให้สวยงาม (เช่น 25,000)
function formatNumber(v)
    return tostring(v):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

------------------------------------------------------------------------------------
--- Main Logic (เพิ่มส่วน Rebirth เข้าไป)
------------------------------------------------------------------------------------
-- ใส่ลูปนี้แยกออกมาหรือรวมใน LogicAuto ก็ได้ครับ แต่แนะนำให้เช็คเมื่อ #enemies == 0 (อยู่ Lobby)
task.spawn(function()
    while true do
        if Window.Destroyed then break end
        task.wait(1)
        local nextCost, currentRank, currentGold = UpdateRebirthUI()
        
        -- เงื่อนไข: ต้องไม่เจอมอนสเตอร์ (อยู่ Lobby) และ เงินถึง
        local enemies = workspace.GlobalSpriteAnchor:GetChildren()
        if State.AutoRebirth then
            if #enemies == 0 and currentGold >= nextCost then
                game:GetService("ReplicatedStorage"):WaitForChild("InventoryComm"):WaitForChild("RF"):WaitForChild("EquipBestWeapons"):InvokeServer()
                game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/Rebirth_Request"):FireServer()
            end

        end
    end
end)
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
------------------------------------------------------------------------------------
--- Window UI - Upgrade Tab
------------------------------------------------------------------------------------
local SettingTab = Window:Tab({
    Title = "Setting",
    Icon = "settings-2",
    IconColor = Grey,
    IconShape = "Square",
});

SettingTab:Button({
	Title = "Boost FPS (Low Graphics)",
	Icon = "rocket",
	Callback = function()
		BoostFps()
	end
})
Window:SelectTab(1);