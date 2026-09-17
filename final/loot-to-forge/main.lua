local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local eco = player:WaitForChild("Eco")
local level = eco:WaitForChild("level")
local rebirth = eco:WaitForChild("rebirth")
local coin = eco:WaitForChild("coin")
local rebirthConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Rebirth"):WaitForChild("Config"))
local rebirthRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Rebirth"):WaitForChild("TryRebirthRE")
local trainRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Train"):WaitForChild("TrainOnceRE")
local autoTrainRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Train"):WaitForChild("IntoAutoTrainRE")
local oreConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Ore"):WaitForChild("Config"))
local sellRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Backpack"):WaitForChild("TrySellItemRE")
local upgradeRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Upgrade"):WaitForChild("UpgradeOnceRE")
local upgradeOk, upgradeData = pcall(function() return require(ReplicatedStorage:WaitForChild("LocalData"):WaitForChild("UpgradeData")) end)
upgradeData = upgradeOk and upgradeData or nil
local upgradeFolder = ReplicatedStorage:WaitForChild("Config"):WaitForChild("Upgrade")
local upgradeConfig = require(upgradeFolder:WaitForChild("Config"))
local upgradeHelper = require(upgradeFolder:WaitForChild("Helper"))

local autoRebirth, autoTrain, autoTrain2 = false, false, false
local trainDelay, trainToken, autoTrain2Token, lastRebirth, selectedAutoTrainArea = 0.1, 0, 0, 0, nil
local autoStageFarm, stageFarmToken, selectedStage, minimumOrePrice = false, 0, nil, 0
local stageRadius = 250
local autoSell, sellToken, sellNames, sellRarities = false, 0, {}, {}
local autoRefreshSell, refreshSellToken, refreshSellDelay = false, 0, 5
local autoUpgrade, upgradeTokens, upgradeDelay = {}, {}, 0.5
local oreStatus, sellStatus, upgradeStatus, nameDropdown, rarityDropdown
local speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled = false, false, false, false
local walkSpeed, jumpPower, flySpeed, flyHeight = 50, 100, 50, 15
local normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
local flyVelocity, flyGyro, flyPosition, flyConnection, hoverY

local function nextRebirth()
	return rebirthConfig[rebirth.Value + 1]
end

local function tryRebirth()
	local data = nextRebirth()
	if data and level.Value >= data.NeedLevel then rebirthRemote:FireServer() end
end

local function setAutoTrain(enabled)
	autoTrain, trainToken = enabled, trainToken + 1
	if not enabled then return end
	local token = trainToken
	task.spawn(function()
		while autoTrain and token == trainToken do
			trainRemote:FireServer()
			task.wait(trainDelay)
		end
	end)
end

local function getUnlockedAutoTrainArea()
	local areas = workspace:FindFirstChild("TOUCHED")
	areas = areas and areas:FindFirstChild("AutoTrainArea")
	local best
	for _, area in ipairs(areas and areas:GetChildren() or {}) do
		local required = area:FindFirstChild("UIAtta") and area.UIAtta:FindFirstChild("TrainGui") and area.UIAtta.TrainGui:FindFirstChild("Frame") and area.UIAtta.TrainGui.Frame:FindFirstChild("Rebirth") and area.UIAtta.TrainGui.Frame.Rebirth:FindFirstChild("Rebirth")
		local value = required and (required:IsA("ValueBase") and required.Value or (required:IsA("TextLabel") or required:IsA("TextButton") or required:IsA("TextBox")) and required.Text)
		local areaId, requiredRebirth = tonumber(area.Name), tonumber(tostring(value):match("%d+"))
		if areaId and requiredRebirth and rebirth.Value >= requiredRebirth and (not best or areaId > best) then best = areaId end
	end
	return best
end

local function setAutoTrain2(enabled)
	autoTrain2, autoTrain2Token, selectedAutoTrainArea = enabled, autoTrain2Token + 1, nil
	if not enabled then return end
	local token = autoTrain2Token
	task.spawn(function()
		while autoTrain2 and token == autoTrain2Token do
			local areaId = getUnlockedAutoTrainArea()
			if areaId and areaId ~= selectedAutoTrainArea then
				autoTrainRemote:FireServer(areaId)
				selectedAutoTrainArea = areaId
			end
			task.wait(1)
		end
	end)
end

local function getPart(item)
	if item:IsA("BasePart") then return item end
	return (item:IsA("Model") and item.PrimaryPart) or item:FindFirstChildWhichIsA("BasePart", true)
end

local function teleportTo(item)
	local part = getPart(item)
	if part and rootPart.Parent then rootPart.CFrame = part.CFrame * CFrame.new(0, 3, 0); return true end
end

local function stageNames()
	local folder = workspace:FindFirstChild("WorldModel")
	folder = folder and folder:FindFirstChild("StageMap") and folder.StageMap:FindFirstChild("AreaPart")
	local names = {}
	for _, stage in ipairs(folder and folder:GetChildren() or {}) do table.insert(names, stage.Name) end
	table.sort(names, function(a, b) return (tonumber(a:match("%d+")) or math.huge) < (tonumber(b:match("%d+")) or math.huge) end)
	return names, folder
end

local function orePack()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local title = gui and gui:FindFirstChild("Hud") and gui.Hud:FindFirstChild("LeftInfos") and gui.Hud.LeftInfos:FindFirstChild("OrePack") and gui.Hud.LeftInfos.OrePack:FindFirstChild("Title")
	if not title then return 0, 999 end
	local current, maximum = title.Text:match("(%d+)%s*/%s*(%d+)")
	return tonumber(current) or 0, tonumber(maximum) or 999
end

local function inStageArea(stagePart, item)
	if not stagePart then return true end
	local part = getPart(item)
	if not part then return false end
	local offset = part.Position - stagePart.Position
	return math.sqrt(offset.X ^ 2 + offset.Z ^ 2) <= stageRadius
end

local function getLivingEnemy(folder, stagePart)
	for _, enemy in ipairs(folder and folder:GetChildren() or {}) do
		local humanoid = enemy:FindFirstChildWhichIsA("Humanoid", true)
		if humanoid and humanoid.Health > 0 and getPart(enemy) and inStageArea(stagePart, enemy) then return enemy end
	end
end

local function clickGui(button)
	if type(firesignal) == "function" then
		pcall(firesignal, button.MouseButton1Down)
		pcall(firesignal, button.MouseButton1Click)
		pcall(firesignal, button.Activated, Enum.UserInputType.MouseButton1)
		return true
	end
	local inset = GuiService:GetGuiInset()
	local center = button.AbsolutePosition + button.AbsoluteSize / 2 + inset
	if isMobile then
		local touchId = 91
		pcall(function()
			VirtualInputManager:SendTouchEvent(touchId, 0, center.X, center.Y)
			task.wait(0.05)
		end)
		VirtualInputManager:SendTouchEvent(touchId, 2, center.X, center.Y)
		return true
	end
	VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
	task.wait(0.05)
	VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
	return true
end

local function returnFromStage()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local returnRoot = gui and gui:FindFirstChild("Hud") and gui.Hud:FindFirstChild("Top") and gui.Hud.Top:FindFirstChild("Return")
	if not returnRoot then return false end
	local button = returnRoot:IsA("GuiButton") and returnRoot or returnRoot:FindFirstChildWhichIsA("GuiButton", true)
	if not button then return false end
	return clickGui(button)
end

local function collectOre(ore)
	local prompt = ore:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		if type(fireproximityprompt) == "function" then
			fireproximityprompt(prompt, 2)
			return "prompt"
		end
		local held = pcall(function()
			prompt.HoldDuration = 0
			prompt:InputHoldBegin()
			task.wait(0.1)
			prompt:InputHoldEnd()
		end)
		if held then return "hold" end
	end
	if isMobile then return "none" end
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(2)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	return "key"
end

local function setAutoStageFarm(enabled)
	autoStageFarm, stageFarmToken = enabled, stageFarmToken + 1
	if not enabled then return end
	local token = stageFarmToken
	task.spawn(function()
		while autoStageFarm and token == stageFarmToken do
			local _, stages = stageNames()
			local stage = stages and stages:FindFirstChild(selectedStage or "")
			if stage and teleportTo(stage) then
				if oreStatus then oreStatus:Set("Entering stage...") end
				task.wait(2)
				local stagePart = getPart(stage)
				local enemies = workspace:FindFirstChild("EnemyFolder")
				local target = getLivingEnemy(enemies, stagePart)
				while autoStageFarm and token == stageFarmToken and target do
					if oreStatus then oreStatus:Set("Fighting: " .. target.Name) end
					teleportTo(target)
					task.wait(0.35)
					target = getLivingEnemy(enemies, stagePart)
				end
				if oreStatus then oreStatus:Set("Collecting ores...") end
				local ores = workspace:FindFirstChild("OreCache")
				for _, ore in ipairs(ores and ores:GetChildren() or {}) do
					local current, maximum = orePack()
					if not autoStageFarm or token ~= stageFarmToken or current >= maximum then break end
					local data = oreConfig[ore.Name]
					local price = data and data.Price or 0
					if price >= minimumOrePrice and inStageArea(stagePart, ore) then
						if oreStatus then oreStatus:Set(("Ore %d/%d: %s"):format(current, maximum, ore.Name)) end
						if teleportTo(ore) then
							collectOre(ore)
							task.wait(0.25)
						elseif oreStatus then
							oreStatus:Set("No BasePart: " .. ore.Name)
						end
					end
				end
				if oreStatus then oreStatus:Set(("Ore pack: %d/%d"):format(orePack())) end
				if oreStatus then oreStatus:Set(returnFromStage() and "Returning..." or "Return button not found") end
				task.wait(2)
			else
				if oreStatus then oreStatus:Set("Stage not found: " .. tostring(selectedStage)) end
				task.wait(1)
			end
		end
	end)
end

local function sellList()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local root = gui and gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Sell")
	root = root and root:FindFirstChild("zheng") and root.zheng:FindFirstChild("ScrollingFrame")
	local items = {}
	for _, frame in ipairs(root and root:GetChildren() or {}) do
		if frame:IsA("GuiObject") and frame.Name:match("%-%x+%-%d+$") then
			local ming, im = frame:FindFirstChild("ming", true), frame:FindFirstChild("Im", true)
			local nameLabel = ming and ming:FindFirstChild("TextLabel")
			local rarityLabel = ming and ming:FindFirstChild("TextLa")
			local countLabel = im and im:FindFirstChild("TextLa")
			table.insert(items, {
				uid = frame.Name,
				name = nameLabel and nameLabel.Text ~= "" and nameLabel.Text or frame.Name,
				rarity = rarityLabel and rarityLabel.Text ~= "" and rarityLabel.Text or "?",
				count = tonumber((countLabel and countLabel.Text or ""):match("%d+")) or 1,
			})
		end
	end
	return items
end

local function stripCount(label)
	return (tostring(label):gsub("%s+x%d+$", ""))
end

local function toSet(value)
	local set = {}
	for _, v in ipairs(type(value) == "table" and value or { value }) do set[stripCount(v)] = true end
	return set
end

local function sellOptions()
	local nameTotals, rarityTotals = {}, {}
	for _, item in ipairs(sellList()) do
		nameTotals[item.name] = (nameTotals[item.name] or 0) + item.count
		rarityTotals[item.rarity] = (rarityTotals[item.rarity] or 0) + item.count
	end
	local names, rarities = {}, {}
	for name, total in pairs(nameTotals) do table.insert(names, ("%s x%d"):format(name, total)) end
	for rarity, total in pairs(rarityTotals) do table.insert(rarities, ("%s x%d"):format(rarity, total)) end
	table.sort(names)
	table.sort(rarities)
	return names, rarities
end

local function refreshDropdown(dropdown, options)
	if dropdown then dropdown:Refresh(options) end
end

local function refreshSellLists()
	local names, rarities = sellOptions()
	refreshDropdown(nameDropdown, names)
	refreshDropdown(rarityDropdown, rarities)
	return names, rarities
end

local function setAutoRefreshSell(enabled)
	autoRefreshSell, refreshSellToken = enabled, refreshSellToken + 1
	if not enabled then return end
	local token = refreshSellToken
	task.spawn(function()
		while autoRefreshSell and token == refreshSellToken do
			refreshSellLists()
			task.wait(refreshSellDelay)
		end
	end)
end

local function setAutoSell(enabled)
	autoSell, sellToken = enabled, sellToken + 1
	if not enabled then return end
	local token = sellToken
	task.spawn(function()
		while autoSell and token == sellToken do
			local sold = 0
			for _, item in ipairs(sellList()) do
				if not autoSell or token ~= sellToken then break end
				if sellNames[item.name] or sellRarities[item.rarity] then
					sellRemote:FireServer(item.uid, item.count)
					sold = sold + item.count
					task.wait(0.15)
				end
			end
			if sold > 0 then refreshSellLists() end
			if sellStatus then sellStatus:Set(sold > 0 and ("Sold %d item(s)"):format(sold) or ("Nothing matched (%d stack(s) in bag)"):format(#sellList())) end
			task.wait(1)
		end
	end)
end

local upgradeOrder = { OrePack = 1, Luck = 2, Train = 3 }

local function upgradeKinds()
	local kinds = {}
	for kind in pairs(upgradeConfig) do table.insert(kinds, kind) end
	table.sort(kinds, function(a, b)
		local rankA, rankB = upgradeOrder[a] or math.huge, upgradeOrder[b] or math.huge
		if rankA ~= rankB then return rankA < rankB end
		return a < b
	end)
	return kinds
end

local function short(number)
	if number >= 1e9 then return ("%.2fB"):format(number / 1e9) end
	if number >= 1e6 then return ("%.2fM"):format(number / 1e6) end
	if number >= 1e3 then return ("%.1fK"):format(number / 1e3) end
	return ("%d"):format(number)
end

local function refreshUpgradeTexts()
	if not upgradeStatus then return end
	local lines = { "Coin: " .. short(coin.Value) }
	for _, kind in ipairs(upgradeKinds()) do
		local lv = upgradeData and upgradeData.GetLevel(kind) or 0
		local price = upgradeHelper.GetPrice(kind, lv + 1)
		table.insert(lines, ("%s Lv.%d | %s"):format(kind, lv, price and ("next " .. short(price) .. (coin.Value >= price and "" or " (not enough)")) or "MAX"))
	end
	upgradeStatus:Set(table.concat(lines, "\n"))
end

local function setAutoUpgrade(kind, enabled)
	autoUpgrade[kind], upgradeTokens[kind] = enabled, (upgradeTokens[kind] or 0) + 1
	if not enabled then return end
	local token = upgradeTokens[kind]
	task.spawn(function()
		while autoUpgrade[kind] and token == upgradeTokens[kind] do
			local levelNow = upgradeData and upgradeData.GetLevel(kind) or 0
			if upgradeHelper.CheckIsMax(kind, levelNow) then
				autoUpgrade[kind] = false
				break
			end
			local price = upgradeHelper.GetPrice(kind, levelNow + 1)
			if not price or coin.Value >= price then upgradeRemote:FireServer(kind) end
			task.wait(upgradeDelay)
		end
	end)
end

local function setFly(enabled)
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end
	if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
	if flyGyro then flyGyro:Destroy() flyGyro = nil end
	if flyPosition then flyPosition:Destroy() flyPosition = nil end
	if not enabled then return end

	hoverY = rootPart.Position.Y + flyHeight
	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce, flyVelocity.Parent = Vector3.new(1e5, 1e5, 1e5), rootPart
	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque, flyGyro.P, flyGyro.Parent = Vector3.new(1e5, 1e5, 1e5), 1e4, rootPart
	flyPosition = Instance.new("BodyPosition")
	flyPosition.MaxForce, flyPosition.P, flyPosition.Parent = Vector3.new(0, 1e5, 0), 1e4, rootPart
	flyConnection = RunService.RenderStepped:Connect(function()
		if not rootPart.Parent then return end
		local move = humanoid.MoveDirection
		flyVelocity.Velocity = Vector3.new(move.X, 0, move.Z) * flySpeed
		flyPosition.Position = Vector3.new(0, hoverY, 0)
		flyGyro.CFrame = workspace.CurrentCamera.CFrame
	end)
end

RunService.Heartbeat:Connect(function()
	if speedEnabled then humanoid.WalkSpeed = walkSpeed end
	if jumpEnabled then humanoid.UseJumpPower = true; humanoid.JumpPower = jumpPower end
	if autoRebirth and os.clock() - lastRebirth >= 0.5 then pcall(tryRebirth); lastRebirth = os.clock() end
end)

player.Idled:Connect(function()
	if antiAfkEnabled then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

local function resetAll()
	autoRebirth = false
	setAutoTrain(false)
	setAutoTrain2(false)
	setAutoStageFarm(false)
	setAutoSell(false)
	setAutoRefreshSell(false)
	for kind in pairs(autoUpgrade) do setAutoUpgrade(kind, false) end
	speedEnabled, flyEnabled, jumpEnabled, antiAfkEnabled = false, false, false, false
	humanoid.WalkSpeed = normalSpeed
	humanoid.UseJumpPower, humanoid.JumpPower = normalUseJumpPower, normalJumpPower
	setFly(false)
end

local Window = Rayfield:CreateWindow({
	name = "DEK DEV HUB", subtitle = "+1 Loot The Force", sidebarLayout = not isMobile, theme = "default",
	icon = "rbxassetid://134664151762829", showName = "DEK", showIcon = "rbxassetid://134664151762829", showIconOnly = true,
})
local Tabs = {}
Tabs.Main = Window:CreateTab({ name = "Main" })
Tabs.Farm = Window:CreateTab({ name = "Train & Rebirth" })
Tabs.Combat = Window:CreateTab({ name = "Combat" })
Tabs.Sell = Window:CreateTab({ name = "Sell & Upgrade" })
Tabs.Settings = Window:CreateTab({ name = "Settings" })

local rebirthStatus = Tabs.Farm:CreateText({ name = "Rebirth Status", text = "Loading..." })
Tabs.Farm:CreateSection({ name = "Rebirth" })
Tabs.Farm:CreateToggle({ name = "Auto Rebirth", flag = "AutoRebirth", value = false, callback = function(value) autoRebirth = value end })
Tabs.Farm:CreateButton({ name = "Rebirth Once", callback = function() pcall(tryRebirth) end })
Tabs.Farm:CreateSection({ name = "Train" })
Tabs.Farm:CreateToggle({ name = "Auto Train", flag = "AutoTrain", value = false, callback = setAutoTrain })
Tabs.Farm:CreateSlider({ name = "Train Delay (seconds)", flag = "TrainDelay", value = 0.1, range = { 0.1, 10 }, increment = 0.1, callback = function(value) trainDelay = value end })
Tabs.Farm:CreateToggle({ name = "Auto Train 2", flag = "AutoTrain2", value = false, description = "เลือก AutoTrainArea สูงสุดที่ Rebirth ถึงเงื่อนไข", callback = setAutoTrain2 })

local stages = stageNames()
selectedStage = stages[1]
Tabs.Combat:CreateSection({ name = "Stage Farm" })
oreStatus = Tabs.Combat:CreateText({ name = "Ore Status", text = "Waiting..." })
Tabs.Combat:CreateDropdown({ name = "Select Stage", flag = "SelectStage", options = stages, default = selectedStage, callback = function(value) selectedStage = value end })
Tabs.Combat:CreateSlider({ name = "Stage Radius", flag = "StageRadius", value = 250, range = { 25, 2000 }, increment = 25, description = "ระยะจากจุดกลาง stage ที่ยอมให้ตี/เก็บ", callback = function(value) stageRadius = value end })
Tabs.Combat:CreateInput({ name = "Minimum Ore Price", flag = "MinimumOrePrice", value = "0", placeholder = "e.g. 1000", callback = function(value) minimumOrePrice = tonumber(value) or 0 end })
Tabs.Combat:CreateToggle({ name = "Auto Stage Farm", flag = "AutoStageFarm", value = false, description = "วาร์ปตีมอน เก็บ Ore แล้ว Return", callback = setAutoStageFarm })

local sellNameOptions, sellRarityOptions = sellOptions()
Tabs.Sell:CreateSection({ name = "Auto Sell" })
sellStatus = Tabs.Sell:CreateText({ name = "Sell Status", text = "Waiting..." })
nameDropdown = Tabs.Sell:CreateDropdown({ name = "Sell Items", flag = "SellItems", options = sellNameOptions, multiSelect = true, value = {}, callback = function(value) sellNames = toSet(value) end })
rarityDropdown = Tabs.Sell:CreateDropdown({ name = "Sell Rarities", flag = "SellRarities", options = sellRarityOptions, multiSelect = true, value = {}, callback = function(value) sellRarities = toSet(value) end })
Tabs.Sell:CreateButton({ name = "Refresh Item List", callback = function()
	local names = refreshSellLists()
	local total = 0
	for _, item in ipairs(sellList()) do total = total + item.count end
	if sellStatus then sellStatus:Set(("%d name(s), %d item(s) total"):format(#names, total)) end
end })
Tabs.Sell:CreateToggle({ name = "Auto Refresh List", flag = "AutoRefreshSell", value = false, description = "อัปเดตรายการของในกระเป๋าเป็นระยะ", callback = setAutoRefreshSell })
Tabs.Sell:CreateSlider({ name = "Refresh Delay (seconds)", flag = "RefreshSellDelay", value = 5, range = { 1, 60 }, increment = 1, callback = function(value) refreshSellDelay = value end })
Tabs.Sell:CreateToggle({ name = "Auto Sell", flag = "AutoSell", value = false, description = "ขายของที่เลือกไว้ตามชื่อหรือ rarity", callback = setAutoSell })

Tabs.Sell:CreateSection({ name = "Auto Upgrade" })
upgradeStatus = Tabs.Sell:CreateText({ name = "Upgrade Status", text = "Loading..." })
Tabs.Sell:CreateSlider({ name = "Upgrade Delay (seconds)", flag = "UpgradeDelay", value = 0.5, range = { 0.1, 5 }, increment = 0.1, callback = function(value) upgradeDelay = value end })
for _, kind in ipairs(upgradeKinds()) do
	Tabs.Sell:CreateToggle({ name = "Auto Upgrade: " .. kind, flag = "AutoUpgrade" .. kind, value = false, callback = function(value) setAutoUpgrade(kind, value) end })
end

Tabs.Main:CreateSection({ name = "Speed" })
Tabs.Main:CreateToggle({ name = "Speed", flag = "Speed", value = false, callback = function(value) speedEnabled = value; humanoid.WalkSpeed = value and walkSpeed or normalSpeed end })
Tabs.Main:CreateSlider({ name = "Walk Speed", flag = "WalkSpeed", value = 50, range = { 16, 200 }, increment = 1, callback = function(value) walkSpeed = value end })
Tabs.Main:CreateSection({ name = "Jump" })
Tabs.Main:CreateToggle({ name = "High Jump", flag = "HighJump", value = false, callback = function(value) jumpEnabled = value; humanoid.UseJumpPower = value and true or normalUseJumpPower; humanoid.JumpPower = value and jumpPower or normalJumpPower end })
Tabs.Main:CreateSlider({ name = "Jump Power", flag = "JumpPower", value = 100, range = { 50, 300 }, increment = 1, callback = function(value) jumpPower = value end })
Tabs.Main:CreateSection({ name = "Fly" })
Tabs.Main:CreateToggle({ name = "Fly", flag = "Fly", value = false, callback = function(value) flyEnabled = value; setFly(value) end })
Tabs.Main:CreateSlider({ name = "Fly Speed", flag = "FlySpeed", value = 50, range = { 10, 200 }, increment = 1, callback = function(value) flySpeed = value end })
Tabs.Main:CreateSlider({ name = "Fly Height", flag = "FlyHeight", value = 15, range = { 5, 200 }, increment = 1, callback = function(value) if flyEnabled and hoverY then hoverY = hoverY + value - flyHeight end; flyHeight = value end })

Tabs.Settings:CreateToggle({ name = "Anti AFK", flag = "AntiAfk", value = false, callback = function(value) antiAfkEnabled = value end })
Tabs.Settings:CreateButton({ name = "Boost FPS", callback = function()
	_G.Settings = { Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true }, Meshes = { NoMesh = false, NoTexture = false, Destroy = false }, Images = { Invisible = true, Destroy = false }, Explosions = { Smaller = true, Invisible = false, Destroy = false }, Particles = { Invisible = true, Destroy = false }, TextLabels = { LowerQuality = true, Invisible = false, Destroy = false }, MeshParts = { LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false }, Other = { ["FPS Cap"] = 360, ["No Camera Effects"] = true, ["No Clothes"] = true, ["Low Water Graphics"] = true, ["No Shadows"] = true, ["Low Rendering"] = true, ["Low Quality Parts"] = true, ["Reset Materials"] = true } }
	loadstring(game:HttpGet("https://raw.githubusercontent.com/worldclup/Script/refs/heads/main/components/boost-fps.lua"))()
end })
Tabs.Settings:CreateButton({ name = "Stop All & Close UI", callback = function() resetAll(); Window:Unload() end })

task.spawn(function()
	while not Window.unloaded do
		local data = nextRebirth()
		rebirthStatus:Set(data and ("Level: %d/%d | Rebirth: %d"):format(level.Value, data.NeedLevel, rebirth.Value) or "Reached final rebirth")
		refreshUpgradeTexts()
		task.wait(0.5)
	end
end)

Tabs.Main:Select()

player.CharacterAdded:Connect(function(newCharacter)
	resetAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	normalSpeed, normalJumpPower, normalUseJumpPower = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.UseJumpPower
end)
