------------------------------------------------------------------------------------
--- Color
------------------------------------------------------------------------------------
local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green = Color3.fromHex("#10C550")
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Red = Color3.fromHex("#EF4F1D")
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
local YenModule = require(ConfigsPath.Machines.YenUpgrades);
local TokenModule = require(ConfigsPath.Machines.TokenUpgrades);
local RankModule = require(ConfigsPath.Machines.RankUp);
local UtilsModule = require(ConfigsPath.Utility.Utils);
local MaterialsModule = require(ConfigsPath.General.Materials);
local GamemodeModule = require(ConfigsPath.Gamemodes);

local ChanceModules = {};
local ChancePath = ReplicatedStorage.Scripts.Configs:FindFirstChild("ChanceUpgrades");
------------------------------------------------------------------------------------
--- Game Script
------------------------------------------------------------------------------------
local YenUpgradeConfig = YenModule.Config;
local TokenUpgradeConfig = TokenModule.Config;
local MaxRankCap = RankModule.MAX or 33;
local function GetYenCost(lvl)
	return YenModule.GetUpgradeCost(lvl);
end;
local function GetYenBuff(name, lvl)
	return YenModule.GetUpgradeBuff(name, lvl);
end;
local function GetTokenCost(lvl)
	return TokenModule.GetUpgradeCost(lvl);
end;
local function GetTokenBuff(name, lvl)
	return TokenModule.GetUpgradeBuff(name, lvl);
end;
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
	AutoYen_Luck = false,
	AutoYen_Damage = false,
	AutoYen_Yen = false,
	AutoYen_Mastery = false,
	AutoYen_Critical = false,
	AutoRollBiju = false,
	AutoRollRace = false,
	AutoRollSayajin = false,
	AutoRollFruits = false,
	AutoRollHaki = false,
	AutoRollBreathing = false,
	AutoRollOrganization = false,
	AutoRollTitan = false,
    AutoRollMagicEyes = false,
    AutoRollDemonArt = false,
    AutoUpgradeMagicEyes = false,
	AutoChance_Breath = false,
	AutoChance_Pirate = false,
	AutoChance_Wise = false,
	AutoChance_Leve = false,
	SelectedEnemy = nil,
	ZoneConfigurations = {},
	TargetDungeon = {},
	TargetRaid = {},
	TargetDefense = {} 
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
	SideBarWidth = 150,
	Theme = "Dark", -- Dark, Darker, Light, Aqua, Amethyst, Rose
	Size = UDim2.fromOffset(700, 400),
	MinSize = Vector2.new(700, 400),
    MaxSize = Vector2.new(700, 400),
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
	},
})

Window:OnDestroy(function()
	State.AutoFarm = false;
	State.AutoDungeon = false;
	State.AutoFuse = false;
	State.AutoRankUp = false;
	State.AutoRollBiju = false;
	State.AutoRollRace = false;
	State.AutoRollSayajin = false;
	State.AutoYen_Luck = false;
	State.AutoYen_Damage = false;
	State.AutoYen_Yen = false;
	State.AutoYen_Mastery = false;
	State.AutoYen_Critical = false;
	if CurrentZoneName ~= "" and State.SelectedEnemy then
		-- SaveZoneConfig(CurrentZoneName, State.SelectedEnemy);
	end;
end);
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
                
                local groupName = display 

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
    local allModes = GamemodeModule:GetList(GamemodeModule)
    local unifiedList = {}

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
        ["Default"] = 4
    }

    local GamemodeMap = {
        ["Defense: Easy"] = "Defense:1",
        ["Dungeon: Easy"] = "Dungeon:1",
    	["Dungeon: Medium"] = "Dungeon:2",
    	["Dungeon: Hard"] = "Dungeon:3",
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
                    -- Difficulty = phase.Name or "Easy",
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
local function LogicGamemodes()
	local wasInGamemode = false;
	local currentTargetObj = nil;
	local refreshTimer = 0;
	while State.AutoDungeon do
		if Window.Destroyed then
			break;
		end;
		local currentMap = GetCurrentMapStatus();
		local inLobbyZone = false;
        -- เช็คว่าอยู่ในแมพต่อสู้หรือไม่
        local isFightingZone = (currentMap ~= "Unknown" and currentMap ~= "Dungeon" and not Workspace:FindFirstChild("Zones")) 
            or string.find(currentMap, ":Active") 
            or currentMap:match("^Dungeon:%d+") or currentMap == "Raid" or currentMap == "Defense" or currentMap == "ShadowGate" or currentMap == "PirateTower";

            
        if currentMap ~= "Unknown" then
            if isFightingZone then
                wasInGamemode = true;
                if os.time() - refreshTimer > 1 then
                    RefreshEnemyData();
                    refreshTimer = os.time();
                end;

                -- วนลูปตีมอนสเตอร์ทุกตัวที่เจอใน Map
                local foundEnemy = false
                for _, enemyList in pairs(GlobalEnemyMap) do
                    for _, enemyObj in ipairs(enemyList) do
                        if enemyObj.Alive == true and enemyObj.Data and enemyObj.Data.CFrame then
                            foundEnemy = true
                            
                            -- 1. วาร์ปไปหา (เลือกตัวใดตัวหนึ่งใน Loop มาเป็นตำแหน่งหลัก)
                            if hrp then
                                hrp.CFrame = enemyObj.Data.CFrame * CFrame.new(0, 0, -5)
                            end

                            -- 2. ส่ง Remote ตี (ยิงรัวทุกตัวที่ยังมีชีวิต)
                            if enemyObj.Uid and Unreliable then
                                pcall(function()
                                    Unreliable:FireServer("Hit", {
                                        enemyObj.Uid
                                    });
                                end);
                            end
                        end
                    end
                end

                if not foundEnemy then
                    RefreshEnemyData()
                end

                task.wait(0.1);
			elseif inLobbyZone or wasInGamemode and (not isFightingZone) then
                -- print("warp farm")
                currentTargetObj = nil;
                GlobalEnemyMap = {};
                if LastZone and LastZone ~= "" and LastZone ~= "Unknown" then
                    task.wait(10);
                    -- Window:Notify({Title = "Finished", Content = "Returning to " .. LastZone, Duration = 3});
                    wasInGamemode = false;
                    if Reliable then pcall(function() Reliable:FireServer("Zone Teleport", {LastZone}) end) end;
                    task.wait(5);
                    EnemyDropdown:Refresh(RefreshEnemyData());

                else
                    wasInGamemode = false;
                end;
			else
                -- [Logic การ Join แบบใหม่]
                local t = os.date("*t");
                local currentMinute = t.min;
                local joinTarget = nil;

                -- วนลูปเช็คด่านที่เราเลือกไว้ใน State.TargetDungeon
                for _, targetValue in pairs(State.TargetDungeon) do

                    -- targetValue จะเป็นค่าเช่น "Dungeon:1" หรือ "ShadowGate"
                    local split = string.split(targetValue, ":")
                    local mName = split[1]
                    local mIndex = tonumber(split[2])

                    local mData = GamemodeModule:Get(mName)
                    if mData then
                        if mData.PHASES and mData.PHASES[1] and mIndex then
                            local phase = mData.PHASES[mIndex]
                            if phase and phase.START_TIMES then
                                for _, startTime in ipairs(phase.START_TIMES) do
                                    if currentMinute == startTime then
                                        joinTarget = targetValue
                                        break
                                    end
                                end
                            end
                        elseif mData.TYPE and table.find(mData.TYPE, "KEY") then
                            -- ถ้าเป็นโหมดใช้กุญแจ (ไม่ต้องรอเวลา) ให้เข้าได้เลย
                            joinTarget = targetValue
                        end
                    end
                    if joinTarget then break end
                end
                
                print("===========================================")
                print("joinTarget: ",joinTarget)
                print("isFightingZone: ",isFightingZone)
                print("wasInGamemode: ",wasInGamemode)
                print("===========================================")

                if joinTarget and not isFightingZone then

                    print("Warp")

                    if currentMap ~= "Unknown" then LastZone = currentMap end;
                    -- Window:Notify({Title = "Auto Mode", Content = "Joining " .. joinTarget, Duration = 3});
                    if Reliable then 
                        pcall(function() Reliable:FireServer("Join Gamemode", {joinTarget}) end) 
                    end;
                    task.wait(5); -- รอโหลดแมพ
                end
                task.wait(1);
			end;
		end;
	end;
end;
------------------------------------------------------------------------------------
--- MainSection
------------------------------------------------------------------------------------
local MainSection = Window:Section({
	Title = "Main Features",
	Icon = "folder",
	Opened = true,
});
------------------------------------------------------------------------------------
--- MainSection Tab 1
------------------------------------------------------------------------------------
local FarmTab = MainSection:Tab({
	Title = "Farming",
	Icon = "swords",
    IconColor = Green,
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
	Icon = "clock-alert",
    IconColor = Red,
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

Window:SelectTab(1);