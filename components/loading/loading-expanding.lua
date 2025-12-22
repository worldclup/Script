local function PlayPortalLoading()
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local TargetParent = pcall(function() return CoreGui.Name end) and CoreGui or PlayerGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DEKDEV_Portal"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = TargetParent

    local BG = Instance.new("Frame")
    BG.Size = UDim2.fromScale(1, 1)
    BG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BG.BackgroundTransparency = 1
    BG.Parent = ScreenGui

    -- กรอบหลัก (CanvasGroup เพื่อการ Fade)
    local Main = Instance.new("CanvasGroup")
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = UDim2.fromOffset(0, 2) -- เริ่มจากเส้นบางๆ
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    Main.BorderSizePixel = 0
    Main.GroupTransparency = 1
    Main.Parent = ScreenGui

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(15, 15, 18)
    Stroke.Thickness = 1.5
    Stroke.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Text = "DEK DEV HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 30
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Size = UDim2.fromScale(1, 1)
    Title.BackgroundTransparency = 1
    Title.Parent = Main

    -- --- ANIMATION ---
    TweenService:Create(BG, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
    task.wait(0.2)

    -- ขั้นที่ 1: ยืดออกแนวนอน (กลายเป็นเส้นตรง)
    Main.GroupTransparency = 0
    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(400, 2)
    }):Play()

    task.wait(0.6)

    -- ขั้นที่ 2: ขยายออกแนวตั้ง (กลายเป็นกรอบ)
    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(400, 180)
    }):Play()

    task.wait(2.5) -- โชว์ชื่อ

    -- ขั้นที่ 3: ปิดตัว (หดกลับ)
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 2),
        GroupTransparency = 1
    }):Play()
    
    TweenService:Create(BG, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()

    task.wait(0.8)
    ScreenGui:Destroy()
end

PlayPortalLoading()