local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- */  Colors  /* --
local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green = Color3.fromHex("#10C550")
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Red = Color3.fromHex("#EF4F1D")

----------------------------------------------------------------
-- UI Window
----------------------------------------------------------------

local Window = WindUI:CreateWindow({
	Title = "Dek Dev Hub",
	-- Icon = "keyboard",
	SideBarWidth = 150,
	Theme = "Dark", -- Dark, Darker, Light, Aqua, Amethyst, Rose
	Size = UDim2.fromOffset(800, 600),
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
-- Game
----------------------------------------------------------------
local ReliableRemote = game.ReplicatedStorage:WaitForChild("Reply"):WaitForChild("Reliable")
local Reliable = game:GetService("ReplicatedStorage").Reply.Reliable
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
----------------------------------------------------------------
-- State
----------------------------------------------------------------
local State = {
	ScriptRunning = true,
	Mode = "WORLD",
	AutoFarm = false,
	AutoJoin = false,
	SelectedZone = nil,
	ReturnToFarmPending = false,
	SelectedEnemy = {},
	EnemyTypeIndex = 1,   -- ชนิดปัจจุบัน
	EnemyUnitIndex = {}, -- index ของแต่ละชนิด
	Gamemode = {
		Dungeon = {},
		Raid = {},
		Defense = {},
		ShadowGate = {},
		PirateTower = {},
	},
	RaidWave = 500,
	DefenseWave = 200,
	ShadowGateWave = 500,
	PirateTowerFloor = 100,
	JoiningGamemode = false,
	DamageBuffApplied = false,
	MasteryBuffApplied = false,
    AutoRankUp = false,
    SelectedStat = nil,
    YenSelectedLuck = false,
    YenSelectedYen = false,
    YenSelectedMastery = false,
    YenSelectedCritical = false,
    YenSelectedDamage = false,
}

local GamemodePriority = {
	"PirateTower",
	"ShadowGate",
	"Defense",
	"Raid",
	"Dungeon",
}

----------------------------------------------------------------
-- Master data
----------------------------------------------------------------

local EnemyMaster = {
	Naruto = {
		["Zabuzão"] = {
			Order = 1,
			Difficulty = "Easy",
			Health = "6.19K",
			Drops = {},
			Accessories = {
				"Accessory (zabuza)",
				"Accessory (Meshes/12Accessory)",
				"Accessory (whitescarf)"
			}
		},
		["Tobão"] = {
			Order = 2,
			Difficulty = "Medium",
			Health = "618.34K",
			Drops = {},
			Accessories = {
				"Spiraling Orange Rogue Shinobi Mask w/ Hair",
				"Meshes/PurpleCollarlPAccessory"
			}
		},
		Nargato = {
			Order = 3,
			Difficulty = "Hard",
			Health = "20.76M",
			Drops = {},
			Accessories = {
				"Accessory (Baki_HeadTemplate)",
				"Ears with Black Gauges"
			}
		},
		Peixame = {
			Order = 4,
			Difficulty = "Boss",
			Health = "206.85M",
			Drops = {},
			Accessories = {
				"Accessory (Kisame)"
			}
		},
		Madeira = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "1.94B",
			Drops = {},
			Accessories = {
				"Accessory (MadaraShoulderLeft)"
			}
		},
		Itaxin = {
			Order = 6,
			Difficulty = "Secret",
			Health = "30Qa",
			Drops = {},
			Accessories = {
				"Accessory (Itachi)",
				"Accessory (Baki_HeadTemplate)"
			}
		}
	},
	DragonBall = {
		Picole = {
			Order = 1,
			Difficulty = "Easy",
			Health = "3.02Bw",
			Drops = {},
			Accessories = {
				"Omega Demon King of Earth Ears",
				"Omega Demon King of Earth Face",
				"Peak-olo Demon King of Earth Antenna"
			}
		},
		Frioso = {
			Order = 2,
			Difficulty = "Medium",
			Health = "797.85B",
			Drops = {},
			Accessories = {
				"Accessory (Emperor Armor)",
				"Accessory (Emperor Tail)",
				"Accessory (First Form Emperor Face)",
				"Accessory (First Form Emperor Hat)"
			}
		},
		["Friozaço"] = {
			Order = 3,
			Difficulty = "Hard",
			Health = "30T",
			Drops = {},
			Accessories = {
				"Accessory (Emperor Cut Tail)",
				"Accessory (Third Form Emperor Face)",
				"Accessory (Third Form Emperor Hat)"
			}
		},
		Bubu = {
			Order = 4,
			Difficulty = "Boss",
			Health = "1000T",
			Drops = {},
			Accessories = {
				"Cape",
				"ChubbyEars",
				"ChubbyHead"
			}
		},
		Jeromin = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "20Qa",
			Drops = {},
			Accessories = {
				"Midren Ears",
				"Midren Head"
			}
		},
		["Gekão"] = {
			Order = 6,
			Difficulty = "Secret",
			Health = "80Sx",
			Drops = {},
			Accessories = {
				"Accessory (Goku Black Left)",
				"Accessory (Goku Black Right)",
				"Accessory (Goku Black Shirt Black)",
				"Black Spiky Male Hair",
				"Earrings Potar Green"
			}
		}
	},
	OnePiece = {
		Cobinha = {
			Order = 1,
			Difficulty = "Easy",
			Health = "40Qa",
			Drops = {},
			Accessories = {
				"Accessory (Koby_Face_Capt_001)",
				"Accessory (Koby_Hair_Capt_001)",
			}
		},
		Buguinho = {
			Order = 2,
			Difficulty = "Medium",
			Health = "600Qa",
			Drops = {},
			Accessories = {
				"Accessory (BuggyHat_Original)",
				"Clown Pirate face",
				"Meshes/rig_for_people (3)_CubeAccessory",
				"Scarf",
				"defaultAccessory"
			}
		},
		["Marcão"] = {
			Order = 3,
			Difficulty = "Hard",
			Health = "80Qiw",
			Drops = {},
			Accessories = {
				"Accessory (MeshPartAccessory)",
				"Meshes/birdtal1Accessory",
				"Meshes/marbeltAccessory",
				"moderation"
			}
		},
		Cometa = {
			Order = 4,
			Difficulty = "Boss",
			Health = "3Sx",
			Drops = {},
			Accessories = {
				"Accessory (Kuma_001)",
				"Accessory (Kuma_Face_001)",
			}
		},
		Edmundo = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "50Sx",
			Drops = {},
			Accessories = {
				"Fazer Processo de ItemAccessory",
				"L Ceremonial Epaulette",
				"MeshPartAccessory",
				"R Ceremonial Epaulette",
				"WhitePirateCaptain'sCloak(v2)",
				"b e a n"
			}
		},
		Leopardo = {
			Order = 6,
			Difficulty = "Secret",
			Health = "80No",
			Drops = {},
			Accessories = {
				"Accessory (RL_Awaken_Face hair)",
				"Accessory (RL_Awaken_Tail_02 waist)",
				"Accessory (RL_Awaken_beard_03)",
			}
		}
	},
	DemonSlayer = {
		Demon = {
			Order = 1,
			Difficulty = "Easy",
			Health = "500Sx",
			Drops = {},
			Accessories = {
				"Accessory (Black Stylish Layered Wolf Cut Short Hair)",
				"Accessory (MeshPartAccessory)",
				"Accessory (Meshes/messy hair 2Accessory)",
				"Accessory (Sekido)",
				"Meshes/hair_3Accessory",
				"zohak Demon Horns Black",
			}
		},
		Lyokko = {
			Order = 2,
			Difficulty = "Medium",
			Health = "80Sp",
			Drops = {},
			Accessories = {
				"Accessory (MeshPartAccessory)",
				"Cyan_Sergal_Neck_Floof",
				"monster Face",
			}
		},
		Jyutaro = {
			Order = 3,
			Difficulty = "Hard",
			Health = "4Oc",
			Drops = {},
			Accessories = {
				"Accessory (Meshes/17687533242 (1)Accessory)",
				"Fazer Processo de ItemAccessory",
				"Gyu's left bandaged arm",
				"Gyu's right bandaged arm",
				"MeshPartAccessory"
			}
		},
		Dola = {
			Order = 4,
			Difficulty = "Boss",
			Health = "300Oc",
			Drops = {},
			Accessories = {
				"Accessory (Baki_HeadTemplate)",
				"Accessory (Douma)",
				"Fazer Processo de ItemAccessory"
			}
		},
		Mokushibo = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "10No",
			Drops = {},
			Accessories = {
				"Accessory (Kokushibo Nichirin BladeAccessory)",
				"Accessory (Kokushibo)",
				"Accessory (Upper Moon 1 Demon Slayer Red Anime Hair)",
				"CapeShoulderAccessory",
				"CapeShoulderAccessory",
				"Eyes Leather CapeAccessory"
			}
		},
		Alaza = {
			Order = 6,
			Difficulty = "Secret",
			Health = "6Dd",
			Drops = {},
			Accessories = {
				"Accessory (Baki_HeadTemplate)",
				"Accessory (MeshPartAccessory)",
				"Akaz Upper Moon Vest",
			}
		}
	},
	Paradis = {
		Richala = {
			Order = 1,
			Difficulty = "Easy",
			Health = "700Dc",
			Drops = {},
			Accessories = {
				"Another Short",
				"Blonde ombre",
				"DarkBeltAccessory",
				"FACE1",
				"HandleAccessory",
				"sword holderAccessory",
			}
		},
		["Female titan"] = {
			Order = 2,
			Difficulty = "Medium",
			Health = "80Ud",
			Drops = {},
			Accessories = {
				"Another Short",
				"HEADAccessory",
			}
		},
		Mandile = {
			Order = 3,
			Difficulty = "Hard",
			Health = "5.5Dd",
			Drops = {},
			Accessories = {
				"Accessory (Meshes/Jaw Titan UGCJER (1)Accessory)",
				"Accessory (Meshes/Jaw Titan UGCJERhair (2)Accessory)",
			}
		},
		Blind = {
			Order = 4,
			Difficulty = "Boss",
			Health = "100Dd",
			Drops = {},
			Accessories = {
				"Accessory (Meshes/ArmoredTitanAccessory)",
			}
		},
		Colosso = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "5Td",
			Drops = {},
			Accessories = {
				"Accessory (colossal titan)",
			}
		},
		["Elen yage"] = {
			Order = 6,
			Difficulty = "Secret",
			Health = "200Qid",
			Drops = {},
			Accessories = {
				"Accessory (Handle1Accessory)",
				"Accessory (MeshPartAccessory)",
			}
		}
	},
	SoloLevel = {
		TangFak = {
			Order = 1,
			Difficulty = "Easy",
			Health = "8Td",
			Drops = {},
			Accessories = {
				"Accessory (MeshPartAccessory)",
				"Accessory (MeshPartAccessory)",
			}
		},
		Sunly = {
			Order = 2,
			Difficulty = "Medium",
			Health = "100Qad",
			Drops = {},
			Accessories = {
				"Accessory (Meshes/Sung Il-Hwan.Accessory)",
				"Accessory (handcuffAccessory)",
			}
		},
		Haler = {
			Order = 3,
			Difficulty = "Hard",
			Health = "10Qid",
			Drops = {},
			Accessories = {
				"Accessory (Anime Samurai Ninja Hair (Black))",
				"Accessory (defaultAccessory)",
			}
		},
		Thomas = {
			Order = 4,
			Difficulty = "Boss",
			Health = "1Sxd",
			Drops = {},
			Accessories = {
				"Accessory (Meshes/default_headAccessory1)",
				"LongWolfCutHair",
			}
		},
		Frieze = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "10Spd",
			Drops = {},
			Accessories = {
				"Accessory (Baruka Elf Ears)",
				"Accessory (Baruka Hair)",
				"Accessory (Baruka)"
			}
		},
		Belu = {
			Order = 6,
			Difficulty = "Secret",
			Health = "60Dec",
			Drops = {},
			Accessories = {
				"Armor",
			},
			_AllowTransparentHead = true
		}
	},
	OnePiece2 = {
		Xucci = {
			Order = 1,
			Difficulty = "Easy",
			Health = "10Spd",
			Drops = {},
			Accessories = {
				"Accessory (RL_CPO_coat)",
				"Accessory (RL_CPO_face_002)",
				"Accessory (RL_CPO_hair)",
				"Accessory (RL_CPO_hat)",
				"Accessory (RL_CPO_pidge)"
			}
		},
		Gengoku = {
			Order = 2,
			Difficulty = "Medium",
			Health = "500Spd",
			Drops = {},
			Accessories = {
				"Accessory (Sengoku_Beard_001)",
				"Accessory (Sengoku_Face_001)",
				"Accessory (Sengoku_Hat_001)",
			}
		},
		Erocodile = {
			Order = 3,
			Difficulty = "Hard",
			Health = "4Ocd",
			Drops = {},
			Accessories = {
				"Golden Hook",
				"Hats",
			}
		},
		Neopard = {
			Order = 4,
			Difficulty = "Boss",
			Health = "500Ocd",
			Drops = {},
			Accessories = {
				"Accessory (RL_Awaken_Face hair)",
				"Accessory (RL_Awaken_Tail_02 waist)",
				"Accessory (RL_Awaken_beard_03)",
			}
		},
		Narce = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "600Nod",
			Drops = {},
			Accessories = {
				"HEADAccessory",
				"Meshes/marcoheadthingAccessory",
				"Meshes/marwing2Accessory",
				"Meshes/marwingAccessory"
			}
		},
		["Big Lom"] = {
			Order = 6,
			Difficulty = "Secret",
			Health = "50Duo",
			Drops = {},
			Accessories = {
				"HAT PINK",
				"HEADAccessory",
				"Meshes/FATNOSEAccessory",
				"YellowCape",
				"hair cheio",
			},
		}
	},
	Bleach = {
		Jaegar = {
			Order = 1,
			Difficulty = "Easy",
			Health = "600Nod",
			Drops = {},
			Accessories = {
				"Accessory (GiantElfEarsFrostBlue)",
				"Accessory (Grimmjow)",
				"Accessory (MeshPartAccessory)",
				"Accessory (Meshpart1Accessory)",
			}
		},
		Ororibashi = {
			Order = 2,
			Difficulty = "Medium",
			Health = "3Dec",
			Drops = {},
			Accessories = {
				"Accessory (Harribel)",
				"Accessory (MeshPartAccessory)",
				"Accessory (Meshes/teAccessory)"
			}
		},
		Jikifune = {
			Order = 3,
			Difficulty = "Hard",
			Health = "700Dec",
			Drops = {},
			Accessories = {
				"Accessory (Nodt)",
			}
		},
		Eier = {
			Order = 4,
			Difficulty = "Boss",
			Health = "60Und",
			Drops = {},
			Accessories = {
				"Assassin Pale Mask",
				"Meshes/brokhornAccessory",
				"SBHair",
			}
		},
		Aizan = {
			Order = 5,
			Difficulty = "Emperor",
			Health = "300Duo",
			Drops = {},
			Accessories = {
				"Accessory ((L) Aizen Sleeve)",
				"Accessory ((R) Aizen Sleeve)",
				"Accessory (Aizen Hair)",
				"Accessory (Aizen Haori)"
			}
		},
		Alquiorra = {
			Order = 6,
			Difficulty = "Secret",
			Health = "100Qui",
			Drops = {},
			Accessories = {
				"Accessory (MeshPartAccessory)",
				"Accessory (Meshes/meshPartAccessory)",
				"Accessory (defaultAccessory)",
				"Black Fluff Tail",
			},
		}
	},
}

----------------------------------------------------------------
-- Get Zone
----------------------------------------------------------------
local function GetZone()
	local zonesFolder = workspace:FindFirstChild("Zones")
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

local function GetWorldZone()
	local zone = GetZone()
	if not zone then
		return nil
	end
	if zone:match("^Dungeon") or zone:match("^Raid") or zone:match("^Defense") or zone:match("ShadowGate") or zone:match("PirateTower") then
		return nil
	end
	return zone
end

----------------------------------------------------------------
-- Detect Enemy From Master
----------------------------------------------------------------
local function DetectEnemyFromMaster(enemy, zone)
	for enemyName, data in pairs(zone) do
		local matched = true
		for _, accName in ipairs(data.Accessories) do
			if not enemy:FindFirstChild(accName, true) then
				matched = false
				-- break
			end
		end
		if matched then
			return enemyName, data
		end
	end
	return nil, nil
end

----------------------------------------------------------------
-- Get Enemy
----------------------------------------------------------------
local function GetEnemy()
	local list = {}
	local added = {} -- กันซ้ำ

	local currentZone = GetZone()
	if not currentZone then
		return {}
	end
	local zoneMaster = EnemyMaster[currentZone]
	if not zoneMaster then
		return {}
	end
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return {}
	end

	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		local enemyName, data = DetectEnemyFromMaster(enemy, zoneMaster)
		if enemyName and not added[enemyName] then
			added[enemyName] = true
			table.insert(list, {
				Title = string.format("%s [%s]", enemyName, data.Difficulty),
				Desc = "HP: " .. data.Health,
				Icon = "skull",
				Order = data.Order, -- ไว้ sort
			})
		end
	end

 	-- sort ตาม Order
	table.sort(list, function(a, b)
		return (a.Order or 999) < (b.Order or 999)
	end)
	return list
end

----------------------------------------------------------------
--- Is In Gamemode
----------------------------------------------------------------
local function IsInGamemode()
	local zone = GetZone()
	if not zone then
		return false
	end
	return zone:match("^Dungeon:%d+") or zone:match("^Raid:%d+") or zone:match("^Defense:%d+") or zone:match("ShadowGate") or zone:match("PirateTower")
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
	local currentZone = GetZone()
	if currentZone == zone then
		return
	end
	State.SelectedZone = zone
	ReliableRemote:FireServer("Zone Teleport", {
		zone
	})
end

----------------------------------------------------------------
-- Tap 1 #######################################################
----------------------------------------------------------------
local FarmTab = Window:Tab({
	Title = "Farm",
	Icon = "swords",
	IconColor = Green,
	IconShape = "Square",
})

local EnemyDropdown
EnemyDropdown = FarmTab:Dropdown({
	Title = "Select Enemy",
	Values = GetEnemy(),
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.SelectedEnemy = v
	end
})

FarmTab:Button({
	Title = "Refresh Enemies",
	Icon = "refresh-cw",
	Callback = function()
		local list = GetEnemy()
		EnemyDropdown:Refresh(list)
		EnemyDropdown:Select({})
	end
})

FarmTab:Toggle({
	Title = "Auto Farm",
	Value = false,
	Callback = function(v)
		State.AutoFarm = v
		if v then
			State.SelectedZone = GetWorldZone()
		else
			State.SelectedZone = nil
		end
	end
})
----------------------------------------------------------------
-- Auto Farm Loop
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
-- Is Enemy Dead
----------------------------------------------------------------
local function IsEnemyDead(enemy)
    -- local hum = enemy:FindFirstChildOfClass("Humanoid")
    -- if hum then
    --     return hum.Health <= 0
    -- end

    -- fallback ถ้าเกมนี้ไม่ใช้ Humanoid
	local head = enemy:FindFirstChild("Head")
	if head and head.Transparency > 0 then
		return true
	end
	return false
end
----------------------------------------------------------------
-- Get Enemy By Type And Index
----------------------------------------------------------------
local function GetEnemyByTypeAndIndex(enemyTypeTitle, index)
	local currentZone = GetZone()
	if not currentZone then
		return nil
	end
	local zoneMaster = EnemyMaster[currentZone]
	if not zoneMaster then
		return nil
	end
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		return nil
	end
	local matched = {}
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		local name, data = DetectEnemyFromMaster(enemy, zoneMaster)
		if name and enemyTypeTitle:find(name, 1, true) then
			table.insert(matched, enemy)
		end
	end
	table.sort(matched, function(a, b)
		return a:GetDebugId() < b:GetDebugId()
	end)
	return matched[index]
end
----------------------------------------------------------------
-- Loop Tab 1
----------------------------------------------------------------
local function IsValidEnemy(enemy)
	return enemy and typeof(enemy) == "Instance" and enemy.Parent and enemy:FindFirstChild("HumanoidRootPart")
end

local function WorldFarmStep()
	if not State.AutoFarm then
		return
	end
	if # State.SelectedEnemy == 0 then
		return
	end
	if State.Mode == "GAMEMODE" or State.Mode == "RETURNING" then
		return
	end

	local zone = GetZone()
	if not zone then
		return
	end

    -- กลับ Zone เดิม (ครั้งเดียว)
	if State.ReturnToFarmPending then
		if State.SelectedZone then
			TeleportToZone(State.SelectedZone)
			State.ReturnToFarmPending = false
			task.wait(3)
		end
		return
	end

	local enemyType = State.SelectedEnemy[State.EnemyTypeIndex]
	if not enemyType then
		State.EnemyTypeIndex = 1
		return
	end
	local title = enemyType.Title
	State.EnemyUnitIndex[title] = State.EnemyUnitIndex[title] or 1
	local enemy = GetEnemyByTypeAndIndex(title, State.EnemyUnitIndex[title])
	if not IsValidEnemy(enemy) then
        -- enemy ตัวเก่าใช้ไม่ได้แล้ว → รีใหม่
		State.EnemyUnitIndex[title] = 1
		State.EnemyTypeIndex = State.EnemyTypeIndex + 1
		if State.EnemyTypeIndex > # State.SelectedEnemy then
			State.EnemyTypeIndex = 1
		end
		return
	end

	if enemy then
		if IsEnemyDead(enemy) then
			State.EnemyUnitIndex[title] = State.EnemyUnitIndex[title] + 1
			State.EnemyTypeIndex = State.EnemyTypeIndex + 1
		else
			TPToEnemy(enemy, -5)
		end
	else
		State.EnemyUnitIndex[title] = 1
		State.EnemyTypeIndex = State.EnemyTypeIndex + 1
	end
	if State.EnemyTypeIndex > # State.SelectedEnemy then
		State.EnemyTypeIndex = 1
	end
end

----------------------------------------------------------------
-- Tab 2
----------------------------------------------------------------
-- GamemodeConfig
----------------------------------------------------------------
local GamemodeConfig = {
	Dungeon = {
		Easy = "Dungeon:1",
		Medium = "Dungeon:2",
		Hard = "Dungeon:3",
	},
	Raid = {
		Shinobi = "Raid:1",
		Bleach = "Raid:2",
	},
	Defense = {
		Easy = "Defense:1",
	},
	ShadowGate = {
		Easy = "ShadowGate",
	},
	PirateTower = {
		Easy = "PirateTower",
	},
}

local GamemodeTab = Window:Tab({
	Title = "Gamemode",
	Icon = "clock-alert",
	IconColor = Red,
	IconShape = "Square",
})
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
		State.Gamemode.Dungeon = v or {}
	end
})
----------------------------------------------------------------
-- Dropdown Raid
----------------------------------------------------------------
local GamemodeTabGroup1 = GamemodeTab:Group({})
GamemodeTabGroup1:Dropdown({
	Title = "Raid",
	Values = {
		"Shinobi",
		"Bleach",
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.Gamemode.Raid = v or {}
	end
})

GamemodeTabGroup1:Slider({
	Title = "Wave",
	Step = 1,
	Value = {
		Min = 0,
		Max = 500,
		Default = 500,
	},
	Callback = function(v)
		State.RaidWave = v
	end
})
----------------------------------------------------------------
-- Dropdown Defense
----------------------------------------------------------------
local GamemodeTabGroup2 = GamemodeTab:Group({})
GamemodeTabGroup2:Dropdown({
	Title = "Defense",
	Values = {
		"Easy"
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.Gamemode.Defense = v or {}
	end
})

GamemodeTabGroup2:Slider({
	Title = "Wave",
	Step = 1,
	Value = {
		Min = 0,
		Max = 200,
		Default = 200,
	},
	Callback = function(v)
		State.DefenseWave = v
	end
})
----------------------------------------------------------------
-- Dropdown Shadow Gate
----------------------------------------------------------------
local GamemodeTabGroup3 = GamemodeTab:Group({})
GamemodeTabGroup3:Dropdown({
	Title = "Shadow Gate",
	Values = {
		"Easy"
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.Gamemode.ShadowGate = v or {}
	end
})

GamemodeTabGroup3:Slider({
	Title = "Wave",
	Step = 1,
	Value = {
		Min = 0,
		Max = 500,
		Default = 500,
	},
	Callback = function(v)
		State.ShadowGateWave = v
	end
})
----------------------------------------------------------------
-- Dropdown Pirate Tower
----------------------------------------------------------------
local GamemodeTabGroup4 = GamemodeTab:Group({})
GamemodeTabGroup4:Dropdown({
	Title = "Pirate Tower",
	Values = {
		"Easy"
	},
	Multi = true,
	AllowNone = true,
	Callback = function(v)
		State.Gamemode.PirateTower = v or {}
	end
})

GamemodeTabGroup4:Slider({
	Title = "Floor",
	Step = 1,
	Value = {
		Min = 0,
		Max = 100,
		Default = 100,
	},
	Callback = function(v)
		State.PirateTowerFloor = v
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
----------------------------------------------------------------
-- Get Gamemode Progress
----------------------------------------------------------------
local function GetGamemodeProgress()
	local gui = LP:FindFirstChild("PlayerGui")
	if not gui then
		return
	end
	local screen = gui:FindFirstChild("Screen")
	if not screen then
		return
	end
	local hud = screen:FindFirstChild("Hud")
	if not hud then
		return
	end
	local gm = hud:FindFirstChild("gamemode")
	if not gm then
		return
	end

    -- Raid
	local raid = gm:FindFirstChild("Raid")
	if raid and raid:FindFirstChild("wave") and raid.wave:FindFirstChild("amount") then
		local txt = raid.wave.amount.Text
		return "Raid", tonumber(txt)
	end

    -- Defense
	local defense = gm:FindFirstChild("Defense")
	if defense and defense:FindFirstChild("wave") and defense.wave:FindFirstChild("amount") then
		local txt = defense.wave.amount.Text
		return "Defense", tonumber(txt:match("%d+"))
	end

    -- ShadowGate
	local shadow = gm:FindFirstChild("ShadowGate")
	if shadow and shadow:FindFirstChild("wave") and shadow.wave:FindFirstChild("amount") then
		return "ShadowGate", tonumber(shadow.wave.amount.Text)
	end

    -- PirateTower
	local pirate = gm:FindFirstChild("PirateTower")
	if pirate and pirate:FindFirstChild("floor") and pirate.floor:FindFirstChild("amount") then
		return "PirateTower", tonumber(pirate.floor.amount.Text)
	end
end
----------------------------------------------------------------
-- Leave Gamemode
----------------------------------------------------------------
local function LeaveGamemode(mode)
	local hud = LP.PlayerGui.Screen.Hud.gamemode
	local node = hud:FindFirstChild(mode)
	if node and node:FindFirstChild("leave") then
		firesignal(node.leave.MouseButton1Click)
	end
end
----------------------------------------------------------------
-- Check Auto Leave
----------------------------------------------------------------
local function CheckAutoLeave()
	local mode, value = GetGamemodeProgress()
	if not mode or not value then
		return
	end
	-- if mode == "Raid" and value >= State.RaidWave then
	-- 	LeaveGamemode("Raid")
	-- elseif mode == "Defense" and value >= State.DefenseWave then
	-- 	LeaveGamemode("Defense")
	-- elseif mode == "ShadowGate" and value >= State.ShadowGateWave then
	-- 	LeaveGamemode("ShadowGate")
	-- elseif mode == "PirateTower" and value >= State.PirateTowerFloor then
	-- 	LeaveGamemode("PirateTower")
	-- end
end
----------------------------------------------------------------
-- Gamemode Farm Step
----------------------------------------------------------------
local function GamemodeFarmStep()
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then
		return
	end
	for _, enemy in ipairs(enemies:GetChildren()) do
		if enemy and enemy.Parent then
			TPToEnemy(enemy, -10)
			task.wait(0.25)
		end
	end
end
----------------------------------------------------------------
-- Auto Join Step
----------------------------------------------------------------
local function AutoJoinStep()
	if not State.AutoJoin then
		return
	end
	if IsInGamemode() then
		return
	end
	if State.ReturnToFarmPending then
		return
	end

    -- กันยิงซ้ำถี่เกิน
	if State.JoiningGamemode then
		return
	end

	-- for mode, list in pairs(State.Gamemode) do
	for _, mode in ipairs(GamemodePriority) do
		local list = State.Gamemode[mode]
		if # list > 0 then
			State.JoiningGamemode = true
			State.Mode = "JOINING"
			local map = GamemodeConfig[mode]
			for _, k in ipairs(list) do
				Reliable:FireServer("Join Gamemode", {
					map[k]
				})
				task.wait(0.3)
			end

			 -- 🔥 สำคัญ: ปล่อยให้ loop ตรวจเองว่าจะเข้าไหม
			task.delay(2, function()
				if not IsInGamemode() then
					State.JoiningGamemode = false
				end
			end)

			break
		end
	end
end
----------------------------------------------------------------
-- ApplyVaultEquipBest
----------------------------------------------------------------
local function ApplyVaultEquipBest(typeName)
	local args = {
		[1] = "Vault Equip Best",
		[2] = {
			[1] = typeName, -- "Damage" หรือ "Mastery"
		}
	}
	ReliableRemote:FireServer(unpack(args))
end
----------------------------------------------------------------
-- Loop
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.3)
		if not State.ScriptRunning then
			return
		end
		local inGame = IsInGamemode()
		if inGame and State.AutoJoin then
			if State.Mode ~= "GAMEMODE" then
				ApplyVaultEquipBest("Damage")
				State.DamageBuffApplied = true
				State.MasteryBuffApplied = false
			end

			State.Mode = "GAMEMODE"
			State.JoiningGamemode = false
			GamemodeFarmStep()
			CheckAutoLeave()
		else
			if State.Mode == "GAMEMODE" then
				ApplyVaultEquipBest("Mastery")
				State.MasteryBuffApplied = true
				State.DamageBuffApplied = false
                -- เพิ่งออกดัน
				State.Mode = "RETURNING"
				State.ReturnToFarmPending = true
			end
			if State.Mode == "RETURNING" then
                -- รอ Zone โหลด
				if GetZone() then
					State.Mode = "WORLD"
				end
			end
			AutoJoinStep()
			WorldFarmStep()
		end
	end
end)
----------------------------------------------------------------
-- Tap 3
----------------------------------------------------------------
local UpgradeTab = Window:Tab({
	Title = "Upgrade",
	Icon = "chart-no-axes-combined",
	IconColor = Blue,
	IconShape = "Square",
})
----------------------------------------------------------------
-- Toggle: Upgrade Tab Group1
----------------------------------------------------------------
UpgradeTab:Section({
	Title = "Auto Upgrade",
	TextSize = 14,
})
local UpgradeTabGroup1 = UpgradeTab:Group({})

UpgradeTabGroup1:Toggle({
	Title = "Auto RankUp (Mastery)",
	Value = false,
	Callback = function(v)
		State.AutoRankUp = v
	end
})
UpgradeTabGroup1:Dropdown({
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
local UpgradeTabGroup2 = UpgradeTab:Group({})
local UpgradeTabGroup3 = UpgradeTab:Group({})
local UpgradeTabGroup4 = UpgradeTab:Group({})

UpgradeTabGroup2:Toggle({
	Title = "Luck",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedLuck = v
	end
})
UpgradeTabGroup2:Toggle({
	Title = "Yen",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedYen = v
	end
})
UpgradeTabGroup3:Toggle({
	Title = "Mastery",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedMastery = v
	end
})
UpgradeTabGroup3:Toggle({
	Title = "Critical",
	Justify = "Center",
	Callback = function(v)
		State.YenSelectedCritical = v
	end
})
UpgradeTabGroup4:Toggle({
	Title = "Damage",
	Justify = "Right",
	Callback = function(v)
		State.YenSelectedDamage = v
	end
})
----------------------------------------------------------------
-- Toggle: Auto Token Upgrades
----------------------------------------------------------------
UpgradeTab:Section({
	Title = "Token Upgrades",
	TextSize = 14,
})
local UpgradeTabGroup5 = UpgradeTab:Group({})
local UpgradeTabGroup6 = UpgradeTab:Group({})
local UpgradeTabGroup7 = UpgradeTab:Group({})
local UpgradeTabGroup8 = UpgradeTab:Group({})

UpgradeTabGroup5:Toggle({ Title = "Run Speed", Justify = "Center", Callback = function(v) State.TokenSelectedRunSpeed = v end})
UpgradeTabGroup5:Toggle({ Title = "Luck", Justify = "Center", Callback = function(v) State.TokenSelectedLuck = v end})
UpgradeTabGroup6:Toggle({ Title = "Yen", Justify = "Center", Callback = function(v) State.TokenSelectedYen = v end})
UpgradeTabGroup6:Toggle({ Title = "Mastery", Justify = "Center", Callback = function(v) State.TokenSelectedMastery = v end})
UpgradeTabGroup7:Toggle({ Title = "Drop", Justify = "Center", Callback = function(v) State.TokenSelectedDrop = v end})
UpgradeTabGroup7:Toggle({ Title = "Critical", Justify = "Center", Callback = function(v) State.TokenSelectedCritical = v end})
UpgradeTabGroup8:Toggle({ Title = "Damage", Justify = "Center", Callback = function(v) State.TokenSelectedDamage = v end})
----------------------------------------------------------------
-- Has Available Stats Points
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
-- Fire Yen Upgrade
----------------------------------------------------------------
local function FireYenUpgrade(stat)
    ReliableRemote:FireServer("Yen Upgrade", {
        stat
    })
end
----------------------------------------------------------------
-- Fire Token Upgrade
----------------------------------------------------------------
local function FireTokenUpgrade(stat)
    ReliableRemote:FireServer("Token Upgrade", {
        stat
    })
end
----------------------------------------------------------------
-- Loop Tap 3
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(2)

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

        if State.YenSelectedLuck then FireYenUpgrade("Luck") end
        if State.YenSelectedYen then FireYenUpgrade("Yen") end
        if State.YenSelectedMastery then FireYenUpgrade("Mastery") end
        if State.YenSelectedCritical then FireYenUpgrade("Critical") end
        if State.YenSelectedDamage then FireYenUpgrade("Damage") end

        if State.TokenSelectedRunSpeed then FireTokenUpgrade("Run Speed") end
        if State.TokenSelectedLuck then FireTokenUpgrade("Luck") end
        if State.TokenSelectedYen then FireTokenUpgrade("Yen") end
        if State.TokenSelectedMastery then FireTokenUpgrade("Mastery") end
        if State.TokenSelectedDrop then FireTokenUpgrade("Drop") end
        if State.TokenSelectedCritical then FireTokenUpgrade("Critical") end
        if State.TokenSelectedDamage then FireTokenUpgrade("Damage") end

	end
end)
----------------------------------------------------------------
-- Tab 4
----------------------------------------------------------------
local SettingTab = Window:Tab({
	Title = "Settings",
	Icon = "settings-2",
	IconColor = Grey,
	IconShape = "Square",
})
local function BoostFps ()
    -- MADE BY RIP#6666
    -- send issues or suggestions to my discord: discord.gg/rips

    -- ลบการตั้งค่า _G.SendNotifications และ _G.ConsoleLogs ออก

    if not game:IsLoaded() then
        repeat
            task.wait()
        until game:IsLoaded()
    end
    if not _G.Settings then
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
                Invisible = false, -- Not recommended for PVP games
                Destroy = false -- Not recommended for PVP games
            },
            Particles = {
                Invisible = true,
                Destroy = false
            },
            TextLabels = {
                LowerQuality = false,
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
                ["FPS Cap"] = true, -- Set this true to uncap FPS
                ["No Camera Effects"] = true,
                ["No Clothes"] = true,
                ["Low Water Graphics"] = true,
                ["No Shadows"] = true,
                ["Low Rendering"] = true,
                ["Low Quality Parts"] = true,
                ["Low Quality Models"] = true,
                ["Reset Materials"] = true,
                ["Lower Quality MeshParts"] = true,
                ClearNilInstances = false
            }
        }
    end
    local Players, Lighting, StarterGui, MaterialService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("StarterGui"), game:GetService("MaterialService")
    local ME, CanBeEnabled = Players.LocalPlayer, {"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}
    local function PartOfCharacter(Inst)
        for i, v in pairs(Players:GetPlayers()) do
            if v ~= ME and v.Character and Inst:IsDescendantOf(v.Character) then
                return true
            end
        end
        return false
    end
    local function DescendantOfIgnore(Inst)
        for i, v in pairs(_G.Ignore) do
            if Inst:IsDescendantOf(v) then
                return true
            end
        end
        return false
    end
    local function CheckIfBad(Inst)
        if not Inst:IsDescendantOf(Players) and (_G.Settings.Players["Ignore Others"] and not PartOfCharacter(Inst) 
        or not _G.Settings.Players["Ignore Others"]) and (_G.Settings.Players["Ignore Me"] and ME.Character and not Inst:IsDescendantOf(ME.Character) 
        or not _G.Settings.Players["Ignore Me"]) and (_G.Settings.Players["Ignore Tools"] and not Inst:IsA("BackpackItem") and not Inst:FindFirstAncestorWhichIsA("BackpackItem") 
        or not _G.Settings.Players["Ignore Tools"]) and (_G.Ignore and not table.find(_G.Ignore, Inst) and not DescendantOfIgnore(Inst) 
        or (not _G.Ignore or type(_G.Ignore) ~= "table" or #_G.Ignore <= 0)) then
            if Inst:IsA("DataModelMesh") then
                if Inst:IsA("SpecialMesh") then
                    if _G.Settings.Meshes.NoMesh then
                        Inst.MeshId = ""
                    end
                    if _G.Settings.Meshes.NoTexture then
                        Inst.TextureId = ""
                    end
                end
                if _G.Settings.Meshes.Destroy or _G.Settings["No Meshes"] then
                    Inst:Destroy()
                end
            elseif Inst:IsA("FaceInstance") then
                if _G.Settings.Images.Invisible then
                    Inst.Transparency = 1
                    Inst.Shiny = 1
                end
                if _G.Settings.Images.LowDetail then
                    Inst.Shiny = 1
                end
                if _G.Settings.Images.Destroy then
                    Inst:Destroy()
                end
            elseif Inst:IsA("ShirtGraphic") then
                if _G.Settings.Images.Invisible then
                    Inst.Graphic = ""
                end
                if _G.Settings.Images.Destroy then
                    Inst:Destroy()
                end
            elseif table.find(CanBeEnabled, Inst.ClassName) then
                if _G.Settings["Invisible Particles"] or _G.Settings["No Particles"] or (_G.Settings.Other and _G.Settings.Other["Invisible Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Invisible) then
                    Inst.Enabled = false
                end
                if (_G.Settings.Other and _G.Settings.Other["No Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Destroy) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("PostEffect") and (_G.Settings["No Camera Effects"] or (_G.Settings.Other and _G.Settings.Other["No Camera Effects"])) then
                Inst.Enabled = false
            elseif Inst:IsA("Explosion") then
                if _G.Settings["Smaller Explosions"] or (_G.Settings.Other and _G.Settings.Other["Smaller Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Smaller) then
                    Inst.BlastPressure = 1
                    Inst.BlastRadius = 1
                end
                if _G.Settings["Invisible Explosions"] or (_G.Settings.Other and _G.Settings.Other["Invisible Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Invisible) then
                    Inst.BlastPressure = 1
                    Inst.BlastRadius = 1
                    Inst.Visible = false
                end
                if _G.Settings["No Explosions"] or (_G.Settings.Other and _G.Settings.Other["No Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Destroy) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap") then
                if _G.Settings["No Clothes"] or (_G.Settings.Other and _G.Settings.Other["No Clothes"]) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("BasePart") and not Inst:IsA("MeshPart") then
                if _G.Settings["Low Quality Parts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Parts"]) then
                    Inst.Material = Enum.Material.Plastic
                    Inst.Reflectance = 0
                end
            elseif Inst:IsA("TextLabel") and Inst:IsDescendantOf(workspace) then
                if _G.Settings["Lower Quality TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Lower Quality TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.LowerQuality) then
                    Inst.Font = Enum.Font.SourceSans
                    Inst.TextScaled = false
                    Inst.RichText = false
                    Inst.TextSize = 14
                end
                if _G.Settings["Invisible TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Invisible TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Invisible) then
                    Inst.Visible = false
                end
                if _G.Settings["No TextLabels"] or (_G.Settings.Other and _G.Settings.Other["No TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Destroy) then
                    Inst:Destroy()
                end
            elseif Inst:IsA("Model") then
                if _G.Settings["Low Quality Models"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Models"]) then
                    Inst.LevelOfDetail = 1
                end
            elseif Inst:IsA("MeshPart") then
                if _G.Settings["Low Quality MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.LowerQuality) then
                    Inst.RenderFidelity = 2
                    Inst.Reflectance = 0
                    Inst.Material = Enum.Material.Plastic
                end
                if _G.Settings["Invisible MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Invisible MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Invisible) then
                    Inst.Transparency = 1
                    Inst.RenderFidelity = 2
                    Inst.Reflectance = 0
                    Inst.Material = Enum.Material.Plastic
                end
                if _G.Settings.MeshParts and _G.Settings.MeshParts.NoTexture then
                    Inst.TextureID = ""
                end
                if _G.Settings.MeshParts and _G.Settings.MeshParts.NoMesh then
                    Inst.MeshId = ""
                end
                if _G.Settings["No MeshParts"] or (_G.Settings.Other and _G.Settings.Other["No MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Destroy) then
                    Inst:Destroy()
                end
            end
        end
    end
    -- ลบ Notification เริ่มต้นการโหลด
    coroutine.wrap(pcall)(function()
        if (_G.Settings["Low Water Graphics"] or (_G.Settings.Other and _G.Settings.Other["Low Water Graphics"])) then
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if not terrain then
                repeat
                    task.wait()
                until workspace:FindFirstChildOfClass("Terrain")
                terrain = workspace:FindFirstChildOfClass("Terrain")
            end
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            if sethiddenproperty then
                sethiddenproperty(terrain, "Decoration", false)
            else
                -- ลบ Notification และ Warn เมื่อ Exploit ไม่รองรับ
            end
            -- ลบ Notification แจ้งเตือนเมื่อเปิดใช้งาน Low Water Graphics
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings["No Shadows"] or (_G.Settings.Other and _G.Settings.Other["No Shadows"]) then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.ShadowSoftness = 0
            if sethiddenproperty then
                sethiddenproperty(Lighting, "Technology", 2)
            else
                -- ลบ Notification และ Warn เมื่อ Exploit ไม่รองรับ
            end
            -- ลบ Notification แจ้งเตือนเมื่อเปิดใช้งาน No Shadows
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings["Low Rendering"] or (_G.Settings.Other and _G.Settings.Other["Low Rendering"]) then
            settings().Rendering.QualityLevel = 1
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            -- ลบ Notification แจ้งเตือนเมื่อเปิดใช้งาน Low Rendering
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings["Reset Materials"] or (_G.Settings.Other and _G.Settings.Other["Reset Materials"]) then
            for i, v in pairs(MaterialService:GetChildren()) do
                v:Destroy()
            end
            MaterialService.Use2022Materials = false
            -- ลบ Notification แจ้งเตือนเมื่อเปิดใช้งาน Reset Materials
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"]) then
            if setfpscap then
                if type(_G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])) == "string" or type(_G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])) == "number" then
                    setfpscap(tonumber(_G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])))
                    -- ลบ Notification แจ้งเตือนเมื่อ Cap FPS
                elseif _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"]) == true then
                    setfpscap(1e6)
                    -- ลบ Notification แจ้งเตือนเมื่อ Uncap FPS
                end
            else
                -- ลบ Notification แจ้งเตือนเมื่อ FPS Cap Failed
            end
        end
    end)
    coroutine.wrap(pcall)(function()
        if _G.Settings.Other["ClearNilInstances"] then
            if getnilinstances then
                for _, v in pairs(getnilinstances()) do
                    pcall(v.Destroy, v)
                end
                -- ลบ Notification แจ้งเตือนเมื่อ Clear Nil Instances
            else
                -- ลบ Notification และ Warn เมื่อ Exploit ไม่รองรับ
            end
        end
    end)
    local Descendants = game:GetDescendants()
    -- ลบ Notification แจ้งเตือน "Checking Instances..."
    for i, v in pairs(Descendants) do
        CheckIfBad(v)
    end
    -- ลบ Notification แจ้งเตือน "FPS Booster Loaded!" และ Warn
    warn("FPS Booster Loaded!") -- เหลือ warn ตัวสุดท้ายนี้ไว้เพื่อให้รู้ว่าสคริปต์ทำงานเสร็จแล้ว

    game.DescendantAdded:Connect(function(value)
        wait(_G.LoadedWait or 1)
        CheckIfBad(value)
    end)
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
-- Window
----------------------------------------------------------------
Window:OnClose(function()
   
end)

Window:OnDestroy(function()
	State.ScriptRunning = true
	State.Mode = "WORLD"
	State.AutoFarm = false
	State.AutoJoin = false
	State.SelectedZone = nil
	State.ReturnToFarmPending = false
	State.SelectedEnemy = {}
	State.EnemyTypeIndex = 1
	State.EnemyUnitIndex = {}
	State.Gamemode.Dungeon = {}
	State.Gamemode.Raid = {}
	State.Gamemode.Defense = {}
	State.Gamemode.ShadowGate = {}
	State.Gamemode.PirateTower = {}
    State.RaidWave = 500
    State.DefenseWave = 200
    State.ShadowGateWave = 500
    State.PirateTowerFloor = 100
    State.JoiningGamemode = false
    State.DamageBuffApplied = false
    State.MasteryBuffApplied = false
    State.AutoRankUp = false
    State.SelectedStat = nil
    State.YenSelectedLuck = false
    State.YenSelectedYen = false
    State.YenSelectedMastery = false
    State.YenSelectedCritical = false
    State.YenSelectedDamage = false
	_G.ScriptRunning = false
end)