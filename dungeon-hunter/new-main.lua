-- [[ 1. ตั้งค่าพื้นฐานและการโหลดเกม ]]
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- [[ 2. ระบบรันต่อเนื่องเมื่อเปลี่ยนด่าน ]]
local queue_on_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    -- ใส่ลิงก์ Raw ของสคริปต์คุณจาก GitHub เพื่อให้มันดึงตัวเองมารันใหม่ทุกด่าน
    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/dungeon-hunter/new-main.lua", true))()]])
end

-- [[ 3. ฟังก์ชันช่วยเหลือกดเข้าประตู (HandleNextStage) ]]
local function GetCurrentRoom(myHrp)
    local sandbox = Workspace:FindFirstChild("SandboxPlayFolder")
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

local function HandleNextStage(currentRoom, myHrp)
    local voteDoorFolder = currentRoom:FindFirstChild("VoteDoor")
    if not voteDoorFolder then return end
    for _, door in pairs(voteDoorFolder:GetChildren()) do
        if not door:FindFirstChild("UnlockDoor") then
            local targetVfx = door:FindFirstChild("UnlockVfx")
            if targetVfx then
                -- 1. หยุดตัวละครและล็อคไว้ชั่วคราวกันตกแมพ
                myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                myHrp.Anchored = true 

                local doorCFrame = targetVfx:IsA("BasePart") and targetVfx.CFrame or targetVfx:GetModelCFrame()
                local backDist = 6 -- เพิ่มระยะถอยอีกนิด
                local heightOffset = 2 
                
                local targetPosition = doorCFrame.Position - (doorCFrame.LookVector * backDist) + Vector3.new(0, heightOffset, 0)
                myHrp.CFrame = CFrame.lookAt(targetPosition, doorCFrame.Position)
                
                task.wait(0.5) -- รอให้ตำแหน่งนิ่ง
                
                -- 2. กด F เพื่อเข้าประตู
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                
                task.wait(1)
                myHrp.Anchored = false -- ปลดล็อคตัวละคร
                break
            end
        end
    end
end

-- [[ 4. ลูปหลักการฟาร์ม (LogicAuto) ]]
local function StartAutoFarm()
    while true do
        pcall(function()
            local activationFolder = Workspace:FindFirstChild("Creature") and Workspace.Creature:FindFirstChild("Activation")
            if not activationFolder then return end

            -- ค้นหาตัวละครเรา
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

            -- ค้นหาเป้าหมาย
            local targetMonster = nil
            local monstersLeft = 0
            for _, folderID in pairs(activationFolder:GetChildren()) do
                for _, child in pairs(folderID:GetChildren()) do
                    local name = child.Name:lower()
                    if name:find("monster") or name:find("boss") or name:find("chest") then 
                        local hum = child:FindFirstChild("Humanoid")
                        local mHrp = child:FindFirstChild("HumanoidRootPart")
                        if mHrp and (not hum or hum.Health > 0) then
                            targetMonster = child
                            monstersLeft = monstersLeft + 1
                        end
                    end
                end
            end

            -- การตัดสินใจ
            if targetMonster then
                local mHrp = targetMonster:FindFirstChild("HumanoidRootPart")
                local targetPosition = mHrp.Position + Vector3.new(0, 15, 0) -- ลอยสูง 15 หน่วย
                
                myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                myHrp.CFrame = CFrame.lookAt(targetPosition, mHrp.Position)
                
                -- โจมตีและกดสกิลรัวๆ
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                for _, key in ipairs({Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R}) do
                    VirtualInputManager:SendKeyEvent(true, key, false, game)
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                end
            elseif monstersLeft == 0 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                local currentRoom = GetCurrentRoom(myHrp)
                if currentRoom then
                    HandleNextStage(currentRoom, myHrp)
                end
            end
        end)
        RunService.Heartbeat:Wait()
    end
end

-- สั่งเริ่มงานทันที
task.spawn(StartAutoFarm)

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