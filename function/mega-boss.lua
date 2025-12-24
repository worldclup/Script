local TextChatService = game:GetService("TextChatService")

task.spawn(function()
    print("🚀 เริ่มระบบดักจับผ่าน TextChatService (High Sensitivity)...")
    
    -- ใช้ Event ดักจับข้อความที่ไหลเข้ามาในระบบ
    TextChatService.OnIncomingMessage = function(message)
        -- ดึงเนื้อหาข้อความ
        local content = message.Text
        
        -- ตรวจสอบว่าข้อความมีเนื้อหาหรือไม่
        if content and content ~= "" then
            -- [LOG ทุกอย่างที่ผ่านเข้ามาเพื่อ Debug]
            print("📩 พบข้อความใหม่ในระบบ: " .. content)

            -- ตรวจสอบคำที่ต้องการ (เช่น Legendary, Gift)
            local keywords = {"Mega"}
            for _, word in pairs(keywords) do
                if string.find(content:lower(), word:lower()) then
                    print("🔥 [MATCH FOUND] เจอคำที่ตามหา: " .. word)
                    -- คุณสามารถใส่ฟังก์ชันการแจ้งเตือนตรงนี้ได้
                end
            end
        end
        
        -- คืนค่า nil เพื่อให้ระบบแชททำงานตามปกติ (ไม่ไปขัดขวางข้อความ)
        return nil
    end
end)
-- ###########################################################################################
local TextChatService = game:GetService("TextChatService")

task.spawn(function()
    print("🚀 ระบบดักจับ Mega Boss เริ่มทำงาน...")
    
    TextChatService.OnIncomingMessage = function(message)
        local content = message.Text
        
        if content and content ~= "" then
            -- 1. เช็คว่าเป็นข้อความ Mega Boss Spawned หรือไม่
            if string.find(content, "Mega Boss Spawned") then
                print("📩 พบข้อความระบบ: " .. content)

                -- 2. ใช้ Pattern Matching ดึงข้อความหลัง "at " จนจบประโยค
                -- %s*at%s+ คือการหาคำว่า "at" ที่มีช่องว่างล้อมรอบ
                -- (.*) คือการจับข้อความที่เหลือทั้งหมดมาเก็บไว้ในตัวแปร
                local mapName = string.match(content, "at%s+(.+)")

                if mapName then
                    -- ตัดเครื่องหมาย ! ออก (ถ้ามี) เพื่อให้ได้ชื่อแมพเพียวๆ
                    mapName = mapName:gsub("!", "")
                    
                    print("🌍 [BOSS DETECTED] แมพที่บอสเกิดคือ: " .. mapName)
                    
                    -- ตรงนี้คุณสามารถเอา mapName ไปใช้ต่อได้ เช่น:
                    -- if mapName == "Namek Planet" then ... end
                end
            end
        end
        return nil
    end
end)
-- ###########################################################################################
local function FindRealMegaBossByConfig()
    -- 1. ดึงข้อมูล Config มาตรฐานของโซน (ในที่นี้คือ DemonSlayer)
    local Success, ZoneConfig = pcall(function()
        return require(game:GetService("ReplicatedStorage").Scripts.Configs.MultipleZones.Enemies.DemonSlayer)
    end)
    
    if not Success or not ZoneConfig then
        print("❌ ไม่สามารถดึงสคริปต์ Config ของโซนได้")
        return
    end

    -- หาค่าเลือดมาตรฐานของ Emperor ในโซนนี้
    local StandardEmperorHP = 0
    for _, data in pairs(ZoneConfig) do
        if data.Difficult == "Emperor" then
            StandardEmperorHP = data.MaxHealth
            break
        end
    end

    print(string.format("--- [ 🔍 Cross-Checking MegaBoss (Normal Emperor HP: %s) ] ---", tostring(StandardEmperorHP)))
    
    local foundCount = 0
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local config = rawget(v, "Config")
            local diffConfig = rawget(v, "DifficultConfig")
            local alive = rawget(v, "Alive")

            if type(config) == "table" and alive == true and config.Difficult == "Emperor" then
                local currentMaxHP = config.MaxHealth or 0
                
                -- [จุดตัดสิน] ถ้าเลือดไม่เท่ากับค่ามาตรฐาน แปลว่าเป็น MegaBoss
                if currentMaxHP ~= StandardEmperorHP then
                    foundCount = foundCount + 1
                    print(string.format("👿 [พบ MegaBoss ตัวจริง!]"))
                    print(string.format("   ชื่อ: %s", config.Display or "Unknown"))
                    print(string.format("   เลือดปัจจุบัน: %s (ไม่ตรงกับค่ามาตรฐาน! ✅)", tostring(currentMaxHP)))
                    print(string.format("   UID: %s", tostring(rawget(v, "Uid"))))
                    print("   -------------------------")
                else
                    print(string.format("ℹ️ พบ Emperor ปกติ: %s (เลือดตรงตาม Config)", config.Display))
                end
            end
        end
    end

    if foundCount == 0 then
        print("⚠️ ไม่พบ MegaBoss ที่เลือดผิดปกติในโซนนี้")
    end
end

FindRealMegaBossByConfig()