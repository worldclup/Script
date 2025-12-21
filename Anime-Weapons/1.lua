local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading.lua"))()

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


----------------------------------------------------------------
-- Game
----------------------------------------------------------------
local ReliableRemote = game.ReplicatedStorage:WaitForChild("Reply"):WaitForChild("Reliable")
local Reliable = game:GetService("ReplicatedStorage").Reply.Reliable
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ConfigsPath = ReplicatedStorage.Scripts.Configs;

local YenModule = require(ConfigsPath.Machines.YenUpgrades);
local YenUpgradeConfig = YenModule.Config;
local TokenModule = require(ConfigsPath.Machines.TokenUpgrades);
local TokenUpgradeConfig = TokenModule.Config;
local RankModule = require(ConfigsPath.Machines.RankUp);
local UtilsModule = require(ConfigsPath.Utility.Utils);
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
	YenUpgradeState = {},
	TokenUpgradeState = {},
	GachaState = {},
	TrainerState = {},
	AutoEquipBest = false,
    AutoFuse = false,
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
-- Format Number
----------------------------------------------------------------
-- local function FormatNumber(value)
--     if value >= 1000 and value < 1000000 then
--         -- ใช้ math.floor เพื่อปัดเศษทศนิยมตำแหน่งที่ 2 ลงก่อนแสดงผล
--         local rounded = math.floor(value / 100) / 10 
--         return string.format("%.1fk", rounded):gsub("%.0k", "k")
--     elseif value >= 1000000 then
--         local rounded = math.floor(value / 100000) / 10
--         return string.format("%.1fM", rounded):gsub("%.0M", "M")
--     end
--     return tostring(math.floor(value)) -- ปัดเศษจำนวนเต็มลงด้วย
-- end
local MaxRankCap = RankModule.MAX or 33;
local function GetRankRequirement(rank)
	return RankModule.GetRequirement(rank);
end;
local function GetRankBuff(rank)
	return RankModule.GetBuff(rank);
end;
local function FormatNumber(n)
	return UtilsModule.ToText(n);
end;
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
-- local FormatNumber = UtilsModule.ToText
----------------------------------------------------------------
-- Get Player Data
----------------------------------------------------------------
local function GetPlayerData()
    if getgenv().PlayerData then return getgenv().PlayerData end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "Attributes") and rawget(v, "YenUpgrades") then
            getgenv().PlayerData = v
            return v
        end
    end
end
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

local function GetCurrentGamemodeFromZone()
	local zone = GetZone()
	if not zone then
		return nil
	end
	if zone:match("^Raid") then
		return "Raid"
	elseif zone:match("^Defense") then
		return "Defense"
	elseif zone:match("^Dungeon") then
		return "Dungeon"
	elseif zone:match("ShadowGate") then
		return "ShadowGate"
	elseif zone:match("PirateTower") then
		return "PirateTower"
	end
	return nil
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
-- Teleport to enemy
----------------------------------------------------------------
-- local function TPToEnemy(enemy, range)
-- 	local hrp = enemy:FindFirstChild("HumanoidRootPart")
-- 	local lp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- 	if hrp and lp then
-- 		lp.CFrame = hrp.CFrame * CFrame.new(0, 0, range)
-- 	end
-- end
local function TPToEnemy(enemy, range)
	local character = game.Players.LocalPlayer.Character
	local hrp = enemy:FindFirstChild("HumanoidRootPart")
	local lp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and lp then
        -- 1. หยุดแรงเฉื่อยทั้งหมด (แก้ปัญหาวาร์ปแล้วเด้ง/สั่น)
		lp.Velocity = Vector3.new(0, 0, 0)
		lp.RotVelocity = Vector3.new(0, 0, 0) -- หยุดแรงหมุนด้วย

        -- 2. ปรับตำแหน่งการวาร์ป (Offset)
        -- แนะนำให้เปลี่ยนจากด้านหน้า (0,0,range) เป็น "เหนือหัวและเยื้องหลัง"
        -- เช่น CFrame.new(0, 5, 2) จะทำให้เราลอยอยู่เหนือมอนสเตอร์เล็กน้อย ลดการชน (Collision)
		local targetCFrame = hrp.CFrame * CFrame.new(0, 0, range) -- วาร์ปไปเหนือหัวมอนสเตอร์ 5 หน่วย

        -- 3. สั่งวาร์ป
		lp.CFrame = targetCFrame
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
GamemodeTabGroup1:Input({
	Title = "Wave",
	Value = State.RaidWave,
	Type = "Input",
	Callback = function(v)
		local num = tonumber(v)
		if not num then
			warn("กรุณากรอกตัวเลขเท่านั้น")
			return
		end
		State.RaidWave = num
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
GamemodeTabGroup2:Input({
	Title = "Wave",
	Value = State.DefenseWave,
	Type = "Input",
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
GamemodeTabGroup3:Input({
	Title = "Wave",
	Value = State.ShadowGateWave,
	Type = "Input",
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
GamemodeTabGroup4:Input({
	Title = "Floor",
	Value = State.PirateTowerFloor,
	Type = "Input",
	Callback = function(v)
		State.PirateTowerFloor = v
	end
})
----------------------------------------------------------------
-- Auto Equip Best
----------------------------------------------------------------
local GamemodeTabGroup5 = GamemodeTab:Group({})
GamemodeTab:Toggle({
	Title = "Auto Equip Best",
    -- Desc = "Gamemode (Damage)",
	Value = false,
	Callback = function(v)
		State.AutoEquipBest = v
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
	local mode = GetCurrentGamemodeFromZone()
	if not mode then
		return
	end

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
	local node = gm:FindFirstChild(mode)
	if not node then
		return
	end

    -- Raid / Defense / ShadowGate ใช้ wave
	if node:FindFirstChild("wave") and node.wave:FindFirstChild("amount") then
		local txt = node.wave.amount.Text
		return mode, tonumber(txt:match("%d+"))
	end

    -- PirateTower ใช้ floor
	if node:FindFirstChild("floor") and node.floor:FindFirstChild("amount") then
		local txt = node.floor.amount.Text
		return mode, tonumber(txt:match("%d+"))
	end
end
----------------------------------------------------------------
-- Leave Gamemode
----------------------------------------------------------------
local function LeaveGamemode(mode)
	if mode == "Raid" then
		ReliableRemote:FireServer("Zone Teleport", {
			"Dungeon"
		})
	elseif mode == "Defense" then
		ReliableRemote:FireServer("Zone Teleport", {
			"Paradis"
		})
	elseif mode == "ShadowGate" then
		ReliableRemote:FireServer("Zone Teleport", {
			"SoloLevel"
		})
	elseif mode == "PirateTower" then
		ReliableRemote:FireServer("Zone Teleport", {
			"OnePiece2"
		})
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
	if mode == "Raid" and value >= State.RaidWave then
		LeaveGamemode("Raid")
	elseif mode == "Defense" and value >= State.DefenseWave then
		LeaveGamemode("Defense")
	elseif mode == "ShadowGate" and value >= State.ShadowGateWave then
		LeaveGamemode("ShadowGate")
	elseif mode == "PirateTower" and value >= State.PirateTowerFloor then
		LeaveGamemode("PirateTower")
	end
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
	if State.Mode ~= "WORLD" then
		return
	end
	if IsInGamemode() then
		return
	end
	-- if State.ReturnToFarmPending then
	-- 	return
	-- end

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
			task.delay(3, function()
				if not IsInGamemode() then
					State.JoiningGamemode = false
					State.Mode = "WORLD"
				end
			end)

			-- break
		end
	end
end
----------------------------------------------------------------
-- Apply Vault Equip Best
----------------------------------------------------------------
local function ApplyVaultEquipBest(typeName)
	local args = {
		[1] = "Vault Equip Best",
		[2] = {
			[1] = typeName, -- "Damage" หรือ "Mastery"
		}
	}
	ReliableRemote:FireServer(unpack(args))
	if typeName == "Damage" then
		WindUI:Notify({
			Title = "Equip Best!",
			Content = "Damage",
			Duration = 3, -- 3 seconds
			Icon = "flame",
		})
	else
		WindUI:Notify({
			Title = "Equip Best!",
			Content = "Mastery",
			Duration = 3, -- 3 seconds
			Icon = "battery-plus",
		})
	end
end
----------------------------------------------------------------
-- Is Gamemode Loaded
----------------------------------------------------------------
local function IsGamemodeLoaded()
	local char = LP.Character
	if not char then
		return false
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return false
	end

    -- ต้องมี Enemy spawn แล้วด้วย
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies or # enemies:GetChildren() == 0 then
		return false
	end
	return true
end
----------------------------------------------------------------
-- Loop
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.1)
		-- if not State.ScriptRunning then
		-- 	return
		-- end
		if Window.Destroyed then
			break;
		end;

		local inGame = IsInGamemode()
		if inGame and State.AutoJoin then
			if State.Mode == "JOINING" then
				if not IsGamemodeLoaded() then
                    -- แค่รอ ไม่ทำอะไร
				else
                    -- โหลดเสร็จจริง
					State.Mode = "GAMEMODE"
				end
				if State.AutoEquipBest then
					ApplyVaultEquipBest("Damage")
				end
			end

			-- if State.Mode ~= "GAMEMODE" then
			-- 	ApplyVaultEquipBest("Damage")
			-- end

			State.Mode = "GAMEMODE"
			State.JoiningGamemode = false
			GamemodeFarmStep()
			CheckAutoLeave()
		else
			if State.Mode == "GAMEMODE" then
				if State.AutoEquipBest then
					task.wait(3)
					ApplyVaultEquipBest("Mastery")
				end
				-- State.MasteryBuffApplied = true
				-- State.DamageBuffApplied = false
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