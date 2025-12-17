local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reliable = ReplicatedStorage:WaitForChild("Reply"):WaitForChild("Reliable")

-- รายการคำที่ต้องการตัดทิ้ง (ขยายเพิ่มจากที่คุณต้องการ)
local blackList = {"OnlineTime", "DailyTime", "AFKTime", "PlayTime", "TotalKill", "TotalDrops", "Experience", "Yen", "Mastery"}

print("------------------------------------------------")
print("--- 🛡️ IMPROVED MATERIAL FILTER ACTIVE 🛡️ ---")

local function DeepSearch(tbl)
    if type(tbl) ~= "table" then return end
    
    -- เกมนี้ส่งข้อมูลมาเป็นคู่ [1] คือชื่อ [2] คือค่า
    local name = tostring(tbl[1])
    local value = tbl[2]
    
    if name and value then
        local isBlacklisted = false
        for _, word in ipairs(blackList) do
            if name:lower():find(word:lower()) then 
                isBlacklisted = true 
                break 
            end
        end
        
        if not isBlacklisted and name:match("Materials%.") then
            local cleanName = name:gsub("Materials%.", "")
            -- แสดงผลเฉพาะไอเท็มจริงๆ
            print(string.format(" [💎] ITEM: %-18s | Amount: %d", cleanName, math.floor(tonumber(value) or 0)))
        end
    end

    -- มุดลงไปตรวจชั้นถัดไป
    for _, v in pairs(tbl) do
        if type(v) == "table" then DeepSearch(v) end
    end
end

Reliable.OnClientEvent:Connect(function(action, data)
    if action == "Data Sync Update" and type(data) == "table" then
        DeepSearch(data)
    end
end)

print("Status: Blocking Blacklist... Please trigger an update in-game.")
print("------------------------------------------------")