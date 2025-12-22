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
local ReplicatedFirst = game:GetService("ReplicatedFirst");
local RunService = game:GetService("RunService");
local Reliable = (ReplicatedStorage:WaitForChild("Reply")):WaitForChild("Reliable");
local Unreliable = (ReplicatedStorage:WaitForChild("Reply")):WaitForChild("Unreliable");
------------------------------------------------------------------------------------
--- Module
------------------------------------------------------------------------------------
local ConfigsPath = ReplicatedStorage.Scripts.Configs;
local AttackAreaModule = require(ConfigsPath.BasicUpgrades.AttackArea);
local YenModule = require(ConfigsPath.Machines.YenUpgrades);
local TokenModule = require(ConfigsPath.Machines.TokenUpgrades);
local RankModule = require(ConfigsPath.Machines.RankUp);
local UtilsModule = require(ConfigsPath.Utility.Utils);
local MaterialsModule = require(ConfigsPath.General.Materials);
local GamemodeModule = require(ConfigsPath.Gamemodes);
local ZoneModule = require(ConfigsPath.Zones);
local RollGachaModule = ConfigsPath.RollGachas;
local RollGachaUpgradeModule = ConfigsPath.RollGachaUpgrades;
local TrainerModule = ConfigsPath.Trainers;
local LevelUpModule = require(ConfigsPath.General.LevelUp)

local ChanceModules = {};
local ChancePath = ReplicatedStorage.Scripts.Configs:FindFirstChild("ChanceUpgrades");

local function GetPlayerData()
    if getgenv().PlayerData then return getgenv().PlayerData end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "Attributes") and rawget(v, "YenUpgrades") then
            getgenv().PlayerData = v
            return v
        end
    end
end
------------------------------------------------------------------------------------
--- Game Script
------------------------------------------------------------------------------------
local AttackAreaUpgradeConfig = AttackAreaModule;
local YenUpgradeConfig = YenModule.Config;
local TokenUpgradeConfig = TokenModule.Config;
local MaxRankCap = RankModule.MAX or 33;
local function GetYenCost(lvl)
	return YenModule.GetUpgradeCost(lvl);
end;
local function GetYenBuff(name, lvl)
	return YenModule.GetUpgradeBuff(name, lvl);
end;
-- local function GetTokenCost(lvl)
-- 	return TokenModule.GetUpgradeCost(lvl);
-- end;
-- local function GetTokenBuff(name, lvl)
-- 	return TokenModule.GetUpgradeBuff(name, lvl);
-- end;
local GetTokenCost = TokenModule.GetUpgradeCost
local GetTokenBuff = TokenModule.GetUpgradeBuff
local function GetRankRequirement(rank)
	return RankModule.GetRequirement(rank);
end;
local function GetRankBuff(rank)
	return RankModule.GetBuff(rank);
end;
local function FormatNumber(n)
	return UtilsModule.ToText(n);
end;
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
	AutoDungeon = false,
	AutoFuse = false,
	AutoRankUp = false,
    SelectedStat = nil,
    AutoAscension = false,
    YenUpgradeState = {},
    TokenUpgradeState = {},
    AutoAttackAreaUpgrade = false,
	SelectedEnemy = nil,
    SelectedEquipBestFarm = nil,
    SelectedEquipBestGamemode = nil,
	TargetDungeon = {},
    GamemodeSession = {
        Active = false,
        Mode = nil,
        StartTime = 0,
    },
    GachaState = {},
    RollUpgradeState = {},
    TrainerState = {},
};

LocalPlayer.CharacterAdded:Connect(function(char)
	hrp = char:WaitForChild("HumanoidRootPart");
	humanoid = char:WaitForChild("Humanoid");
end);
pcall(function()
	if LocalPlayer.Character then
		hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
		humanoid = LocalPlayer.Character:FindFirstChild("Humanoid");
	end;
end);
------------------------------------------------------------------------------------
--- Window UI
------------------------------------------------------------------------------------
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
	},
})

Window:OnDestroy(function()
	State.AutoFarm = false;
	State.AutoDungeon = false;
	State.AutoFuse = false;
	State.AutoRankUp = false;
    State.SelectedStat = nil;
    State.AutoAscension = false;
    State.YenUpgradeState = {};
    State.TokenUpgradeState = {};
    State.AutoAttackAreaUpgrade = false;
    State.GamemodeSession.Active = false;
    State.GamemodeSession.Mode = nil;
    State.GamemodeSession.StartTime = 0;
    State.GachaState = {};
    State.RollUpgradeState = {};
    State.TrainerState = {};
    State.SelectedEquipBestFarm = nil;
    State.SelectedEquipBestGamemode = nil;
	if CurrentZoneName ~= "" and State.SelectedEnemy then
		-- SaveZoneConfig(CurrentZoneName, State.SelectedEnemy);
	end;
end);
----------------------------------------------------------------
--- Apply Vault Equip Best
----------------------------------------------------------------
local IconNoti = {
    ["Mastery"] = "chess-queen",
    ["Damage"] = "flame",
    ["Luck"] = "clover",
    ["Yen"] = "badge-japanese-yen",
}
local function ApplyVaultEquipBest(typeName)
	local args = {
		[1] = "Vault Equip Best",
		[2] = {
			[1] = typeName, -- "Damage" หรือ "Mastery"
		}
	}
	Reliable:FireServer(unpack(args))
	UI:Notify({
		Title = "Equip Best!",
		Content = typeName,
		Duration = 3, -- 3 seconds
		Icon = IconNoti[typeName],
	})
		
end
------------------------------------------------------------------------------------
--- Refresh Enemy Data
------------------------------------------------------------------------------------
local function RefreshEnemyData()
    local uiList = {};
    local seenForUI = {};
    GlobalEnemyMap = {}; -- ล้างค่าใหม่ทุกครั้งที่ Refresh

    local EnemiesFolder = Workspace:FindFirstChild("Enemies");
    if not EnemiesFolder then return uiList; end;

    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local config = rawget(v, "Config");
            local alive = rawget(v, "Alive");
            local uid = rawget(v, "Uid");
            local dataSection = rawget(v, "Data");

            if config and alive == true and uid and dataSection and dataSection.CFrame then
                local display = config.Display or "Unknown";
                local difficulty = config.Difficult or "Normal";
                -- local realName = rawget(v, "Character") and v.Character.Name or display;

                local groupName = display;

                if not GlobalEnemyMap[display] then
                    GlobalEnemyMap[display] = {};
                end;
                table.insert(GlobalEnemyMap[display], v);

                if not seenForUI[groupName] then
                    seenForUI[groupName] = true;
                    table.insert(uiList, {
                        Title = display .. " (" .. difficulty .. ")",
                        Value = display,
                        Desc = "HP: " .. FormatNumber((config.MaxHealth or 0)),
                        HP = config.MaxHealth or 0
                    });
                end;
            end;
        end;
    end;

    table.sort(uiList, function(a, b) return a.HP < b.HP; end);
    CurrentZoneEnemiesCache = uiList;
    return uiList;
end;
------------------------------------------------------------------------------------
--- Logic Auto Farm
------------------------------------------------------------------------------------
local function LogicAutoFarm()
	local currentTargetObj = nil;
	while State.AutoFarm do
		if Window.Destroyed then
			break
		end;
		if currentTargetObj then
			if currentTargetObj.Alive == false or (not currentTargetObj.Data) or (not currentTargetObj.Uid) then
				currentTargetObj = nil;
			end;
		end;
		if not currentTargetObj and State.SelectedEnemy then

			local targetName = State.SelectedEnemy.Value;
			if targetName and hrp and GlobalEnemyMap[targetName] then
				local enemyList = GlobalEnemyMap[targetName] or {};
				local closest, minDst = nil, math.huge;
				local myPos = hrp.Position;
				for _, enemyObj in ipairs(enemyList) do
					if enemyObj.Alive == true and enemyObj.Data and enemyObj.Data.CFrame then
						local dst = (myPos - enemyObj.Data.CFrame.Position).Magnitude;
						if dst < minDst then
							minDst = dst;
							closest = enemyObj;
						end;
					end;
				end;
				if closest then
					currentTargetObj = closest;
					if hrp and currentTargetObj.Data and currentTargetObj.Data.CFrame then
						hrp.CFrame = currentTargetObj.Data.CFrame * CFrame.new(0, 0, -5);
					end;
				end;
			end;
		elseif currentTargetObj.Uid and Unreliable then
			pcall(function()
				Unreliable:FireServer("Hit", {
					currentTargetObj.Uid
				});
			end);
		end;
		task.wait(0.1);
	end;
end;
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function GetAllGamemodesUnified()
    -- ใส่ GamemodeModule เข้าไปใน GetList เพราะมันคือ p5 (ตามโครงสร้าง module ของเกมคุณ)
    local allModes = GamemodeModule:GetList(GamemodeModule);
    local unifiedList = {};

    -- 1. กำหนดลำดับของกลุ่มโหมด (ยิ่งน้อยยิ่งขึ้นก่อน)
    local modeOrder = {
        ["Dungeon"] = 1,
        ["Raid"] = 2,
        ["Defense"] = 3,
        ["ShadowGate"] = 4,
        ["PirateTower"] = 5
    }

    -- 2. กำหนดลำดับของความยากภายในกลุ่ม
    local diffOrder = {
        ["Easy"] = 1,
        ["Shinobi"] = 1, -- สำหรับ Raid
        ["Medium"] = 2,
        ["Bleach"] = 2,  -- สำหรับ Raid
        ["Hard"] = 3,
        ["Default"] = 4,
        ["Insane"] = 4,
    }

    local GamemodeMap = {
        ["Defense: Easy"] = "Defense:1",
        ["Dungeon: Easy"] = "Dungeon:1",
    	["Dungeon: Medium"] = "Dungeon:2",
    	["Dungeon: Hard"] = "Dungeon:3",
        ["Dungeon: Insane"] = "Dungeon:4",
        ["Raid: Shinobi"] = "Raid:1",
    	["Raid: Bleach"] = "Raid:2",
        ["Shadow Gate"] = "ShadowGate",
        ["Pirate Tower"] = "PirateTower",
    }

    if not allModes then return unifiedList end

    for modeName, modeData in pairs(allModes) do
        if modeData.PHASES and modeData.PHASES[1] then
            for _, phase in ipairs(modeData.PHASES) do
                table.insert(unifiedList, {
                    Mode = modeName,
                    Difficulty = phase.Name or "Easy",
                    -- Health = phase.HealthBase or 0,
                    -- Rewards = phase.ChanceReward or {}
                    Title = modeName .. ": " .. (phase.Name or "Easy"),
                    Value = GamemodeMap[modeName .. ": " .. (phase.Name or "Easy")],
                    Desc = "HP: " .. FormatNumber(phase.HealthBase or 0)
                })
            end
        else
            table.insert(unifiedList, {
                Mode = modeName,
                Title = (modeData.Display or modeName),
                Value = GamemodeMap[modeData.Display or modeName],
                Desc = "HP: " .. FormatNumber(modeData.HealthBase or 0)
            })
        end
    end

    table.sort(unifiedList, function(a, b)
        local aOrder = modeOrder[a.Mode] or 99
        local bOrder = modeOrder[b.Mode] or 99

        if aOrder ~= bOrder then
            -- ถ้าคนละโหมด ให้เรียงตาม modeOrder (Dungeon > Raid > ...)
            return aOrder < bOrder
        else
            -- ถ้าโหมดเดียวกัน ให้เรียงตามความยาก (Easy > Medium > Hard)
            local aDiff = diffOrder[a.Difficulty] or 99
            local bDiff = diffOrder[b.Difficulty] or 99
            return aDiff < bDiff
        end
    end)

    return unifiedList
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function GetZone()
	local zonesFolder = Workspace:FindFirstChild("Zones")
	if not zonesFolder then
		return nil
	end
	for _, z in ipairs(zonesFolder:GetChildren()) do
		if z:IsA("Folder") and # z:GetChildren() > 0 then
			return z.Name
			-- break
		end
	end
	return nil
end
local function isPlayerInZone(zone)
	local chars = zone:FindFirstChild("Characters");
	if chars and chars:FindFirstChild(LocalPlayer.Name) then
		return true;
	end;
	return false;
end;
local function GetCurrentMapStatus()
	local zones = Workspace:FindFirstChild("Zones");
	if zones then
		for _, zone in pairs(zones:GetChildren()) do
			if isPlayerInZone(zone) then
				return zone.Name;
			end;
		end;
	end;
	if Workspace:FindFirstChild("Dungeon") then
		return "Dungeon";
	end;
	if Workspace:FindFirstChild("Raid") then
		return "Raid";
	end;
	if Workspace:FindFirstChild("Defense") then
		return "Defense";
	end;
    if Workspace:FindFirstChild("ShadowGate") then
		return "ShadowGate";
	end;
    if Workspace:FindFirstChild("PirateTower") then
		return "PirateTower";
	end;
	if Workspace:FindFirstChild("Enemies") and (not zones) then
		return "Dungeon:Active";
	end;
	return "Unknown";
end;
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function JoinGamemode(targetValue)
    if State.GamemodeSession.Active then return end

    local currentMap = GetCurrentMapStatus()
    if currentMap ~= "Unknown" then
        LastZone = currentMap
    end
    pcall(function()
        Reliable:FireServer("Join Gamemode", { targetValue })
    end)

    task.wait(5) -- รอโหลดแมพ
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function IsInGamemodeZone()
    local zone = GetZone()
    if not zone then return false end

    return zone:match("^Dungeon:%d+")
        or zone:match("^Raid:%d+")
        or zone:match("^Defense:%d+")
        or zone:match("ShadowGate")
        or zone:match("PirateTower")
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function LogicGamemodes()
    local refreshTimer = 0

    while State.AutoDungeon do
        if Window.Destroyed then break end
        local inGamemodeZone = IsInGamemodeZone()

        if State.TargetDungeon and # State.TargetDungeon > 0 and not State.GamemodeSession.Active and not inGamemodeZone then
            local joinTarget = nil
            local t = os.date("*t")
            local currentMinute = t.min

            for _, targetValue in ipairs(State.TargetDungeon) do
                local split = string.split(targetValue, ":")
                local mName = split[1]
                local mIndex = tonumber(split[2])

                inGamemodeZone = IsInGamemodeZone()

                local mData = GamemodeModule:Get(mName)
                if not mData then return nil end

                -- กรณีมี PHASE + เวลา
                if mData.PHASES and mIndex then
                    local phase = mData.PHASES[mIndex]
                    if phase and phase.START_TIMES then
                        for _, startTime in ipairs(phase.START_TIMES) do
                            if currentMinute == startTime then
                                joinTarget = targetValue
                            end
                        end
                    end

                -- กรณีโหมดใช้ Key (เข้าได้ตลอด)
                elseif mData.TYPE and table.find(mData.TYPE, "KEY") then
                    joinTarget = targetValue
                end

                if joinTarget and not State.GamemodeSession.Active and not inGamemodeZone then
                    JoinGamemode(joinTarget)
                end
            end
        end

        --------------------------------------------------
        -- FIGHT (อยู่ในดันจริง)
        --------------------------------------------------
        if inGamemodeZone then
            if State.SelectedEquipBestGamemode and not State.GamemodeSession.Active then
                ApplyVaultEquipBest(State.SelectedEquipBestGamemode)
            end
            State.GamemodeSession.Active = true
            -- State.GamemodeSession.Mode = targetValue
            -- State.GamemodeSession.StartTime = os.clock()

            if os.time() - refreshTimer > 1 then
                RefreshEnemyData()
                refreshTimer = os.time()
            end

            for _, enemyList in pairs(GlobalEnemyMap) do
                for _, enemyObj in ipairs(enemyList) do
                    if enemyObj.Alive and enemyObj.Data and enemyObj.Data.CFrame then
                        if hrp then
                            hrp.CFrame = enemyObj.Data.CFrame * CFrame.new(0, 0, -5)
                        end
                        if enemyObj.Uid then
                            pcall(function()
                                Unreliable:FireServer("Hit", { enemyObj.Uid })
                            end)
                        end
                    end
                end
            end

        --------------------------------------------------
        -- FINISH (ออกจาก GamemodeZone แล้ว)
        --------------------------------------------------
        elseif State.GamemodeSession.Active and not inGamemodeZone then
            if State.SelectedEquipBestFarm then
                ApplyVaultEquipBest(State.SelectedEquipBestFarm)
            end
            State.GamemodeSession.Active = false
            State.GamemodeSession.Mode = nil

            GlobalEnemyMap = {}
            if LastZone then
                task.wait(3)
                pcall(function()
                    Reliable:FireServer("Zone Teleport", { LastZone })
                end)
                task.wait(5)
                EnemyDropdown:Refresh(RefreshEnemyData())
            end
        end

        task.wait(0.2)
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
	Values = RefreshEnemyData(),
	Multi = false,
	AllowNone = true,
	Callback = function(v)
		State.SelectedEnemy = v
	end
})

FarmTab:Button({
	Title = "Refresh List",
	Icon = "refresh-cw",
	Callback = function()
		EnemyDropdown:Refresh(RefreshEnemyData());
	end
});

FarmTab:Toggle({
	Title = "Auto Farm",
	Callback = function(val)
		State.AutoFarm = val;
		if val then
			task.spawn(LogicAutoFarm);
		end;
	end
});
------------------------------------------------------------------------------------
--- MainSection Tab 2
------------------------------------------------------------------------------------
local GamemodeTap = MainSection:Tab({
	Title = "Gamemode",
	Icon = "skull",
    IconColor = Mythic,
	IconShape = "Square",
});


GamemodeTap:Dropdown({
	Title = "Select Gamemode",
	Values = GetAllGamemodesUnified(),
	Multi = true,
	AllowNone = true,
	Callback = function(val)
        local t = {};
		for _, v in pairs(val) do
			table.insert(t, type(v) == "table" and v.Value or v);
		end;
		State.TargetDungeon = t;
	end
})

GamemodeTap:Toggle({
	Title = "Auto Join & Kill",
	Flag = "AutoDungeon_Cfg",
	Callback = function(val)
		State.AutoDungeon = val;
		if val then
			task.spawn(LogicGamemodes);
		end;
	end
});
------------------------------------------------------------------------------------
--- MainSection Tab 3
------------------------------------------------------------------------------------
local EquipTap = MainSection:Tab({
	Title = "Equip Best",
	Icon = "flame",
    IconColor = Mythic,
	IconShape = "Square",
});

EquipTap:Dropdown({
	Title = "Auto Equip Best (Farm)",
    Desc = "Auto Equip Best When outside Gamemode",
	Values = {
        "--",
		"Mastery",
		"Damage",
		"Luck",
		"Yen"
    },
	Multi = false,
	AllowNone = true,
	Callback = function(v)
        if v == "--" then
			State.SelectedEquipBestFarm = nil
		else
			State.SelectedEquipBestFarm = v
		end
	end
})

EquipTap:Dropdown({
	Title = "Auto Equip Best (Gamemode)",
    Desc = "Auto Equip Best When inside Gamemode",
	Values = {
        "--",
		"Mastery",
		"Damage",
		"Luck",
		"Yen"
    },
	Multi = false,
	AllowNone = true,
	Callback = function(v)
        if v == "--" then
			State.SelectedEquipBestGamemode = nil
		else
			State.SelectedEquipBestGamemode = v
		end
	end
})
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
--- CharacterSection Tab 2
------------------------------------------------------------------------------------
local StatsTab = CharacterSection:Tab({
	Title = "Stats",
	Icon = "coins",
    IconColor = Divine,
	IconShape = "Square",
});

local StatsProgressUI = StatsTab:Paragraph({
	Title = "Stats Overview",
	Desc = "Loading data...",
	Image = "coins",
	ImageSize = 32
})
local StatsDropdownUI = StatsTab:Dropdown({
	Title = "Auto Upgrade Stats",
	Values = {
		"--",
		"Mastery",
		"Damage",
		"Luck",
		"Yen"
	},
	Multi = false,
	Callback = function(v)
		if v == "--" then
			State.SelectedStat = nil
		else
			State.SelectedStat = v
		end
	end
})
local AscensionToggle = StatsTab:Toggle({
	Title = "Auto Ascension",
	Value = false,
	Callback = function(v)
		State.AutoAttackAreaUpgrade = v
	end
})
------------------------------------------------------------------------------------
--- CharacterSection Tab 2.5
------------------------------------------------------------------------------------
local AttackAreaTab = CharacterSection:Tab({
	Title = "Attack Area",
	Icon = "land-plot",
    IconColor = Divine,
	IconShape = "Square",
});

local AttackAreaProgressUI = AttackAreaTab:Paragraph({
	Title = "Attack Area",
	Desc = "Loading data...",
	Image = "geist:codepen",
	ImageSize = 32
})
local AttackAreaToggle = AttackAreaTab:Toggle({
	Title = "Auto Upgrade",
	Value = false,
	Callback = function(v)
		State.AutoAttackAreaUpgrade = v
	end
})
------------------------------------------------------------------------------------
--- CharacterSection Tab 3
------------------------------------------------------------------------------------
local YenUpgradeTab = CharacterSection:Tab({
	Title = "Yen Upgrades",
	Icon = "badge-japanese-yen",
    IconColor = Divine,
	IconShape = "Square",
});
local YenToggleUI = {}
local YenUpgradeNames = {
	"Luck",
	"Yen",
	"Mastery",
	"Critical",
	"Damage"
}
local YenCurrentGroup = nil
local YenProgressUI = YenUpgradeTab:Paragraph({
	Title = "Yen Progress",
	Desc = "Loading data...",
	Image = "badge-japanese-yen",
	ImageSize = 32
})
for i, name in ipairs(YenUpgradeNames) do
	if i % 2 == 1 then
		YenCurrentGroup = YenUpgradeTab:Group({})
	end
	State.YenUpgradeState[name] = false
	YenToggleUI[name] = YenCurrentGroup:Toggle({
		Title = name,
		Value = false,
		Callback = function(v)
			State.YenUpgradeState[name] = v
		end
	})
end
----------------------------------------------------------------
--- CharacterSection Tab 4
----------------------------------------------------------------
local TokenUpgradeTab = CharacterSection:Tab({
	Title = "Token Upgrades",
	Icon = "geist:chevron-double-up",
    IconColor = Divine,
	IconShape = "Square",
});
local TokenToggleUI = {}
local TokenUpgradeNames = {
	"Run Speed",
	"Luck",
	"Yen",
	"Mastery",
	"Drop",
	"Critical",
	"Damage"
}
local TokenCurrentGroup = nil

local TokenProgressUI = TokenUpgradeTab:Paragraph({
	Title = "Token Progress",
	Desc = "Loading data...",
	Image = "geist:chevron-double-up",
	ImageSize = 32
})

for i, name in ipairs(TokenUpgradeNames) do
	if i % 2 == 1 then
		TokenCurrentGroup = TokenUpgradeTab:Group({})
	end
	State.TokenUpgradeState[name] = false
	TokenToggleUI[name] = TokenCurrentGroup:Toggle({
		Title = name,
		Value = false,
		Callback = function(v)
			State.TokenUpgradeState[name] = v
		end
	})
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
			local PlayerData = GetPlayerData()
			if PlayerData and PlayerData.Attributes then
				local currentRank = PlayerData.Attributes.Rank or 0
				local currentMastery = PlayerData.Attributes.Mastery or 0

                -- ดึงค่าจาก Module ที่ส่งมา
				local req = GetRankRequirement(currentRank) or 1
				local currentBuff = GetRankBuff(currentRank) or 0
				local nextBuff = GetRankBuff(currentRank + 1) or 0
				pcall(function()
                    -- คำนวณเปอร์เซ็นต์ (Mastery / Requirement)

					local percent = math.clamp(currentMastery / req, 0, 1)
					local barText = string.rep("█", math.floor(percent * 10)) .. string.rep("▒", 10 - math.floor(percent * 10))

                    -- จัดการข้อความ Buff (Mastery ของเกมนี้ Buff เพิ่มขึ้นแบบ 2^(n-1))
					local buffText = ""
					if currentRank >= MaxRankCap then
						buffText = string.format("Buff: %s%% (MAX)", FormatNumber(currentBuff))
					else
						buffText = string.format("Buff: %s%% -> %s%%", FormatNumber(currentBuff), FormatNumber(nextBuff))
					end

                    -- อัปเดต UI ให้สวยเหมือน anui
					RankProgressUI:SetTitle(string.format("Rank [%d/%s]", currentRank, MaxRankCap))
					RankProgressUI:SetDesc(string.format("%s\n[%s] %d%%\n%s / %s", buffText, barText, math.floor(percent * 100), FormatNumber(currentMastery), FormatNumber(req)))
				end)

                -- -- ระบบ Auto Rank Up
                -- if State.AutoRankUp and currentMastery >= req then
                --     -- ตรวจสอบว่า Rank ยังไม่เต็ม
                --     if currentRank < MaxRankCap then
                --         Reliable:FireServer("Rank Up") -- ส่ง Remote ไปอัปเกรด
                --         task.wait(0.5)
                --     end
                -- end
			end
			-- ภายใน Loop task.spawn หลักที่เช็ค PlayerData
			if PlayerData and PlayerData.Attributes and PlayerData.StatPoints then
                -- 1. คำนวณแต้มคงเหลือ (ใช้ฟังก์ชันจาก Module ได้เลยเพื่อความแม่นยำ)
                local pointsAvailable = LevelUpModule.CountPoints(PlayerData)

                -- 2. ดึงข้อมูลเลเวลและการเกิดใหม่
                local lv = PlayerData.Attributes.Level or 1
                local asc = PlayerData.Attributes.Ascension or 0

                -- ✨ 3. คำนวณ Max Level ตาม Ascension ปัจจุบัน
                -- สูตรใน Module คือ: 200 + (10 * Ascension)
                local maxLv = LevelUpModule.GetMaxLevel(asc)

                -- 4. ดึงข้อมูล Stat และคำนวณ Buff (ใช้ฟังก์ชัน GetBuff จาก Module)
                local masteryLv = PlayerData.StatPoints.Mastery or 1
                local damageLv = PlayerData.StatPoints.Damage or 1
                local luckLv = PlayerData.StatPoints.Luck or 1
                local yenLv = PlayerData.StatPoints.Yen or 1

                local descText = string.format(
                    "🔮 Mastery Lv.%d | Buff: +%d%%\n" ..
                    "⚔️ Damage Lv.%d | Buff: +%d%%\n" ..
                    "🍀 Luck Lv.%d | Buff: +%d%%\n" ..
                    "💰 Yen Lv.%d | Buff: +%d%%", 
                    masteryLv, LevelUpModule.GetBuff(masteryLv), 
                    damageLv, LevelUpModule.GetBuff(damageLv), 
                    luckLv, LevelUpModule.GetBuff(luckLv), 
                    yenLv, LevelUpModule.GetBuff(yenLv)
                )
                local descToggleText = string.format("Points Available: %d", pointsAvailable)
            
                -- 5. อัปเดตลงใน UI
                pcall(function()
                    -- ✨ แสดงผล Level [193/200] หรือถ้าเกิดใหม่ 1 รอบจะเป็น [193/210]
                    StatsProgressUI:SetTitle(string.format("Level [%d/%d]", lv, maxLv))

                    StatsProgressUI:SetDesc(descText)
                    StatsDropdownUI:SetDesc(descToggleText)
                    AscensionToggle:SetDesc(string.format("Ascension: %d", asc))
                end)
            end
            if PlayerData.AttackArea then
                local AttackAreaUpgrades = PlayerData.AttackArea or {}

                local currentLevel = AttackAreaUpgrades or 0
                local maxLevel = AttackAreaUpgradeConfig.MAX or 9

                local currentToken = PlayerData.Materials and PlayerData.Materials.AttackAreaToken or 0
                pcall(function()
                    if currentLevel >= maxLevel then
							AttackAreaProgressUI:SetTitle("Attack Area" .. " [MAX] ✅")
							AttackAreaProgressUI:SetDesc(string.format("Attack Area Token: %s\nSize: +%s%%", FormatNumber(currentToken), AttackAreaUpgradeConfig.GetAreaSize(AttackAreaUpgradeConfig, currentLevel)))
                            AttackAreaToggle:Lock()
						else
							AttackAreaProgressUI:SetTitle("Attack Area" .. " [" .. currentLevel .. "/" .. maxLevel .. "]")
							AttackAreaProgressUI:SetDesc(string.format("Attack Area Token: %s\nCost: %s | Size: +%s%%", FormatNumber(currentToken), FormatNumber(AttackAreaUpgradeConfig.GetEvolveCost(AttackAreaUpgradeConfig,currentLevel)), AttackAreaUpgradeConfig.GetAreaSize(AttackAreaUpgradeConfig, currentLevel)))
							AttackAreaProgressUI:Unlock()
							AttackAreaToggle:Unlock()
						end
                    -- AttackAreaProgressUI:SetDesc(string.format("Attack Area Token\nAmount: %s", FormatNumber(currentToken)))
                end)

            end

			if PlayerData.YenUpgrades then
				local YenUpgrades = PlayerData.YenUpgrades or {}

                -- [ส่วนที่เพิ่ม] ดึงยอดเงินปัจจุบันมาแสดงผลที่หัวข้อใหญ่
				local currentYen = PlayerData.Attributes and PlayerData.Attributes.Yen or 0
				YenProgressUI:SetTitle(string.format("Yen", FormatNumber(currentYen)))
				YenProgressUI:SetDesc(string.format("Amount: %s", FormatNumber(currentYen)))
				for name, toggleUI in pairs(YenToggleUI) do
					local currentLevel = YenUpgrades[name] or 0
					local maxLevel = YenUpgradeConfig[name].MaxLevel or 0
					pcall(function()
                        -- 1. จัดการ Title และสถานะ MAX
						-- if currentLevel == nil then
						-- 	toggleUI:SetTitle(name .. " 🔒")
						-- 	toggleUI:SetDesc("Status: Locked")
						-- 	toggleUI:Lock()
						if currentLevel >= maxLevel then
							toggleUI:SetTitle(name .. " [MAX] ✅")
							toggleUI:SetDesc(string.format("Buff: +%s%%", GetYenBuff(name, currentLevel)))
							toggleUI:Lock()
							if State["YenSelected" .. name] then
								State["YenSelected" .. name] = false
								toggleUI:Set(false)
							end
						else
							local cost = GetYenCost(currentLevel);
							toggleUI:SetTitle(name .. " [" .. currentLevel .. "/" .. maxLevel .. "]")
							toggleUI:SetDesc(string.format("Cost: %s | Buff: +%s%%", FormatNumber(cost), FormatNumber(GetYenBuff(name, currentLevel))))
							toggleUI:Unlock()
						end
					end)
				end
			end
			if PlayerData.TokenUpgrades then
				local TokenUpgrades = PlayerData.TokenUpgrades
				for name, toggleUI in pairs(TokenToggleUI) do
					local currentLevel = TokenUpgrades[name]
					local config = TokenUpgradeConfig[name]
					local maxLevel = config and config.MaxLevel or 0

                    -- [ส่วนที่เพิ่ม] ดึงยอดเงินปัจจุบันมาแสดงผลที่หัวข้อใหญ่
					local currentToken = PlayerData.Materials and PlayerData.Materials.UpgradeToken or 0
					TokenProgressUI:SetTitle(string.format("Upgrade Shard", FormatNumber(currentToken)))
					TokenProgressUI:SetDesc(string.format("Amount: %s", FormatNumber(currentToken)))
					pcall(function()
						-- if currentLevel == nil then
                        --     -- สถานะล็อก (🔒)
						-- 	toggleUI:SetTitle(name .. " 🔒")
						-- 	toggleUI:SetDesc("Status: Locked")
						-- 	toggleUI:Lock()
						if currentLevel >= maxLevel then
                            -- สถานะอัปเกรดเต็ม (MAX)
							toggleUI:SetTitle(name .. " [MAX] ✅")
                            -- ดึงค่า Buff มาแสดงผล
							local buffValue = GetTokenBuff(name, currentLevel)
							toggleUI:SetDesc(string.format("Buff: +%s%%", FormatNumber(buffValue)))
							toggleUI:Lock()
						else
                            -- สถานะกำลังอัปเกรด
							toggleUI:Unlock()
							toggleUI:SetTitle(name .. " [" .. currentLevel .. "/" .. maxLevel .. "]")

                            -- สำคัญ: ตรวจสอบว่า GetTokenCost ต้องการ (level, name) หรือไม่
							local cost = GetTokenCost(currentLevel, name)
							local buffValue = GetTokenBuff(name, currentLevel)

                            -- แสดงข้อมูลราคา, บัฟ และจำนวน Token ที่มี
							toggleUI:SetDesc(string.format("Cost: %s | Buff: +%s%%", FormatNumber(cost), FormatNumber(buffValue)))
						end
					end)
				end
			end
		end
		task.wait(2)
	end
end)
----------------------------------------------------------------
-- Fire Yen Upgrade
----------------------------------------------------------------
local function FireYenUpgrade(stat)
	Reliable:FireServer("Yen Upgrade", {
		stat
	})
end
----------------------------------------------------------------
-- Fire Token Upgrade
----------------------------------------------------------------
local function FireTokenUpgrade(stat)
	Reliable:FireServer("Token Upgrade", {
		stat
	})
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
task.spawn(function()
    while true do
        if Window.Destroyed then break end

        -- ทำงานเฉพาะเมื่อเปิดใช้งาน Auto ใดๆ อยู่ (ลดการทำงาน CPU)
        local isAnyAutoEnabled = State.AutoRankUp or State.SelectedStat or next(State.YenUpgradeState) or next(State.TokenUpgradeState)
        if isAnyAutoEnabled then
            -- ใช้ PlayerData ที่เราสแกนเจอจาก Loop UI (แชร์ข้อมูลกัน)
            local PlayerData = GetPlayerData()
            if PlayerData and PlayerData.Attributes then
                -- --- [ 1. Auto Rank Up ] ---
                if State.AutoRankUp then
                    local currentRank = PlayerData.Attributes.Rank or 0
                    local currentMastery = PlayerData.Attributes.Mastery or 0
                    local req = GetRankRequirement(currentRank)

                    -- เช็คว่า Rank ไม่ตัน และ Mastery ถึงเกณฑ์
                    if currentRank < MaxRankCap and currentMastery >= (req or 0) then
                        Reliable:FireServer("RankUp", {})
                        task.wait(0.3) -- รอเล็กน้อยหลังอัปเกรด
                    end
                end

                -- --- [ 2. Auto Stats (Points) ] ---
                -- ส่วนของ Auto Stats ในลูป Auto Upgrade
                if State.SelectedStat and State.SelectedStat ~= "--" then
                    pcall(function()
                        -- 1. คำนวณหาแต้มคงเหลือจริง (Points Available)
                        local lv = PlayerData.Attributes.Level or 1
                        local asc = PlayerData.Attributes.Ascension or 0
                        local totalPoints = lv * (1 + asc)

                        local spentPoints = 0
                        for _, amount in pairs(PlayerData.StatPoints) do
                            spentPoints = spentPoints + amount
                        end

                        local pointsAvailable = totalPoints - spentPoints

                        -- 2. ส่งคำสั่งอัปเกรดเมื่อมีแต้มเหลือ
                        if pointsAvailable > 0 then
                            -- ดึงจำนวนที่ต้องการอัปจาก StatPointAmount (ที่เราสแกนเจอว่าเป็น 19)
                            local amountToUpgrade = PlayerData.Attributes.StatPointAmount or 1

                            -- ตรวจสอบไม่ให้อัปเกินแต้มที่มีอยู่จริง
                            local finalAmount = math.min(amountToUpgrade, pointsAvailable)

                            Reliable:FireServer("Distribute Stat Point", {
                                State.SelectedStat,
                                finalAmount -- อัปตามจำนวนที่กำหนด หรือเท่าที่แต้มเหลือ
                            })
                            task.wait(0.2) -- หน่วงเวลาเล็กน้อยเพื่อป้องกันการส่งซ้ำซ้อน
                        end
                    end)
                end

                if State.AutoAttackAreaUpgrade then
                    local AttackAreaUpgrades = PlayerData.AttackArea or {}
                    local currentLevel = AttackAreaUpgrades or 0
                    local maxLevel = AttackAreaUpgradeConfig.MAX or 9

                    local currentToken = PlayerData.Materials and PlayerData.Materials.AttackAreaToken or 0
                    local cost = AttackAreaUpgradeConfig.GetEvolveCost(AttackAreaUpgradeConfig,currentLevel)

                    if currentLevel < maxLevel and currentToken >= (cost or 0) then
                        Reliable:FireServer("Evolve AttackArea")
                        task.wait(0.2)
                    end
                end

                -- --- [ 3. Auto Yen Upgrades ] ---
                local currentYen = PlayerData.Attributes.Yen or 0
                for name, isEnabled in pairs(State.YenUpgradeState) do
                    if isEnabled then
                        local currentLevel = PlayerData.YenUpgrades and PlayerData.YenUpgrades[name] or 0
                        local maxLevel = YenUpgradeConfig[name] and YenUpgradeConfig[name].MaxLevel or 0
                        local cost = GetYenCost(currentLevel)

                        -- เช็คว่าไม่ตันและเงินพอ
                        if currentLevel < maxLevel and currentYen >= (cost or 0) then
                            FireYenUpgrade(name)
                            task.wait(0.2)
                        end
                    end
                end

                -- --- [ 4. Auto Token Upgrades ] ---
                local currentToken = PlayerData.Materials and PlayerData.Materials.UpgradeToken or 0
                for name, isEnabled in pairs(State.TokenUpgradeState) do
                    if isEnabled then
                        local currentLevel = PlayerData.TokenUpgrades and PlayerData.TokenUpgrades[name] or 0
                        local maxLevel = TokenUpgradeConfig[name] and TokenUpgradeConfig[name].MaxLevel or 0
                        local cost = GetTokenCost(currentLevel, name)

                        -- เช็คว่าไม่ตันและ Token พอ
                        if currentLevel < maxLevel and currentToken >= (cost or 0) then
                            FireTokenUpgrade(name)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end

        task.wait(0.5) -- ปรับความเร็วลูปให้พอดี (2 ครั้งต่อวินาที) ไม่กินสเปคเครื่อง
    end
end)
------------------------------------------------------------------------------------
--- GachaSection
------------------------------------------------------------------------------------
local GachaSection = Window:Section({
	Title = "Gacha & Augments",
	-- Icon = "dices",
	Opened = true,
});
------------------------------------------------------------------------------------
--- GachaSection Tab 1
------------------------------------------------------------------------------------
local GachaRoll = GachaSection:Tab({
	Title = "Rolls",
	Icon = "dices",
	IconColor = Purple,
	IconShape = "Square",
})
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local ConfigZones = ZoneModule
local sortedList = {}
------------------------------------------------------------------------------------
--- 1. นำข้อมูลจาก Module มาใส่ตารางชั่วคราวเพื่อเตรียม Sort
------------------------------------------------------------------------------------
for zoneKey, zoneData in pairs(ConfigZones) do
    table.insert(sortedList, {
        Key = zoneKey,
		DisplayName = zoneData.Name,
        Order = zoneData.Order,
        Objects = zoneData.Objects
    })
end
------------------------------------------------------------------------------------
--- 2. ทำการ Sort ตารางตามค่า Order (น้อยไปมาก)
------------------------------------------------------------------------------------
table.sort(sortedList, function(a, b)
    return a.Order < b.Order
end)
------------------------------------------------------------------------------------
--- 3. แปลงข้อมูลให้อยู่ในรูปแบบ zones = { { ["Name"] = { screens } } }
------------------------------------------------------------------------------------
local zones = {}
for _, data in ipairs(sortedList) do
    local screens = {}
    if data.Objects then
        for _, obj in ipairs(data.Objects) do
            if obj.Screen then
                table.insert(screens, obj.Screen)
            end
        end
    end

    table.insert(zones, {
        [data.DisplayName] = screens
    })
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function GetGachaConfig(name)
    -- หาไฟล์ใน RollGachas ก่อน
    local file = RollGachaModule:FindFirstChild(name)
    if not file then
        -- ถ้าไม่เจอ หาใน RollGachaUpgrades
        file = RollGachaUpgradeModule:FindFirstChild(name)
    end
    if file and file:IsA("ModuleScript") then
        return require(file)
    end
    return nil
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function GetRollUpgradeConfig(name)
    -- หาไฟล์ใน RollGachas ก่อน
    local file = RollGachaUpgradeModule:FindFirstChild(name)
    if file and file:IsA("ModuleScript") then
        return require(file)
    end
    return nil
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local RollToggleUI = {}
local RollConfigCache = {}
for _, zoneInfo in ipairs(zones) do
    for zoneName, screenList in pairs(zoneInfo) do
        -- 1. ตารางเก็บ Screen ที่พบในโฟลเดอร์ที่กำหนด
        local validGachasInZone = {}

        for _, screenName in ipairs(screenList) do
            local config = GetGachaConfig(screenName)
            if config then
                table.insert(validGachasInZone, screenName)
                -- เก็บข้อมูลที่ดึงมาจาก Config ลง Cache
                local maxLvl = 7
                if config.List and type(config.List) == "table" then
                    maxLvl = #config.List -- นับจำนวนสมาชิกในตาราง List
                end

                RollConfigCache[screenName] = {
                    Material = config.Material,
                    Display = config.Display,
                    MaxLevel = tostring(maxLvl) -- ✨ เก็บเป็น String เพื่อไปเช็คกับ PlayerData.Vault
                }
            end
        end

        -- 2. สร้าง UI เฉพาะโซนที่มีรายการ Gacha หรือ Upgrade เท่านั้น
        if #validGachasInZone > 0 then
            GachaRoll:Section({
                Title = zoneName,
                TextSize = 14
            })

            local currentGroup = nil
            for i, gachaName in ipairs(validGachasInZone) do
                -- จัดกลุ่ม Toggle ทีละ 2 ปุ่ม
                if i % 2 == 1 then
                    currentGroup = GachaRoll:Group({})
                end

                -- สร้าง State และ Toggle สำหรับรายการนั้นๆ
                State.GachaState[gachaName] = false

                RollToggleUI[gachaName] = currentGroup:Toggle({
                    Title = gachaName,
                    Value = false,
                    Callback = function(v)
                        State.GachaState[gachaName] = v
                    end
                })
            end
        end
    end
end
----------------------------------------------------------------
-- [ส่วนเพิ่มเติม] ฟังก์ชันจัดการ UI ตอนสุ่ม (Anti-Animation)
----------------------------------------------------------------
task.spawn(function()
	local Players = game:GetService("Players")
	local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	while true do
		if Window.Destroyed then
			break
		end

        -- 1. เช็คว่าตอนนี้เราเปิด Auto Roll ตัวไหนทิ้งไว้บ้างไหม
		local isRolling = false
		for name, isActive in pairs(State.GachaState) do
			if isActive then
				isRolling = true
				break
			end
		end

        -- 2. ถ้ากำลังสุ่มอยู่ ให้รันตรรกะปิด Animation และบังคับเปิด HUD
		if isRolling then
            -- ปิดหน้าต่างสุ่ม (Crate) เพื่อไม่ให้แสดง Animation
			local CrateUI = PlayerGui:FindFirstChild("Crate")
			if CrateUI then
				CrateUI.Parent = nil
			end

            -- บังคับให้หน้าจอหลัก (HUD) แสดงผลตลอดเวลา
			local ScreenUI = PlayerGui:FindFirstChild("Screen")
			if ScreenUI and (not ScreenUI.Enabled) then
				ScreenUI.Enabled = true
			end

            -- บังคับเปิดแถบเมนูด้านบนของ Roblox
			local Topbar = PlayerGui:FindFirstChild("TopbarStandard")
			if Topbar and (not Topbar.Enabled) then
				Topbar.Enabled = true
			end
		end
		task.wait(0.5) -- เช็คทุกๆ 0.5 วินาทีตามต้นฉบับ
	end
end)
------------------------------------------------------------------------------------
--- GachaSection Tab 1.5
------------------------------------------------------------------------------------
local RollUpgradeTap = GachaSection:Tab({
	Title = "Roll Upgrades",
	Icon = "package-plus",
	IconColor = Purple,
	IconShape = "Square",
})
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local RollUpgradeToggleUI = {}
local RollUpgradeConfigCache = {}
for _, zoneInfo in ipairs(zones) do
    for zoneName, screenList in pairs(zoneInfo) do
        -- 1. ตารางเก็บ Screen ที่พบในโฟลเดอร์ที่กำหนด
        local validRollUpgradeInZone = {}

        for _, screenName in ipairs(screenList) do
            local config = GetRollUpgradeConfig(screenName)
            if config then
                table.insert(validRollUpgradeInZone, screenName)
                -- เก็บข้อมูลที่ดึงมาจาก Config ลง Cache

                RollUpgradeConfigCache[screenName] = {
                    Material = config.UpgradeMaterial,
                    Display = config.Display,
                    MaxLevel = config.MaxLevel or 50,
                }
            end
        end

        -- 2. สร้าง UI เฉพาะโซนที่มีรายการ Gacha หรือ Upgrade เท่านั้น
        if #validRollUpgradeInZone > 0 then
            RollUpgradeTap:Section({
                Title = zoneName,
                TextSize = 14
            })

            local currentGroup = nil
            for i, gachaName in ipairs(validRollUpgradeInZone) do
                -- จัดกลุ่ม Toggle ทีละ 2 ปุ่ม
                if i % 2 == 1 then
                    currentGroup = RollUpgradeTap:Group({})
                end

                -- สร้าง State และ Toggle สำหรับรายการนั้นๆ
                State.RollUpgradeState[gachaName] = false

                RollUpgradeToggleUI[gachaName] = currentGroup:Toggle({
                    Title = gachaName,
                    Value = false,
                    Callback = function(v)
                        State.RollUpgradeState[gachaName] = v
                    end
                })
            end
        end
    end
end
------------------------------------------------------------------------------------
--- GachaSection Tab 2
------------------------------------------------------------------------------------
local TrainerUpgradeTab = GachaSection:Tab({
	Title = "Trainers",
	Icon = "box",
	IconColor = Purple,
	IconShape = "Square",
})
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local function GetTrainerConfig(name)
    -- หาไฟล์ใน RollGachas ก่อน
    local file = TrainerModule:FindFirstChild(name)
    if file and file:IsA("ModuleScript") then
        return require(file)
    end
    return nil
end
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
local TrainerToggleUI = {}
local TrainerConfigCache = {}
for _, zoneInfo in ipairs(zones) do
    for zoneName, screenList in pairs(zoneInfo) do
        -- 1. ตารางเก็บ Screen ที่พบในโฟลเดอร์ที่กำหนด
        local validTrainersInZone = {}

        for _, screenName in ipairs(screenList) do
            local config = GetTrainerConfig(screenName)
            if config then
                table.insert(validTrainersInZone, screenName)
                -- เก็บข้อมูลที่ดึงมาจาก Config ลง Cache

                TrainerConfigCache[screenName] = {
                    Material = config.TOKEN_NAME,
                    Display = config.Display,
                    MaxLevel = config.MAX_LEVEL or 100,
                    -- ดึงฟังก์ชันมาเก็บไว้เรียกใช้ใน Loop
                    GetCost = config.GetCost, 
                    GetChance = config.GetChance 
                }
            end
        end

        -- 2. สร้าง UI เฉพาะโซนที่มีรายการ Gacha หรือ Upgrade เท่านั้น
        if #validTrainersInZone > 0 then
            TrainerUpgradeTab:Section({
                Title = zoneName,
                TextSize = 14
            })

            local currentGroup = nil
            for i, gachaName in ipairs(validTrainersInZone) do
                -- จัดกลุ่ม Toggle ทีละ 2 ปุ่ม
                if i % 2 == 1 then
                    currentGroup = TrainerUpgradeTab:Group({})
                end

                -- สร้าง State และ Toggle สำหรับรายการนั้นๆ
                State.TrainerState[gachaName] = false

                TrainerToggleUI[gachaName] = currentGroup:Toggle({
                    Title = gachaName,
                    Value = false,
                    Callback = function(v)
                        State.TrainerState[gachaName] = v
                    end
                })
            end
        end
    end
end
----------------------------------------------------------------
-- 
----------------------------------------------------------------
task.spawn(function()
    while true do
        -- 1. หยุดทำงานทันทีถ้าทำลาย Window ไปแล้ว
        if Window.Destroyed then break end

        -- 2. ตรวจสอบสถานะ Window: จะทำงานเฉพาะตอนที่ UI เปิดอยู่เท่านั้น
        -- ใช้ Window.Opened หรือเช็คสถานะจาก Library ของคุณ เพื่อหยุดการทำงานขณะพับสคริปต์
        if not Window.Closed then
            local PlayerData = GetPlayerData()
            
            if PlayerData and PlayerData.Materials then
                local TrainerLevels = PlayerData.CrateUpgrades or {}

                -- --- [ ส่วนของ Gacha / Rolls ] ---
                for name, toggleUI in pairs(RollToggleUI) do
                    local configData = RollConfigCache[name]
                    if configData then
                        local tokenKey = configData.Material or (name .. "Token")
                        local currentAmount = PlayerData.Materials[tokenKey] or 0
                        
                        -- เช็ค Max Level
                        local targetMaxLevel = configData.MaxLevel
                        local isMaxed = PlayerData.Vault and PlayerData.Vault[name] and PlayerData.Vault[name][targetMaxLevel] == true
                        
                        pcall(function()
                            if isMaxed then
                                toggleUI:SetTitle(name .. " [MAX] ✅")
                                if State.GachaState[name] then
                                    State.GachaState[name] = false
                                    toggleUI:Set(false)
                                end
                                toggleUI:Lock()
                            else
                                toggleUI:SetTitle(name)
                                toggleUI:Unlock()
                            end
                            toggleUI:SetDesc((configData.Display or name) .. " Token: " .. FormatNumber(currentAmount))
                        end)
                    end
                end

                -- --- [ ส่วนของ Roll Upgrade ] ---
                for name, toggleUI in pairs(RollUpgradeToggleUI) do
                    local configData = RollUpgradeConfigCache[name]
                    if configData then
                        -- 1. หา Current Level โดยการดึงค่า Value จาก Key ล่าสุดใน GachaLevel
                        local gachaData = PlayerData.GachaLevel and PlayerData.GachaLevel[name]
                        local currentLevel = 0

                        if type(gachaData) == "table" then
                            local highestGachaCount = -1
                            for gachaCount, gachaLevel in pairs(gachaData) do
                                local countNum = tonumber(gachaCount)
                                if countNum and countNum > highestGachaCount then
                                    highestGachaCount = countNum
                                    -- ✨ เลเวลที่แท้จริงคือ Value (ในรูปคือ 50)
                                    currentLevel = tonumber(gachaLevel) or 0 
                                end
                            end
                        elseif type(gachaData) == "number" then
                            currentLevel = gachaData
                        end
                    
                        -- 2. ข้อมูลจาก Config
                        local targetMaxLevel = tonumber(configData.MaxLevel) or 100
                        local tokenKey = configData.Material or (name .. "Token")
                        local currentAmount = (PlayerData.Materials and PlayerData.Materials[tokenKey]) or 0

                        -- 3. เช็คสถานะ Max
                        local isMaxed = currentLevel >= targetMaxLevel

                        pcall(function()
                            if isMaxed then
                                toggleUI:SetTitle(name .. " [MAX] ✅")
                                if State.RollUpgradeState and State.RollUpgradeState[name] then
                                    State.RollUpgradeState[name] = false
                                    toggleUI:Set(false)
                                end
                                toggleUI:Lock()
                            else
                                -- ✨ แสดงผลเลเวล 50 ตามค่าใน Value
                                toggleUI:SetTitle(string.format("%s [%d/%d]", name, currentLevel, targetMaxLevel))
                                toggleUI:Unlock()
                            end
                        
                            -- 4. คำอธิบาย
                            local detailText = ""
                            if not isMaxed then
                                local cost = configData.GetCost and configData.GetCost(currentLevel) or 0
                                detailText = string.format("\nCost: %d", cost)
                            else
                                detailText = "\n✨ Max Level Reached!"
                            end
                        
                            toggleUI:SetDesc(string.format("%s Token: %s%s", configData.Display or name, FormatNumber(currentAmount), detailText))
                        end)
                    end
                end

                -- --- [ ส่วนของ Trainers ] ---
                for name, toggleUI in pairs(TrainerToggleUI) do
                    local configData = TrainerConfigCache[name]
                    if configData then
                        -- กำหนดค่าเริ่มต้นเป็น 0 หรือ 1 เสมอเพื่อกัน Error
                        local currentLevel = tonumber(TrainerLevels[name]) or 0
                        local maxLevel = tonumber(configData.MaxLevel) or 100
                        local tokenKey = configData.Material or (name .. "Token")

                        -- ตรวจสอบ Materials ว่ามีตารางไหม ถ้าไม่มีให้เป็น 0
                        local currentAmount = (PlayerData.Materials and PlayerData.Materials[tokenKey]) or 0

                        -- เช็คสถานะการปลดล็อก (ถ้าอยากโชว์ 🔒 แต่ไม่ Lock ปุ่มให้กดไม่ได้)

                        pcall(function()
                            -- 1. จัดการ Title
                            if currentLevel >= maxLevel then
                                toggleUI:SetTitle(name .. " [MAX] ✅")
                                if State.TrainerState[name] then
                                    State.TrainerState[name] = false
                                    toggleUI:Set(false)
                                end
                                toggleUI:Lock() -- ล็อกเฉพาะตัวที่ MAX
                            else
                                -- ไม่ Lock ปุ่ม แต่ใส่ไอคอน 🔒 ไว้หลังชื่อแทนเพื่อให้รู้ว่ายังไม่ปลดด่าน
                                toggleUI:SetTitle(string.format("%s [%d/%d]", name, currentLevel, maxLevel))
                                toggleUI:Unlock()
                            end

                            -- 2. จัดการ Description (คำนวณแม้จะยังไม่ปลดล็อก)
                            local detailText = ""
                            if currentLevel < maxLevel then
                                -- เรียกฟังก์ชันคำนวณจาก Config (ส่ง 0 ไปถ้ายังไม่เริ่มอัป)
                                local cost = 0
                                local chance = 0

                                if configData.GetCost then
                                    cost = configData.GetCost(currentLevel)
                                end

                                if configData.GetChance then
                                    chance = configData.GetChance(currentLevel)
                                end

                                detailText = string.format("\nCost: %d | Chance: %.1f%%", cost, chance)
                            else
                                detailText = "\n✨ Max Upgraded!"
                            end

                            -- แสดงผล Description เสมอ
                            toggleUI:SetDesc(string.format("%s: %s%s", configData.Display or name, FormatNumber(currentAmount), detailText))
                        end)
                    end
                end
            end
        end
        -- 3. เพิ่มเวลาการรอ (Wait) เป็น 1.5 หรือ 2 วินาที เพื่อลดภาระเครื่อง
        task.wait(1.5)
    end
end)
----------------------------------------------------------------
--- Loop auto upgrade trainer
----------------------------------------------------------------
task.spawn(function()
	while true do
		if Window.Destroyed then
			break
		end

        -- ดึงข้อมูล PlayerData ล่าสุดจากถังข้อมูลกลาง
		local PlayerData = GetPlayerData()
		if PlayerData then
            for name, enabled in pairs(State.GachaState) do
                local configData = RollConfigCache[name]
		    	if enabled then
                    -- 1. ค้นหาชื่อ Token และจำนวนที่มีปัจจุบัน
		    		local tokenKey = configData.Material or (name .. "Token")
		    		local currentAmount = (PlayerData and PlayerData.Materials and PlayerData.Materials[tokenKey]) or 0

                    -- 2. เงื่อนไข: ถ้าของมีตั้งแต่ 10 ชิ้นขึ้นไป ถึงจะส่ง Remote
		    		if currentAmount >= 10 then
		    			local args = {
		    				[1] = "Crate Roll Start",
		    				[2] = {
		    					[1] = name,
		    					[2] = false,
		    				}
		    			}
		    			Reliable:FireServer(unpack(args))
		    			task.wait(0.5) -- ดีเลย์ระหว่างการส่งแต่ละครั้ง
		    		end
		    	end
		    end

            for name, enabled in pairs(State.RollUpgradeState) do
                if enabled then
                    local configData = RollUpgradeConfigCache[name]
                    if configData then
                        -- 1. ดึงเลเวลปัจจุบัน (Value) จาก GachaLevel โดยหาจาก Key ที่สูงที่สุด
                        local gachaData = PlayerData.GachaLevel and PlayerData.GachaLevel[name]
                        local currentLevel = 0

                        if type(gachaData) == "table" then
                            local highestGachaCount = -1
                            for gachaCount, gachaLevel in pairs(gachaData) do
                                local countNum = tonumber(gachaCount)
                                if countNum and countNum > highestGachaCount then
                                    highestGachaCount = countNum
                                    currentLevel = tonumber(gachaLevel) or 0 -- ใช้ค่า Value เป็นเลเวล
                                end
                            end
                        elseif type(gachaData) == "number" then
                            currentLevel = gachaData
                        end
                    
                        local maxLevel = tonumber(configData.MaxLevel) or 100

                        -- 2. ตรวจสอบว่าเลเวลยังไม่เต็ม
                        if currentLevel < maxLevel then
                            -- 3. คำนวณราคา (Cost)
                            local cost = configData.GetCost and configData.GetCost(currentLevel) or 1

                            -- 4. ตรวจสอบจำนวน Material (Token)
                            local tokenKey = configData.Material or (name .. "Token")
                            local currentAmount = (PlayerData.Materials and PlayerData.Materials[tokenKey]) or 0
                        
                            -- 5. เงื่อนไข: ถ้า Token พอ ให้ส่งคำสั่งอัปเกรด
                            if currentAmount >= cost then
                                -- ⚠️ หมายเหตุ: ตรวจสอบชื่อ Remote ให้ตรงกับระบบ Gacha Upgrade ของคุณ
                                -- ปกติจะเป็น "Gacha Upgrade" หรือ "Roll Upgrade" ไม่ใช่ "Crate Upgrade"
                                local args = {
                                    [1] = "Crate Upgrade", -- เปลี่ยนให้ตรงกับ Remote ของระบบสุ่ม
                                    [2] = {
                                        [1] = name, 
                                    }
                                }
                                Reliable:FireServer(unpack(args))
                            
                                -- รอการตอบสนองจากเซิร์ฟเวอร์
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end

			for name, enabled in pairs(State.TrainerState) do
				if enabled then
                    -- 1. ดึงเลเวลปัจจุบันจาก CrateUpgrades
                    local configData = TrainerConfigCache[name]
					local currentLevel = (PlayerData.CrateUpgrades and PlayerData.CrateUpgrades[name]) or 0
					local maxLevel = tonumber(configData.MaxLevel) or 100
					if currentLevel < maxLevel then
                        -- 2. คำนวณราคาที่ต้องใช้ตามสูตร (Level ^ 1) + 9
						local cost = configData.GetCost and configData.GetCost(currentLevel) or (math.ceil(currentLevel ^ 0.7) * 1 + 5)

                        -- 3. ตรวจสอบจำนวน Material ที่มี
						local tokenKey = configData.Material or (name .. "Token")
				        local currentAmount = (PlayerData and PlayerData.Materials and PlayerData.Materials[tokenKey]) or 0

                        -- 4. เงื่อนไข: ถ้าของมีพอให้ทำการอัปเกรด
						if currentAmount >= cost then
							local args = {
								[1] = "Chance Upgrade",
								[2] = {
									[1] = name, -- เช่น "Sung", "Wise"
								}
							}
							Reliable:FireServer(unpack(args))

                            -- รอให้เซิร์ฟเวอร์อัปเดตข้อมูลสักครู่ก่อนรอบถัดไป
							task.wait(0.5)
						else
                            -- ถ้าของไม่พอ จะข้ามไปเช็คตัวอื่นที่เปิด Auto ไว้ทันที
						end
					end
				end
			end
		end
		task.wait(0.5) -- หน่วงเวลาภาพรวมของ Loop
	end
end)
----------------------------------------------------------------
---
----------------------------------------------------------------
local SettingTab = Window:Tab({
	Title = "Settings",
	Icon = "settings-2",
	IconColor = Grey,
	IconShape = "Square",
})
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
SettingTab:Button({
	Title = "Boost FPS (Low Graphics)",
	Icon = "rocket",
	Callback = function()
		BoostFps()
	end
})
----------------------------------------------------------------
-- Auto Fuse Weapons
----------------------------------------------------------------
SettingTab:Toggle({
	Title = "Auto Fuse Weapons",
	Callback = function(v)
		State.AutoFuse = v;
		if v then
			task.spawn(function()
				while State.AutoFuse do
					if Window.Destroyed then
						break;
					end;
					if Reliable then
						pcall(function()
							Reliable:FireServer("Weapon Fuse All");
						end);
					end;
					task.wait(5);
				end;
			end);
		end;
	end
});
------------------------------------------------------------------------------------
---
------------------------------------------------------------------------------------
Window:SelectTab(1);

Window:OnClose(function()
   
end)
