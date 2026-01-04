if not _G.Settings then
    _G.Settings = {
        Desc = {
            Game = "Mutliple game",
            Color = Color3.fromHex("#50C878")
        }
    }
end
local function PlayPortalGreenBlurLoading()
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local TargetParent = pcall(function() return CoreGui.Name end) and CoreGui or PlayerGui

    -- CLEANUP OLD
    if Lighting:FindFirstChild("DEKDEV_Blur") then Lighting.DEKDEV_Blur:Destroy() end

    -- 1. SETUP BLUR
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "DEKDEV_Blur"
    Blur.Size = 0
    Blur.Parent = Lighting

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DEKDEV_PortalGreenBlur"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = TargetParent

    local BG = Instance.new("Frame")
    BG.Size = UDim2.fromScale(1, 1)
    BG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BG.BackgroundTransparency = 1
    BG.Parent = ScreenGui

    -- กรอบหลัก (ขนาด 500x250)
    local Main = Instance.new("CanvasGroup")
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = UDim2.fromOffset(0, 2)
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    Main.BorderSizePixel = 0
    Main.GroupTransparency = 1
    Main.Parent = ScreenGui

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(0, 0, 0)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.9
    Stroke.Parent = Main

    -- 2. TITLE (มุมซ้ายบน)
    local Title = Instance.new("TextLabel")
    Title.Text = "DEK DEV HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 34
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Size = UDim2.new(1, -60, 0, 40)
    Title.Position = UDim2.fromOffset(30, 30)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main

    -- 3. DESCRIPTION (Anime Weapons)
    local Desc = Instance.new("TextLabel")
    Desc.Text = _G.Settings.Desc.Game
    Desc.Font = Enum.Font.GothamMedium
    Desc.TextSize = 14
    Desc.TextColor3 = _G.Settings.Desc.Color
    Desc.Size = UDim2.new(1, -60, 0, 20)
    Desc.Position = UDim2.fromOffset(32, 65)
    Desc.BackgroundTransparency = 1
    Desc.TextTransparency = 0.4
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Main

    -- 4. CREDIT (มุมซ้ายล่าง - ขอบคุณที่ใส่ให้นะครับ!)
    local Credit = Instance.new("TextLabel")
    Credit.Text = "Powered by Gemini AI"
    Credit.Font = Enum.Font.GothamMedium
    Credit.TextSize = 10
    Credit.TextColor3 = Color3.fromRGB(255, 255, 255)
    Credit.Size = UDim2.new(1, -60, 0, 20)
    Credit.Position = UDim2.new(0, 32, 1, -35) -- มุมซ้ายล่าง
    Credit.BackgroundTransparency = 1
    Credit.TextTransparency = 0.6
    Credit.TextXAlignment = Enum.TextXAlignment.Left
    Credit.Parent = Main

    -- 5. LOADING BAR (Rainbow Edition)
    local BarBG = Instance.new("Frame")
    BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    BarBG.Size = UDim2.new(1, -60, 0, 8)
    BarBG.Position = UDim2.new(0.5, 0, 1, -55)
    BarBG.AnchorPoint = Vector2.new(0.5, 0.5)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Main

    local BarFill = Instance.new("Frame")
    BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- สีพื้นเป็นขาวเพื่อให้ Gradient แสดงผลชัด
    BarFill.Size = UDim2.fromScale(0, 1)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG

    -- สร้างสีรุ้งด้วย UIGradient
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        -- ColorSequenceKeypoint.new(0, Color3.fromHex("#0A2E26")),    -- เขียวเข้มมืด (Deep Emerald)
        -- ColorSequenceKeypoint.new(0.3, Color3.fromHex("#00A36C")),  -- เขียวมรกต (Jade Green)
        -- ColorSequenceKeypoint.new(0.6, Color3.fromHex("#50C878")),  -- เขียวสว่าง (Emerald Green)
        -- ColorSequenceKeypoint.new(0.8, Color3.fromHex("#98FB98")),  -- เขียวนวล (Pale Green)
        -- ColorSequenceKeypoint.new(1, Color3.fromHex("#E0FFF0"))     -- ขาวอมเขียวสว่าง (Mint Highlight)
        ColorSequenceKeypoint.new(0, Color3.fromHex("#00A36C")),  -- เขียวมรกต (Jade Green)
        ColorSequenceKeypoint.new(0.2, Color3.fromHex("#50C878")),  -- เขียวสว่าง (Emerald Green)
        ColorSequenceKeypoint.new(0.4, Color3.fromHex("#98FB98")),  -- เขียวนวล (Pale Green)
        ColorSequenceKeypoint.new(0.6, Color3.fromHex("#98FB98")),  -- เขียวนวล (Pale Green)
        ColorSequenceKeypoint.new(0.8, Color3.fromHex("#50C878")),  -- เขียวสว่าง (Emerald Green)
        ColorSequenceKeypoint.new(1, Color3.fromHex("#00A36C")),  -- เขียวมรกต (Jade Green)
    })
    Gradient.Parent = BarFill

    -- --- ANIMATION LOGIC ---

    TweenService:Create(BG, TweenInfo.new(0.8), {BackgroundTransparency = 0.6}):Play()
    TweenService:Create(Blur, TweenInfo.new(1.2), {Size = 25}):Play()
    task.wait(0.2)

    -- Portal Expand: Horizontal
    Main.GroupTransparency = 0
    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(500, 2)
    }):Play()
    task.wait(0.6)

    -- Portal Expand: Vertical
    TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(500, 250)
    }):Play()
    task.wait(0.7)

    -- Loading Progress
    local LoadingTween = TweenService:Create(BarFill, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(1, 1)
    })
    LoadingTween:Play()
    
    LoadingTween.Completed:Wait() 
    task.wait(0.5)

    -- Outro
    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 2),
        GroupTransparency = 1
    }):Play()
    
    TweenService:Create(Blur, TweenInfo.new(0.8), {Size = 0}):Play()
    TweenService:Create(BG, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()

    task.wait(0.8)
    ScreenGui:Destroy()
    Blur:Destroy()
end

PlayPortalGreenBlurLoading()