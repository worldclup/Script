local function PlayFixedPremiumLoading()
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- CONFIGURATION (Theme: Midnight Premium)
    local DarkBG = Color3.fromRGB(10, 10, 12) 
    local AccentColor = Color3.fromRGB(255, 255, 255) -- สีขาวคลีน
    local Duration = 5 -- ความเร็วในการโหลด

    local TargetParent = pcall(function() return CoreGui.Name end) and CoreGui or PlayerGui

    -- CLEANUP
    for _, v in pairs(TargetParent:GetChildren()) do
        if v.Name == "DEKDEV_Loading" then v:Destroy() end
    end

    -- 1. SETUP SCREEN
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DEKDEV_Loading"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 10000
    ScreenGui.Parent = TargetParent

    -- Background Overlay (พื้นหลังมืด)
    local Overlay = Instance.new("Frame")
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.Size = UDim2.fromScale(1, 1)
    Overlay.Parent = ScreenGui

    -- 2. MAIN CONTAINER (ใช้ CanvasGroup เพื่อให้ Fade ได้ทั้งกรอบ)
    local MainContainer = Instance.new("CanvasGroup")
    MainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    MainContainer.Position = UDim2.fromScale(0.5, 0.5)
    MainContainer.Size = UDim2.fromOffset(400, 200) -- ขนาดกรอบ
    MainContainer.BackgroundColor3 = DarkBG
    MainContainer.GroupTransparency = 1 -- เริ่มต้นแบบโปร่งใส
    MainContainer.BorderSizePixel = 0
    MainContainer.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainContainer

    -- Stroke (เส้นขอบขาวบางๆ)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = AccentColor
    Stroke.Thickness = 1.2
    Stroke.Transparency = 0.8
    Stroke.Parent = MainContainer

    -- 3. CONTENT
    local Title = Instance.new("TextLabel")
    Title.Text = "DEK DEV HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 32
    Title.TextColor3 = AccentColor
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Position = UDim2.fromOffset(0, 60)
    Title.Parent = MainContainer

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Text = "PREMIUM AUTOMATION"
    SubTitle.Font = Enum.Font.GothamMedium
    SubTitle.TextSize = 12
    SubTitle.TextTransparency = 0.4
    SubTitle.TextColor3 = AccentColor
    SubTitle.BackgroundTransparency = 1
    SubTitle.Size = UDim2.new(1, 0, 0, 20)
    SubTitle.Position = UDim2.fromOffset(0, 95)
    SubTitle.Parent = MainContainer

    -- Loading Bar Background
    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(0, 250, 0, 3)
    BarBG.Position = UDim2.new(0.5, -125, 0.75, 0)
    BarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = MainContainer

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.fromScale(0, 1)
    BarFill.BackgroundColor3 = AccentColor
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG

    -- 4. ANIMATION LOGIC
    -- Fade & Scale In (เฟดกรอบ 4 เหลี่ยมเข้ามา)
    TweenService:Create(Overlay, TweenInfo.new(1), {BackgroundTransparency = 0.4}):Play()
    
    -- ขยายขนาดและเฟดจางเข้ามาพร้อมกัน
    MainContainer.Size = UDim2.fromOffset(350, 150) -- เริ่มจากขนาดเล็กกว่านิดหน่อย
    TweenService:Create(MainContainer, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(400, 200),
        GroupTransparency = 0
    }):Play()

    task.wait(1)

    -- Progress Loading
    local TweenProgress = TweenService:Create(BarFill, TweenInfo.new(Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(1, 1)
    })
    TweenProgress:Play()

    TweenProgress.Completed:Wait()
    task.wait(0.5)

    -- 5. FADE OUT (เฟดออกอย่างนุ่มนวล)
    TweenService:Create(MainContainer, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(450, 250), -- ขยายออกนิดหน่อยตอนเฟดออก
        GroupTransparency = 1
    }):Play()
    
    TweenService:Create(Overlay, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()

    task.wait(1)
    ScreenGui:Destroy()
end

PlayFixedPremiumLoading()