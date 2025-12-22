local function PlayDiagonalSlashLoading()
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local TargetParent = pcall(function() return CoreGui.Name end) and CoreGui or PlayerGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DEKDEV_Slash"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = TargetParent

    -- Background
    local BG = Instance.new("Frame")
    BG.Size = UDim2.fromScale(1, 1)
    BG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BG.BackgroundTransparency = 1
    BG.Parent = ScreenGui

    -- Container สำหรับควบคุมชิ้นส่วน
    local Holder = Instance.new("Frame")
    Holder.AnchorPoint = Vector2.new(0.5, 0.5)
    Holder.Position = UDim2.fromScale(0.5, 0.5)
    Holder.Size = UDim2.fromOffset(500, 300)
    Holder.BackgroundTransparency = 1
    Holder.Parent = ScreenGui

    -- ฟังก์ชันสร้างชิ้นส่วนทะแยง
    local function CreateSlashPart(name, startPos, color)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.Size = UDim2.fromScale(1.5, 1.5) -- ใหญ่กว่าปกติเพื่อรองรับการหมุน
        frame.Position = startPos
        frame.BackgroundColor3 = color
        frame.Rotation = 15 -- เอียงแนวทะแยง
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 0
        frame.Parent = Holder
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(1, 1, 1)
        stroke.Thickness = 2
        stroke.Transparency = 0.8
        stroke.Parent = frame
        
        return frame
    end

    -- สร้าง 2 ชิ้นพุ่งสวนกัน
    local Part1 = CreateSlashPart("Slash1", UDim2.fromScale(-1.5, -1.5), Color3.fromRGB(15, 15, 18))
    local Part2 = CreateSlashPart("Slash2", UDim2.fromScale(1.5, 1.5), Color3.fromRGB(10, 10, 12))

    -- Title (CanvasGroup เพื่อให้โผล่มาหลังประกบกัน)
    local Content = Instance.new("CanvasGroup")
    Content.Size = UDim2.fromScale(1, 1)
    Content.BackgroundTransparency = 1
    Content.GroupTransparency = 1
    Content.Parent = Holder

    local Title = Instance.new("TextLabel")
    Title.Text = "DEK DEV HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 45
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Size = UDim2.fromScale(1, 1)
    Title.BackgroundTransparency = 1
    Title.Parent = Content

    -- --- ANIMATION START ---
    TweenService:Create(BG, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()
    
    local slashInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    -- 1. พุ่งมาประกบกันแนวทะแยง
    TweenService:Create(Part1, slashInfo, {Position = UDim2.fromScale(-0.4, -0.5)}):Play()
    TweenService:Create(Part2, slashInfo, {Position = UDim2.fromScale(-0.1, -0.1)}):Play()
    
    task.wait(0.5)
    
    -- 2. กระแทกเบาๆ (Shake Effect)
    Holder.Position = UDim2.fromScale(0.51, 0.5)
    TweenService:Create(Holder, TweenInfo.new(0.1, Enum.EasingStyle.Elastic), {Position = UDim2.fromScale(0.5, 0.5)}):Play()

    -- 3. โชว์ข้อความ
    TweenService:Create(Content, TweenInfo.new(0.4), {GroupTransparency = 0}):Play()
    
    task.wait(2.5)

    -- 4. Slash Out (ฟันออก)
    local exitInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    TweenService:Create(Content, TweenInfo.new(0.2), {GroupTransparency = 1}):Play()
    TweenService:Create(Part1, exitInfo, {Position = UDim2.fromScale(-2, -0.5)}):Play()
    TweenService:Create(Part2, exitInfo, {Position = UDim2.fromScale(2, -0.1)}):Play()
    TweenService:Create(BG, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

    task.wait(0.6)
    ScreenGui:Destroy()
end

PlayDiagonalSlashLoading()