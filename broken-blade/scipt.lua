-- ==========================================
-- [ DEK DEV HUB - ULTIMATE STABLE MASTER ]
-- UI Library: WindUI
-- Feature: Multi-Farm (Rotation), Float Mode, G-Lock, Advanced Skills, Fixed Collector
-- ==========================================
-- 1. Loading Screen
loadstring(game:HttpGet(
               "https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/loading-aw.lua"))()

local WindUI = loadstring(game:HttpGet(
                              "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Vim = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

-- [ Global Settings ]
getgenv().Settings = {
    -- Collector
    AutoChomusuke = false,
    AutoGubby = false,
    IslandDelay = 1.0,
    ItemDelay = 0.2,
    CurrentIslandIndex = 1,
    -- Farm
    AutoFarm = false,
    TargetList = {},
    CurrentTargetIndex = 1,
    FarmDistance = 3,
    FarmHeight = 5,
    -- Advanced Skills
    AutoSkill_Z = false, Delay_Z = 0.5,
    AutoSkill_X = false, Delay_X = 0.5,
    AutoSkill_C = false, Delay_C = 0.5,
    AutoSkill_V = false, Delay_V = 0.5,
    AutoSkill_R = false, Delay_R = 0.5,
    -- System
    AntiAFK = true,
    AutoRejoin = false
}

-- [ Anti-AFK & Auto Rejoin ]
LocalPlayer.Idled:Connect(function()
    if getgenv().Settings.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

GuiService.ErrorMessageChanged:Connect(function()
    if getgenv().Settings.AutoRejoin then
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- [ Utility Functions ]
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function extractLevel(name)
    if type(name) ~= "string" then return 9999 end
    local lvStr = string.match(name, "%[Lv%.(%d+)%]")
    return tonumber(lvStr) or 9999
end

local function getEnemyList()
    local names = {}
    local enemyService = workspace:FindFirstChild("EnemyService")
    if enemyService then
        local hash = {}
        for _, enemy in ipairs(enemyService:GetChildren()) do
            if (enemy:IsA("Model") or enemy:IsA("BasePart")) and enemy.Name ~= "" then
                if not hash[enemy.Name] then
                    table.insert(names, enemy.Name)
                    hash[enemy.Name] = true
                end
            end
        end
        pcall(function()
            table.sort(names, function(a, b)
                local lvA = extractLevel(a)
                local lvB = extractLevel(b)
                if lvA ~= lvB then return lvA < lvB end
                return a < b
            end)
        end)
    end
    table.insert(names, 1, "--")
    return names
end

-- [ Auto Skill Logic (Independent Cooldowns) ]
local lastSkillTime = {Z = 0, X = 0, C = 0, V = 0, R = 0}
local isUsingSkills = false

local function runAutoSkills()
    if isUsingSkills or not getgenv().Settings.AutoFarm then return end
    isUsingSkills = true
    
    local keys = {"Z", "X", "C", "V", "R"}
    for _, key in ipairs(keys) do
        if getgenv().Settings.AutoFarm and getgenv().Settings["AutoSkill_"..key] then
            local delay = getgenv().Settings["Delay_"..key]
            if tick() - lastSkillTime[key] >= delay then
                lastSkillTime[key] = tick()
                local keyCode = Enum.KeyCode[key]
                if keyCode then
                    Vim:SendKeyEvent(true, keyCode, false, game)
                    task.wait(0.05)
                    Vim:SendKeyEvent(false, keyCode, false, game)
                    task.wait(0.1)
                end
            end
        end
    end
    isUsingSkills = false
end

-- [ Collector Logic (Fixed Teleport) ]
local function sweepCurrentIsland()
    local root = getRoot()
    local world = workspace:FindFirstChild("World")
    local island = world and world:FindFirstChild("Island")
    local spawnCollide = island and island:FindFirstChild("SpawnCollide")
    local islands = spawnCollide and spawnCollide:GetChildren() or {}

    if not root or #islands == 0 then return end
    if not getgenv().Settings.AutoChomusuke and not getgenv().Settings.AutoGubby then
        return
    end

    if getgenv().Settings.CurrentIslandIndex > #islands then
        getgenv().Settings.CurrentIslandIndex = 1
    end
    local targetIsland = islands[getgenv().Settings.CurrentIslandIndex]

    if targetIsland and targetIsland:IsA("BasePart") then
        -- โหลดแมพเกาะหลักก่อน
        root.CFrame = targetIsland.CFrame * CFrame.new(0, 50, 0)
        task.wait(getgenv().Settings.IslandDelay)

        local function visitAndCollect(folderName, settingFlag)
            if not getgenv().Settings[settingFlag] then return end
            local npcFolder = world:FindFirstChild("NPC")
            local folder = npcFolder and npcFolder:FindFirstChild(folderName)
            if not folder then return end

            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("Model") or item:IsA("BasePart") then
                    root = getRoot()
                    if not root then break end
                    
                    -- 1. วาร์ปไปหา NPC ทุกตัวก่อน เพื่อให้เกมโหลด Highlight/Prompt
                    local itemPos = item:GetPivot()
                    root.CFrame = itemPos
                    task.wait(getgenv().Settings.ItemDelay)

                    -- 2. ค่อยเช็คว่าตัวนี้มีของให้เก็บไหม
                    if item:FindFirstChild("PromptFlashHighlight") then
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            local startTime = tick()
                            -- พยายามกดเก็บจนกว่า Highlight จะหาย หรือผ่านไป 5 วินาที
                            while getgenv().Settings[settingFlag] and item:FindFirstChild("PromptFlashHighlight") and (tick() - startTime) < 5 do
                                local cRoot = getRoot()
                                if cRoot then
                                    cRoot.CFrame = itemPos
                                    if fireproximityprompt then
                                        fireproximityprompt(prompt, 1, true)
                                    else
                                        prompt.HoldDuration = 0
                                        prompt:InputHoldBegin()
                                        task.wait(0.1)
                                        prompt:InputHoldEnd()
                                    end
                                end
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end
        end
        visitAndCollect("Chomusuke", "AutoChomusuke")
        visitAndCollect("Gubby", "AutoGubby")
    end
    getgenv().Settings.CurrentIslandIndex = getgenv().Settings.CurrentIslandIndex + 1
end

-- [ Auto Farm Logic ]
local function farmEnemy(targetName)
    local enemyService = workspace:FindFirstChild("EnemyService")
    if not enemyService or not targetName or targetName == "--" then
        return false
    end

    local targetEnemy = nil
    for _, enemy in ipairs(enemyService:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if enemy.Name == targetName and hum and hum.Health > 0.01 then
            targetEnemy = enemy;
            break
        end
    end

    if targetEnemy then
        local hum = targetEnemy:FindFirstChildOfClass("Humanoid")
        local root = getRoot()
        if not root then return false end

        local floatName = "FarmFloatBypass"
        local bv = root:FindFirstChild(floatName)
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = floatName
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
        end

        local targetPos = targetEnemy:GetPivot() * CFrame.new(0, getgenv().Settings.FarmHeight, -getgenv().Settings.FarmDistance)
        root.CFrame = CFrame.lookAt(targetPos.Position, targetEnemy:GetPivot().Position)

        task.wait(0.2)

        Vim:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        task.wait(0.05)
        Vim:SendKeyEvent(false, Enum.KeyCode.G, false, game)

        while getgenv().Settings.AutoFarm and targetEnemy.Parent == enemyService and hum and hum.Health > 0.01 do
            root = getRoot()
            if root then
                if not root:FindFirstChild(floatName) then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = floatName
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bv.Velocity = Vector3.zero
                    bv.Parent = root
                end

                local monsterPos = targetEnemy:GetPivot().Position
                local currentPos = targetEnemy:GetPivot() * CFrame.new(0, getgenv().Settings.FarmHeight, -getgenv().Settings.FarmDistance)

                root.CFrame = CFrame.lookAt(currentPos.Position, monsterPos)

                task.spawn(runAutoSkills)
            else
                break
            end
            task.wait(0.05)
        end
        
        root = getRoot()
        if root and root:FindFirstChild(floatName) then
            root[floatName]:Destroy()
        end

        return true
    end
    return false
end

-- [ Main Loop ]
task.spawn(function()
    while true do
        local acted = false
        if getgenv().Settings.AutoChomusuke or getgenv().Settings.AutoGubby then
            sweepCurrentIsland()
            acted = true
        end

        if not acted and getgenv().Settings.AutoFarm and #getgenv().Settings.TargetList > 0 then
            if getgenv().Settings.CurrentTargetIndex > #getgenv().Settings.TargetList then
                getgenv().Settings.CurrentTargetIndex = 1
            end

            local currentTarget = getgenv().Settings.TargetList[getgenv().Settings.CurrentTargetIndex]
            local success = farmEnemy(currentTarget)

            getgenv().Settings.CurrentTargetIndex = getgenv().Settings.CurrentTargetIndex + 1

            if success then acted = true end
        end
        task.wait(0.1)
    end
end)

-- [ UI CONSTRUCTION ]
local Window = WindUI:CreateWindow({
    Title = "DEK DEV HUB",
    Folder = "Dek_Dev_Hub_v1",
    Icon = "swords",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "DEK",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#2f9fff")),
        Enabled = true, Draggable = true, OnlyMobile = false, Position = UDim2.new(0, 10, 0, 150)
    },
    Topbar = {Height = 44, ButtonsType = "Mac"}
})

Window:SetToggleKey(Enum.KeyCode.RightControl)

-- 1. Farm Tab
local FarmTab = Window:Tab({Title = "Auto Farm", Icon = "swords"})
do
    FarmTab:Section({Title = "Farm Settings"})
    FarmTab:Toggle({
        Title = "Enable Auto Farm",
        Value = false,
        Callback = function(v) getgenv().Settings.AutoFarm = v end
    })

    local MonsterDropdown = FarmTab:Dropdown({
        Title = "Select Monsters",
        Values = getEnemyList(),
        Multi = true,
        Callback = function(v)
            getgenv().Settings.TargetList = v
            getgenv().Settings.CurrentTargetIndex = 1
        end
    })

    FarmTab:Button({
        Title = "Refresh Monster List",
        Icon = "refresh-cw",
        Callback = function() MonsterDropdown:Refresh(getEnemyList()) end
    })

    FarmTab:Slider({
        Title = "Farm Distance",
        Step = 1, Value = {Min = 1, Max = 15, Default = 3},
        Callback = function(v) getgenv().Settings.FarmDistance = v end
    })
    
    FarmTab:Slider({
        Title = "Farm Height",
        Step = 1, Value = {Min = -5, Max = 15, Default = 5},
        Callback = function(v) getgenv().Settings.FarmHeight = v end
    })

    FarmTab:Section({Title = "Advanced Attack & Skills"})
    local skillKeys = {"Z", "X", "C", "V", "R"}
    for _, key in ipairs(skillKeys) do
        FarmTab:Toggle({
            Title = "Auto Skill [" .. key .. "]",
            Value = getgenv().Settings["AutoSkill_"..key],
            Callback = function(v) getgenv().Settings["AutoSkill_"..key] = v end
        })
        FarmTab:Slider({
            Title = "Delay [" .. key .. "]",
            Step = 0.1, Value = {Min = 0.1, Max = 30, Default = 0.5},
            Callback = function(v) getgenv().Settings["Delay_"..key] = v end
        })
    end
end

-- 2. Collector Tab
local CollectTab = Window:Tab({Title = "Collector", Icon = "package"})
do
    CollectTab:Section({Title = "Visitation Settings"})
    CollectTab:Slider({
        Title = "Map Load Delay",
        Desc = "รอให้เกาะโหลดหลัก",
        Step = 0.1, Value = {Min = 0.5, Max = 5, Default = 1.0},
        Callback = function(v) getgenv().Settings.IslandDelay = v end
    })
    CollectTab:Slider({
        Title = "NPC Wait Time",
        Desc = "ระยะเวลาเข้าไปเช็คหน้า NPC",
        Step = 0.05, Value = {Min = 0.1, Max = 1, Default = 0.2},
        Callback = function(v) getgenv().Settings.ItemDelay = v end
    })

    CollectTab:Section({Title = "Select Items"})
    CollectTab:Toggle({
        Title = "Auto Chomusuke",
        Value = false,
        Callback = function(v) getgenv().Settings.AutoChomusuke = v end
    })
    CollectTab:Toggle({
        Title = "Auto Gubby",
        Value = false,
        Callback = function(v) getgenv().Settings.AutoGubby = v end
    })
end

-- 3. Settings Tab
local SettingsTab = Window:Tab({Title = "Settings", Icon = "settings"})
do
    SettingsTab:Section({Title = "Performance & System"})
    SettingsTab:Toggle({
        Title = "Anti-AFK",
        Value = getgenv().Settings.AntiAFK,
        Callback = function(v) getgenv().Settings.AntiAFK = v end
    })
    SettingsTab:Button({
        Title = "Boost FPS",
        Icon = "zap",
        Color = Color3.fromHex("#30FF6A"),
        Callback = function()
            _G.Settings = {
                Players = {
                    ["Ignore Me"] = true,
                    ["Ignore Others"] = true,
                    ["Ignore Tools"] = true
                },
                Meshes = {NoMesh = false, NoTexture = false, Destroy = false},
                Images = {Invisible = true, Destroy = false},
                Explosions = {
                    Smaller = true,
                    Invisible = false,
                    Destroy = false
                },
                Particles = {Invisible = true, Destroy = false},
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
                    ["FPS Cap"] = 360,
                    ["No Camera Effects"] = true,
                    ["No Clothes"] = true,
                    ["Low Water Graphics"] = true,
                    ["No Shadows"] = true,
                    ["Low Rendering"] = true,
                    ["Low Quality Parts"] = true,
                    ["Low Quality Models"] = true,
                    ["Reset Materials"] = true
                }
            }
            loadstring(game:HttpGet(
                           "https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
        end
    })
    SettingsTab:Section({Title = "UI Settings"})
    SettingsTab:Keybind({
        Title = "ปุ่ม เปิด/ปิด เมนู",
        Value = "RightControl",
        Callback = function(key) Window:SetToggleKey(Enum.KeyCode[key]) end
    })
    SettingsTab:Button({
        Title = "Destroy UI",
        Color = Color3.fromHex("#ff4830"),
        Callback = function() Window:Destroy() end
    })
end

WindUI:Notify({
    Title = "DEK DEV HUB",
    Content = "อัปเกรดระบบ Auto Skills เรียบร้อยแล้ว!",
    Duration = 5
})
