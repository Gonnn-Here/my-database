-- =========================================================
--        ULTIMATE HOST PRO - SECURITY EDITION (VIP)
-- =========================================================
-- Owner: Gonnn-Here
-- Versi: 1.8 (Mod Detector, Relog, Rejoin Added)
-- =========================================================

local whitelistURL = "https://raw.githubusercontent.com/Gonnn-Here/my-database/main/waitlist.txt"
local myHWID = getHWID()
local myID = getLocal().name
local isWhitelisted = false

-- Variabel Fitur
local wrenchPullMode = false
local lastWrenchedNetID = -1
local homeWorld, spamText = "", ""
local lastSpamTime, spamInterval, myPing = 0, 0, 0
local fpsEnabled, spamActive = false, false

-- Variabel FPS
local lastFrameTime, frameCount, currentFPS = os.clock(), 0, 0

-- 1. SISTEM LISENSI
function checkLicense()
    local status, content = makeRequest(whitelistURL, "GET")
    if status == 200 and content:find(myHWID) then
        isWhitelisted = true
        sendVariantList({[1]="OnConsoleMessage", [2]="`2[LICENSE] `wHardware ID Recognized!"}, -1)
    else
        isWhitelisted = false
        sendVariantList({[1]="OnConsoleMessage", [2]="`4[LICENSE] `wDevice not registered!\n`wHWID: `9" .. myHWID}, -1)
    end
end

checkLicense()

addEvent(Event.VariantList, function(varlist, netid)
    if not isWhitelisted then return end 

    local chat = varlist[1]
    local function systemLog(msg)
        sendVariantList({[1]="OnConsoleMessage", [2]=msg}, netid)
    end

    -- [ 2. MOD DETECTOR SYSTEM ]
    -- Mendeteksi saat ada player baru masuk (OnSpawn)
    if varlist[1] == "OnSpawn" then
        local mem = varlist[2]
        if mem:find("type|admin") or mem:find("mstate|1") then
            -- Notifikasi di Chat & Overlay Tengah Layar
            systemLog("`4[!!!] WARNING: MODERATOR DETECTED! `w(Name: " .. mem:match("name|([^|]+)") .. ")")
            sendVariantList({[1]="OnTextOverlay", [2]="`4[!!!] MODERATOR DETECTED [!!!]"}, -1)
            -- Mainkan suara peringatan (opsional jika proxy support)
            sendPacket(3, "action|play_sfx\nfile|audio/sfx/alert.wav")
        end
    end

    -- [ 3. RELOG & REJOIN COMMANDS ]
    if chat == "/relog" then
        systemLog("`2[SYSTEM] `wRelogging...")
        sendPacket(3, "action|logout") -- Memaksa akun logout ke menu awal
        return true
    elseif chat == "/rejoin" then
        local currentWorld = getLocal().world
        systemLog("`2[SYSTEM] `wRejoining world: " .. currentWorld)
        sendPacket(3, "action|join_request\nname|" .. currentWorld)
        return true
    end

    -- [ 4. CUSTOM NAME COMMANDS ]
    if chat == "/hname" then
        sendVariantList({[1] = "OnNameChanged", [2] = "`e[" .. myPing .. "ms] `wHIDDEN `e[" .. netid .. "]"}, netid); return true
    elseif chat == "/nlegend" then
        sendVariantList({[1] = "OnNameChanged", [2] = "`e[" .. myPing .. "ms] `w" .. myID .. " of Legend `e[" .. netid .. "]"}, netid); return true
    elseif chat == "/nreset" then
        sendVariantList({[1] = "OnNameChanged", [2] = myID}, netid); return true
    end

    -- [ 5. UTILITY & FPS ]
    if chat == "/fps" then
        fpsEnabled = not fpsEnabled
        systemLog("`2[SYSTEM] `wFPS Counter: " .. (fpsEnabled and "`9ON" or "`4OFF")); return true
    elseif chat == "/wp" then
        wrenchPullMode = not wrenchPullMode
        systemLog("`2[SYSTEM] `wWrench Pull Mode: " .. (wrenchPullMode and "`9ON" or "`4OFF")); return true
    end

    -- [ 6. REAL WHEEL & WRENCH LOGIC ]
    if varlist[1] == "OnDialogRequest" and varlist[2]:find("p_id") then
        local targetNetID = varlist[2]:match("p_id|(%d+)")
        if targetNetID then
            lastWrenchedNetID = targetNetID
            if wrenchPullMode then sendPacket(2, "action|input\n|text|/pull") return true end
        end
    end

    if varlist[1] == "OnTalkBubble" and varlist[2]:find("spun the wheel and got") then
        local name, number = varlist[2]:match("CP:(%w+).+got (%d+)") or varlist[2]:match("(.+) spun the wheel and got (%d+)")
        if number then
            local totalDigit = 0
            for digit in number:gmatch(".") do totalDigit = totalDigit + tonumber(digit) end
            systemLog("`#REAL! `w" .. name .. " `2rolled `w" .. number .. " `0[`b" .. totalDigit .. "`0]")
            sendVariantList({[1]="OnTextOverlay", [2]="`w" .. name .. " `2Punched `w" .. number .. " `0[`b" .. totalDigit .. "`0]"}, netid)
        end
    end

    -- [ 7. DROP & PAY SYSTEM ]
    local cmd, count = chat:match("(/%S+)%s+(%d+)")
    if not count then count = "1" end
    
    if chat:find("/dw") then
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. count); return true
    elseif chat:find("/dd") then
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|242|\ncount|" .. count); return true
    elseif chat:find("/db") then
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|7188|\ncount|" .. count); return true
    elseif chat:find("/pay") then
        local b, m = chat:match("(%d+)[xX*](%d+)")
        if b and m then
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. (tonumber(b)*tonumber(m)))
            return true
        end
    elseif chat == "/dropall" then
        for _, id in ipairs({7188, 1796, 242}) do
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. id .. "|\ncount|200")
        end
        return true
    end

    -- [ 8. SPAM & WORLD SAVE ]
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

-- [ 9. BACKGROUND LOOP ]
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
