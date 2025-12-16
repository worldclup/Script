local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- */  Colors  /* --
local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green = Color3.fromHex("#10C550")
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Red = Color3.fromHex("#EF4F1D")

----------------------------------------------------------------
-- Game
----------------------------------------------------------------

local ReliableRemote = game.ReplicatedStorage:WaitForChild("Reply"):WaitForChild("Reliable")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

----------------------------------------------------------------
-- FPS BOOST (TOGGLE SAFE MODE)
----------------------------------------------------------------

local function EnableFPSBoost()

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
	loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/boost-fps-script.lua"))()
end


----------------------------------------------------------------
-- UI Window
----------------------------------------------------------------

local Window = WindUI:CreateWindow({
	Title = "Dek Dev Hub",
	-- Icon = "keyboard",
	SideBarWidth = 150,
    Theme = "Light",
	Size = UDim2.fromOffset(600, 360),
    Topbar = {
        Height = 44,
        ButtonsType = "Mac", -- Default or Mac
    },

})

Window:EditOpenButton({
	Title = "Dek",
	CornerRadius = UDim.new(0, 16),
	StrokeThickness = 2,
	Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
	OnlyMobile = false,
	Enabled = true,
	Draggable = true,
})


----------------------------------------------------------------
-- Enemy Data แยกตาม Zone
----------------------------------------------------------------
local EnemyData = {
	-- NARUTO (Shinobi Village)
	Naruto = {
		EnemyNameMap = {
			Zabuzao = {
				"Accessory (zabuza)",
				"Accessory (Meshes/12Accessory)",
				"Accessory (whitescarf)"
			},
			Tobao = {
				"Spiraling Orange Rogue Shinobi Mask w/ Hair",
				"Meshes/PurpleCollarlPAccessory"
			},
			Nargato = {
				"Accessory (Baki_HeadTemplate)",
				"Ears with Black Gauges"
			},
			Peixame = {
				"Accessory (Kisame)"
			},
			["Madeira (Boss)"] = {
				"Accessory (MadaraShoulderLeft)"
			},
			["Itaxin (Secret)"] = {
				"Accessory (Itachi)",
				"Accessory (Baki_HeadTemplate)"
			}
		},
		EnemyOrder = {
			Zabuzao = 1,
			Tobao = 2,
			Nargato = 3,
			Peixame = 4,
			["Madeira (Boss)"] = 5,
			["Itaxin (Secret)"] = 6
		}
	},
	-- DRAGON BALL (Namek Planet)
	DragonBall = {
		EnemyNameMap = {
			Picole = {
				"Omega Demon King of Earth Ears",
				"Omega Demon King of Earth Face",
				"Peak-olo Demon King of Earth Antenna"
			},
			Frioso = {
				"Accessory (Emperor Armor)",
				"Accessory (Emperor Tail)",
				"Accessory (First Form Emperor Face)",
				"Accessory (First Form Emperor Hat)"
			},
			Friozaco = {
				"Accessory (Emperor Cut Tail)",
				"Accessory (Third Form Emperor Face)",
				"Accessory (Third Form Emperor Hat)"
			},
			Bubu = {
				"Cape",
				"ChubbyEars",
				"ChubbyHead"
			},
			["Jeromin (Boss)"] = {
				"Midren Ears",
				"Midren Head"
			},
			["Gekao (Secret)"] = {
				"Accessory (Goku Black Left)",
				"Accessory (Goku Black Right)",
				"Accessory (Goku Black Shirt Black)",
				"Black Spiky Male Hair",
				"Earrings Potar Green"
			}
		},
		EnemyOrder = {
			Picole = 1,
			Frioso = 2,
			Friozaco = 3,
			Bubu = 4,
			["Jeromin (Boss)"] = 5,
			["Gekao (Secret)"] = 6
		}
	},
    -- One Piece (Desert Land)
	OnePiece = {
		EnemyNameMap = {
			Cobinha = {
				"Accessory (Koby_Face_Capt_001)",
				"Accessory (Koby_Hair_Capt_001)",
			},
			Buguinho = {
				"Accessory (BuggyHat_Original)",
				"Clown Pirate face",
				"Meshes/rig_for_people (3)_CubeAccessory",
				"Scarf",
				"defaultAccessory"
			},
			Marcao = {
				"Accessory (MeshPartAccessory)",
				"Meshes/birdtal1Accessory",
				"Meshes/marbeltAccessory",
				"moderation"
			},
			Cometa = {
				"Accessory (Kuma_001)",
				"Accessory (Kuma_Face_001)",
			},
			["Edmundo (Boss)"] = {
				"Fazer Processo de ItemAccessory",
				"L Ceremonial Epaulette",
				"MeshPartAccessory",
				"R Ceremonial Epaulette",
				"WhitePirateCaptain'sCloak(v2)",
				"b e a n"
			},
			["Leopardo (Secret)"] = {
				"Accessory (RL_Awaken_Face hair)",
				"Accessory (RL_Awaken_Tail_02 waist)",
				"Accessory (RL_Awaken_beard_03)",
			}
		},
		EnemyOrder = {
			Cobinha = 1,
			Buguinho = 2,
			Marcao = 3,
			Cometa = 4,
			["Edmundo (Boss)"] = 5,
			["Leopardo (Secret)"] = 6
		}
	},
    -- Demon Slayer (Demon Land)
	DemonSlayer = {
		EnemyNameMap = {
			Demon = {
				"Accessory (Black Stylish Layered Wolf Cut Short Hair)",
				"Accessory (MeshPartAccessory)",
				"Accessory (Meshes/messy hair 2Accessory)",
				"Accessory (Sekido)",
				"Meshes/hair_3Accessory",
				"zohak Demon Horns Black",
			},
			Lyokko = {
				"Accessory (MeshPartAccessory)",
				"Cyan_Sergal_Neck_Floof",
				"monster Face",
			},
			Jyutaro = {
				"Accessory (Meshes/17687533242 (1)Accessory)",
				"Fazer Processo de ItemAccessory",
				"Gyu's left bandaged arm",
				"Gyu's right bandaged arm",
				"MeshPartAccessory"
			},
			Dola = {
				"Accessory (Baki_HeadTemplate)",
				"Accessory (Douma)",
				"Fazer Processo de ItemAccessory"
			},
			["Mokushibo (Boss)"] = {
				"Accessory (Kokushibo Nichirin BladeAccessory)",
				"Accessory (Kokushibo)",
				"Accessory (Upper Moon 1 Demon Slayer Red Anime Hair)",
				"CapeShoulderAccessory",
				"CapeShoulderAccessory",
				"Eyes Leather CapeAccessory"
			},
			["Alaza (Secret)"] = {
				"Accessory (Baki_HeadTemplate)",
				"Accessory (MeshPartAccessory)",
				"Akaz Upper Moon Vest",
			}
		},
		EnemyOrder = {
			Demon = 1,
			Lyokko = 2,
			Jyutaro = 3,
			Dola = 4,
			["Mokushibo (Boss)"] = 5,
			["Alaza (Secret)"] = 6
		}
	},
    -- Paradis (Paradis)
	Paradis = {
		EnemyNameMap = {
			Richala = {
				"Another Short",
				"Blonde ombre",
				"DarkBeltAccessory",
				"FACE1",
				"HandleAccessory",
				"sword holderAccessory",
			},
			["Female titan"] = {
				"Another Short",
				"HEADAccessory",
			},
			Mandile = {
				"Accessory (Meshes/Jaw Titan UGCJER (1)Accessory)",
				"Accessory (Meshes/Jaw Titan UGCJERhair (2)Accessory)",
			},
			Blind = {
				"Accessory (Meshes/ArmoredTitanAccessory)",
			},
			["Colosso (Boss)"] = {
				"Accessory (colossal titan)",
			},
			["Elen yage (Secret)"] = {
				"Accessory (Handle1Accessory)",
				"Accessory (MeshPartAccessory)",
			}
		},
		EnemyOrder = {
			Richala = 1,
			["Female titan"] = 2,
			Mandile = 3,
			Blind = 4,
			["Colosso (Boss)"] = 5,
			["Elen yage (Secret)"] = 6
		}
	},
    -- Solo Level (Shadow City)
	SoloLevel = {
		EnemyNameMap = {
			TangFak = {
				"Accessory (MeshPartAccessory)",
				"Accessory (MeshPartAccessory)",
			},
			Sunly = {
				"Accessory (Meshes/Sung Il-Hwan.Accessory)",
				"Accessory (handcuffAccessory)",
			},
			Haler = {
				"Accessory (Anime Samurai Ninja Hair (Black))",
				"Accessory (defaultAccessory)",
			},
			Thomas = {
				"Accessory (Meshes/default_headAccessory1)",
				"LongWolfCutHair",
			},
			["Frieze (Boss)"] = {
				"Accessory (Baruka Elf Ears)",
				"Accessory (Baruka Hair)",
				"Accessory (Baruka)"
			},
			["Belu (Secret)"] = {
				"Armor",
				_AllowTransparentHead = true
			}
		},
		EnemyOrder = {
			TangFak = 1,
			Sunly = 2,
			Haler = 3,
			Thomas = 4,
			["Frieze (Boss)"] = 5,
			["Belu (Secret)"] = 6
		}
	},
}
----------------------------------------------------------------
-- State
----------------------------------------------------------------
local State = {
    ------Tab1-----------
	AutoFarm = false,
	FloatEnabled = false,
	SelectedZone = nil,
	SelectedEnemy = {},
	CurrentIndex = 1,
	CurrentTarget = nil,
	LastTargetName = nil,  -- ⭐ FIX: กันจำศัตรูเก่า,
    ------Tab2-----------
	AutoJoin = false,
    AutoEquipBest = false,
	Raid = {},
	ShadowGate = {},
	Defense = {},
	Dungeon = {},
	WasInGamemode = false,
    ------Tab3-----------
	AutoRankUp = false,
	SelectedStat = nil,
	YenSelectedLuck = false,
	YenSelectedYen = false,
	YenSelectedMastery = false,
	YenSelectedCritical = false,
	YenSelectedDamage = false,
    ------Tab4-----------
	GachaState = {},
    ------Tab4-----------
	ClaimState = false,

}

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local DifficultyIndex = {
	Easy = 1,
	Medium = 2,
	Hard = 3,
}

local ModeKey = {
	Dungeon = "Dungeon",
	Raid = "Raid",
	Defense = "Defense",
	ShadowGate = "ShadowGate",
}

local PriorityOrder = {
	"ShadowGate",
	"Raid",
	"Defense",
	"Dungeon",
}


----------------------------------------------------------------
-- Sidebar
----------------------------------------------------------------
-- 1
local FarmTab = Window:Tab({
	Title = "Farm",
	Icon = "swords",
	IconColor = Green,
	IconShape = "Square",
})
-- 2
local GamemodeTab = Window:Tab({
	Title = "Gamemode",
	Icon = "clock-alert",
	IconColor = Red,
	IconShape = "Square",
})
-- 3
local UpgradeTab = Window:Tab({
	Title = "Upgrade",
	Icon = "chart-no-axes-combined",
	IconColor = Blue,
	IconShape = "Square",
})
-- 3
local GachaRoll = Window:Tab({
	Title = "Gacha Roll",
	Icon = "dices",
	IconColor = Yellow,
	IconShape = "Square",
})
-- 5
local SettingTab = Window:Tab({
	Title = "Settings",
	Icon = "settings-2",
	IconColor = Grey,
	IconShape = "Square",
})


----------------------------------------------------------------
-- Utils
----------------------------------------------------------------
-- เปิดลอย
----------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if not State.FloatEnabled then
		return
	end

	local char = game.Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- หยุดแรงทั้งหมด
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end)
----------------------------------------------------------------
-- function get current zones
----------------------------------------------------------------
local function GetCurrentZone()
	local zonesFolder = workspace:FindFirstChild("Zones")
	if not zonesFolder then
		return nil
	end
	for _, zone in ipairs(zonesFolder:GetChildren()) do
		if zone:IsA("Folder") and # zone:GetChildren() > 0 then
			return zone.Name
		end
	end
	return nil
end
----------------------------------------------------------------
-- teleport zone
----------------------------------------------------------------
local function TeleportToZone(zone)
	if not zone or zone == "--" then
		return
	end
	if not ReliableRemote then
		return
	end
	local currentZone = GetCurrentZone()
	if currentZone == zone then
		return
	end
	State.SelectedZone = zone

    if State.AutoEquipBest then ReliableRemote:FireServer("Vault Equip Best", { "Mastery" }) end
	ReliableRemote:FireServer("Zone Teleport", {
		zone
	})
end
----------------------------------------------------------------
-- teleport dungeon
----------------------------------------------------------------
local function TeleportToGamemode(mode, diff)
	local idx
	if not (mode == "ShadowGate") then
		idx = DifficultyIndex[diff]
		if not idx then
			return
		end
	end
	local payload
	if idx then
		payload = string.format("%s:%d", ModeKey[mode], idx)
	else
		payload = ModeKey[mode]
	end

    if State.AutoEquipBest then ReliableRemote:FireServer("Vault Equip Best", { "Damage" }) end
	ReliableRemote:FireServer("Join Gamemode", {
		payload
	})
end
----------------------------------------------------------------
--- Function check when come to Gamemode
----------------------------------------------------------------
local function IsInGamemode()
	local zoneName = GetCurrentZone()
	if not zoneName then
		return false
	end
	-- return zoneName:find("Dungeon:1") or zoneName:find("Dungeon:2") or zoneName:find("Dungeon:3") or zoneName:find("Raid:1") or zoneName:find("Defense:1") or zoneName:find("ShadowGate")
	return zoneName:match("^Dungeon:%d+") or zoneName:match("^Raid:%d+") or zoneName:match("^Defense:%d+") or zoneName:match("ShadowGate")
end


----------------------------------------------------------------
-- Tab 1
----------------------------------------------------------------
-- Detect enemies from accessory
----------------------------------------------------------------
local function detectEnemyName(enemy, map)
	for name, accList in pairs(map) do
		local ok = true
		for _, acc in ipairs(accList) do
			if typeof(acc) == "string" then
				if not enemy:FindFirstChild(acc) then
					ok = false
					break
				end
			end
		end
		if ok then
			return name
		end
	end
	return nil
end
----------------------------------------------------------------
-- function get enemies from current zones
----------------------------------------------------------------
local function GetEnemiesInCurrentZone()
	local zone = GetCurrentZone()
	if not zone or not EnemyData[zone] then
		return {}
	end

	local nameMap = EnemyData[zone].EnemyNameMap
	local orderMap = EnemyData[zone].EnemyOrder

	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return {}
	end

	local list = {}

	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		local name = detectEnemyName(enemy, nameMap)
		if name and not table.find(list, name) then
			table.insert(list, name)
		end
	end

	table.sort(list, function(a, b)
		return (orderMap[a] or 999) < (orderMap[b] or 999)
	end)

	return list
end
----------------------------------------------------------------
-- Select Zone
----------------------------------------------------------------
FarmTab:Dropdown({
	Title = "Select Zone",
	Values = {
		"--",
		"Naruto",
		"DragonBall",
		"OnePiece",
		"DemonSlayer",
		"Paradis",
		"SoloLevel"
	},
	Multi = false,
	AllowNone = true,
	Callback = function(zone)
		TeleportToZone(zone)
	end
})
----------------------------------------------------------------
-- Select Enemy
----------------------------------------------------------------
local EnemyDropdown
EnemyDropdown = FarmTab:Dropdown({
	Title = "Select Enemy",
	Values = GetEnemiesInCurrentZone(),
	Multi = true,
	AllowNone = true,
	Callback = function(sel)
		State.SelectedEnemy = sel
		State.CurrentIndex = 1
		State.CurrentTarget = nil
		State.LastTargetName = nil
	end
})
----------------------------------------------------------------
-- Refresh Enemies List
----------------------------------------------------------------
FarmTab:Button({
	Title = "Refresh Enemies List",
	Callback = function()
		State.SelectedEnemy = {}
		State.CurrentIndex = 1
		State.CurrentTarget = nil
		State.LastTargetName = nil
		local list = GetEnemiesInCurrentZone()
		EnemyDropdown:Refresh(list)
		EnemyDropdown:Select({})
	end
})
----------------------------------------------------------------
-- AutoFarm Toggle
----------------------------------------------------------------
FarmTab:Toggle({
	Title = "Auto Farm",
	Value = false,
	Callback = function(v)
		State.AutoFarm = v
		-- State.FloatEnabled = v

		if not v then
			State.CurrentTarget = nil
			State.LastTargetName = nil
		end
	end
})
----------------------------------------------------------------
-- function find enemy alive
----------------------------------------------------------------
local function FindEnemyAlive(targetName)
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return nil
	end

	local zone = GetCurrentZone()
	if not zone then
		return nil
	end

	local nameMap = EnemyData[zone].EnemyNameMap
	local accList = nameMap[targetName]

	local allowTransparent = accList and accList._AllowTransparentHead or false

	for _, enemy in ipairs(enemiesFolder:GetChildren()) do

		local name = detectEnemyName(enemy, nameMap)
		if name == targetName then

			local head = enemy:FindFirstChild("Head")

			if allowTransparent then
				return enemy
			end

			if head and head.Transparency == 0 then
				return enemy
			end
		end
	end

	return nil
end
----------------------------------------------------------------
-- Teleport to enemy
----------------------------------------------------------------
local function TPToEnemy(enemy, range)
	local hrp = enemy:FindFirstChild("HumanoidRootPart")
	local lp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if hrp and lp then
		lp.CFrame = hrp.CFrame * CFrame.new(0, 0, range)
	end
end
----------------------------------------------------------------
-- Auto Farm Loop
----------------------------------------------------------------
local function IsValidEnemy(enemy)
	return enemy and typeof(enemy) == "Instance" and enemy.Parent and enemy:FindFirstChild("HumanoidRootPart")
end

task.spawn(function()
	while true do
		task.wait(0.25)
		local inGamemode = IsInGamemode()
		if inGamemode then
		else
			local zone = GetCurrentZone()
			if State.SelectedZone and State.SelectedZone ~= zone then
				TeleportToZone(State.SelectedZone)
				task.wait(5)
			end
			if State.AutoFarm and # State.SelectedEnemy > 0 then
				if zone then
					if not IsValidEnemy(State.CurrentTarget) then
						State.CurrentTarget = nil
					end
					if State.CurrentTarget then
                        ---------------------------------------------------------
                        -- มี target แล้ว → เช็คว่าตายไหม
                        ---------------------------------------------------------
						local name = detectEnemyName(State.CurrentTarget, EnemyData[zone].EnemyNameMap)
						if name ~= State.LastTargetName then
							State.CurrentTarget = nil
						end
						local accList = EnemyData[zone].EnemyNameMap[name]
						local allowTransparent = accList and accList._AllowTransparentHead or false
						local head = State.CurrentTarget:FindFirstChild("Head")
						local dead = false
						if not allowTransparent then
							if not head or head.Transparency > 0 then
								dead = true
							end
						end
						if dead then
							State.CurrentTarget = nil
							State.CurrentIndex = State.CurrentIndex + 1
							if State.CurrentIndex > # State.SelectedEnemy then
								State.CurrentIndex = 1
							end
						else
							TPToEnemy(State.CurrentTarget, -5)
						end
					else
                        ---------------------------------------------------------
                        -- ถ้าไม่มี target → หาใหม่
                        ---------------------------------------------------------
						local enemyName = State.SelectedEnemy[State.CurrentIndex]
						State.LastTargetName = enemyName
						local enemy = FindEnemyAlive(enemyName)
						if enemy then
							State.CurrentTarget = enemy
						else
							State.CurrentIndex = State.CurrentIndex + 1
							if State.CurrentIndex > # State.SelectedEnemy then
								State.CurrentIndex = 1
							end
						end
					end
				end
			end
		end

	end
end)

----------------------------------------------------------------
-- Tab 2
----------------------------------------------------------------
-- Function Auto Join
----------------------------------------------------------------
local function AutoJoin()
	if not State.AutoJoin then
		return
	end
	if IsInGamemode() then
		return
	end
	for _, mode in ipairs(PriorityOrder) do
		local list = State[mode]
		if list and # list > 0 then
			for _, diff in ipairs(list) do
				TeleportToGamemode(mode, diff)
				task.wait(0.25)
			end
		end
	end
end
----------------------------------------------------------------
-- Function get enemies no map name
----------------------------------------------------------------
local function GetEnemies()
	local folder = workspace:FindFirstChild("Enemies")
	if not folder then
		return {}
	end
	return folder:GetChildren()
end

----------------------------------------------------------------
-- Dropdown Dungeon
----------------------------------------------------------------
GamemodeTab:Dropdown({
	Title = "Dungeon",
	Values = {
		"Easy",
		"Medium",
		"Hard"
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.Dungeon = v or {}
	end
})
----------------------------------------------------------------
-- Dropdown Raid
----------------------------------------------------------------
GamemodeTab:Dropdown({
	Title = "Raid",
	Values = {
		"Easy",
		"Medium",
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.Raid = v or {}
	end
})
----------------------------------------------------------------
-- Dropdown Defense
----------------------------------------------------------------
GamemodeTab:Dropdown({
	Title = "Defense",
	Values = {
		"Easy"
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.Defense = v or {}
	end
})
----------------------------------------------------------------
-- Dropdown Shadow Gate
----------------------------------------------------------------
GamemodeTab:Dropdown({
	Title = "Shadow Gate",
	Values = {
		"Easy"
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.ShadowGate = v or {}
	end
})
----------------------------------------------------------------
-- Auto Join Toggle
----------------------------------------------------------------
GamemodeTab:Toggle({
	Title = "Auto Join",
	Value = false,
	Callback = function(v)
		State.AutoJoin = v
	end
})

GamemodeTab:Toggle({
	Title = "Equip Best Damage (Gamemode)",
	Value = false,
	Callback = function(v)
		State.AutoEquipBest = v
	end
})
----------------------------------------------------------------
-- Auto Join Loop
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		if State.AutoJoin then
			local inGamemode = IsInGamemode()
			if not inGamemode then
				AutoJoin()
			end
		end
	end
end)
----------------------------------------------------------------
-- Auto Kill Enemies on gamemode Loop
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)

		local inGamemode = IsInGamemode()
		if State.AutoJoin and inGamemode then
			local enemies = GetEnemies()
			if # enemies == 0 then
				task.wait(0.5)
			end
			for _, enemy in ipairs(enemies) do
				if enemy and enemy.Parent then
					TPToEnemy(enemy, -10)
					task.wait(1)
				end
			end
		end
	end
end)


----------------------------------------------------------------
-- Tab 3
----------------------------------------------------------------
-- Fuction find current
----------------------------------------------------------------
local function FindByPath(root, path)
	local cur = root
	for name in string.gmatch(path, "[^%.]+") do
		if not cur then
			return nil
		end
		cur = cur:FindFirstChild(name)
	end
	return cur
end
----------------------------------------------------------------
-- Fuction check point stat
----------------------------------------------------------------
local function HasAvailableStatPoints()
	local player = game.Players.LocalPlayer
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then
		return false
	end
	local notif = FindByPath(gui, "Screen.Hud.left.buttons.StatPoints.Notification")
	if not notif then
		return false
	end

    -- บางเกม Notification อาจไม่ใช่ TextLabel แต่อาจเป็น TextButton/Frame
    -- เลยเช็คว่ามี property Text ไหม
	local ok, text = pcall(function()
		return notif.Text
	end)
	if not ok or not text then
		return false
	end
	text = tostring(text)
	if text == "" or text == "0" or text == "1" then
		return false
	end

    -- "1".."9" หรือ "9+" ถือว่ามีแต้ม
	return true
end
----------------------------------------------------------------
-- Toggle: Auto RankUp (Mastery เต็ม)
----------------------------------------------------------------
UpgradeTab:Section({
	Title = "Rank Up",
	TextSize = 14,
})
UpgradeTab:Toggle({
	Title = "Auto RankUp (Mastery)",
	Value = false,
	Callback = function(v)
		State.AutoRankUp = v
	end
})
----------------------------------------------------------------
-- Dropdown: เลือก Stat ที่จะอัป
----------------------------------------------------------------
UpgradeTab:Section({
	Title = "Stats",
	TextSize = 14,
})
UpgradeTab:Dropdown({
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
----------------------------------------------------------------
-- Toggle: Auto Yen Upgrades
----------------------------------------------------------------
UpgradeTab:Section({
	Title = "Yen Upgrades",
	TextSize = 14,
})
local UpgradeTabGroup1 = UpgradeTab:Group({})
local UpgradeTabGroup2 = UpgradeTab:Group({})
local UpgradeTabGroup3 = UpgradeTab:Group({})

UpgradeTabGroup1:Toggle({
	Title = "Luck",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedLuck = v
	end
})
UpgradeTabGroup1:Toggle({
	Title = "Yen",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedYen = v
	end
})
UpgradeTabGroup2:Toggle({
	Title = "Mastery",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedMastery = v
	end
})
UpgradeTabGroup2:Toggle({
	Title = "Critical",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedCritical = v
	end
})
UpgradeTabGroup3:Toggle({
	Title = "Damage",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedDamage = v
	end
})


----------------------------------------------------------------
-- AUTO Tap 3
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)

        -- 🔼 RankUp (Server จะเช็ค mastery เต็มเอง)
		if State.AutoRankUp then
			ReliableRemote:FireServer("RankUp", {})
		end

		if State.SelectedStat then
			-- เช็คก่อนเสมอ
			if HasAvailableStatPoints() then
                -- อัปทีละ 1 (ปลอดภัยสุด)
				ReliableRemote:FireServer("Distribute Stat Point", {
					State.SelectedStat,
					1
				})
			end
		end

        if State.YenSelectedLuck then
            local args = {
                [1] = "Yen Upgrade";
                [2] = {
                    [1] = "Luck";
                };
            }           

            ReliableRemote:FireServer(unpack(args))
        end

        if State.YenSelectedYen then
            local args = {
                [1] = "Yen Upgrade";
                [2] = {
                    [1] = "Yen";
                };
            }           

            ReliableRemote:FireServer(unpack(args))
        end

        if State.YenSelectedMastery then
            local args = {
                [1] = "Yen Upgrade";
                [2] = {
                    [1] = "Mastery";
                };
            }           

            ReliableRemote:FireServer(unpack(args))
        end

        if State.YenSelectedCritical then
            local args = {
                [1] = "Yen Upgrade";
                [2] = {
                    [1] = "Critical";
                };
            }           

            ReliableRemote:FireServer(unpack(args))
        end

        if State.YenSelectedDamage then
            local args = {
                [1] = "Yen Upgrade";
                [2] = {
                    [1] = "Damage";
                };
            }           

            ReliableRemote:FireServer(unpack(args))
        end

	end
end)

----------------------------------------------------------------
-- Tab 4
----------------------------------------------------------------
local CreateRoll = workspace.Billboards.CrateRoll
local RollNames = {}
for _, roll in ipairs(CreateRoll:GetChildren()) do
	table.insert(RollNames, roll.Name)
end
table.sort(RollNames, function(a, b)
	return a < b
end)
local currentGroup = nil

for i, name in ipairs(RollNames) do
	State.GachaState[name] = false

	-- ทุก ๆ ตัวคี่ (1,3,5,...) ให้สร้าง Group ใหม่
	if i % 2 == 1 then
		currentGroup = GachaRoll:Group({})
	end

	-- เพิ่ม Toggle ลง Group ปัจจุบัน
	currentGroup:Toggle({
		Title = name,
		Value = false,
		Icon = "bird",
		Callback = function(v)
			State.GachaState[name] = v
		end
	})
end


----------------------------------------------------------------
-- Loop auto gacha roll
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1) -- ปรับ delay ได้
		for name, enabled in pairs(State.GachaState) do
			if enabled then
				local args = {
					[1] = "Crate Roll Start",
					[2] = {
						[1] = name,
						[2] = false,
					}
				}
				ReliableRemote:FireServer(unpack(args))
				task.wait(0.3) -- กัน spam server
			end
		end
	end
end)

----------------------------------------------------------------
-- Tab 5
----------------------------------------------------------------
-- Toggle Boost FPS
----------------------------------------------------------------
SettingTab:Toggle({
	Title = "Boost FPS (Low Graphics)",
	Value = false,
	Callback = function(v)
		FPSBoost = v
		if v then
			EnableFPSBoost()
		else
			-- DisableFPSBoost()
		end
	end
})
----------------------------------------------------------------
-- Toggle Auto Claim Daily & Weekly Rewards
----------------------------------------------------------------
SettingTab:Toggle({
	Title = "Auto Claim Daily & Weekly Rewards",
	Value = false,
	Callback = function(v)
		State.ClaimState = v
	end
})
----------------------------------------------------------------
-- Loop auto claim rewards
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(5) -- ปรับ delay ได้
		if State.ClaimState then
			for i = 1, 7 do
				local args = {
					[1] = "Collect Time Reward List";
					[2] = {
						[1] = "Weekly";
						[2] = {
							[1] = i;
						};
					};
				}
				ReliableRemote:FireServer(unpack(args))
			end
			for i = 1, 12 do
				local args = {
					[1] = "Collect Time Reward List";
					[2] = {
						[1] = "Daily";
						[2] = {
							[1] = i;
						};
					};
				}
				ReliableRemote:FireServer(unpack(args))
			end
		end
	end
end)

Window:OnClose(function()
   
end)

Window:OnDestroy(function()
	State.AutoFarm = false
	State.FloatEnabled = false
	State.SelectedZone = nil
	State.SelectedEnemy = {}
	State.CurrentIndex = 1
	State.CurrentTarget = nil
	State.LastTargetName = nil
	State.AutoJoin = false
    State.AutoEquipBest = false
	State.Raid = {}
	State.ShadowGate = {}
	State.Defense = {}
	State.Dungeon = {}
	State.WasInGamemode = false
	State.AutoRankUp = false
	State.SelectedStat = nil
    YenSelectedLuck = false
    YenSelectedYen = false
    YenSelectedMastery = false
    YenSelectedCritical = false
    YenSelectedDamage = false
	State.GachaState = {}
	State.ClaimState = false
	icon.Visible = false
	_G.ScriptRunning = false
end)