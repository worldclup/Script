-- [[ สคริปต์สแกนข้อมูล PlayerData จากหน่วยความจำ ]]
local function GetMaterials()
    local PlayerData = nil
    
    -- 1. สแกนหาตารางข้อมูลผู้เล่นในหน่วยความจำ (วิธีเดียวกับสคริปต์ที่คุณส่งมา)
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "Attributes") and rawget(v, "YenUpgrades") then
            PlayerData = v
            break
        end
    end

    if PlayerData and PlayerData.Materials then
        print("\n=== 🎒 สรุปไอเท็มในกระเป๋า (Materials) 🎒 ===")
        local found = false
        
        -- 2. วนลูปอ่านค่าจากตาราง Materials โดยตรง
        for itemName, amount in pairs(PlayerData.Materials) do
            -- itemName มักจะเป็นชื่อ ID เช่น BijuToken, RaceToken
            print(string.format("💎 %-18s : %s", tostring(itemName), tostring(amount)))
            found = true
        end
        
        if not found then print("ไม่พบไอเท็มในหมวด Materials") end
        print("==========================================\n")
    else
        warn("❌ ไม่พบข้อมูล PlayerData ในหน่วยความจำ (ลองตีมอนสเตอร์สัก 1 ครั้งเพื่อให้ข้อมูลอัปเดต)")
    end
end

-- รันฟังก์ชัน
GetMaterials()