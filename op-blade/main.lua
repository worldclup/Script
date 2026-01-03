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

local RebirthConstants = require(game:GetService("ReplicatedStorage").Modules.Constants.RebirthConstants)
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
    Wave = 5000,
    AutoRebirth = false
};

Window:OnDestroy(function()
    State.AutoStart = false;
	State.AutoFarm = false;
    State.AutoLeave = false;
    State.Wave = 5000;
    State.AutoRebirth = false;
end);

------------------------------------------------------------------------------------
--- Main Logic (Updated with Auto Loot)
------------------------------------------------------------------------------------
local function LogicAuto()
    while State.AutoFarm do
        if Window.Destroyed then break end
        task.wait(0.2)
        local myChar = workspace:FindFirstChild(LocalPlayer.Name)
        local rootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        ------------------------------------------------------------------------------------
        -- 1. ตรวจสอบ Auto Leave (เช็ค Wave)
        ------------------------------------------------------------------------------------
        if State.AutoLeave then
            local success, currentWaveStr = pcall(function()
                return LocalPlayer.PlayerGui.DifficultyDisplayUI.RoactTree.WaveDisplay.Content.Value.ContentText
            end)
        
            if success and currentWaveStr then
                local currentWave = tonumber(currentWaveStr)
                if currentWave and currentWave >= State.Wave then
                    local leaveRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/Arena_LeaveRequest")
                    leaveRemote:FireServer()
                    -- ไม่ต้องปิด AutoFarm เพื่อให้มันทำงานต่อเมื่อกลับถึง Lobby (จะไปเข้า Auto Start ต่อ)
                    task.wait(5) -- รอให้ระบบวาร์ปออก
                    continue 
                end
            end
        end

        ------------------------------------------------------------------------------------
        -- 2. ตรวจสอบ Loot (เก็บของสำคัญที่สุด)
        ------------------------------------------------------------------------------------
        local lootTarget = nil
        local shortestLootDist = math.huge
        for _, loot in pairs(workspace.LootAnchor:GetChildren()) do
            if loot.Name:find("Loot") then
                local lootPos = (loot:IsA("Attachment") and loot.WorldPosition) or (loot:IsA("BasePart") and loot.Position)
                if lootPos then
                    local dist = (rootPart.Position - lootPos).Magnitude
                    if dist < shortestLootDist then
                        shortestLootDist = dist
                        lootTarget = lootPos
                    end
                end
            end
        end

        if lootTarget then
            rootPart.CFrame = CFrame.new(lootTarget + Vector3.new(0, 1, 0))
            task.wait(0.1)
            continue 
        end

        ------------------------------------------------------------------------------------
        -- 3. ค้นหามอนสเตอร์
        ------------------------------------------------------------------------------------
        local enemies = workspace.GlobalSpriteAnchor:GetChildren()
        local monsterTarget = nil
        local shortestMonsterDist = math.huge

        for _, enemy in pairs(enemies) do
            if enemy.Name == "EnemyBillboard" or enemy.Name == "EnemyAttachment" or enemy:IsA("Attachment") then
                local monsterPos = enemy:IsA("Attachment") and enemy.WorldPosition or (enemy:IsA("BasePart") and enemy.Position)
                if monsterPos then
                    local dist = (rootPart.Position - monsterPos).Magnitude
                    if dist < shortestMonsterDist then
                        shortestMonsterDist = dist
                        monsterTarget = monsterPos
                    end
                end
            end
        end

        if monsterTarget then
            rootPart.CFrame = CFrame.new(monsterTarget + Vector3.new(0, 5, 0))
        else
            ------------------------------------------------------------------------------------
            -- [เพิ่มใหม่] 4. ถ้าไม่เจอมอนสเตอร์ และเปิด Auto Start (Lobby Logic)
            ------------------------------------------------------------------------------------
            if State.AutoStart and #enemies == 0 then
                task.wait(10) -- รอโหลดแมพสักครู่เพื่อไม่ให้ Remote ทำงานซ้ำซ้อน
                game:GetService("ReplicatedStorage"):WaitForChild("InventoryComm"):WaitForChild("RF"):WaitForChild("EquipBestWeapons"):InvokeServer()


                local netPath = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
                
                -- ส่ง Remote อันแรก (Teleport)
                local teleportRemote = netPath:WaitForChild("RE/Arena_TeleportToArena")
                teleportRemote:FireServer()
                
                task.wait(1) -- ดีเลย์ 1 วินาทีตามที่ต้องการ
                
                -- ส่ง Remote อันที่สอง (Enter)
                local enterRemote = netPath:WaitForChild("RE/Arena_PlayerEnter")
                enterRemote:FireServer()
            end
        end
    end
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
    Icon = "geist:chevron-double-up", -- เปลี่ยน Icon ให้เข้ากับชื่อ
    IconColor = Mythic,
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

Window:SelectTab(1);