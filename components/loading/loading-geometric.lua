local function PlayAssembleLoading()
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local TargetParent = pcall(function() return CoreGui.Name end) and CoreGui or PlayerGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DEKDEV_Assemble"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = TargetParent

    -- Background Dark Overlay
    local BG = Instance.new("Frame")
    BG.Size = UDim2.fromScale(1, 1)
    BG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BG.BackgroundTransparency = 1
    BG.Parent = ScreenGui

    -- Main Center Point
    local Center = Instance.new("Frame")
    Center.AnchorPoint = Vector2.new(0.5, 0.5)
    Center.Position = UDim2.fromScale(0.5, 0.5)
    Center.Size = UDim2.fromOffset(400, 200)
    Center.BackgroundTransparency = 1
    Center.Parent = ScreenGui

    -- สร้างชิ้นส่วนกรอบ 4 ชิ้น (Pieces)
    local function CreatePiece(name, startPos)
        local p = Instance.new("Frame")
        p.Name = name
        p.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        p.BorderSizePixel = 0
        p.Position = startPos
        p.BackgroundTransparency = 1
        p.Parent = Center
        
        -- ใส่เส้นขอบขาวบางๆ
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(15, 15, 18)
        -- stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 1
        stroke.Transparency = 1
        stroke.Parent = p
        
        return p, stroke
    end

    -- กำหนดตำแหน่งเริ่มต้น (วิ่งมาจากคนละทิศ)
    local top, s1 = CreatePiece("Top", UDim2.new(0, 0, -1, 0))
    local bot, s2 = CreatePiece("Bot", UDim2.new(0, 0, 1, 0))
    local left, s3 = CreatePiece("Left", UDim2.new(-1, 0, 0, 0))
    local right, s4 = CreatePiece("Right", UDim2.new(1, 0, 0, 0))

    -- ตั้งค่าขนาดให้เต็ม Center เมื่อรวมกัน
    top.Size = UDim2.new(1, 0, 0.5, 0)
    bot.Size = UDim2.new(1, 0, 0.5, 0)
    bot.Position = UDim2.new(0, 0, 1, 0) -- วิ่งมาจากข้างล่าง
    left.Size = UDim2.new(0.5, 0, 1, 0)
    right.Size = UDim2.new(0.5, 0, 1, 0)
    right.Position = UDim2.new(1, 0, 0, 0) -- วิ่งมาจากขวา

    -- Title & Bar (ซ่อนไว้ก่อน)
    local Content = Instance.new("CanvasGroup")
    Content.Size = UDim2.fromScale(1, 1)
    Content.BackgroundTransparency = 1
    Content.GroupTransparency = 1
    Content.Parent = Center

    local Title = Instance.new("TextLabel")
    Title.Text = "DEK DEV HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 35
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Parent = Content

    -- 1. เริ่มแอนิเมชั่น "รวมร่าง"
    TweenService:Create(BG, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()
    
    local assembleInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    -- วิ่งเข้ามารวมตรงกลางพร้อมเฟดเส้นขอบ
    TweenService:Create(top, assembleInfo, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}):Play()
    TweenService:Create(bot, assembleInfo, {Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 0}):Play()
    TweenService:Create(left, assembleInfo, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}):Play()
    TweenService:Create(right, assembleInfo, {Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 0}):Play()
    
    -- เฟดเส้นขอบให้เห็นตอนรวมกัน
    for _, s in pairs({s1, s2, s3, s4}) do
        TweenService:Create(s, assembleInfo, {Transparency = 0.8}):Play()
    end

    task.wait(0.6)

    -- 2. เมื่อประกอบเสร็จ เฟด Title ขึ้นมา
    TweenService:Create(Content, TweenInfo.new(0.5), {GroupTransparency = 0}):Play()
    
    task.wait(2.5) -- หน่วงเวลาโชว์ชื่อ

    -- 3. แยกย้าย (Disassemble) ตอนออก
    local disassembleInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    TweenService:Create(Content, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
    
    TweenService:Create(top, disassembleInfo, {Position = UDim2.new(0, 0, -1.5, 0)}):Play()
    TweenService:Create(bot, disassembleInfo, {Position = UDim2.new(0, 0, 1.5, 0)}):Play()
    TweenService:Create(left, disassembleInfo, {Position = UDim2.new(-1.5, 0, 0, 0)}):Play()
    TweenService:Create(right, disassembleInfo, {Position = UDim2.new(1.5, 0, 0, 0)}):Play()
    TweenService:Create(BG, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

    task.wait(0.6)
    ScreenGui:Destroy()
end

PlayAssembleLoading()