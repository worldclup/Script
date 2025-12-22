local function PlaySquareFragmentLoading()
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local TargetParent = pcall(function() return CoreGui.Name end) and CoreGui or PlayerGui
    
    if Lighting:FindFirstChild("DEKDEV_Blur") then Lighting.DEKDEV_Blur:Destroy() end

    -- 1. SETUP
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "DEKDEV_Blur"
    Blur.Size = 0
    Blur.Parent = Lighting

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DEKDEV_SquareAssemble"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = TargetParent

    local BG = Instance.new("Frame")
    BG.Size = UDim2.fromScale(1, 1)
    BG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BG.BackgroundTransparency = 1
    BG.Parent = ScreenGui

    -- UI ขนาดหลัก
    local FrameWidth, FrameHeight = 500, 250

    local Main = Instance.new("CanvasGroup")
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = UDim2.fromOffset(FrameWidth, FrameHeight)
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    Main.BorderSizePixel = 0
    Main.GroupTransparency = 1
    Main.Parent = ScreenGui

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(0, 0, 0)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.8
    Stroke.Parent = Main

    -- Content (Title, Desc, Credit)
    local Title = Instance.new("TextLabel")
    Title.Text = "DEK DEV HUB"
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 34
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Position = UDim2.fromOffset(30, 30)
    Title.Size = UDim2.new(0, 300, 0, 40)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main

    local Desc = Instance.new("TextLabel")
    Desc.Text = "Anime Weapons"
    Desc.Font = Enum.Font.GothamMedium
    Desc.TextSize = 14
    Desc.TextColor3 = Color3.fromHex("#FF3B3B")
    Desc.Position = UDim2.fromOffset(32, 65)
    Desc.Size = UDim2.new(0, 300, 0, 20)
    Desc.BackgroundTransparency = 1
    Desc.TextTransparency = 0.4
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Main

    local Credit = Instance.new("TextLabel")
    Credit.Text = "Powered by Gemini AI"
    Credit.Font = Enum.Font.GothamMedium
    Credit.TextSize = 10
    Credit.TextColor3 = Color3.new(1, 1, 1)
    Credit.Position = UDim2.new(0, 32, 1, -35)
    Credit.Size = UDim2.new(0, 200, 0, 20)
    Credit.BackgroundTransparency = 1
    Credit.TextTransparency = 0.6
    Credit.TextXAlignment = Enum.TextXAlignment.Left
    Credit.Parent = Main

    local BarBG = Instance.new("Frame")
    BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    BarBG.Size = UDim2.new(1, -60, 0, 4)
    BarBG.Position = UDim2.new(0.5, 0, 1, -55)
    BarBG.AnchorPoint = Vector2.new(0.5, 0.5)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Main

    local BarFill = Instance.new("Frame")
    BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    BarFill.Size = UDim2.fromScale(0, 1)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG

    -- 2. FRAGMENTS (สร้างเศษสี่เหลี่ยม)
    local Fragments = {}
    local RandomGen = Random.new()
    local FragmentCount = 1000

    for i = 1, FragmentCount do
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        -- f.BackgroundTransparency = 1
        local size = RandomGen:NextInteger(2, 10)
        f.Size = UDim2.fromOffset(size, size)

        -- เริ่มต้นจากกระจายทั่วจอ
        f.Position = UDim2.fromScale(RandomGen:NextNumber(-0.2, 1.2), RandomGen:NextNumber(-0.2, 1.2))
        f.Parent = ScreenGui
        table.insert(Fragments, f)
    end

    -- --- ANIMATION START ---
    TweenService:Create(BG, TweenInfo.new(1), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(Blur, TweenInfo.new(1.5), {Size = 25}):Play()

    -- 3. STEP 1: พุ่งเข้ามารวมเป็น "ทรงสี่เหลี่ยม" (Square Assemble)
    for _, f in pairs(Fragments) do
        local delayTime = RandomGen:NextNumber(0, 1.5)
        task.delay(delayTime, function()
            -- คำนวณตำแหน่งสุ่มให้อยู่ภายในกรอบ 500x250
            local offsetX = RandomGen:NextInteger(-FrameWidth/2, FrameWidth/2)
            local offsetY = RandomGen:NextInteger(-FrameHeight/2, FrameHeight/2)
            
            TweenService:Create(f, TweenInfo.new(1.2, Enum.EasingStyle.Quart), {
                Position = UDim2.new(0.5, offsetX, 0.5, offsetY),
                BackgroundTransparency = RandomGen:NextNumber(0.3, 0.7),
                Rotation = (RandomGen:NextNumber() > 0.5 and 0 or 90) -- ให้จัดวางแนวนอนหรือตั้งเท่านั้นเพื่อให้ดูเป็นบล็อก
            }):Play()
        end)
    end

    task.wait(3.5) -- นานขึ้นเพื่อให้เห็นการก่อตัวเป็นสี่เหลี่ยม

    -- 4. STEP 2: หลอมละลายกลายเป็นกรอบเดียว (Final Merge)
    for _, f in pairs(Fragments) do
        TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0)
        }):Play()
    end

    -- 5. STEP 3: เปิดตัว UI หลัก (โผล่ออกมาตรงๆ)
    Main.GroupTransparency = 0
    Main.Size = UDim2.fromOffset(FrameWidth + 20, FrameHeight + 10) -- ขยายเกินนิดนึงแล้วหดกลับ
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(FrameWidth, FrameHeight)
    }):Play()

    -- Progress Bar
    local LoadingTween = TweenService:Create(BarFill, TweenInfo.new(5, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1, 1)})
    LoadingTween:Play()
    LoadingTween.Completed:Wait()

    task.wait(0.5)

    -- Outro
    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0), GroupTransparency = 1}):Play()
    TweenService:Create(Blur, TweenInfo.new(0.8), {Size = 0}):Play()
    TweenService:Create(BG, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()

    task.wait(0.8)
    ScreenGui:Destroy()
    Blur:Destroy()
end

PlaySquareFragmentLoading()