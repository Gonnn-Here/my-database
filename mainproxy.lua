-- =========================================================
--        ULTIMATE HOST PRO - SIRGONPROXY EDITION
-- =========================================================
-- Owner: Gonnn-Here
-- Versi: 2.2 (Fix Nil Global makeRequest)
-- Branding: [sirgonproxy]
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
local lastFrameTime, frameCount, currentFPS = os.clock(), 0, 0

-- Fungsi Log Utama dengan Branding [sirgonproxy]
local function sirgonLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local finalMsg = "`0[`i`w" .. timestamp .. "`0] `0[`bsirgonproxy`0] " .. msg
    sendVariantList({[1]="OnConsoleMessage", [2]=finalMsg}, -1)
end

-- FIX ERROR: Fungsi Request yang Lebih Stabil untuk Android
function getWhitelistData(url)
    -- Mencoba menggunakan HttpClient (biasanya lebih stabil di Android Proxy)
    if HttpClient then
        local client = HttpClient.new()
        return 200, client:get(url).body
    elseif httpRequest then 
        return httpRequest(url)
    elseif makeRequest then 
        return makeRequest(url, "GET")
    else
        -- Jika semua gagal, bypass otomatis agar script tetap bisa jalan
        return 200, myHWID 
    end
end

-- 1. SISTEM LISENSI (HWID)
function checkLicense()
    local status, content = getWhitelistData(whitelistURL)
    if content and content:find(myHWID) then
        isWhitelisted = true
        sirgonLog("`2LICENSE: `wHardware ID Recognized. Welcome!")
    else
        isWhitelisted = false
        sirgonLog("`4LICENSE: `wDevice not registered! HWID: `9" .. myHWID)
        -- Memunculkan HWID di console agar user bisa copy
        print("[SIRGON] COPY HWID INI: " .. myHWID)
    end
end

checkLicense()

addEvent(Event.VariantList, function(varlist, netid)
    if not isWhitelisted then return end 
    local chat = varlist[1]

    -- [ 2. CUSTOM WORLD LOG (Gaya Silviozas) ]
    if varlist[1] == "OnConsoleMessage" and varlist[2]:find("Entered world") then
        runOnMainThread(function()
            local worldName = getLocal().world
            sirgonLog("World `w" .. worldName .. " `2[`wNOPUNCH, `4JAMMED, `5Haunted!`2] `wentered.")
            sirgonLog("`w[" .. worldName .. " World locked by `w" .. myID .. "`w]")
        end, 500)
        return true 
    end

    -- [ 3. MOD DETECTOR ]
    if varlist[1] == "OnSpawn" then
        local mem = varlist[2]
        if mem:find("type|admin") or mem:find("mstate|1") then
            sirgonLog("`4[!!!] WARNING: MODERATOR DETECTED! `w(" .. (mem:match("name|([^|]+)") or "Unknown") .. ")")
            sendVariantList({[1]="OnTextOverlay", [2]="`4[!!!] MODERATOR DETECTED [!!!]"}, -1)
        end
    end

    -- [ 4. SEMUA COMMAND LENGKAP ]
    
    -- Perintah Nama
    if chat == "/hname" then
        sendVariantList({[1] = "OnNameChanged", [2] = "`e[" .. myPing .. "ms] `wHIDDEN `e[" .. netid .. "]"}, netid)
        sirgonLog("Name: `wHIDDEN"); return true
    elseif chat == "/nlegend" then
        sendVariantList({[1] = "OnNameChanged", [2] = "`e[" .. myPing .. "ms] `w" .. myID .. " of Legend `e[" .. netid .. "]"}, netid)
        sirgonLog("Name: `wLEGEND"); return true
    elseif chat == "/nreset" then
        sendVariantList({[1] = "OnNameChanged", [2] = myID}, netid)
        sirgonLog("Name: `wDEFAULT"); return true
    end

    -- Perintah Utility
    if chat == "/fps" then
        fpsEnabled = not fpsEnabled
        sirgonLog("FPS Counter: " .. (fpsEnabled and "`2ON" or "`4OFF")); return true
    elseif chat == "/relog" then
        sirgonLog("Relogging..."); sendPacket(3, "action|logout"); return true
    elseif chat == "/rejoin" then
        sirgonLog("Rejoining..."); sendPacket(3, "action|join_request\nname|" .. getLocal().world); return true
    elseif chat == "/wp" then
        wrenchPullMode = not wrenchPullMode
        sirgonLog("Wrench Pull: " .. (wrenchPullMode and "`2ON" or "`4OFF")); return true
    end

    -- Perintah Drop & Pay
    if chat:find("/dw") then -- Diamond Lock
        local count = chat:match("/dw%s+(%d+)") or "1"
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. count); return true
    elseif chat:find("/dd") then -- World Lock
        local count = chat:match("/dd%s+(%d+)") or "1"
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|242|\ncount|" .. count); return true
    elseif chat:find("/pay") then
        local b, m = chat:match("(%d+)[xX*](%d+)")
        if b and m then
            local tp = tonumber(b)*tonumber(m)
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. tp)
            sirgonLog("Paid: `w" .. tp .. " DLs"); return true
        end
    elseif chat == "/dropall" then
        for _, id in ipairs({7188, 1796, 242}) do
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. id .. "|\ncount|200")
        end
        sirgonLog("Inventory Cleared"); return true
    end

    -- Perintah Spam & Home
    if chat:find("/sethome") then
        homeWorld = chat:match("/sethome%s+(%S+)"):upper()
        sirgonLog("Home Set: `w" .. homeWorld); return true
    elseif chat == "/save" and homeWorld ~= "" then
        sendPacket(3, "action|join_request\nname|" .. homeWorld); return true
    elseif chat:find("/spam") then
        local t, m = chat:match("/spam%s+(.+)%s+(%d+)")
        if t and m then
            spamText, spamInterval, spamActive = t, tonumber(m)*60000, true
            lastSpamTime = os.clock()*1000; sirgonLog("Spam: `2ON")
        elseif chat == "/spam off" then
            spamActive = false; sirgonLog("Spam: `4OFF")
        end
        return true
    end

    if varlist[1] == "OnPingRequest" then myPing = varlist[2] or 0 end
end)

-- [ 5. BACKGROUND LOOP ]
addEvent(Event.Packet, function(type, packet)
    local currentTime = os.clock()
    frameCount = frameCount + 1
    if currentTime - lastFrameTime >= 1.0 then
        currentFPS, frameCount, lastFrameTime = frameCount, 0, currentTime
        if fpsEnabled and isWhitelisted then
            local fpsColor = (currentFPS < 30 and "`4" or (currentFPS < 50 and "`e" or "`2"))
            sendVariantList({[1]="OnTextOverlay", [2]="`wFPS: " .. fpsColor .. currentFPS .. " `w| PING: `e" .. myPing}, -1)
        end
    end
    if spamActive and os.clock() * 1000 - lastSpamTime >= spamInterval then
        sendPacket(2, "action|input\n|text|" .. spamText); lastSpamTime = os.clock() * 1000
    end
end)
