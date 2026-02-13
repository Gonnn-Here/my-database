-- =========================================================
--        ULTIMATE HOST PRO - HWID PROTECTED (VIP)
-- =========================================================
-- Owner: Gonnn-Here
-- Versi: 1.6 (Added Fast Drop System)
-- =========================================================

local whitelistURL = "https://raw.githubusercontent.com/Gonnn-Here/my-database/main/waitlist.txt"
local myHWID = getHWID()
local isWhitelisted = false

-- Variabel Fitur Utama
local wrenchPullMode = false
local lastWrenchedNetID = -1
local fastTele, spamActive = false, false
local homeWorld, spamText = "", ""
local lastSpamTime, spamInterval, myPing = 0, 0, 0

-- Variabel Perhitungan FPS
local fpsEnabled = false
local lastFrameTime = os.clock()
local frameCount = 0
local currentFPS = 0

-- 1. SISTEM LISENSI (HWID CHECK)
function checkLicense()
    local status, content = makeRequest(whitelistURL, "GET")
    if status == 200 and content:find(myHWID) then
        isWhitelisted = true
        sendVariantList({[1]="OnConsoleMessage", [2]="`2[LICENSE] `wHardware ID Recognized!"}, -1)
    else
        isWhitelisted = false
        sendVariantList({[1]="OnConsoleMessage", [2]="`4[LICENSE] `wDevice not registered!\n`wHWID: `9" .. myHWID}, -1)
        print("KODE HWID USER: " .. myHWID)
    end
end

checkLicense()

addEvent(Event.VariantList, function(varlist, netid)
    if not isWhitelisted then return end 

    local chat = varlist[1]
    local function systemLog(msg)
        sendVariantList({[1]="OnConsoleMessage", [2]=msg}, netid)
    end

    -- [ COMMAND: /fps & /wp ]
    if chat == "/fps" then
        fpsEnabled = not fpsEnabled
        systemLog("`2[SYSTEM] `wFPS Counter: " .. (fpsEnabled and "`9ON" or "`4OFF")); return true
    elseif chat == "/wp" then
        wrenchPullMode = not wrenchPullMode
        systemLog("`2[SYSTEM] `wWrench Pull Mode: " .. (wrenchPullMode and "`9ON" or "`4OFF")); return true
    end

    -- [ LOGIKA WRENCH ]
    if varlist[1] == "OnDialogRequest" and varlist[2]:find("p_id") then
        local targetNetID = varlist[2]:match("p_id|(%d+)")
        if targetNetID then
            lastWrenchedNetID = targetNetID
            if wrenchPullMode then sendPacket(2, "action|input\n|text|/pull") return true end
        end
    end

    -- [ REAL WHEEL CHECKER ]
    if varlist[1] == "OnTalkBubble" and varlist[2]:find("spun the wheel and got") then
        local name, number = varlist[2]:match("CP:(%w+).+got (%d+)") or varlist[2]:match("(.+) spun the wheel and got (%d+)")
        if number then
            local totalDigit = 0
            for digit in number:gmatch(".") do totalDigit = totalDigit + tonumber(digit) end
            systemLog("`#REAL! `w" .. name .. " `2rolled `w" .. number .. " `0[`b" .. totalDigit .. "`0]")
        end
    end

    -- [ SISTEM DROP & PAY (LENGKAP) ]
    local cmd, count = chat:match("(/%S+)%s+(%d+)")
    if not count then count = "1" end
    
    -- Drop Satuan (Contoh: /dw 50)
    if chat:find("/dw") then -- Drop Diamond Lock
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. count); return true
    elseif chat:find("/dd") then -- Drop World Lock
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|242|\ncount|" .. count); return true
    elseif chat:find("/db") then -- Drop Blue Gem Lock
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|7188|\ncount|" .. count); return true
    
    -- Drop Perkalian (Contoh: /pay 2x5)
    elseif chat:find("/pay") then
        local b, m = chat:match("(%d+)[xX*](%d+)")
        if b and m then
            local total = tonumber(b) * tonumber(m)
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. total)
            systemLog("`2[SYSTEM] Paid " .. total .. " DLs."); return true
        end
    
    -- Drop All (Semua WL, DL, BGL keluar)
    elseif chat == "/dropall" then
        for _, id in ipairs({7188, 1796, 242}) do
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. id .. "|\ncount|200")
        end
        systemLog("`wCleaning inventory..."); return true
    end

    -- [ SPAM & WORLD SAVE ]
    if chat:find("/sethome") then
        homeWorld = chat:match("/sethome%s+(%S+)"):upper()
        systemLog("`2[SYSTEM] Home: " .. homeWorld); return true
    elseif chat == "/save" and homeWorld ~= "" then
        sendPacket(3, "action|join_request\nname|" .. homeWorld); return true
    elseif chat:find("/spam") then
        local t, m = chat:match("/spam%s+(.+)%s+(%d+)")
        if t and m then
            spamText, spamInterval, spamActive = t, tonumber(m)*60000, true
            lastSpamTime = os.clock()*1000; systemLog("`2[SYSTEM] Spam ON"); sendPacket(2, "action|input\n|text|" .. spamText)
        elseif chat == "/spam off" then
            spamActive = false; systemLog("`2[SYSTEM] Spam OFF")
        end
        return true
    end

    if varlist[1] == "OnPingRequest" then myPing = varlist[2] or 0 end
end)

-- [ LOOP UTAMA ]
addEvent(Event.Packet, function(type, packet)
    local currentTime = os.clock()
    frameCount = frameCount + 1
    if currentTime - lastFrameTime >= 1.0 then
        currentFPS = frameCount
        frameCount = 0
        lastFrameTime = currentTime
        if fpsEnabled and isWhitelisted then
            local fpsColor = (currentFPS < 30 and "`4" or (currentFPS < 50 and "`e" or "`2"))
            sendVariantList({[1]="OnTextOverlay", [2]="`wFPS: " .. fpsColor .. currentFPS .. " `w| PING: `e" .. myPing}, -1)
        end
    end
    if spamActive then
        local now = os.clock() * 1000
        if now - lastSpamTime >= spamInterval then
            sendPacket(2, "action|input\n|text|" .. spamText)
            lastSpamTime = now
        end
    end
end)
