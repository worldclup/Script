-- [[ 1. ระบบ Queue on Teleport (ให้ดึงตัวเองมารันใหม่) ]]
local queue_on_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/dungeon-hunter/new-main.lua", true))()]])
end

-- [[ 2. รอโหลดเกม ]]
if not game:IsLoaded() then game.Loaded:Wait() end

-- [[ 3. ตั้งค่าเบื้องต้น ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- บังคับให้เป็น True ตั้งแต่แรก (เพราะไม่มีปุ่มกดแล้ว)
local State = {
    AutoFarm = true, 
}

------------------------------------------------------------------------------------
--- ฟังก์ชันเสริม (ลอกมาจากตัวเดิมของคุณ)
------------------------------------------------------------------------------------

local function GetCurrentRoom(myHrp)
    local sandbox = workspace:FindFirstChild("SandboxPlayFolder")
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

local function AutoAttack(targetMonster)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    local keys = {Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R}
    for _, key in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

local function HandleNextStage(currentRoom, myHrp)
    local voteDoorFolder = currentRoom:FindFirstChild("VoteDoor")
    if not voteDoorFolder then return end

    for _, door in pairs(voteDoorFolder:GetChildren()) do
        if not door:FindFirstChild("UnlockDoor") then
            local targetVfx = door:FindFirstChild("UnlockVfx")
            if targetVfx then
                -- 1. เคลียร์แรงเหวี่ยงและล็อคตัวละคร
                myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                myHrp.Anchored = true 

                -- 2. ดึงค่า CFrame ของประตูมาใช้
                local doorCFrame = targetVfx:IsA("BasePart") and targetVfx.CFrame or targetVfx:GetModelCFrame()
                local doorPos = doorCFrame.Position
                
                -- [[ จุดที่ปรับปรุง: วาร์ปไปข้างหน้าประตูตรงๆ ]]
                -- เราใช้ doorCFrame.LookVector เพื่อหาทิศทาง "ด้านหน้า" ของ Object ประตู
                -- ระยะห่าง 5-6 หน่วยมักจะเป็นระยะที่ปุ่ม F แสดงผลพอดี
                local forwardDist = 6 
                local heightOffset = 2
                
                -- สูตร: ตำแหน่งประตู + (ทิศทางหน้าประตู * ระยะห่าง)
                local targetPosition = doorPos + (doorCFrame.LookVector * forwardDist) + Vector3.new(0, heightOffset, 0)
                
                -- วาร์ปและหันหน้าเข้าหาประตู
                myHrp.CFrame = CFrame.lookAt(targetPosition, doorPos)
                
                task.wait(0.5) -- รอให้นิ่ง
                
                -- 3. กด F รัวนิดนึงเพื่อความชัวร์
                for i = 1, 3 do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    task.wait(0.1)
                end
                
                task.wait(1) -- รอโหลดแมพ
                myHrp.Anchored = false 
                break
            end
        end
    end
end
------------------------------------------------------------------------------------
--- ลูปหลัก (LogicAuto)
------------------------------------------------------------------------------------
local function LogicAuto()
    print("DEK DEV HUB: Auto Farm Started (No UI Mode)")
    while State.AutoFarm do
        pcall(function()
            local activationFolder = Workspace:FindFirstChild("Creature") and Workspace.Creature:FindFirstChild("Activation")
            if not activationFolder then return end

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

            if targetMonster then
                local mHrp = targetMonster:FindFirstChild("HumanoidRootPart")
                if mHrp then
                    local targetPosition = mHrp.Position + Vector3.new(0, 15, 0)
                    myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    myHrp.CFrame = CFrame.lookAt(targetPosition, mHrp.Position)
                    AutoAttack(targetMonster)
                end
            elseif monstersLeft == 0 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                local currentRoom = GetCurrentRoom(myHrp)
                if currentRoom then
                    HandleNextStage(currentRoom, myHrp)
                    task.wait(1) 
                end
            end
        end)
        RunService.Heartbeat:Wait()
    end
end

-- [[ เริ่มต้นทำงานทันที ]]
task.spawn(LogicAuto)